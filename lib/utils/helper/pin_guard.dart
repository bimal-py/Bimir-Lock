import 'package:shared_preferences/shared_preferences.dart';

/// How long a lock lasts, and how many wrong PINs in a row lead to it.
class PinStage {
  const PinStage(this.misses, this.lock);

  /// Wrong PINs, counted from the end of the previous lock.
  final int misses;
  final Duration lock;
}

/// Slows down PIN guessing, in stages. The first ten wrong PINs in a row lock
/// the keypad for 30 seconds (typos happen, so the count only shows from the
/// fifth). Each lock after that comes sooner and lasts longer: seven more for
/// a minute, five more for five minutes, then every three for fifteen. A
/// correct PIN or a fingerprint / face scan starts the count again. Stored on
/// disk, so closing the app does not reset it.
class PinGuard {
  static const List<PinStage> stages = <PinStage>[
    PinStage(10, Duration(seconds: 30)),
    PinStage(7, Duration(minutes: 1)),
    PinStage(5, Duration(minutes: 5)),
    // The last stage repeats for as long as the guessing goes on.
    PinStage(3, longest),
  ];

  /// The wrong PIN that first locks the keypad.
  static const int attempts = 10;

  /// Before the first lock, how few tries must be left before the keypad
  /// says how many. After any lock it always says.
  static const int warnFrom = 5;

  /// The longest a single lock lasts.
  static const Duration longest = Duration(minutes: 15);

  static const String _failuresKey = 'pin_failures';
  static const String _untilKey = 'pin_locked_until';

  /// Where [failures] wrong PINs in a row stand: the stage being counted
  /// down, how many wrong PINs are left in it, and whether the last one
  /// completed a stage (and so locked the keypad).
  static ({PinStage stage, int left, bool locked}) position(int failures) {
    int before = 0; // wrong PINs used up by the stages already passed
    int i = 0;
    while (true) {
      final PinStage stage = stages[i < stages.length ? i : stages.length - 1];
      final int end = before + stage.misses;
      if (failures < end) {
        return (stage: stage, left: end - failures, locked: false);
      }
      if (failures == end) {
        return (stage: stage, left: 0, locked: true);
      }
      before = end;
      i++;
    }
  }

  /// How long the pad stays locked after the given total of wrong PINs: the
  /// stage's lock on the wrong PIN that completes it, nothing in between.
  static Duration lockFor(int failures) {
    if (failures <= 0) return Duration.zero;
    final ({PinStage stage, int left, bool locked}) at = position(failures);
    return at.locked ? at.stage.lock : Duration.zero;
  }

  /// What the keypad says about the tries left before the next lock, or null
  /// while it is too early to mention them (before the [warnFrom]th-to-last
  /// try of the first stage). After a lock it is always shown.
  static String? triesLeftLine(int failures) {
    if (failures <= 0) return null;
    final ({PinStage stage, int left, bool locked}) at = position(failures);
    // Just locked: the next stage is the one now counting down.
    final ({PinStage stage, int left, bool locked}) next = at.locked
        ? position(failures + 1)
        : at;
    final int left = at.locked ? next.left + 1 : at.left;
    final bool firstStage = failures < attempts;
    if (firstStage && left > warnFrom) return null;
    return '$left ${left == 1 ? 'try' : 'tries'} left before a '
        '${span(next.stage.lock)} lock.';
  }

  /// "30-second", "1-minute", "15-minute": a lock's length as an adjective.
  static String span(Duration d) =>
      d.inMinutes >= 1 ? '${d.inMinutes}-minute' : '${d.inSeconds}-second';

  /// Time left before another PIN may be tried, or zero.
  static Future<Duration> remaining({DateTime? now}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? until = prefs.getInt(_untilKey);
    if (until == null) return Duration.zero;
    final Duration left = DateTime.fromMillisecondsSinceEpoch(
      until,
    ).difference(now ?? DateTime.now());
    // A clock moved backwards could leave an absurd wait; never exceed the cap.
    if (left > longest) return longest;
    return left.isNegative ? Duration.zero : left;
  }

  /// Wrong PINs so far without a correct one.
  static Future<int> failures() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_failuresKey) ?? 0;
  }

  /// Records a wrong PIN and returns the lock it triggers (zero for none).
  static Future<Duration> recordFailure({DateTime? now}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int count = (prefs.getInt(_failuresKey) ?? 0) + 1;
    await prefs.setInt(_failuresKey, count);
    final Duration lock = lockFor(count);
    if (lock > Duration.zero) {
      await prefs.setInt(
        _untilKey,
        (now ?? DateTime.now()).add(lock).millisecondsSinceEpoch,
      );
    }
    return lock;
  }

  static Future<void> recordSuccess() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_failuresKey);
    await prefs.remove(_untilKey);
  }
}

/// Debug builds only: master codes that open the keypad whatever the saved
/// PIN is, one per keypad length (old 4-digit PINs, new 6-digit ones).
/// kDebugMode is a compile-time constant, so in profile and release builds
/// this is always false and the codes are compiled out.
bool isDebugMasterPin(String pin) => (pin == '2462' || pin == '246255');
// kDebugMode && (pin == '2462' || pin == '246255');

/// Digits in a new access PIN. PINs set before this went from 4 to 6 keep
/// working at their own length until they are changed.
const int pinLength = 6;

/// Six-digit PINs people pick most, beyond the patterns caught below.
const Set<String> _commonPins = <String>{
  '112233',
  '123321',
  '147258',
  '147852',
  '159357',
  '159753',
  '258456',
  '520520',
  '696969',
  '789456',
  '102030',
  '010203',
  '007007',
  '142536',
  '456123',
  '741852',
  '963852',
  '321654',
  '987456',
  '135790',
  '246810',
};

/// Why a new PIN is too easy to guess, or null when it is fine. Only applied
/// when a PIN is chosen; existing PINs keep working.
String? pinWeakness(String pin) {
  if (pin.length < pinLength || !RegExp(r'^\d+$').hasMatch(pin)) {
    return 'Use $pinLength digits';
  }
  if (pin.split('').toSet().length == 1) {
    return 'All the same digit is the first thing anyone tries';
  }
  bool step(int d) {
    for (int i = 1; i < pin.length; i++) {
      if (pin.codeUnitAt(i) - pin.codeUnitAt(i - 1) != d) return false;
    }
    return true;
  }

  if (step(1) || step(-1)) return 'Straight runs like 123456 are easy to guess';
  // 121212, 123123: a short block typed over and over.
  for (final int period in <int>[2, 3]) {
    if (pin.length % period == 0 &&
        pin == pin.substring(0, period) * (pin.length ~/ period)) {
      return 'Repeating a few digits, like 121212, is easy to guess';
    }
  }
  if (_commonPins.contains(pin)) {
    return 'That is one of the most used PINs';
  }
  return null;
}
