import 'dart:convert';
import 'dart:typed_data';

import 'package:bimir_lock/utils/helper/backup_crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';

// The smallest settings the format accepts, so the suite stays fast. Real
// backups use BackupKdfParams.standard.
const BackupKdfParams fast = BackupKdfParams(memoryKiB: 8192, iterations: 1, parallelism: 1);

const List<BackupEntry> sample = <BackupEntry>[
  BackupEntry(title: 'Normal', userName: 'groot.tester', password: 'Simple123'),
  BackupEntry(title: 'Unicode', userName: 'пользователь', password: 'пароль🔐日本語'),
  BackupEntry(title: 'Quotes', userName: 'o"brien', password: 'O\'Brien"\\x\'; drop table --'),
  BackupEntry(title: 'Prefix', userName: 'u', password: 'v1:QWxhZGRpbk9wZW5TZXNhbWVQYXNzd29yZDIwMjZYeQ=='),
  BackupEntry(title: '', userName: '', password: ''),
];

Map<String, dynamic> _json(Uint8List file) => jsonDecode(utf8.decode(file)) as Map<String, dynamic>;
Uint8List _bytes(Map<String, dynamic> m) => Uint8List.fromList(utf8.encode(jsonEncode(m)));

void main() {
  test('Argon2id matches the RFC 9106 test vector', () {
    final Argon2BytesGenerator gen = Argon2BytesGenerator()
      ..init(Argon2Parameters(
        Argon2Parameters.ARGON2_id,
        Uint8List.fromList(List<int>.filled(16, 0x02)),
        desiredKeyLength: 32,
        secret: Uint8List.fromList(List<int>.filled(8, 0x03)),
        additional: Uint8List.fromList(List<int>.filled(12, 0x04)),
        iterations: 3,
        memory: 32,
        lanes: 4,
        version: Argon2Parameters.ARGON2_VERSION_13,
      ));
    final Uint8List tag = gen.process(Uint8List.fromList(List<int>.filled(32, 0x01)));
    expect(
      tag.map((int b) => b.toRadixString(16).padLeft(2, '0')).join(),
      '0d640df58d78766c08c037a34a8b53c9d01ef0452d75b65eb52520e96b01e659',
    );
  });

  test('round trip keeps every entry byte for byte', () {
    final Uint8List file = BackupCrypto.seal(sample, 'correct horse battery', params: fast);
    final List<BackupEntry> opened = BackupCrypto.open(file, 'correct horse battery');
    expect(opened.map((BackupEntry e) => e.identity).toList(),
        sample.map((BackupEntry e) => e.identity).toList());
  });

  test('notes survive a round trip, and a file without notes still opens', () {
    const List<BackupEntry> withNotes = <BackupEntry>[
      BackupEntry(title: 'Bank', userName: 'u', password: 'p', note: 'Recovery: 1234-5678\nMother: Sita'),
      BackupEntry(title: 'Mail', userName: 'u', password: 'p'),
    ];
    final Uint8List file = BackupCrypto.seal(withNotes, 'correct horse battery', params: fast);
    final List<BackupEntry> opened = BackupCrypto.open(file, 'correct horse battery');
    expect(opened.map((BackupEntry e) => e.note).toList(), <String>['Recovery: 1234-5678\nMother: Sita', '']);
    expect(withNotes.last.toJson().containsKey('note'), isFalse);
    expect(utf8.decode(file).contains('Recovery'), isFalse);
  });

  test('no password or username appears in the file', () {
    final String text = utf8.decode(BackupCrypto.seal(sample, 'correct horse battery', params: fast));
    // Only strings long enough to mean something; a one-letter username
    // naturally occurs inside words like "argon2id".
    for (final BackupEntry e in sample) {
      for (final String secret in <String>[e.password, e.userName]) {
        if (secret.length > 3) expect(text.contains(secret), isFalse);
      }
    }
  });

  test('a wrong password is refused', () {
    final Uint8List file = BackupCrypto.seal(sample, 'correct horse battery', params: fast);
    expect(() => BackupCrypto.open(file, 'correct horse batterY'),
        throwsA(isA<BackupAuthException>()));
  });

  test('a changed byte of data is refused', () {
    final Map<String, dynamic> m = _json(BackupCrypto.seal(sample, 'pw-pw-pw-pw', params: fast));
    final Uint8List data = base64Decode(m['data'] as String);
    data[3] ^= 0x01;
    m['data'] = base64Encode(data);
    expect(() => BackupCrypto.open(_bytes(m), 'pw-pw-pw-pw'), throwsA(isA<BackupAuthException>()));
  });

  test('a changed header field is refused', () {
    final Map<String, dynamic> m = _json(BackupCrypto.seal(sample, 'pw-pw-pw-pw', params: fast));
    final Uint8List nonce = base64Decode((m['cipher'] as Map<String, dynamic>)['nonce'] as String);
    nonce[0] ^= 0x01;
    (m['cipher'] as Map<String, dynamic>)['nonce'] = base64Encode(nonce);
    expect(() => BackupCrypto.open(_bytes(m), 'pw-pw-pw-pw'), throwsA(isA<BackupAuthException>()));
  });

  test('a file that is not a backup is reported as such, not as a wrong password', () {
    expect(() => BackupCrypto.checkFormat(Uint8List.fromList(utf8.encode('hello'))),
        throwsA(isA<BackupFormatException>()));
    expect(() => BackupCrypto.checkFormat(_bytes(<String, dynamic>{'app': 'other'})),
        throwsA(isA<BackupFormatException>()));
  });

  test('a backup from a newer app version is refused clearly', () {
    final Map<String, dynamic> m = _json(BackupCrypto.seal(sample, 'pw-pw-pw-pw', params: fast));
    m['version'] = 99;
    expect(
        () => BackupCrypto.checkFormat(_bytes(m)),
        throwsA(isA<BackupFormatException>()
            .having((BackupFormatException e) => e.message, 'message', 'newer_version')));
  });

  test('a hostile file cannot demand huge memory', () {
    final Map<String, dynamic> m = _json(BackupCrypto.seal(sample, 'pw-pw-pw-pw', params: fast));
    (m['kdf'] as Map<String, dynamic>)['memoryKiB'] = 64 * 1024 * 1024;
    expect(() => BackupCrypto.checkFormat(_bytes(m)), throwsA(isA<BackupFormatException>()));
  });

  test('two backups of the same data never share a salt or nonce', () {
    final Map<String, dynamic> a = _json(BackupCrypto.seal(sample, 'pw-pw-pw-pw', params: fast));
    final Map<String, dynamic> b = _json(BackupCrypto.seal(sample, 'pw-pw-pw-pw', params: fast));
    expect((a['kdf'] as Map<String, dynamic>)['salt'], isNot((b['kdf'] as Map<String, dynamic>)['salt']));
    expect((a['cipher'] as Map<String, dynamic>)['nonce'],
        isNot((b['cipher'] as Map<String, dynamic>)['nonce']));
  });

  test('standard settings take a bearable time (printed, not asserted)', () {
    final Stopwatch sw = Stopwatch()..start();
    final Uint8List file = BackupCrypto.seal(sample, 'correct horse battery');
    BackupCrypto.open(file, 'correct horse battery');
    // ignore: avoid_print
    print('standard seal+open on this machine (JIT): ${sw.elapsedMilliseconds} ms');
  });
}
