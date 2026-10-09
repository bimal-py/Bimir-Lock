import 'dart:math';

/// Password generation and a small strength estimate. Pure Dart, no packages,
/// so it adds almost nothing to the app size and is fully unit-tested.

const String _lower = 'abcdefghijkmnopqrstuvwxyz'; // no l
const String _upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // no I, O
const String _digits = '23456789'; // no 0, 1
const String _symbols = '!@#\$%^&*-_=+?';

/// A random password from the OS's cryptographic RNG. Look-alike characters
/// (l/1/I, O/0) are left out so it can be read or typed by hand. Every
/// selected kind of character is guaranteed to appear at least once.
String generatePassword({
  int length = 20,
  bool digits = true,
  bool symbols = true,
}) {
  final Random random = Random.secure();
  final List<String> sets = <String>[
    _lower,
    _upper,
    if (digits) _digits,
    if (symbols) _symbols,
  ];
  final int n = length.clamp(sets.length, 128);
  final String all = sets.join();
  final List<String> out = <String>[
    for (final String set in sets) set[random.nextInt(set.length)],
    for (int i = sets.length; i < n; i++) all[random.nextInt(all.length)],
  ];
  // Fisher-Yates, so the guaranteed characters are not always at the front.
  for (int i = out.length - 1; i > 0; i--) {
    final int j = random.nextInt(i + 1);
    final String t = out[i];
    out[i] = out[j];
    out[j] = t;
  }
  return out.join();
}

enum Strength { empty, veryWeak, weak, fair, strong, veryStrong }

extension StrengthLabel on Strength {
  String get label => switch (this) {
    Strength.empty => '',
    Strength.veryWeak => 'Very weak',
    Strength.weak => 'Weak',
    Strength.fair => 'Fair',
    Strength.strong => 'Strong',
    Strength.veryStrong => 'Very strong',
  };

  /// 0..4 filled segments of the meter.
  int get segments => switch (this) {
    Strength.empty => 0,
    Strength.veryWeak => 1,
    Strength.weak => 1,
    Strength.fair => 2,
    Strength.strong => 3,
    Strength.veryStrong => 4,
  };
}

// A short list of the most common passwords and their roots. Anything built on
// these is weak whatever else is added to it.
const Set<String> _common = <String>{
  'password',
  'passw0rd',
  'qwerty',
  'qwertyuiop',
  'asdfgh',
  'zxcvbn',
  'letmein',
  'welcome',
  'admin',
  'login',
  'iloveyou',
  'monkey',
  'dragon',
  'football',
  'baseball',
  'sunshine',
  'princess',
  'master',
  'shadow',
  'superman',
  'abc123',
  '123456',
  '1234567',
  '12345678',
  '123456789',
  '1234567890',
  '111111',
  '000000',
  'nepal',
  'kathmandu',
  'bimir',
};

/// A rough estimate in the spirit of an entropy check: length and variety
/// raise it; repeats, runs like "abcd"/"1234", keyboard rows and common
/// passwords pull it down. It guides the user; it does not certify anything.
Strength estimateStrength(String password) {
  if (password.isEmpty) return Strength.empty;
  final String lower = password.toLowerCase();
  for (final String c in _common) {
    if (lower == c || (c.length >= 5 && lower.contains(c))) {
      return Strength.veryWeak;
    }
  }

  int pool = 0;
  if (password.contains(RegExp(r'[a-z]'))) pool += 26;
  if (password.contains(RegExp(r'[A-Z]'))) pool += 26;
  if (password.contains(RegExp(r'[0-9]'))) pool += 10;
  if (password.contains(RegExp(r'[^a-zA-Z0-9]'))) pool += 33;
  double bits = password.length * (log(max(pool, 1)) / ln2);

  // Penalise predictable structure.
  bits -= _repeats(password) * 3.0;
  bits -= _sequences(lower) * 3.0;
  if (RegExp(r'^[0-9]+$').hasMatch(password)) bits *= 0.6;
  if (RegExp(r'^[a-zA-Z]+[0-9]{1,4}$').hasMatch(password)) bits *= 0.8;

  // A word followed by a year (and maybe one symbol), e.g. "Summer2024!", is
  // one of the first shapes a guessing tool tries.
  if (RegExp(r'^[a-zA-Z]{3,12}(19|20)\d{2}[^a-zA-Z0-9]?$').hasMatch(password)) {
    return bits < 28 ? Strength.veryWeak : Strength.weak;
  }

  if (password.length < 8 || bits < 28) return Strength.veryWeak;
  if (bits < 40) return Strength.weak;
  if (bits < 60) return Strength.fair;
  if (bits < 80) return Strength.strong;
  return Strength.veryStrong;
}

int _repeats(String s) {
  int count = 0;
  for (int i = 1; i < s.length; i++) {
    if (s[i] == s[i - 1]) count++;
  }
  return count;
}

const List<String> _rows = <String>[
  'abcdefghijklmnopqrstuvwxyz',
  '0123456789',
  'qwertyuiop',
  'asdfghjkl',
  'zxcvbnm',
];

int _sequences(String s) {
  int count = 0;
  for (int i = 2; i < s.length; i++) {
    final String tri = s.substring(i - 2, i + 1);
    for (final String row in _rows) {
      if (row.contains(tri) || row.split('').reversed.join().contains(tri)) {
        count++;
        break;
      }
    }
  }
  return count;
}
