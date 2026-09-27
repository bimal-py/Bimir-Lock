import CryptoKit
import Foundation
import Security

/// Bimir Lock vault crypto — the iOS half of the frozen cross-platform envelope contract.
///
/// FROZEN FORMAT (identical bytes on Android/Kotlin, iOS/Swift and consumed by Dart):
///
///     envelope := "v1:" ++ base64Standard( iv[12] || ciphertext[n] || tag[16] )
///     cipher    AES-256-GCM, 128-bit tag
///     aad       ASCII "bimirlock.pwd.v1"  (authenticated, never stored)
///     base64    RFC 4648 §4, standard alphabet, WITH padding, NO line breaks
///
/// Nothing in this file ever logs, prints or persists a plaintext, an envelope or key material.
/// Errors carry codes and type names only — never a value.
///
/// The key is per-install, 32 random bytes, held in the data-protection keychain under an access
/// group shared with the (future) AutoFill credential provider extension. It is never exported and
/// never overwritten: a key that is replaced while rows are already encrypted under it destroys
/// the vault permanently.
enum VaultCrypto {

    // MARK: - Frozen constants (SHARED CONTRACT S1 / S3 — changing any of these strands vaults)

    private static let accessGroup = "group.com.cklamib.bimirLock"
    private static let service = "com.cklamib.bimirLock.vault"
    private static let account = "pwd.v1"
    private static let aad = Data("bimirlock.pwd.v1".utf8)
    private static let kcvPlaintext = "bimirlock.kcv.v1"

    static let prefix = "v1:"
    private static let keyBytes = 32
    private static let nonceBytes = 12
    private static let tagBytes = 16

    // MARK: - Types

    /// Classification (SHARED CONTRACT S4). The "v1:" prefix is a cheap PRE-FILTER and never a
    /// decision. There is deliberately no "damaged" state: decode() only runs under a key already
    /// verified against the stored check value, so a value whose tag fails under it was never
    /// sealed by us. It is a legacy password that merely looks like an envelope ("v1:" + valid
    /// base64, e.g. an API token), and hiding it would lock the user out of a real password.
    enum Kind {
        case ok       // structurally valid AND the GCM tag authenticates
        case plain    // anything we did not seal: kept byte for byte, re-sealed losslessly
    }

    struct Decoded {
        let kind: Kind
        /// The opened password for .ok, the stored string unchanged for .plain.
        let value: String?
    }

    enum Failure: Error {
        /// Carries a frozen S6 error code: "kcv_mismatch", "key_unreadable",
        /// "key_wrong_type", "key_create_failed".
        case keyUnavailable(String)
        /// Any non-"not found" keychain status. Surfaces as "keystore_unavailable".
        case keychain(OSStatus)
        /// An internal envelope-layout invariant was violated. Surfaces as "vault_crypto_failed".
        case invalidEnvelope(String)
    }

    // MARK: - Key handling

    private static let keyLock = NSLock()
    private static var cachedKey: SymmetricKey?

    /// Load-or-create. FIRST RUN ONLY (no stored check value): see ensureKey(storedKcv:).
    ///
    /// DATA-LOSS GUARD (checklist 3 + 4): `readKey()` returns nil IF AND ONLY IF the keychain
    /// answered errSecItemNotFound. Every other status throws. A transient keychain error must
    /// NEVER be read as "absent, make a new one" — that is the fastest possible route to
    /// destroying every password.
    private static func loadOrCreateKey() throws -> SymmetricKey {
        keyLock.lock()
        defer { keyLock.unlock() }

        if let cached = cachedKey { return cached }

        let resolved: SymmetricKey
        if let existing = try readKey() {
            resolved = existing
        } else {
            resolved = try createKey()
        }
        cachedKey = resolved
        return resolved
    }

    /// The key, or nil when the keychain answered errSecItemNotFound. Never creates one.
    private static func existingKey() throws -> SymmetricKey? {
        keyLock.lock()
        defer { keyLock.unlock() }

        if let cached = cachedKey { return cached }
        guard let existing = try readKey() else { return nil }
        cachedKey = existing
        return existing
    }

    /// For encrypt and decode, which only run after ensureKey(storedKcv:) has proven the key.
    private static func requireKey() throws -> SymmetricKey {
        guard let existing = try existingKey() else {
            throw Failure.keyUnavailable("key_unreadable")
        }
        return existing
    }

    private static func baseQuery() -> [String: Any] {
        // kSecAttrSynchronizable is stated EXPLICITLY on both add and query: it is mutually
        // exclusive with any *ThisDeviceOnly accessibility and would yield errSecParam, and an
        // unstated value on query matches "any", which is not what we want.
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrSynchronizable as String: false,
            kSecUseDataProtectionKeychain as String: true,
        ]
    }

    private static func readKey() throws -> SymmetricKey? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var out: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &out)

        switch status {
        case errSecSuccess:
            guard let data = out as? Data else {
                throw Failure.keyUnavailable("key_unreadable")
            }
            guard data.count == keyBytes else {
                // NEVER overwrite it. An item of the wrong size might still be someone's key.
                throw Failure.keyUnavailable("key_wrong_type")
            }
            return SymmetricKey(data: data)

        case errSecItemNotFound:
            return nil  // the ONLY path that returns nil

        default:
            throw Failure.keychain(status)
        }
    }

    private static func createKey() throws -> SymmetricKey {
        var raw = Data(count: keyBytes)
        let rc: Int32 = raw.withUnsafeMutableBytes { buffer in
            guard let base = buffer.baseAddress else { return errSecParam }
            return SecRandomCopyBytes(kSecRandomDefault, keyBytes, base)
        }
        guard rc == errSecSuccess else {
            throw Failure.keyUnavailable("key_create_failed")
        }

        var attributes = baseQuery()
        attributes[kSecValueData as String] = raw
        // AfterFirstUnlockThisDeviceOnly: the future credential-provider extension is launched by
        // the system, not the user, so the key must not depend on the exact lock state at that
        // instant. ThisDeviceOnly keeps it out of iCloud Keychain and out of encrypted backups —
        // deliberately matching the DB directory's .completeUntilFirstUserAuthentication and its
        // isExcludedFromBackup flag, so the database and the key share one fate.
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(attributes as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            return SymmetricKey(data: raw)

        case errSecDuplicateItem:
            // Lost a race with another process in the access group. RE-READ, never overwrite:
            // overwriting orphans every row already encrypted under the winner's key. The
            // keychain daemon serialises the race for us, so re-reading is the whole guard.
            guard let existing = try readKey() else {
                throw Failure.keyUnavailable("key_unreadable")
            }
            return existing

        default:
            throw Failure.keychain(status)
        }
    }

    // MARK: - Public API (mirrors the Kotlin implementation exactly)

    /// Establish the key and reconcile it against the stored Key Check Value.
    ///
    /// - `storedKcv == nil`  -> first run: seal the public constant and return it for the caller
    ///                          to persist in VaultMeta.
    /// - `storedKcv != nil`  -> it MUST open to exactly the constant, otherwise the key on this
    ///                          device is not the key the vault was encrypted with. Throwing
    ///                          "kcv_mismatch" is what converts silent, total corruption into a
    ///                          loud, detectable, non-destructive halt (checklist 5).
    static func ensureKey(storedKcv: String?) throws -> String {
        // Only a first run may create a key. With a stored check value a key already sealed this
        // vault: if it is gone a new one fixes nothing, and minting one would leave the vault with
        // rows under two keys. Answer "not the vault's key" without touching the keychain item.
        guard let stored = storedKcv else {
            return try seal(kcvPlaintext, using: try loadOrCreateKey())
        }
        guard let resolved = try existingKey() else {
            throw Failure.keyUnavailable("kcv_mismatch")
        }

        let decoded = try decode(stored, using: resolved)
        guard decoded.kind == .ok, decoded.value == kcvPlaintext else {
            throw Failure.keyUnavailable("kcv_mismatch")
        }
        return stored
    }

    static func encrypt(_ plaintext: String) throws -> String {
        return try seal(plaintext, using: try requireKey())
    }

    static func decode(_ stored: String) throws -> Decoded {
        return try decode(stored, using: try requireKey())
    }

    // MARK: - Envelope

    private static func seal(_ plaintext: String, using key: SymmetricKey) throws -> String {
        let nonce = AES.GCM.Nonce()
        let box = try AES.GCM.seal(Data(plaintext.utf8), using: key, nonce: nonce, authenticating: aad)

        // The envelope layout is POSITIONAL, so assert the lengths rather than trusting them
        // (checklist 25). A one-byte disagreement here is permanent, silent data loss.
        let nonceData = Data(nonce)
        guard nonceData.count == nonceBytes else {
            throw Failure.invalidEnvelope("nonce_length")
        }
        guard box.tag.count == tagBytes else {
            throw Failure.invalidEnvelope("tag_length")
        }

        // Written out explicitly rather than using SealedBox.combined. `combined` happens to be
        // exactly this layout, but it is Optional and we would rather not depend on its nil
        // condition for the byte layout of a vault.
        var blob = Data()
        blob.append(nonceData)
        blob.append(box.ciphertext)
        blob.append(box.tag)

        // base64EncodedString() with no options == RFC 4648 §4, padded, no line breaks.
        return prefix + blob.base64EncodedString()
    }

    private static func decode(_ stored: String, using key: SymmetricKey) throws -> Decoded {
        // 1. no prefix -> certainly legacy plaintext
        guard stored.hasPrefix(prefix) else {
            return Decoded(kind: .plain, value: stored)
        }

        let body = String(stored.dropFirst(prefix.count))

        // 2. not valid standard base64 -> structurally impossible to be one of ours
        guard let blob = Data(base64Encoded: body) else {
            return Decoded(kind: .plain, value: stored)
        }

        // 3. too short to hold even an empty ciphertext -> likewise impossible
        guard blob.count >= nonceBytes + tagBytes else {
            return Decoded(kind: .plain, value: stored)
        }

        // 4. structurally valid: the tag is now the only authority
        let opened: Data
        do {
            let nonceData = Data(blob.prefix(nonceBytes))
            let tagData = Data(blob.suffix(tagBytes))
            let ciphertext = Data(blob.dropFirst(nonceBytes).dropLast(tagBytes))

            let box = try AES.GCM.SealedBox(
                nonce: try AES.GCM.Nonce(data: nonceData),
                ciphertext: ciphertext,
                tag: tagData
            )
            opened = try AES.GCM.open(box, using: key, authenticating: aad)
        } catch CryptoKitError.authenticationFailure {
            // 5. the tag does not verify under the verified key: we never sealed this value.
            return Decoded(kind: .plain, value: stored)
        } catch {
            // Anything else is the crypto layer failing, not a property of the value. Reading it
            // as plaintext would re-seal a good envelope as text.
            throw Failure.keyUnavailable("vault_crypto_failed")
        }
        // Everything we seal is UTF-8, so an authentic value that is not is impossible in practice.
        guard let text = String(data: opened, encoding: .utf8) else {
            throw Failure.invalidEnvelope("utf8")
        }
        return Decoded(kind: .ok, value: text)
    }
}
