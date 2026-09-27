import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

/// Dart side of the vault crypto contract.
///
/// Dart performs NO cryptography. It never sees key material, never chooses an
/// IV and never runs a cipher: it moves strings across a platform channel to a
/// native implementation that holds a hardware backed, non exportable key
/// (AndroidKeyStore / iOS Keychain).
///
/// Envelope format (normative, identical on every platform):
///   "v1:" ++ base64Standard( iv[12] || ciphertext[n] || tag[16] )
/// AES-256-GCM, 128 bit tag, AAD = ASCII "bimirlock.pwd.v1".
///
/// NOTHING in this file may ever log, print or persist a password, an envelope
/// or key material. Failure class names / error codes only.

/// Prefix every envelope this app writes carries.
const String envelopePrefix = 'v1:';

/// iv(12) + tag(16). A blob shorter than this cannot be one of ours.
const int minEnvelopeBlobLength = 28;

/// How a stored value was classified. The prefix alone NEVER decides this:
/// only structural validity plus GCM authentication under a verified key does.
enum VaultValueKind {
  /// A real envelope that authenticated. [VaultValue.value] is the plaintext.
  decrypted,

  /// Not one of ours: no prefix, or a prefix that cannot structurally be an
  /// envelope. [VaultValue.value] is the original stored string, verbatim.
  legacyPlaintext,

  /// A structurally valid envelope whose tag failed under a verified key.
  /// Unrecoverable. [VaultValue.value] is null and the bytes must be left
  /// exactly as they are: never displayed, never re-encrypted, never written.
  damaged,
}

class VaultValue {
  const VaultValue(this.value, this.kind);

  const VaultValue.decrypted(String this.value) : kind = VaultValueKind.decrypted;

  const VaultValue.legacy(String this.value) : kind = VaultValueKind.legacyPlaintext;

  const VaultValue.damaged()
      : value = null,
        kind = VaultValueKind.damaged;

  final String? value;
  final VaultValueKind kind;

  bool get isDecrypted => kind == VaultValueKind.decrypted;
  bool get isLegacyPlaintext => kind == VaultValueKind.legacyPlaintext;
  bool get isDamaged => kind == VaultValueKind.damaged;
}

/// Thrown whenever the key cannot be used. Callers must FAIL CLOSED on this:
/// no display of raw bytes, no re-encryption and above all no write.
///
/// [code] is a stable machine code; [detail] may carry a native failure CLASS
/// NAME only. Neither ever carries a value.
class VaultKeyUnavailable implements Exception {
  VaultKeyUnavailable(this.code, [this.detail]);

  final String code;
  final String? detail;

  @override
  String toString() =>
      'VaultKeyUnavailable($code${detail == null ? '' : ': $detail'})';
}

enum VaultKeyHealth {
  /// Not probed yet this launch.
  unknown,

  /// The key exists and matches the stored key check value. Reads and writes
  /// are permitted.
  ok,

  /// The vault holds ciphertext this device can no longer decrypt, or the
  /// invariant that guarantees a key check value exists was violated.
  /// Terminal for this launch. Read only. NEVER regenerate, NEVER re-encrypt.
  keyLost,

  /// A transient native failure (channel missing, keystore unavailable).
  /// Recoverable on a later launch. Writes are forbidden meanwhile, but the
  /// user must NOT be told their data is gone.
  unavailable,
}

class VaultKeyProbe {
  const VaultKeyProbe({required this.newKeyCheckValue, this.securityLevel});

  /// The envelope of the public key check value constant, produced by the
  /// native side under the key it just loaded or created.
  final String newKeyCheckValue;

  /// Diagnostic ONLY. Never gate behaviour on it.
  final String? securityLevel;
}

class VaultCrypto {
  VaultCrypto._();

  static final VaultCrypto instance = VaultCrypto._();

  static const String channelName = 'com.cklamib.bimirLock/vault_crypto';
  static const MethodChannel _channel = MethodChannel(channelName);

  VaultKeyHealth _health = VaultKeyHealth.unknown;

  /// Only [VaultKeyHealth.ok] permits [encryptAll] / [decryptAll].
  VaultKeyHealth get health => _health;

  /// Cheap PRE-FILTER, never a decision. A user password that literally begins
  /// with "v1:" also returns true here, and is then classified as plaintext by
  /// [isStructurallyEnvelope] or by the native decrypt.
  static bool hasEnvelopePrefix(String v) => v.startsWith(envelopePrefix);

  /// True only when [v] could structurally be one of our envelopes: the exact
  /// prefix, a strictly valid padded base64 body, and at least iv+tag bytes.
  ///
  /// This is what makes a real password like "v1:notreallyciphertext"
  /// (invalid base64) classify as plaintext and migrate losslessly, and it is
  /// what the invariant K gate counts, so that such a password can never be
  /// mistaken for live ciphertext and halt the migration.
  static bool isStructurallyEnvelope(String v) {
    if (!v.startsWith(envelopePrefix)) return false;
    final String body = v.substring(envelopePrefix.length);
    if (body.isEmpty || body.length % 4 != 0) return false;
    final Uint8List bytes;
    try {
      bytes = base64.decode(body);
    } on FormatException {
      return false;
    }
    return bytes.length >= minEnvelopeBlobLength;
  }

  /// Loads (or, only on a truly first run, creates) the per install key and
  /// checks it against [keyCheckValue].
  ///
  /// Sets health to ok on success. On failure health is deliberately left
  /// alone: the caller classifies, because "wrong key" and "keystore busy"
  /// demand opposite responses.
  Future<VaultKeyProbe> ensureKey({String? keyCheckValue}) async {
    try {
      final Map<String, dynamic>? result = await _channel
          .invokeMapMethod<String, dynamic>('ensureKey', <String, dynamic>{
        'kcv': keyCheckValue,
      });
      if (result == null) {
        throw VaultKeyUnavailable('vault_crypto_failed', 'null_response');
      }
      final Object? kcv = result['kcv'];
      if (kcv is! String || kcv.isEmpty) {
        throw VaultKeyUnavailable('vault_crypto_failed', 'missing_kcv');
      }
      final Object? level = result['securityLevel'];
      _health = VaultKeyHealth.ok;
      return VaultKeyProbe(
        newKeyCheckValue: kcv,
        securityLevel: level is String ? level : null,
      );
    } on MissingPluginException {
      throw VaultKeyUnavailable('channel_missing');
    } on PlatformException catch (e) {
      throw VaultKeyUnavailable(e.code, e.message);
    }
  }

  /// Seals every plaintext under the verified key. Same length, same order.
  Future<List<String>> encryptAll(List<String> plaintexts) async {
    if (plaintexts.isEmpty) return const <String>[];
    _requireVerifiedKey();
    try {
      final List<String>? sealed = await _channel.invokeListMethod<String>(
        'encryptBatch',
        <String, dynamic>{'values': plaintexts},
      );
      if (sealed == null || sealed.length != plaintexts.length) {
        throw VaultKeyUnavailable('encrypt_length_mismatch');
      }
      return sealed;
    } on MissingPluginException {
      throw VaultKeyUnavailable('channel_missing');
    } on PlatformException catch (e) {
      throw VaultKeyUnavailable(e.code, e.message);
    }
  }

  /// Classifies and opens every stored value. Same length, same order.
  Future<List<VaultValue>> decryptAll(List<String> stored) async {
    if (stored.isEmpty) return const <VaultValue>[];
    _requireVerifiedKey();
    final List<Map<Object?, Object?>>? raw;
    try {
      raw = await _channel.invokeListMethod<Map<Object?, Object?>>(
        'decryptBatch',
        <String, dynamic>{'values': stored},
      );
    } on MissingPluginException {
      throw VaultKeyUnavailable('channel_missing');
    } on PlatformException catch (e) {
      throw VaultKeyUnavailable(e.code, e.message);
    }
    if (raw == null || raw.length != stored.length) {
      throw VaultKeyUnavailable('decrypt_length_mismatch');
    }
    final List<VaultValue> out = <VaultValue>[];
    for (int i = 0; i < raw.length; i++) {
      final Object? status = raw[i]['status'];
      switch (status) {
        case 'ok':
          final Object? value = raw[i]['value'];
          if (value is! String) {
            throw VaultKeyUnavailable('decrypt_bad_payload');
          }
          out.add(VaultValue.decrypted(value));
          break;
        case 'plain':
          // Deliberately the ORIGINAL stored string, not the native echo: a
          // value the native side judged not to be one of ours must come back
          // byte for byte, whatever it echoed.
          out.add(VaultValue.legacy(stored[i]));
          break;
        case 'damaged':
          out.add(const VaultValue.damaged());
          break;
        default:
          throw VaultKeyUnavailable('decrypt_bad_status');
      }
    }
    return out;
  }

  void _requireVerifiedKey() {
    if (_health != VaultKeyHealth.ok) {
      throw VaultKeyUnavailable('key_not_verified');
    }
  }

  /// Revokes permission to encrypt or decrypt for the rest of this launch.
  /// Called when the vault gate or the migration decides the key can no longer
  /// be trusted, so that every later call fails closed instead of writing.
  void invalidate() {
    _health = VaultKeyHealth.unknown;
  }

  @visibleForTesting
  void resetForTesting() {
    _health = VaultKeyHealth.unknown;
  }
}
