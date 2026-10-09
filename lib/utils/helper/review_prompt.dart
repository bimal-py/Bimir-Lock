import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the prompt's history is kept between launches.
abstract class ReviewStore {
  /// The first launch this store has seen. People who had the app before the
  /// rating rules existed get theirs on their first launch after the update,
  /// so they too wait [ReviewPrompt.minDaysSinceFirstLaunch] from then.
  DateTime? get firstLaunchAt;
  Future<void> setFirstLaunchAt(DateTime value);

  /// Cold starts, ever. Never reset.
  int get launchCount;
  Future<void> setLaunchCount(int value);

  DateTime? get lastAskedAt;
  Future<void> setLastAskedAt(DateTime value);

  /// The app version the user was last asked on.
  String? get lastAskedVersion;
  Future<void> setLastAskedVersion(String value);
}

/// The store's own rating sheet. An interface so the rules above it can be
/// tested without the platform.
abstract class ReviewRequester {
  Future<bool> isAvailable();
  Future<void> requestReview();
}

class PlatformReviewRequester implements ReviewRequester {
  final InAppReview _review = InAppReview.instance;

  @override
  Future<bool> isAvailable() => _review.isAvailable();

  @override
  Future<void> requestReview() => _review.requestReview();
}

Future<String> _platformVersion() async =>
    (await PackageInfo.fromPlatform()).version;

/// Decides when to show the store's rating sheet, ported from the Callbreak
/// Tracker app's `ReviewPrompt`.
///
/// The sheet is the App Store's / Google Play's own: Play's in-app review
/// policy forbids asking anything ("Enjoying Bimir Lock?") before it, and Apple
/// wants its API used for prompts. It also returns nothing — there is no
/// knowing whether the user rated, dismissed it, or whether the OS showed it at
/// all. So only the *ask* is recorded, and two layers keep it from becoming a
/// nuisance:
///   1. The gates here — launches, days since the first one, a cool-off, and
///      once per app version.
///   2. The OS, which rations hard (iOS shows it about three times a year) and
///      silently ignores the rest.
///
/// It is asked for only after something went well — a password saved, a
/// backup written — never at launch and never over an unlock.
class ReviewPrompt {
  ReviewPrompt({
    required ReviewStore store,
    ReviewRequester? requester,
    DateTime Function()? now,
    Future<String> Function()? appVersion,
    Duration? settleDelay,
  }) : _store = store, // ignore: prefer_initializing_formals
       _requester = requester ?? PlatformReviewRequester(),
       _now = now ?? DateTime.now,
       _appVersion = appVersion ?? _platformVersion,
       _settleDelay = settleDelay ?? settle;

  /// The app's one prompt, set up by [init] from `main`. Null until then (and
  /// in widget tests), in which case [afterSuccess] does nothing.
  static ReviewPrompt? shared;

  /// Creates [shared] on the app's preferences and counts this launch.
  static Future<void> init() async {
    try {
      shared = ReviewPrompt(
        store: PrefsReviewStore(await SharedPreferences.getInstance()),
      );
      await shared!.recordLaunch();
    } catch (e) {
      _log('init failed: $e');
    }
  }

  /// A good moment has just happened; ask if the rules allow. Never throws,
  /// never awaits the sheet on the caller's behalf.
  static void afterSuccess() {
    final ReviewPrompt? prompt = shared;
    if (prompt == null) return;
    unawaited(prompt.onSuccess());
  }

  final ReviewStore _store;
  final ReviewRequester _requester;
  final DateTime Function() _now;
  final Future<String> Function() _appVersion;
  final Duration _settleDelay;

  /// App opens before the app asks at all.
  static const int minLaunches = 5;

  /// Days since the first launch before the app asks at all.
  static const int minDaysSinceFirstLaunch = 3;

  /// Days an ask lasts before the app may try again.
  static const int coolOffDays = 120;

  /// A beat between the success and the sheet, so the "Saved" note and the
  /// screen change land first.
  static const Duration settle = Duration(milliseconds: 1500);

  /// This process has counted its launch. [recordLaunch] is meant to be
  /// called once from `main`; this makes a second call harmless.
  bool _launchRecorded = false;

  /// Guards the read-then-write window in [maybeRequestReview]. Callers fire
  /// it unawaited, so without this two overlapping calls could both clear the
  /// gates before either recorded the ask. Checked and set before the first
  /// `await` — on a single-threaded isolate that makes it atomic.
  bool _inFlight = false;

  static void _log(String message) {
    if (kDebugMode) debugPrint('[ReviewPrompt] $message');
  }

  /// Counts one cold start. Seeds the first-launch time if there is none and
  /// adds one to the launch count. Never throws.
  Future<void> recordLaunch() async {
    if (_launchRecorded) return;
    _launchRecorded = true;
    try {
      if (_store.firstLaunchAt == null) {
        await _store.setFirstLaunchAt(_now());
      }
      await _store.setLaunchCount(_store.launchCount + 1);
    } catch (e) {
      _log('recordLaunch failed: $e');
    }
  }

  /// Waits for the success to settle, then asks if every gate passes.
  Future<bool> onSuccess() async {
    await Future<void>.delayed(_settleDelay);
    return maybeRequestReview();
  }

  /// Asks for a rating if every gate passes and the sheet can be shown.
  ///
  /// Silently does nothing otherwise, so it is safe to call freely. Returns
  /// whether the sheet was requested. Never throws: a rating prompt that fails
  /// should simply not appear.
  Future<bool> maybeRequestReview() async {
    if (_inFlight) {
      _log('skip: a request is already in flight');
      return false;
    }
    _inFlight = true;
    try {
      final DateTime now = _now();

      final DateTime? firstLaunch = _store.firstLaunchAt;
      if (firstLaunch == null) {
        _log('skip: recordLaunch never ran');
        return false;
      }

      final int daysSinceFirstLaunch = now.difference(firstLaunch).inDays;
      if (daysSinceFirstLaunch < minDaysSinceFirstLaunch) {
        _log('skip: only $daysSinceFirstLaunch day(s) since first launch');
        return false;
      }

      final int launches = _store.launchCount;
      if (launches < minLaunches) {
        _log('skip: only $launches launch(es)');
        return false;
      }

      final DateTime? lastAsked = _store.lastAskedAt;
      if (lastAsked != null) {
        final int daysSinceAsked = now.difference(lastAsked).inDays;
        if (daysSinceAsked < coolOffDays) {
          _log('skip: cool-off, last asked $daysSinceAsked day(s) ago');
          return false;
        }
      }

      final String version = await _appVersion();
      if (_store.lastAskedVersion == version) {
        _log('skip: already asked on version $version');
        return false;
      }

      if (!await _requester.isAvailable()) {
        _log('skip: in-app review not available on this device');
        return false;
      }

      // Recorded BEFORE asking. requestReview() can throw *after* the OS has
      // already put the sheet on screen — Android reports a failed
      // launchReviewFlow through the task that completes once the flow ends —
      // and recording afterwards would miss these writes on that path, leaving
      // the user asked while the cool-off never starts. The gates ration
      // *asking*, not succeeding, so spending the cool-off on an ask that
      // failed is the safe way to be wrong.
      await _store.setLastAskedAt(now);
      await _store.setLastAskedVersion(version);

      await _requester.requestReview();
      _log('requested review on version $version');
      return true;
    } catch (e) {
      _log('maybeRequestReview failed: $e');
      return false;
    } finally {
      _inFlight = false;
    }
  }
}

/// The prompt's history in the app's SharedPreferences, next to its other
/// settings. "Reset app" and "Erase and start again" clear it with them.
class PrefsReviewStore implements ReviewStore {
  PrefsReviewStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _firstLaunch = 'review_first_launch_at';
  static const String _launches = 'review_launch_count';
  static const String _lastAsked = 'review_last_asked_at';
  static const String _lastAskedVersion = 'review_last_asked_version';

  DateTime? _date(String key) {
    final String? raw = _prefs.getString(key);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  @override
  DateTime? get firstLaunchAt => _date(_firstLaunch);

  @override
  Future<void> setFirstLaunchAt(DateTime value) =>
      _prefs.setString(_firstLaunch, value.toIso8601String());

  @override
  int get launchCount => _prefs.getInt(_launches) ?? 0;

  @override
  Future<void> setLaunchCount(int value) => _prefs.setInt(_launches, value);

  @override
  DateTime? get lastAskedAt => _date(_lastAsked);

  @override
  Future<void> setLastAskedAt(DateTime value) =>
      _prefs.setString(_lastAsked, value.toIso8601String());

  @override
  String? get lastAskedVersion => _prefs.getString(_lastAskedVersion);

  @override
  Future<void> setLastAskedVersion(String value) =>
      _prefs.setString(_lastAskedVersion, value);
}

/// Kept only for as long as the object lives. What tests get.
class InMemoryReviewStore implements ReviewStore {
  DateTime? _firstLaunchAt;
  int _launchCount = 0;
  DateTime? _lastAskedAt;
  String? _lastAskedVersion;

  @override
  DateTime? get firstLaunchAt => _firstLaunchAt;

  @override
  Future<void> setFirstLaunchAt(DateTime value) async => _firstLaunchAt = value;

  @override
  int get launchCount => _launchCount;

  @override
  Future<void> setLaunchCount(int value) async => _launchCount = value;

  @override
  DateTime? get lastAskedAt => _lastAskedAt;

  @override
  Future<void> setLastAskedAt(DateTime value) async => _lastAskedAt = value;

  @override
  String? get lastAskedVersion => _lastAskedVersion;

  @override
  Future<void> setLastAskedVersion(String value) async =>
      _lastAskedVersion = value;
}
