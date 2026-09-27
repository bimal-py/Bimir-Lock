package com.cklamib.bimirLock.autofill

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.service.autofill.Dataset
import android.view.WindowManager
import android.view.autofill.AutofillId
import android.view.autofill.AutofillManager
import android.view.autofill.AutofillValue
import android.widget.RemoteViews
import android.widget.Toast
import android.app.AlertDialog
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_WEAK
import androidx.biometric.BiometricManager.Authenticators.DEVICE_CREDENTIAL
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import com.cklamib.bimirLock.R

// Started by the system when the user taps a Bimir Lock suggestion. Nothing is
// decrypted until the user passes fingerprint / face or the phone's screen lock;
// then exactly ONE password is handed back to the system to fill, and this screen
// closes. Every exit path sets a result, so the other app is never left waiting.
class FillAuthActivity : FragmentActivity() {

    private var finished = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Titles and usernames can appear in the picker: keep them out of screenshots
        // and the recents thumbnail.
        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        // Recreated after a configuration change: the prompt fragment survives on its
        // own, and starting a second one would stack two prompts.
        if (savedInstanceState != null) return
        try {
            authenticate()
        } catch (t: Throwable) {
            cancel()
        }
    }

    private fun authenticate() {
        val allowed = BIOMETRIC_WEAK or DEVICE_CREDENTIAL
        if (BiometricManager.from(this).canAuthenticate(allowed) != BiometricManager.BIOMETRIC_SUCCESS) {
            // No fingerprint, face or screen lock at all: anyone holding the phone could
            // fill, so filling is refused rather than made unprotected.
            Toast.makeText(this, "Set a screen lock to fill passwords from Bimir Lock.", Toast.LENGTH_LONG).show()
            cancel()
            return
        }
        val prompt = BiometricPrompt(this, ContextCompat.getMainExecutor(this),
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    onUnlocked()
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    cancel()
                }
                // onAuthenticationFailed = one bad finger; the prompt stays up for a retry.
            })
        prompt.authenticate(
            BiometricPrompt.PromptInfo.Builder()
                .setTitle("Fill with Bimir Lock")
                .setSubtitle(intent.getStringExtra(EXTRA_LABEL) ?: "Confirm it's you")
                .setAllowedAuthenticators(allowed)
                .build()
        )
    }

    private fun onUnlocked() {
        val rowId = intent.getLongExtra(EXTRA_ROW_ID, NO_ROW)
        if (rowId != NO_ROW) {
            deliver(rowId)
        } else {
            showPicker()
        }
    }

    private fun showPicker() {
        val entries = AutofillMatcher.ordered(
            PasswordStore.listEntries(this),
            intent.getStringExtra(EXTRA_TITLE) ?: "",
            intent.getStringExtra(EXTRA_PACKAGE),
            intent.getStringExtra(EXTRA_DOMAIN)
        )
        if (entries.isEmpty()) {
            Toast.makeText(this, "No saved passwords yet.", Toast.LENGTH_SHORT).show()
            cancel()
            return
        }
        val labels = entries.map { e ->
            val user = e.userName.ifBlank { "(no username)" }
            if (e.title.isBlank()) user else "${e.title} — $user"
        }.toTypedArray()
        AlertDialog.Builder(this)
            .setTitle("Choose a password")
            .setItems(labels) { _, which -> deliver(entries[which].id) }
            .setOnCancelListener { cancel() }
            .setNegativeButton("Cancel") { _, _ -> cancel() }
            .show()
    }

    private fun deliver(rowId: Long) {
        val passwordId = autofillId(EXTRA_PASSWORD_ID)
        val usernameId = autofillId(EXTRA_USERNAME_ID)
        val entry = PasswordStore.listEntries(this).firstOrNull { it.id == rowId }
        val password = if (passwordId != null) PasswordStore.revealPassword(this, rowId) else null
        if (entry == null || (passwordId != null && password == null)) {
            Toast.makeText(this, "Bimir Lock couldn't open that password.", Toast.LENGTH_SHORT).show()
            cancel()
            return
        }
        try {
            @Suppress("DEPRECATION")
            val builder = Dataset.Builder(presentation(this, entry))
            if (usernameId != null && entry.userName.isNotEmpty()) {
                @Suppress("DEPRECATION")
                builder.setValue(usernameId, AutofillValue.forText(entry.userName))
            }
            if (passwordId != null && password != null) {
                @Suppress("DEPRECATION")
                builder.setValue(passwordId, AutofillValue.forText(password))
            }
            val reply = Intent().putExtra(AutofillManager.EXTRA_AUTHENTICATION_RESULT, builder.build())
            finished = true
            setResult(Activity.RESULT_OK, reply)
        } catch (t: Throwable) {
            finished = true
            setResult(Activity.RESULT_CANCELED)
        }
        finish()
    }

    private fun autofillId(key: String): AutofillId? = try {
        if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(key, AutofillId::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(key)
        }
    } catch (t: Throwable) {
        null
    }

    private fun cancel() {
        if (finished) return
        finished = true
        setResult(Activity.RESULT_CANCELED)
        finish()
    }

    override fun onDestroy() {
        // Belt and braces: any path out of here without a result is a cancel.
        if (!finished && isFinishing) setResult(Activity.RESULT_CANCELED)
        super.onDestroy()
    }

    companion object {
        const val EXTRA_ROW_ID = "bimir.fill.rowId"
        const val EXTRA_USERNAME_ID = "bimir.fill.usernameId"
        const val EXTRA_PASSWORD_ID = "bimir.fill.passwordId"
        const val EXTRA_TITLE = "bimir.fill.title"
        const val EXTRA_PACKAGE = "bimir.fill.package"
        const val EXTRA_DOMAIN = "bimir.fill.domain"
        const val EXTRA_LABEL = "bimir.fill.label"
        const val NO_ROW = -1L

        // One suggestion row: username first, then which site/app it was saved for.
        fun presentation(context: Context, entry: PasswordStore.Entry): RemoteViews =
            row(context, entry.userName.ifBlank { "(no username)" }, entry.title)

        fun row(context: Context, primary: String, secondary: String): RemoteViews =
            RemoteViews(context.packageName, R.layout.bimir_autofill_item).apply {
                setTextViewText(R.id.bimir_autofill_primary, primary)
                setTextViewText(R.id.bimir_autofill_secondary, secondary)
            }
    }
}
