package com.cklamib.bimirLock.autofill

import android.app.assist.AssistStructure
import android.os.Build
import android.os.CancellationSignal
import android.service.autofill.AutofillService
import android.service.autofill.FillCallback
import android.service.autofill.FillRequest
import android.service.autofill.FillResponse
import android.service.autofill.SaveCallback
import android.service.autofill.SaveInfo
import android.service.autofill.SaveRequest
import android.util.Log

// Save only. We never build datasets, so the single job of onFillRequest is to
// register a SaveInfo -- without one the system never calls onSaveRequest at all.
// Both entry points run on this process's main thread and the system gives us
// 5 seconds, so everything here stays bounded and nothing is allowed to throw.
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
                    reply.send(FillResponse.Builder().setSaveInfo(delayed.build()).build())
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

            // Legal and documented: a SaveInfo with no datasets and no authentication.
            reply.send(FillResponse.Builder().setSaveInfo(builder.build()).build())
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
