import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// The encrypted backup file.
///
/// A backup has to open on ANOTHER device, so it cannot use the vault key: that
/// key never leaves this phone's Keystore / Keychain. It is sealed instead under
/// a key derived from a separate backup password the user chooses, with Argon2id
/// (slow on purpose, so a stolen file cannot be guessed at quickly) and
/// AES-256-GCM (any change to the file makes it refuse to open).
///
/// File layout, UTF-8 JSON:
///   { "app": "bimirlock", "type": "backup", "version": 1,
///     "kdf": { "name": "argon2id", "memoryKiB": m, "iterations": t,
///              "parallelism": p, "salt": base64(16) },
///     "cipher": { "name": "aes-256-gcm", "nonce": base64(12) },
///     "data": base64(ciphertext || tag16) }
/// Every header field is bound into the GCM additional data, so editing one
/// makes the file fail to open rather than open differently.
///
/// Nothing here logs, and no error message ever carries a value.
class BackupEntry {
  const BackupEntry({
    required this.title,
    required this.userName,
    required this.password,
    this.note = '',
  });

  final String title;
  final String userName;
  final String password;

  /// Optional; '' for none. Written only when there is one, so files without
  /// notes stay byte-compatible with older versions of the app, which ignore
  /// the extra field anyway.
  final String note;

  Map<String, String> toJson() => <String, String>{
    'title': title,
    'userName': userName,
    'password': password,
    if (note.isNotEmpty) 'note': note,
  };

  // Exact identity used by restore to skip duplicates. The note is left out
  // on purpose: the same login restored over itself is a duplicate whether or
  // not one side has a note.
  String get identity => jsonEncode(<String>[title, userName, password]);
}

/// The file is not a Bimir Lock backup, or is from a newer app version.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;
  @override
  String toString() => 'BackupFormatException: $message';
}

/// The password is wrong, or the file was changed after it was written. GCM
/// cannot tell these two apart, and neither may we.
class BackupAuthException implements Exception {
  const BackupAuthException();
}

class BackupKdfParams {
  const BackupKdfParams({required this.memoryKiB, required this.iterations, required this.parallelism});

  final int memoryKiB;
  final int iterations;
  final int parallelism;

  /// OWASP's minimum Argon2id setting. Runs in a background isolate.
  static const BackupKdfParams standard =
      BackupKdfParams(memoryKiB: 19456, iterations: 2, parallelism: 1);

  // A hostile file must not be able to make restore allocate gigabytes or spin
  // for minutes before the password is even checked.
  bool get withinLimits =>
      memoryKiB >= 8192 &&
      memoryKiB <= 262144 &&
      iterations >= 1 &&
      iterations <= 10 &&
      parallelism >= 1 &&
      parallelism <= 4;
}

class BackupCrypto {
  static const String _app = 'bimirlock';
  static const String _type = 'backup';
  static const int formatVersion = 1;
  static const int _saltBytes = 16;
  static const int _nonceBytes = 12;
  static const int _keyBytes = 32;
  static const int _tagBits = 128;

  /// Restore refuses anything larger before reading it into memory.
  static const int maxFileBytes = 20 * 1024 * 1024;

  /// Seals [entries] into the bytes of a backup file.
  static Uint8List seal(
    List<BackupEntry> entries,
    String password, {
    BackupKdfParams params = BackupKdfParams.standard,
    DateTime? now,
  }) {
    final Random random = Random.secure();
    final Uint8List salt = _randomBytes(random, _saltBytes);
    final Uint8List nonce = _randomBytes(random, _nonceBytes);
    final Uint8List key = _deriveKey(password, salt, params);

    final Uint8List plain = Uint8List.fromList(utf8.encode(jsonEncode(<String, Object>{
      'exportedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'entries': entries.map((BackupEntry e) => e.toJson()).toList(),
    })));

    final GCMBlockCipher gcm = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), _tagBits, nonce, _aad(params, salt, nonce)));
    final Uint8List sealed = gcm.process(plain);
    plain.fillRange(0, plain.length, 0);
    key.fillRange(0, key.length, 0);

    return Uint8List.fromList(utf8.encode(jsonEncode(<String, Object>{
      'app': _app,
      'type': _type,
      'version': formatVersion,
      'kdf': <String, Object>{
        'name': 'argon2id',
        'memoryKiB': params.memoryKiB,
        'iterations': params.iterations,
        'parallelism': params.parallelism,
        'salt': base64Encode(salt),
      },
      'cipher': <String, Object>{'name': 'aes-256-gcm', 'nonce': base64Encode(nonce)},
      'data': base64Encode(sealed),
    })));
  }

  /// Cheap structural check with no password, so a wrong file is reported as
  /// the wrong file and not as a wrong password.
  static void checkFormat(Uint8List file) => _Header.parse(file);

  /// Opens a backup file. Throws [BackupFormatException] or [BackupAuthException].
  static List<BackupEntry> open(Uint8List file, String password) {
    final _Header h = _Header.parse(file);
    final Uint8List key = _deriveKey(password, h.salt, h.params);
    final Uint8List plain;
    try {
      final GCMBlockCipher gcm = GCMBlockCipher(AESEngine())
        ..init(false, AEADParameters(KeyParameter(key), _tagBits, h.nonce, _aad(h.params, h.salt, h.nonce)));
      plain = gcm.process(h.data);
    } on InvalidCipherTextException {
      throw const BackupAuthException();
    } on ArgumentError {
      throw const BackupAuthException();
    } finally {
      key.fillRange(0, key.length, 0);
    }

    final Object? payload;
    try {
      payload = jsonDecode(utf8.decode(plain));
    } on FormatException {
      throw const BackupFormatException('payload');
    } finally {
      plain.fillRange(0, plain.length, 0);
    }
    if (payload is! Map || payload['entries'] is! List) {
      throw const BackupFormatException('payload');
    }
    final List<BackupEntry> out = <BackupEntry>[];
    for (final Object? item in payload['entries'] as List) {
      if (item is! Map) throw const BackupFormatException('entry');
      final Object? title = item['title'];
      final Object? user = item['userName'];
      final Object? pass = item['password'];
      final Object? note = item['note'];
      if (title is! String || user is! String || pass is! String) {
        throw const BackupFormatException('entry');
      }
      if (note != null && note is! String) {
        throw const BackupFormatException('entry');
      }
      out.add(BackupEntry(
        title: title,
        userName: user,
        password: pass,
        note: note is String ? note : '',
      ));
    }
    return out;
  }

  static Uint8List _deriveKey(String password, Uint8List salt, BackupKdfParams params) {
    final Uint8List pw = Uint8List.fromList(utf8.encode(password));
    final Argon2BytesGenerator generator = Argon2BytesGenerator()
      ..init(Argon2Parameters(
        Argon2Parameters.ARGON2_id,
        salt,
        desiredKeyLength: _keyBytes,
        iterations: params.iterations,
        memory: params.memoryKiB,
        lanes: params.parallelism,
        version: Argon2Parameters.ARGON2_VERSION_13,
      ));
    final Uint8List key = generator.process(pw);
    pw.fillRange(0, pw.length, 0);
    return key;
  }

  static Uint8List _aad(BackupKdfParams p, Uint8List salt, Uint8List nonce) => Uint8List.fromList(
      utf8.encode('$_app|$_type|v$formatVersion|argon2id|m=${p.memoryKiB}|t=${p.iterations}'
          '|p=${p.parallelism}|salt=${base64Encode(salt)}|aes-256-gcm|nonce=${base64Encode(nonce)}'));

  static Uint8List _randomBytes(Random random, int n) =>
      Uint8List.fromList(List<int>.generate(n, (_) => random.nextInt(256)));
}

class _Header {
  _Header(this.params, this.salt, this.nonce, this.data);

  final BackupKdfParams params;
  final Uint8List salt;
  final Uint8List nonce;
  final Uint8List data;

  static _Header parse(Uint8List file) {
    if (file.length > BackupCrypto.maxFileBytes) {
      throw const BackupFormatException('too_large');
    }
    final Object? root;
    try {
      root = jsonDecode(utf8.decode(file));
    } on FormatException {
      throw const BackupFormatException('not_json');
    }
    if (root is! Map || root['app'] != BackupCrypto._app || root['type'] != BackupCrypto._type) {
      throw const BackupFormatException('not_a_backup');
    }
    final Object? version = root['version'];
    if (version is! int) throw const BackupFormatException('not_a_backup');
    if (version > BackupCrypto.formatVersion) {
      throw const BackupFormatException('newer_version');
    }
    final Object? kdf = root['kdf'];
    final Object? cipher = root['cipher'];
    if (kdf is! Map || cipher is! Map) throw const BackupFormatException('header');
    if (kdf['name'] != 'argon2id' || cipher['name'] != 'aes-256-gcm') {
      throw const BackupFormatException('header');
    }
    final Object? m = kdf['memoryKiB'];
    final Object? t = kdf['iterations'];
    final Object? p = kdf['parallelism'];
    if (m is! int || t is! int || p is! int) throw const BackupFormatException('header');
    final BackupKdfParams params = BackupKdfParams(memoryKiB: m, iterations: t, parallelism: p);
    if (!params.withinLimits) throw const BackupFormatException('header');
    try {
      final Uint8List salt = base64Decode(kdf['salt'] as String);
      final Uint8List nonce = base64Decode(cipher['nonce'] as String);
      final Uint8List data = base64Decode(root['data'] as String);
      if (salt.length != BackupCrypto._saltBytes ||
          nonce.length != BackupCrypto._nonceBytes ||
          data.length < BackupCrypto._tagBits ~/ 8) {
        throw const BackupFormatException('header');
      }
      return _Header(params, salt, nonce, data);
    } on FormatException {
      throw const BackupFormatException('header');
    } on TypeError {
      throw const BackupFormatException('header');
    }
  }
}
