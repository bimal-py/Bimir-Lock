import 'dart:async';

import 'package:bimir_lock/utils/helper/review_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

// Plain test()s over the in-memory store throughout, as in the Callbreak
// Tracker app these rules come from.

class _FakeRequester implements ReviewRequester {
  _FakeRequester({this.throwsOnRequest = false});

  bool available = true;
  final bool throwsOnRequest;

  /// Completes isAvailable() only when the test says so, to hold a call open.
  Completer<void>? gate;

  int availabilityChecks = 0;
  int asked = 0;

  @override
  Future<bool> isAvailable() async {
    availabilityChecks++;
    if (gate != null) await gate!.future;
    return available;
  }

  @override
  Future<void> requestReview() async {
    asked++;
    // As Android can: the sheet is up, then the call fails anyway.
    if (throwsOnRequest) throw Exception('launchReviewFlow failed');
  }
}

void main() {
  late _FakeRequester requester;
  late InMemoryReviewStore store;
  late DateTime clock;
  late String version;
  final installed = DateTime(2026, 1, 1, 9);

  /// A fresh prompt over the same store — what a new process looks like.
  ReviewPrompt build({Duration settleDelay = Duration.zero}) => ReviewPrompt(
    store: store,
    requester: requester,
    now: () => clock,
    appVersion: () async => version,
    settleDelay: settleDelay,
  );

  /// [count] cold starts, one process each, all at the current clock.
  Future<void> launch([int count = 1]) async {
    for (var i = 0; i < count; i++) {
      await build().recordLaunch();
    }
  }

  /// Installed, opened five times, and three days on: every gate open.
  Future<void> settledIn() async {
    await launch(ReviewPrompt.minLaunches);
    clock = installed.add(
      const Duration(days: ReviewPrompt.minDaysSinceFirstLaunch),
    );
  }

  setUp(() {
    requester = _FakeRequester();
    store = InMemoryReviewStore();
    clock = installed;
    version = '1.1.1';
  });

  test('the rules: 5 opens, 3 days, 120 days between asks', () {
    expect(ReviewPrompt.minLaunches, 5);
    expect(ReviewPrompt.minDaysSinceFirstLaunch, 3);
    expect(ReviewPrompt.coolOffDays, 120);
  });

  group('recordLaunch', () {
    test('seeds the first launch once and counts every launch', () async {
      await launch();
      expect(store.firstLaunchAt, installed);
      expect(store.launchCount, 1);

      clock = installed.add(const Duration(days: 10));
      await launch();
      expect(store.firstLaunchAt, installed, reason: 'never moved');
      expect(store.launchCount, 2);
    });

    test('counts once per process, however often it is called', () async {
      final prompt = build();
      await prompt.recordLaunch();
      await prompt.recordLaunch();
      await prompt.recordLaunch();
      expect(store.launchCount, 1);
    });

    test('an upgrader keeps their count and gets a first launch now', () async {
      // As left by the build before these rules: a count, no first launch.
      await store.setLaunchCount(7);
      clock = DateTime(2026, 6, 1);

      await launch();
      expect(store.launchCount, 8);
      expect(store.firstLaunchAt, DateTime(2026, 6, 1));
    });
  });

  group('gates', () {
    test('nothing is asked before any launch was recorded', () async {
      clock = installed.add(const Duration(days: 365));
      expect(await build().maybeRequestReview(), isFalse);
      expect(requester.availabilityChecks, 0);
    });

    test(
      'not before 3 days since the first launch — exactly 3 is enough',
      () async {
        await launch(ReviewPrompt.minLaunches);

        clock = installed.add(
          const Duration(days: 3) - const Duration(minutes: 1),
        );
        expect(await build().maybeRequestReview(), isFalse);
        expect(requester.asked, 0);

        clock = installed.add(const Duration(days: 3));
        expect(await build().maybeRequestReview(), isTrue);
        expect(requester.asked, 1);
      },
    );

    test('not before the 5th launch — the 5th is enough', () async {
      // Installed long ago, so only the launch count stands in the way.
      await store.setFirstLaunchAt(installed);
      clock = installed.add(const Duration(days: 30));
      // Launches 1–4: each is a new process that then reaches home.
      for (var i = 1; i < ReviewPrompt.minLaunches; i++) {
        final prompt = build();
        await prompt.recordLaunch();
        expect(await prompt.maybeRequestReview(), isFalse, reason: 'launch $i');
      }
      expect(requester.asked, 0);

      final fifth = build();
      await fifth.recordLaunch();
      expect(store.launchCount, 5);
      expect(await fifth.maybeRequestReview(), isTrue);
      expect(requester.asked, 1);
    });

    test('a 120-day cool-off after an ask, even on a new version', () async {
      await settledIn();
      expect(await build().maybeRequestReview(), isTrue);
      final asked = clock;

      version = '1.1.2';
      clock = asked.add(const Duration(days: 119, hours: 23));
      expect(await build().maybeRequestReview(), isFalse);
      expect(requester.asked, 1);

      clock = asked.add(const Duration(days: ReviewPrompt.coolOffDays));
      expect(await build().maybeRequestReview(), isTrue);
      expect(requester.asked, 2);
    });

    test('never twice on the same version; a new version may ask', () async {
      await settledIn();
      expect(await build().maybeRequestReview(), isTrue);
      expect(store.lastAskedVersion, '1.1.1');

      clock = clock.add(const Duration(days: 400));
      expect(await build().maybeRequestReview(), isFalse, reason: 'same one');
      expect(requester.asked, 1);

      version = '1.1.2';
      expect(await build().maybeRequestReview(), isTrue);
      expect(requester.asked, 2);
      expect(store.lastAskedVersion, '1.1.2');
    });

    test('nothing is recorded when the sheet is unavailable', () async {
      await settledIn();
      requester.available = false;

      expect(await build().maybeRequestReview(), isFalse);
      expect(store.lastAskedAt, isNull);
      expect(store.lastAskedVersion, isNull);

      // So it may try again once the sheet can be shown.
      requester.available = true;
      expect(await build().maybeRequestReview(), isTrue);
    });
  });

  test('the ask is recorded even when requestReview throws', () async {
    await settledIn();
    requester = _FakeRequester(throwsOnRequest: true);

    // And it never reaches the caller.
    expect(await build().maybeRequestReview(), isFalse);
    expect(requester.asked, 1);
    expect(store.lastAskedAt, clock);
    expect(store.lastAskedVersion, '1.1.1');
  });

  test('two calls at once make one request', () async {
    await settledIn();
    requester.gate = Completer<void>();
    final prompt = build();

    final first = prompt.maybeRequestReview();
    final second = prompt.maybeRequestReview();
    requester.gate!.complete();

    expect(await Future.wait([first, second]), [true, false]);
    expect(requester.availabilityChecks, 1);
    expect(requester.asked, 1);
  });

  test('the launch count is never reset by an ask', () async {
    await settledIn();
    expect(await build().maybeRequestReview(), isTrue);
    expect(store.launchCount, ReviewPrompt.minLaunches);

    await launch();
    expect(store.launchCount, ReviewPrompt.minLaunches + 1);
  });

  group('onSuccess', () {
    test('asks once every gate is open', () async {
      await settledIn();
      expect(await build().onSuccess(), isTrue);
      expect(requester.asked, 1);
    });

    test('is held to the same gates', () async {
      await launch(ReviewPrompt.minLaunches - 1);
      clock = installed.add(const Duration(days: 30));
      expect(await build().onSuccess(), isFalse);
      expect(requester.asked, 0);
    });

    test('waits for the success to settle first', () async {
      await settledIn();
      const delay = Duration(milliseconds: 150);
      final watch = Stopwatch()..start();

      final pending = build(settleDelay: delay).onSuccess();
      await Future<void>.delayed(Duration.zero);
      expect(requester.availabilityChecks, 0, reason: 'not yet');

      expect(await pending, isTrue);
      expect(watch.elapsed, greaterThanOrEqualTo(delay));
      expect(requester.asked, 1);
    });

    test('the default delay is the 1.5-second settle', () {
      expect(ReviewPrompt.settle, const Duration(milliseconds: 1500));
    });
  });
}
