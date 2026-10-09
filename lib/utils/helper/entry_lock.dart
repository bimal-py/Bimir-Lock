import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/digests/sha256.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Optional per-entry PINs. An entry either opens with the app's access PIN
/// (the default) or with a PIN of its own.
///
/// Only a salted SHA-256 of the PIN is kept, never the PIN. This is a gate in
/// the app, not extra encryption: the password itself is protected by the
/// vault key either way. Kept in preferences by entry id (ids are never reused),
/// so the vault database schema is untouched.
class EntryLock {
  static const String _prefix = 'entry_pin_';

  static Future<bool> hasOwnPin(int? id) async {
    if (id == null) return false;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_prefix$id');
  }

  static Future<Set<int>> lockedIds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return <int>{
      for (final String k in prefs.getKeys())
        if (k.startsWith(_prefix)) ?int.tryParse(k.substring(_prefix.length)),
    };
  }

  static Future<void> setPin(int id, String pin) async {
    final Random rng = Random.secure();
    final Uint8List salt = Uint8List.fromList(
      List<int>.generate(16, (_) => rng.nextInt(256)),
    );
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$id',
      '${base64Encode(salt)}:${base64Encode(_hash(salt, pin))}',
    );
  }

  static Future<void> clear(int? id) async {
    if (id == null) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$id');
  }

  static Future<bool> matches(int id, String pin) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString('$_prefix$id');
    if (stored == null) return false;
    final List<String> parts = stored.split(':');
    if (parts.length != 2) return false;
    try {
      final Uint8List salt = base64Decode(parts[0]);
      final Uint8List want = base64Decode(parts[1]);
      final Uint8List got = _hash(salt, pin);
      if (got.length != want.length) return false;
      int diff = 0;
      for (int i = 0; i < got.length; i++) {
        diff |= got[i] ^ want[i];
      }
      return diff == 0;
    } catch (_) {
      return false;
    }
  }

  static Uint8List _hash(Uint8List salt, String pin) => SHA256Digest().process(
    Uint8List.fromList(<int>[...salt, ...utf8.encode(pin)]),
  );
}
