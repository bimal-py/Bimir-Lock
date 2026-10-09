import 'dart:convert';
import 'dart:io';

import 'package:bimir_lock/models/password_table.dart';
import 'package:bimir_lock/utils/helper/intruder_watch.dart';
import 'package:bimir_lock/utils/helper/pin_guard.dart';
import 'package:bimir_lock/utils/helper/site_book.dart';
import 'package:bimir_lock/utils/helper/vault_health.dart';
import 'package:bimir_lock/views/homePage/entry_actions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PinGuard', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    test('six wrong PINs are free, the 7th locks, then the lock grows to a cap', () {
      for (int i = 0; i < PinGuard.attempts; i++) {
        expect(PinGuard.lockFor(i), Duration.zero);
      }
      expect(PinGuard.attempts, 7);
      expect(PinGuard.lockFor(7), const Duration(seconds: 30));
      expect(PinGuard.lockFor(8), const Duration(minutes: 1));
      expect(PinGuard.lockFor(9), const Duration(minutes: 5));
      expect(PinGuard.lockFor(10), const Duration(minutes: 15));
      expect(PinGuard.lockFor(50), PinGuard.longest);
    });

    test('failures persist, lock, and a correct PIN clears them', () async {
      final DateTime now = DateTime(2026, 9, 27, 12);
      for (int i = 0; i < 6; i++) {
        expect(await PinGuard.recordFailure(now: now), Duration.zero);
      }
      expect(await PinGuard.remaining(now: now), Duration.zero);
      expect(await PinGuard.recordFailure(now: now), const Duration(seconds: 30));
      expect(await PinGuard.remaining(now: now), const Duration(seconds: 30));
      expect(
        await PinGuard.remaining(now: now.add(const Duration(seconds: 31))),
        Duration.zero,
      );
      await PinGuard.recordSuccess();
      expect(await PinGuard.failures(), 0);
      expect(await PinGuard.remaining(now: now), Duration.zero);
    });

    test('a clock set backwards never means a wait beyond the cap', () async {
      final DateTime now = DateTime(2026, 9, 27, 12);
      for (int i = 0; i < 7; i++) {
        await PinGuard.recordFailure(now: now);
      }
      final Duration left =
          await PinGuard.remaining(now: now.subtract(const Duration(days: 3)));
      expect(left, PinGuard.longest);
    });
  });

  group('pinWeakness', () {
    test('new PINs have six digits', () {
      expect(pinLength, 6);
      for (final String pin in <String>['4826', '48261', '12', '48a619']) {
        expect(pinWeakness(pin), isNotNull, reason: pin);
      }
    });

    test('rejects guessable PINs', () {
      for (final String pin in <String>[
        '000000', '777777', '123456', '654321', '345678', '121212',
        '123123', '909090', '112233', '159753', '696969',
      ]) {
        expect(pinWeakness(pin), isNotNull, reason: pin);
      }
    });

    test('debug master codes fit both keypad lengths (tests run in debug)', () {
      expect(isDebugMasterPin('2462'), isTrue);
      expect(isDebugMasterPin('246255'), isTrue);
      expect(isDebugMasterPin('24625'), isFalse);
      expect(isDebugMasterPin('246250'), isFalse);
    });

    test('accepts ordinary PINs', () {
      for (final String pin in <String>['482619', '905137', '317042', '592806']) {
        expect(pinWeakness(pin), isNull, reason: pin);
      }
    });
  });

  group('SiteBook', () {
    final List<Site> all = SiteBook.all(
      learned: <String>['Pokhara Club'],
      inVault: <String>['gmail', 'Home Wi-Fi'],
    );

    String names(String typed) =>
        SiteBook.suggestions(typed, all).map((Site s) => s.name).join(', ');

    test('matches the start of a name, then any word, then aliases', () {
      // A known site in the vault is offered with its proper spelling.
      expect(names('gm'), 'Gmail');
      expect(names('wi'), 'Wi-Fi, Wise, Home Wi-Fi');
      expect(names('twitter'), 'X');
      expect(names('kath'), isEmpty);
      expect(names('club'), 'Pokhara Club');
      expect(names(''), isEmpty);
    });

    test("the user's own names come first and are not repeated", () {
      expect(all.first.name, 'Pokhara Club');
      expect(all.where((Site s) => s.name.toLowerCase() == 'gmail').length, 1);
      // A vault name that is a known site keeps its kind.
      expect(all.firstWhere((Site s) => s.name == 'Gmail').kind, SiteKind.email);
    });

    test('never offers exactly what is typed', () {
      expect(names('Gmail'), isNot(contains('gmail')));
    });

    test('learns names it does not know, newest first, once', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await SiteBook.learn('Gmail');
      await SiteBook.learn('Hamro Patro');
      await SiteBook.learn('Pokhara Club');
      await SiteBook.learn('hamro patro');
      expect(await SiteBook.learned(), <String>['hamro patro', 'Pokhara Club']);
    });

    test('knows what the username field should ask for', () {
      expect(SiteBook.find('wi-fi')?.kind.userLabel, 'Network name');
      expect(SiteBook.find('Nabil Bank')?.kind, SiteKind.bank);
      expect(SiteBook.find('Nowhere'), isNull);
    });
  });

  group('IntruderWatch', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    test('a wrong PIN that locks the keypad is logged as an unseen alert', () async {
      for (int i = 0; i < 6; i++) {
        expect(await IntruderWatch.recordWrongPin(), Duration.zero);
      }
      expect(await IntruderWatch.events(), isEmpty);
      // Photo is off by default, so no camera is touched.
      expect(await IntruderWatch.recordWrongPin(), const Duration(seconds: 30));
      // The log is written without blocking the keypad.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final List<IntruderEvent> events = await IntruderWatch.events();
      expect(events.single.attempt, 7);
      expect(events.single.photo, isNull);
      expect(IntruderWatch.unseen.value, 1);
      await IntruderWatch.markSeen();
      expect(IntruderWatch.unseen.value, 0);
    });
  });

  group('VaultHealth', () {
    PasswordTable e(int id, String pw, {bool locked = false}) =>
        PasswordTable(id: id, title: 't$id', userName: 'u', password: pw, locked: locked);

    test('finds weak and reused passwords, ignoring locked entries', () {
      final VaultHealth h = VaultHealth.of(<PasswordTable>[
        e(1, 'kR9#vM2!pX7@wQ4&zT8'),
        e(2, 'password123'),
        e(3, 'Bz8!rW3@kN5#Tq'),
        e(4, 'Bz8!rW3@kN5#Tq'),
        e(5, 'Bz8!rW3@kN5#Tq'),
        e(6, 'password123', locked: true),
      ]);
      expect(h.weak, <int>{2});
      expect(h.reused, <int>{3, 4, 5});
      expect(h.sharedWith(e(4, '')), 2);
      expect(h.sharedWith(e(1, '')), 0);
      expect(h.attention, 4);
    });
  });

  group('maskUser', () {
    test('keeps enough to tell accounts apart', () {
      expect(maskUser('sita.sharma@gmail.com'), 'si•••@gmail.com');
      expect(maskUser('a@b.np'), 'a•••@b.np');
      expect(maskUser('sitasharma'), 'sit•••');
      expect(maskUser('ab'), 'ab•••');
      expect(maskUser('  '), 'No username');
      expect(maskUser(null), 'No username');
    });
  });

  group('launch quotes', () {
    final File file = File('assets/quotes/quotes.json');

    test('are short, attributed and unique', () {
      if (!file.existsSync()) {
        markTestSkipped('assets/quotes/quotes.json not present');
        return;
      }
      final List<dynamic> list = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      expect(list.length, 500);
      final Set<String> seen = <String>{};
      final Map<String, int> perAuthor = <String, int>{};
      for (final dynamic raw in list) {
        final Map<String, dynamic> q = raw as Map<String, dynamic>;
        final String text = (q['text'] as String).trim();
        final String author = (q['author'] as String).trim();
        expect(text, isNotEmpty);
        expect(author, isNotEmpty);
        expect(text.length, lessThanOrEqualTo(110), reason: text);
        expect(seen.add(text.toLowerCase()), isTrue, reason: 'duplicate: $text');
        perAuthor[author] = (perAuthor[author] ?? 0) + 1;
      }
      for (final MapEntry<String, int> a in perAuthor.entries) {
        expect(a.value, lessThanOrEqualTo(15), reason: a.key);
      }
    });
  });
}
