package com.cklamib.bimirLock.crypto

import android.content.Context
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyInfo
import android.security.keystore.KeyProperties
import android.util.Base64
import java.io.File
import java.io.RandomAccessFile
import java.nio.channels.FileLock
import java.security.KeyStore
import java.util.Arrays
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.GCMParameterSpec

/**
 * Every failure that means "the key cannot be used right now, or ever again".
 *
 * [code] is one of the codes the vault_crypto MethodChannel contract publishes:
 * kcv_mismatch | keystore_unavailable | key_unreadable | key_wrong_type |
 * key_create_failed | bad_iv_length | vault_crypto_failed.
 * It is a fixed identifier, never a value, so it is safe to log and safe to send to Dart.
 */
class KeyUnavailable(val code: String, cause: Throwable? = null) : Exception(code, cause)

/** Tri-state classification of a stored password column value. Never the prefix alone. */
enum class Kind { OK, PLAIN, DAMAGED }

/** [value] carries the usable string for OK and PLAIN, and is null for DAMAGED. */
data class Decoded(val kind: Kind, val value: String?)

/**
 * AES-256-GCM sealing for the PasswordTable.password column, under a non-exportable
 * AndroidKeyStore key.
 *
 * Envelope, byte-normative and shared with the Dart and Swift sides:
 *
 *     "v1:" ++ base64Standard( iv[12] || ciphertext[n] || tag[16] )
 *
 * AAD is the ASCII constant "bimirlock.pwd.v1"; base64 is RFC 4648 section 4, padded,
 * with NO line breaks. A one byte disagreement between the three platforms is a
 * permanently unreadable vault, so nothing in here may be "tidied up" without changing
 * the other two implementations in the same commit.
 *
 * Imports nothing from io.flutter on purpose: BimirAutofillService calls this with no
 * Flutter engine attached. The MethodChannel wrapper lives in VaultCryptoChannel.kt.
 *
 * Nothing here ever logs, and no function returns key material.
 */
object VaultCrypto {

    private const val PREFIX = "v1:"
    private const val ALIAS = "bimirlock.vault.pwd.v1"
    private const val PROVIDER = "AndroidKeyStore"
    private const val TRANSFORM = "AES/GCM/NoPadding"
    private const val KEY_BITS = 256
    private const val IV_BYTES = 12
    private const val TAG_BITS = 128
    private const val TAG_BYTES = 16
    private const val LOCK_FILE = "bimir_vault_key.lock"

    /** Authenticated, never stored. Deliberately NOT bound to the row id: see the spec. */
    private val AAD = "bimirlock.pwd.v1".toByteArray(Charsets.US_ASCII)

    /** Public constant. Its envelope is VaultMeta.kcv_v1 and proves the key is the same key. */
    private const val KCV_PLAINTEXT = "bimirlock.kcv.v1"

    /** Guards generation against the other threads of THIS process. */
    private val jvmLock = Any()

    @Volatile
    private var cachedKey: SecretKey? = null

    // ---------------------------------------------------------------- public API

    /**
     * Loads (or, exactly once per install, creates) the key and reconciles it with the
     * stored key check value.
     *
     * @param storedKcv null on a first run: the caller gets a fresh envelope back and is
     *   responsible for persisting it as VaultMeta.kcv_v1. Otherwise the stored envelope,
     *   which must decrypt back to KCV_PLAINTEXT under the key we just loaded.
     * @return the envelope to persist (fresh) or the one that was passed in (verified).
     * @throws KeyUnavailable("kcv_mismatch") when the stored value does not recover the
     *   constant. That means this is NOT the key the vault was encrypted under. The caller
     *   must fail closed: never regenerate, never re-encrypt, never write.
     */
    fun ensureKey(context: Context, storedKcv: String?): String {
        val key = key(context)
        if (storedKcv == null) return encryptWith(key, KCV_PLAINTEXT)
        val decoded = decodeUnder(key, storedKcv)
        if (decoded.kind != Kind.OK || decoded.value != KCV_PLAINTEXT) {
            throw KeyUnavailable("kcv_mismatch")
        }
        return storedKcv
    }

    /**
     * "strongbox" | "trusted_environment" | "software" | "unknown".
     * DIAGNOSTICS ONLY. Never gate behaviour on this: a device that reports "software"
     * still holds a perfectly good vault, and refusing to run there would lock the user out.
     */
    fun securityLevel(context: Context): String {
        return try {
            val key = key(context)
            val factory = SecretKeyFactory.getInstance(key.algorithm, PROVIDER)
            val info = factory.getKeySpec(key, KeyInfo::class.java) as KeyInfo
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                when (info.securityLevel) {
                    KeyProperties.SECURITY_LEVEL_STRONGBOX -> "strongbox"
                    KeyProperties.SECURITY_LEVEL_TRUSTED_ENVIRONMENT -> "trusted_environment"
                    KeyProperties.SECURITY_LEVEL_SOFTWARE -> "software"
                    else -> "unknown"
                }
            } else {
                legacySecurityLevel(info)
            }
        } catch (t: Throwable) {
            "unknown"
        }
    }

    /** Seals [plaintext] into a fresh envelope. Throws [KeyUnavailable]; never returns plaintext. */
    fun encrypt(context: Context, plaintext: String): String = encryptWith(key(context), plaintext)

    /**
     * Classifies a stored column value. The three states are what stop the two catastrophes:
     * a real user password that literally starts with "v1:" is PLAIN and migrates losslessly,
     * and a corrupted ciphertext is DAMAGED, never re-encrypted into oblivion.
     */
    fun decode(context: Context, stored: String): Decoded {
        // Rules 1-3 need no key at all, so a value that cannot possibly be one of ours is
        // classified without ever touching the Keystore.
        if (!stored.startsWith(PREFIX)) return Decoded(Kind.PLAIN, stored)
        val blob = decodeBody(stored) ?: return Decoded(Kind.PLAIN, stored)
        // key() throws KeyUnavailable, which must propagate: "the key is broken" is not
        // the same claim as "this row is damaged", and only the first one is recoverable.
        return openBlob(key(context), blob)
    }

    // ------------------------------------------------------------------- envelope

    /** Returns the raw iv||ciphertext||tag blob, or null when the value cannot be one of ours. */
    private fun decodeBody(stored: String): ByteArray? {
        val blob = try {
            // NO_WRAP: the encoder never emits line breaks, so neither does the decoder expect any.
            Base64.decode(stored.substring(PREFIX.length), Base64.NO_WRAP)
        } catch (t: Throwable) {
            return null // rule 2: not valid base64, so it is a legacy plaintext that looks like us
        }
        // rule 3: an envelope is at minimum an iv and a tag, even for an empty password.
        if (blob.size < IV_BYTES + TAG_BYTES) return null
        return blob
    }

    private fun encryptWith(key: SecretKey, plaintext: String): String {
        val cipher = try {
            Cipher.getInstance(TRANSFORM)
        } catch (t: Throwable) {
            throw KeyUnavailable("vault_crypto_failed", t)
        }
        try {
            // NO GCMParameterSpec here. Keystore keys are generated with
            // setRandomizedEncryptionRequired(true), which makes a caller supplied IV an
            // InvalidAlgorithmParameterException on ENCRYPT. The IV is read back below.
            // DECRYPT is the opposite and does take a spec.
            cipher.init(Cipher.ENCRYPT_MODE, key)
        } catch (t: Throwable) {
            throw KeyUnavailable("key_unreadable", t)
        }
        cipher.updateAAD(AAD)
        val iv = cipher.iv
        // Asserted, not trusted: the envelope layout is positional, so a provider that ever
        // handed back a different IV length would silently produce unreadable ciphertext.
        if (iv == null || iv.size != IV_BYTES) throw KeyUnavailable("bad_iv_length")

        val source = plaintext.toByteArray(Charsets.UTF_8)
        val body = try {
            cipher.doFinal(source) // ciphertext || tag
        } catch (t: Throwable) {
            Arrays.fill(source, 0)
            throw KeyUnavailable("vault_crypto_failed", t)
        }
        Arrays.fill(source, 0)

        val out = ByteArray(iv.size + body.size)
        System.arraycopy(iv, 0, out, 0, iv.size)
        System.arraycopy(body, 0, out, iv.size, body.size)
        Arrays.fill(body, 0)

        // NO_WRAP is MANDATORY: Base64.DEFAULT appends "\n", which Dart's base64Decode and
        // Swift's Data(base64Encoded:) both reject outright.
        val envelope = PREFIX + Base64.encodeToString(out, Base64.NO_WRAP)
        Arrays.fill(out, 0)
        return envelope
    }

    private fun decodeUnder(key: SecretKey, stored: String): Decoded {
        if (!stored.startsWith(PREFIX)) return Decoded(Kind.PLAIN, stored)
        val blob = decodeBody(stored) ?: return Decoded(Kind.PLAIN, stored)
        return openBlob(key, blob)
    }

    private fun openBlob(key: SecretKey, blob: ByteArray): Decoded {
        val cipher = try {
            Cipher.getInstance(TRANSFORM)
        } catch (t: Throwable) {
            throw KeyUnavailable("vault_crypto_failed", t)
        }
        try {
            cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(TAG_BITS, blob, 0, IV_BYTES))
            cipher.updateAAD(AAD)
        } catch (t: Throwable) {
            // init has not looked at the ciphertext yet, so this can only be the key or the
            // provider failing. Reporting it as DAMAGED would tell the user their row is
            // lost when in fact the whole Keystore is having a bad day and next launch is fine.
            throw KeyUnavailable("key_unreadable", t)
        }
        val plain = try {
            cipher.doFinal(blob, IV_BYTES, blob.size - IV_BYTES)
        } catch (t: Throwable) {
            // AEADBadTagException and everything else: the tag did not verify under a key we
            // do hold. Do NOT display it, do NOT re-encrypt it, do NOT write it back.
            return Decoded(Kind.DAMAGED, null)
        }
        val value = String(plain, Charsets.UTF_8)
        Arrays.fill(plain, 0)
        return Decoded(Kind.OK, value)
    }

    // --------------------------------------------------------------- key lifecycle

    private fun key(context: Context): SecretKey {
        cachedKey?.let { return it }
        synchronized(jvmLock) {
            cachedKey?.let { return it }
            val loaded = loadOrCreate(context)
            cachedKey = loaded
            return loaded
        }
    }

    /**
     * Two racing generateKey() calls on one alias do NOT fail: the second silently REPLACES
     * the first, and every row already encrypted under key A becomes permanently unreadable.
     * The autofill service can be started by the system while the app's own process is
     * already running, so this really is reachable.
     *
     * Three layers, in this order:
     *  1. synchronized(jvmLock) around the caller, because FileChannel.lock() is exclusive
     *     PER JVM and taking it twice in one process throws OverlappingFileLockException,
     *     which would make the file lock actively harmful on its own.
     *  2. an exclusive FileChannel lock, which covers any future separate process.
     *  3. a re-check of the alias INSIDE the lock, so the loser of the race adopts the
     *     winner's key instead of overwriting it.
     */
    private fun loadOrCreate(context: Context): SecretKey {
        existingOrNull()?.let { return it }

        val app = context.applicationContext
        val lockFile = File(app.filesDir, LOCK_FILE)
        var raf: RandomAccessFile? = null
        var lock: FileLock? = null
        try {
            try {
                lockFile.parentFile?.mkdirs()
            } catch (t: Throwable) {
                // filesDir is created by the framework; a failure here is not fatal on its own.
            }
            val opened = RandomAccessFile(lockFile, "rw")
            raf = opened
            lock = opened.channel.lock()
        } catch (t: Throwable) {
            closeQuietly(lock, raf)
            // Fail closed. Generating without the lock is the one thing that can destroy a
            // vault, and a skipped save or a retried launch costs the user nothing.
            throw KeyUnavailable("key_create_failed", t)
        }

        try {
            existingOrNull()?.let { return it }
            return generate()
        } finally {
            closeQuietly(lock, raf)
        }
    }

    private fun closeQuietly(lock: FileLock?, raf: RandomAccessFile?) {
        try {
            lock?.release()
        } catch (t: Throwable) {
        }
        try {
            raf?.close()
        } catch (t: Throwable) {
        }
    }

    /**
     * Returns null IF AND ONLY IF containsAlias() answered false.
     *
     * A transient Keystore error misread as "the key is absent" is the single fastest route
     * to destroying every password on the device, so every other outcome throws. In
     * particular an alias that exists but will not load is NEVER deleted and NEVER replaced:
     * OEM Keystore entries have come back after a reboot or an OTA, and overwriting is not
     * reversible.
     */
    private fun existingOrNull(): SecretKey? {
        val store = try {
            KeyStore.getInstance(PROVIDER).apply { load(null) }
        } catch (t: Throwable) {
            throw KeyUnavailable("keystore_unavailable", t)
        }
        val present = try {
            store.containsAlias(ALIAS)
        } catch (t: Throwable) {
            throw KeyUnavailable("keystore_unavailable", t)
        }
        if (!present) return null

        val entry = try {
            store.getEntry(ALIAS, null)
        } catch (t: Throwable) {
            throw KeyUnavailable("key_unreadable", t)
        } ?: throw KeyUnavailable("key_unreadable")

        if (entry !is KeyStore.SecretKeyEntry) throw KeyUnavailable("key_wrong_type")
        return entry.secretKey
    }

    /**
     * One boring generation path. No branches, no fallback, no second attempt: code that can
     * generate twice against one alias is code that can replace a key which already encrypted
     * data.
     *
     * Deliberately NOT set, each for a reason:
     *  - setUserAuthenticationRequired: a routine lock screen PIN change permanently
     *    invalidates the key. With allowBackup="false" that is total, irreversible vault
     *    loss. It also breaks autofill saves, which run with no user present.
     *  - setInvalidatedByBiometricEnrollment: same class of catastrophe, triggered by
     *    enrolling a fingerprint.
     *  - setUnlockedDeviceRequired: unverifiable behaviour across OEMs, and it would block
     *    an autofill save on a locked device.
     *  - setIsStrongBoxBacked: patchy OEM availability makes the fallback the common path,
     *    and try/generate/catch/generate against one alias is exactly the shape that
     *    replaces a live key.
     */
    private fun generate(): SecretKey {
        return try {
            val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, PROVIDER)
            generator.init(
                KeyGenParameterSpec.Builder(
                    ALIAS,
                    KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
                )
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .setKeySize(KEY_BITS)
                    // Already the default. Spelled out so that removing it is a visible edit:
                    // without it the encrypt path could accept a caller supplied IV, and a
                    // repeated IV under GCM is a total break of the ciphertext.
                    .setRandomizedEncryptionRequired(true)
                    .build()
            )
            generator.generateKey()
        } catch (t: Throwable) {
            throw KeyUnavailable("key_create_failed", t)
        }
    }

    @Suppress("DEPRECATION")
    private fun legacySecurityLevel(info: KeyInfo): String =
        if (info.isInsideSecureHardware) "trusted_environment" else "software"
}
