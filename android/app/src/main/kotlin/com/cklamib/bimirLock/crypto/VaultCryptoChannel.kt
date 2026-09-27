package com.cklamib.bimirLock.crypto

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * The Dart side of the vault never holds key material and never runs a cipher: it moves
 * strings across this channel. The Swift implementation answers the identical contract.
 *
 *   ensureKey     {"kcv": String?}      -> {"kcv": String, "securityLevel": String}
 *   encryptBatch  {"values": [String]}  -> [String], same length and order
 *   decryptBatch  {"values": [String]}  -> [ {"status":"ok","value":String}
 *                                         |  {"status":"plain","value":String}
 *                                         |  {"status":"damaged"} ], same length and order
 *
 * Every Keystore call is a binder round trip, so a 300 row batch on the platform thread is a
 * visible stall and, at the wrong moment, an ANR. All work runs on a single background daemon
 * thread and every reply is posted back to the main looper, because MethodChannel.Result must
 * be answered there.
 *
 * Error payloads carry a CLASS NAME at most. They cross into Dart logs, so they must never
 * carry a value.
 */
object VaultCryptoChannel {

    private const val CHANNEL = "com.cklamib.bimirLock/vault_crypto"

    private val worker = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "bimir-vault-crypto").apply { isDaemon = true }
    }
    private val main = Handler(Looper.getMainLooper())

    private var channel: MethodChannel? = null

    @Volatile
    private var appContext: Context? = null

    fun attach(messenger: BinaryMessenger, context: Context) {
        detach()
        appContext = context.applicationContext
        val created = MethodChannel(messenger, CHANNEL)
        channel = created
        created.setMethodCallHandler { call, result -> dispatch(call, result) }
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
        appContext = null
    }

    private fun dispatch(call: MethodCall, result: MethodChannel.Result) {
        // Runs on the platform thread: an escaping exception takes the app down and an
        // unanswered call hangs a Dart future forever. Every branch answers exactly once.
        val context = appContext
        if (context == null) {
            result.error("vault_crypto_failed", "DetachedChannel", null)
            return
        }
        try {
            when (call.method) {
                "ensureKey" -> {
                    // Absent and explicit null are the same thing here: a first run.
                    val stored = call.argument<String>("kcv")
                    submit(result) {
                        mapOf(
                            "kcv" to VaultCrypto.ensureKey(context, stored),
                            "securityLevel" to VaultCrypto.securityLevel(context)
                        )
                    }
                }

                "encryptBatch" -> {
                    val values = stringList(call.argument<Any?>("values"))
                    if (values == null) {
                        result.error("vault_crypto_failed", "IllegalArgumentException", null)
                        return
                    }
                    submit(result) { values.map { VaultCrypto.encrypt(context, it) } }
                }

                "decryptBatch" -> {
                    val values = stringList(call.argument<Any?>("values"))
                    if (values == null) {
                        result.error("vault_crypto_failed", "IllegalArgumentException", null)
                        return
                    }
                    submit(result) { values.map { statusOf(VaultCrypto.decode(context, it)) } }
                }

                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            fail(result, t)
        }
    }

    /** Same length, same order, or null when the argument is not a list of strings. */
    private fun stringList(raw: Any?): List<String>? {
        if (raw !is List<*>) return null
        val out = ArrayList<String>(raw.size)
        for (item in raw) {
            if (item !is String) return null
            out.add(item)
        }
        return out
    }

    private fun statusOf(decoded: Decoded): Map<String, Any?> = when (decoded.kind) {
        // value is non-null for OK and PLAIN by construction; the elvis is belt and braces
        // so a future change cannot turn a readable row into a null on the Dart side.
        Kind.OK -> mapOf("status" to "ok", "value" to (decoded.value ?: ""))
        Kind.PLAIN -> mapOf("status" to "plain", "value" to (decoded.value ?: ""))
        Kind.DAMAGED -> mapOf("status" to "damaged")
    }

    private fun submit(result: MethodChannel.Result, work: () -> Any?) {
        try {
            worker.execute {
                var value: Any? = null
                var error: Throwable? = null
                try {
                    value = work()
                } catch (t: Throwable) {
                    error = t
                }
                val produced = value
                val failure = error
                main.post {
                    if (failure != null) fail(result, failure) else result.success(produced)
                }
            }
        } catch (t: Throwable) {
            // RejectedExecutionException and friends: answer now rather than hang the future.
            fail(result, t)
        }
    }

    private fun fail(result: MethodChannel.Result, t: Throwable) {
        if (t is KeyUnavailable) {
            result.error(t.code, t.cause?.javaClass?.simpleName, null)
        } else {
            result.error("vault_crypto_failed", t.javaClass.simpleName, null)
        }
    }
}
