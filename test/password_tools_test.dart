import 'package:bimir_lock/ui/password_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generatePassword', () {
    test('has the requested length and every selected kind of character', () {
      for (int i = 0; i < 200; i++) {
        final String p = generatePassword(length: 16);
        expect(p.length, 16);
        expect(p, matches(RegExp(r'[a-z]')));
        expect(p, matches(RegExp(r'[A-Z]')));
        expect(p, matches(RegExp(r'[0-9]')));
        expect(p, matches(RegExp(r'[^a-zA-Z0-9]')));
      }
    });

    test('leaves out digits and symbols when asked', () {
      for (int i = 0; i < 100; i++) {
        final String p = generatePassword(
          length: 12,
          digits: false,
          symbols: false,
        );
        expect(p, matches(RegExp(r'^[a-zA-Z]{12}$')));
      }
    });

    test('never uses look-alike characters', () {
      final String many = List<String>.generate(
        300,
        (_) => generatePassword(length: 40),
      ).join();
      expect(many, isNot(matches(RegExp(r'[lIO01]'))));
    });

    test('does not repeat itself', () {
      final Set<String> seen = <String>{
        for (int i = 0; i < 500; i++) generatePassword(),
      };
      expect(seen.length, 500);
    });

    test('generated passwords rate strong or better', () {
      for (int i = 0; i < 100; i++) {
        expect(
          estimateStrength(generatePassword(length: 20)).segments,
          greaterThanOrEqualTo(3),
        );
      }
    });
  });

  group('estimateStrength', () {
    test('common and patterned passwords are weak', () {
      for (final String p in <String>[
        'password',
        'Password123',
        '12345678',
        'qwerty2024',
        'aaaaaaaa',
        'abcdefgh',
      ]) {
        expect(estimateStrength(p).segments, lessThanOrEqualTo(1), reason: p);
      }
    });

    test('a word and a year is weak however it is capitalised', () {
      for (final String p in <String>['Summer2024', 'Kathmandu1996!', 'monsoon2025']) {
        expect(estimateStrength(p).segments, lessThanOrEqualTo(1), reason: p);
      }
    });

    test('length and variety make it stronger', () {
      expect(estimateStrength('').segments, 0);
      expect(estimateStrength('Tr7#qLm2').segments, greaterThanOrEqualTo(2));
      expect(estimateStrength('kR9#vM2!pX7@wQ4&zT8').segments, 4);
    });
  });
}
