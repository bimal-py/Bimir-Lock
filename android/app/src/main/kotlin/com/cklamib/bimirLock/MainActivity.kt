package com.cklamib.bimirLock

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.view.autofill.AutofillManager
import com.cklamib.bimirLock.crypto.VaultCryptoChannel
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private var autofillChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Keeps the automatic plugin registration. Never drop this call.
        super.configureFlutterEngine(flutterEngine)

        // The vault crypto channel owns its own handler and its own background thread.
        VaultCryptoChannel.attach(flutterEngine.dartExecutor.binaryMessenger, applicationContext)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUTOFILL_CHANNEL)
        autofillChannel = channel
        channel.setMethodCallHandler { call, result ->
            // Runs on the platform thread: an escaping exception takes the app down,
            // and an unanswered call hangs a Dart future. Every branch answers.
            try {
                when (call.method) {
                    "isAutofillSupported" -> result.success(autofillSupported())
                    "isAutofillEnabled" -> result.success(autofillEnabled())
                    "openAutofillSettings" -> result.success(openAutofillSettings())
                    "disableAutofillService" -> result.success(disableAutofillService())
                    "openSecuritySettings" -> result.success(openSecuritySettings())
                    else -> result.notImplemented()
                }
            } catch (t: Throwable) {
                Log.w(TAG, "autofill channel call ${call.method} failed", t)
                result.success(false)
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // Drop the handlers so a late call cannot touch a destroyed Activity.
        VaultCryptoChannel.detach()
        autofillChannel?.setMethodCallHandler(null)
        autofillChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    // Null on devices built without the autofill feature.
    private fun autofillManager(): AutofillManager? {
        return try {
            getSystemService(AutofillManager::class.java)
        } catch (t: Throwable) {
            Log.w(TAG, "AutofillManager unavailable", t)
            null
        }
    }

    // These make a blocking binder call behind a 5 s SyncResultReceiver and rethrow a
    // timeout as a plain RuntimeException, so they really can throw.
    private fun autofillSupported(): Boolean {
        return try {
            autofillManager()?.isAutofillSupported == true
        } catch (t: Throwable) {
            Log.w(TAG, "isAutofillSupported failed", t)
            false
        }
    }

    // hasEnabledAutofillServices() alone is not trustworthy: verified on API 36, the
    // very first call after our own process starts answers false even when we really
    // are the selected service, and only answers true once the activity has been
    // resumed a second time. getAutofillServiceComponentName() is right on both calls,
    // so a false is cross checked against it. That one is API 28, hence the guard.
    private fun autofillEnabled(): Boolean {
        val manager = autofillManager() ?: return false
        val enabled = try {
            manager.hasEnabledAutofillServices()
        } catch (t: Throwable) {
            Log.w(TAG, "hasEnabledAutofillServices failed", t)
            false
        }
        if (enabled) return true
        if (Build.VERSION.SDK_INT < 28) return false
        return try {
            manager.autofillServiceComponentName?.packageName == packageName
        } catch (t: Throwable) {
            Log.w(TAG, "getAutofillServiceComponentName failed", t)
            false
        }
    }

    private fun disableAutofillService(): Boolean {
        return try {
            val manager = autofillManager() ?: return false
            // Same reason as above: gating on the raw boolean would make turning the
            // switch off a silent no-op on the first run of the app.
            if (autofillEnabled()) {
                manager.disableAutofillServices()
            }
            true
        } catch (t: Throwable) {
            Log.w(TAG, "disableAutofillServices failed", t)
            false
        }
    }

    // Activity context on purpose: this starts an activity in our own task.
    private fun openAutofillSettings(): Boolean {
        val intent = Intent(Settings.ACTION_REQUEST_SET_AUTOFILL_SERVICE)
            .setData(Uri.parse("package:$packageName"))
        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            Log.w(TAG, "device has no autofill settings screen", e)
            false
        } catch (t: Throwable) {
            Log.w(TAG, "could not open autofill settings", t)
            false
        }
    }

    // Where fingerprints and face unlock are enrolled, for "Set up fingerprint first".
    private fun openSecuritySettings(): Boolean {
        return try {
            startActivity(Intent(Settings.ACTION_SECURITY_SETTINGS))
            true
        } catch (t: Throwable) {
            Log.w(TAG, "could not open security settings", t)
            false
        }
    }

    companion object {
        private const val TAG = "BimirAutofill"
        private const val AUTOFILL_CHANNEL = "com.cklamib.bimirLock/autofill"
    }
}
