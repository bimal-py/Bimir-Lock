// Basic smoke tests for Bimir Lock.
//
// The app itself boots through SplashPage and immediately touches sqflite and
// shared_preferences, which are not available in a plain widget test, so these
// tests cover the pure pieces (models, validators, extensions) plus a smoke
// pump of the app theme.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bimir_lock/models/password_table.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/utils/extensions.dart';
import 'package:bimir_lock/utils/validators.dart';

void main() {
  test('DateFormatter formats a date as yyyy-MM-dd', () {
    expect(DateTime(2023, 7, 9).formatDate(), '2023-07-09');
  });

  test('PasswordTable.toJson never carries a plaintext password', () {
    PasswordTable passwordTable = PasswordTable(
      id: 1,
      title: "Facebook",
      userName: "bimal",
      password: "password",
    );
    final Map<String, dynamic> json = passwordTable.toJson();

    // THE regression test for the write invariant: the password column can
    // only ever be filled in by DataBaseHelper, which always encrypts. If
    // toJson ever carries it again, a write path can smuggle plaintext onto
    // disk without touching the crypto at all.
    expect(json.containsKey('password'), isFalse);

    PasswordTable decoded = PasswordTable.fromJson(json);
    expect(decoded.title, "Facebook");
    expect(decoded.userName, "bimal");
    expect(decoded.password, isNull);
    expect(decoded.locked, isFalse);
  });

  test('Validators flag empty and short input', () {
    expect(Validators.checkFieldEmpty(""), 'This field is required');
    expect(Validators.checkFieldEmpty("Facebook"), null);
    expect(Validators.checkPinField("123"), 'Invalid pin');
    expect(Validators.checkPinField("1234"), null);
    expect(Validators.checkConfirmPin("1234", "1235"), "Pin does not match");
    expect(Validators.checkConfirmPin("1234", "1234"), null);
  });

  testWidgets('App theme builds a light and a dark MaterialApp',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ScaleKitBuilder(
        designWidth: 425,
        designHeight: 691,
        child: Builder(
          builder: (BuildContext context) => MaterialApp(
            theme: ThemeConfigs.lightTheme(context: context),
            darkTheme: ThemeConfigs.darkTheme(context: context),
            home: const Scaffold(body: Text("Bimir Lock")),
          ),
        ),
      ),
    );

    expect(find.text("Bimir Lock"), findsOneWidget);
  });
}
