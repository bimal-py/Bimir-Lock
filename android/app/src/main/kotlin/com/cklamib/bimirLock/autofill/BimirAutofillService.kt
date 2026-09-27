package com.cklamib.bimirLock.autofill

import android.app.PendingIntent
import android.app.assist.AssistStructure
import android.content.Intent
import android.content.IntentSender
import android.os.Build
import android.os.CancellationSignal
import android.service.autofill.AutofillService
import android.service.autofill.CharSequenceTransformation
import android.service.autofill.CustomDescription
import android.service.autofill.Dataset
import android.service.autofill.FillCallback
import android.service.autofill.FillRequest
import android.service.autofill.FillResponse
import android.service.autofill.SaveCallback
import android.service.autofill.SaveInfo
import android.service.autofill.SaveRequest
import android.util.Log
import android.view.autofill.AutofillId
import android.view.autofill.AutofillValue
import android.widget.RemoteViews
import com.cklamib.bimirLock.R
import java.util.regex.Pattern

// onFillRequest does two jobs: it offers saved passwords for this app/site (each one
// locked behind FillAuthActivity, so nothing is decrypted before fingerprint / screen
// lock), and it registers a SaveInfo -- without one the system never calls
// onSaveRequest at all. Both entry points run on this process's main thread and the
// system gives us 5 seconds, so everything here stays bounded and nothing throws.
// Only titles and usernames are read here; they are stored unencrypted.
class BimirAutofillService : AutofillService() {

    override fun onFillRequest(
        request: FillRequest,
        cancellationSignal: CancellationSignal,
        callback: FillCallback
    ) {
        val reply = FillReply(callback)
        try {
            val contexts = request.fillContexts
            if (contexts.isEmpty()) {
                reply.send(null)
                return
            }
            // Reading the structure does a blocking binder transfer and can throw.
            val structure: AssistStructure? =
                try { contexts[contexts.size - 1].structure } catch (t: Throwable) { null }
            val pkg = try { structure?.activityComponent?.packageName } catch (t: Throwable) { null }
            if (StructureParser.isBlockedSource(this, structure, pkg)) {
                reply.send(null)
                return
            }

            val parsed = StructureParser.parse(structure)
            val passwordId = parsed?.passwordId
            if (passwordId == null) {
                // A username field but no password: the first step of a two-step login.
                // FLAG_DELAY_SAVE suppresses the save UI here and hands this FillContext
                // to the later requests of the same task, so the password screen's save
                // request still sees the username. Without it the null below would end
                // the session and the row would be written with an empty username.
                val pendingUserId = parsed?.usernameId
                if (pendingUserId != null && Build.VERSION.SDK_INT >= 28) {
                    val delayed = SaveInfo.Builder(
                        SaveInfo.SAVE_DATA_TYPE_USERNAME, arrayOf(pendingUserId)
                    )
                    delayed.setFlags(SaveInfo.FLAG_DELAY_SAVE)
                    val response = FillResponse.Builder().setSaveInfo(delayed.build())
                    // A username is not a secret, so on this first step it fills directly.
                    addUsernameSuggestions(response, parsed, pendingUserId)
                    reply.send(response.build())
                    return
                }
                // Nothing savable on this screen. Returning null destroys the session
                // and any SaveInfo from an earlier request, which is correct only here.
                reply.send(null)
                return
            }

            // requiredIds must be non-empty and every id must come from a ViewNode in
            // THIS structure. Password required, username optional: requiring the
            // username would silently kill save on password-only second steps.
            val builder = SaveInfo.Builder(SaveInfo.SAVE_DATA_TYPE_PASSWORD, arrayOf(passwordId))
            builder.setFlags(SaveInfo.FLAG_SAVE_ON_ALL_VIEWS_INVISIBLE)
            val usernameId = parsed.usernameId
            if (usernameId != null && usernameId != passwordId) {
                builder.setOptionalIds(arrayOf(usernameId))
            }

            val title = StructureParser.credentialTitle(this, parsed)
            describeSave(builder, title, usernameId.takeIf { it != passwordId })

            val response = FillResponse.Builder().setSaveInfo(builder.build())
            addLockedSuggestions(response, parsed, title, usernameId, passwordId)
            // Legal with or without datasets: a SaveInfo alone is enough.
            reply.send(response.build())
        } catch (t: Throwable) {
            Log.w(TAG, "onFillRequest failed: ${t.javaClass.simpleName}")
        } finally {
            reply.send(null) // no-op once already sent; we can never time out
        }
    }

    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
        val reply = SaveReply(callback)
        try {
            val contexts = request.fillContexts
            if (contexts.isEmpty()) {
                reply.send(true)
                return
            }
            // Keep the newest contexts: on a two step login the password screen is last.
            val from = if (contexts.size > MAX_CONTEXTS) contexts.size - MAX_CONTEXTS else 0
            val structures = ArrayList<AssistStructure?>(contexts.size - from)
            for (i in from until contexts.size) {
                structures.add(try { contexts[i].structure } catch (t: Throwable) { null })
            }

            val last = structures.lastOrNull { it != null }
            val pkg = try { last?.activityComponent?.packageName } catch (t: Throwable) { null }
            if (StructureParser.isBlockedSource(this, last, pkg)) {
                reply.send(true)
                return
            }

            val parsed = StructureParser.parseContexts(structures)
            if (parsed == null || !parsed.hasCredential) {
                // No password, or a change password form we could not read safely.
                reply.send(true)
                return
            }

            val title = StructureParser.credentialTitle(this, parsed)
            val result = PasswordStore.save(
                applicationContext, title, parsed.username, parsed.password
            )
            reply.send(result != PasswordStore.Result.FAILED)
        } catch (t: Throwable) {
            Log.w(TAG, "onSaveRequest failed: ${t.javaClass.simpleName}")
            reply.send(false)
        } finally {
            reply.send(true) // no-op once already sent
        }
    }

    // ---- fill ------------------------------------------------------------------

    private fun addLockedSuggestions(
        response: FillResponse.Builder,
        parsed: ParsedCredential,
        title: String,
        usernameId: AutofillId?,
        passwordId: AutofillId
    ) {
        try {
            val entries = PasswordStore.listEntries(this)
            if (entries.isEmpty()) return
            val ids = if (usernameId != null && usernameId != passwordId) {
                arrayOf(usernameId, passwordId)
            } else {
                arrayOf(passwordId)
            }
            val matches = AutofillMatcher.suggestions(entries, title, parsed.packageName, parsed.webDomain)
            for (entry in matches) {
                response.addDataset(lockedDataset(
                    ids, FillAuthActivity.presentation(this, entry),
                    authIntent(entry.id, title, parsed, usernameId, passwordId)
                ))
            }
            // Always offered: reaches passwords the name matching cannot find.
            response.addDataset(lockedDataset(
                ids, FillAuthActivity.row(this, "Choose from Bimir Lock…", "${entries.size} saved"),
                authIntent(FillAuthActivity.NO_ROW, title, parsed, usernameId, passwordId)
            ))
        } catch (t: Throwable) {
            // Suggestions are optional; saving must still work.
            Log.w(TAG, "suggestions failed: ${t.javaClass.simpleName}")
        }
    }

    private fun addUsernameSuggestions(
        response: FillResponse.Builder,
        parsed: ParsedCredential?,
        usernameId: AutofillId
    ) {
        try {
            val entries = PasswordStore.listEntries(this)
            if (entries.isEmpty() || parsed == null) return
            val title = StructureParser.credentialTitle(this, parsed)
            for (entry in AutofillMatcher.suggestions(entries, title, parsed.packageName, parsed.webDomain)) {
                if (entry.userName.isBlank()) continue
                @Suppress("DEPRECATION")
                val dataset = Dataset.Builder(FillAuthActivity.presentation(this, entry))
                @Suppress("DEPRECATION")
                dataset.setValue(usernameId, AutofillValue.forText(entry.userName))
                response.addDataset(dataset.build())
            }
        } catch (t: Throwable) {
            Log.w(TAG, "username suggestions failed: ${t.javaClass.simpleName}")
        }
    }

    // Values stay null until FillAuthActivity returns the unlocked dataset.
    private fun lockedDataset(ids: Array<AutofillId>, presentation: RemoteViews, auth: IntentSender): Dataset {
        @Suppress("DEPRECATION")
        val builder = Dataset.Builder(presentation)
        for (id in ids) {
            @Suppress("DEPRECATION")
            builder.setValue(id, null)
        }
        builder.setAuthentication(auth)
        return builder.build()
    }

    private fun authIntent(
        rowId: Long,
        title: String,
        parsed: ParsedCredential,
        usernameId: AutofillId?,
        passwordId: AutofillId
    ): IntentSender {
        val intent = Intent(this, FillAuthActivity::class.java).apply {
            putExtra(FillAuthActivity.EXTRA_ROW_ID, rowId)
            putExtra(FillAuthActivity.EXTRA_PASSWORD_ID, passwordId)
            if (usernameId != null && usernameId != passwordId) {
                putExtra(FillAuthActivity.EXTRA_USERNAME_ID, usernameId)
            }
            putExtra(FillAuthActivity.EXTRA_TITLE, title)
            putExtra(FillAuthActivity.EXTRA_PACKAGE, parsed.packageName)
            putExtra(FillAuthActivity.EXTRA_DOMAIN, parsed.webDomain)
            putExtra(FillAuthActivity.EXTRA_LABEL, title)
        }
        // MUTABLE: the system adds the assist structure to this intent. A distinct
        // request code per row, or the extras of one suggestion would overwrite another's.
        var flags = PendingIntent.FLAG_CANCEL_CURRENT
        if (Build.VERSION.SDK_INT >= 31) flags = flags or PendingIntent.FLAG_MUTABLE
        val code = if (rowId == FillAuthActivity.NO_ROW) Int.MAX_VALUE else (rowId % Int.MAX_VALUE).toInt()
        return PendingIntent.getActivity(this, code, intent, flags).intentSender
    }

    // ---- save prompt ---------------------------------------------------------------

    // Shows which account is about to be saved inside the system "Save password to
    // Bimir Lock?" sheet: the site/app, the username as typed, and a masked password.
    private fun describeSave(builder: SaveInfo.Builder, title: String, usernameId: AutofillId?) {
        try {
            if (Build.VERSION.SDK_INT >= 27) {
                val views = RemoteViews(packageName, R.layout.bimir_autofill_save_description)
                views.setTextViewText(R.id.bimir_save_title, title)
                views.setTextViewText(R.id.bimir_save_user, "")
                val description = CustomDescription.Builder(views)
                if (usernameId != null) {
                    // Copies whatever is in the username field at save time. The password
                    // field is never referenced here, so it can never be shown.
                    description.addChild(
                        R.id.bimir_save_user,
                        CharSequenceTransformation.Builder(usernameId, Pattern.compile("^(.*)$"), "$1").build()
                    )
                }
                builder.setCustomDescription(description.build())
            } else {
                builder.setDescription(title)
            }
        } catch (t: Throwable) {
            // The plain system sheet still works.
            Log.w(TAG, "save description failed: ${t.javaClass.simpleName}")
        }
    }

    override fun onConnected() { /* nothing to warm up */ }

    override fun onDisconnected() { /* stateless; the process may be killed after this */ }

    // The flag is set BEFORE the call: onSuccess marks itself called even if it then
    // throws, so setting it afterwards would let the finally block call it twice.
    private class FillReply(private val cb: FillCallback) {
        private var done = false
        fun send(response: FillResponse?) {
            if (done) return
            done = true
            try {
                cb.onSuccess(response)
            } catch (t: Throwable) {
                Log.w(TAG, "fill callback rejected: ${t.javaClass.simpleName}")
            }
        }
    }

    private class SaveReply(private val cb: SaveCallback) {
        private var done = false
        fun send(ok: Boolean) {
            if (done) return
            done = true
            try {
                if (ok) cb.onSuccess() else cb.onFailure("Could not save to Bimir Lock")
            } catch (t: Throwable) {
                Log.w(TAG, "save callback rejected: ${t.javaClass.simpleName}")
            }
        }
    }

    companion object {
        private const val TAG = "BimirAutofill"
        private const val MAX_CONTEXTS = 8
    }
}
