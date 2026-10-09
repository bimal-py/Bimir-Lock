// Smoke test for the Notes module ported from Reminder Note: Hive in a temp
// dir, the module's own registration, the notes home on a phone at normal and
// large text, and creating a note through the UI. Fails on any exception,
// including layout overflows.
//
// Text is measured with the app's real UI font (Google Sans Flex, loaded from
// assets/fonts), not flutter_test's default Ahem font whose every glyph is a
// full em wide, so overflow checks reflect what a phone actually renders.

import 'dart:io';

import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/modules/notes/notes.dart';
import 'package:bimir_lock/modules/notes/notes_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadAppFont() async {
  final FontLoader loader = FontLoader(AppFonts.sans);
  for (final String weight in <String>[
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
  ]) {
    final File file = File('assets/fonts/GoogleSansFlex-$weight.ttf');
    loader.addFont(
      file.readAsBytes().then(
        (List<int> b) => ByteData.sublistView(Uint8List.fromList(b)),
      ),
    );
  }
  await loader.load();
}

Widget _app() {
  return ScaleKitBuilder(
    designWidth: 425,
    designHeight: 691,
    child: Builder(
      builder: (BuildContext context) => MaterialApp(
        theme: ThemeConfigs.lightTheme(context: context),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: notesLocalizationsDelegates,
        onGenerateRoute: notesGeneratedRoute,
        initialRoute: notesHomeRoute,
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
  }
}

/// Lets Hive's real file I/O finish (it never completes inside the test's
/// fake-async zone), then rebuilds.
Future<void> _flushIo(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await _settle(tester);
}

void _phone(WidgetTester tester, {double textScale = 1.0}) {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAllTestValues();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    await _loadAppFont();
    hiveDir = Directory.systemTemp.createTempSync('bimir_notes_test_');
    Hive.init(hiveDir.path);
    await registerNotes();
  });

  tearDownAll(() async {
    // A write left pending by a failed test can never finish outside its
    // fake-async zone; don't let it hang the run.
    await getIt<NotesCubit>().close();
    await Hive.close().timeout(
      const Duration(seconds: 2),
      onTimeout: () => const <void>[],
    );
    try {
      hiveDir.deleteSync(recursive: true);
    } on FileSystemException {
      // Best effort.
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // Toasts (CustomSnackbar) go through fluttertoast's channel.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('PonnamKarthik/fluttertoast'),
          (MethodCall call) async => true,
        );
  });

  testWidgets('notes home renders on a phone', (WidgetTester tester) async {
    _phone(tester);
    await tester.pumpWidget(_app());
    await _settle(tester);

    expect(find.byType(NotesScreen), findsOneWidget);
    expect(find.text('Notes'), findsWidgets);
    expect(find.text('Add Notes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notes home renders at text scale 1.5', (
    WidgetTester tester,
  ) async {
    _phone(tester, textScale: 1.5);
    await tester.pumpWidget(_app());
    await _settle(tester);

    expect(find.text('Add Notes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final double scale in <double>[1.0, 1.5]) {
    testWidgets('create a note through the UI (text scale $scale)', (
      WidgetTester tester,
    ) async {
      _phone(tester, textScale: scale);
      await tester.pumpWidget(_app());
      await _settle(tester);

      final String title = 'Groceries $scale';

      // + tile → the editor.
      await tester.tap(find.text('Add Notes'));
      await _settle(tester);
      expect(find.byType(AddNoteScreen), findsOneWidget);
      expect(find.text('New note'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, title);
      await _settle(tester);

      // ✓ saves and pops back to the grid.
      await tester.tap(find.byTooltip('Save'));
      await _settle(tester);
      await _flushIo(tester);

      expect(find.byType(AddNoteScreen), findsNothing);
      expect(find.text(title), findsOneWidget);
      expect(
        getIt<NotesCubit>().state.notes.any((NoteEntity n) => n.title == title),
        isTrue,
      );

      // Open it → read view.
      await tester.tap(find.text(title));
      await _settle(tester);
      expect(find.byType(NoteDetailScreen), findsOneWidget);
      expect(find.text(title), findsOneWidget);

      // Back, then the sort sheet and the list view.
      await tester.pageBack();
      await _settle(tester);
      await tester.tap(find.byTooltip('Sort & view'));
      await _settle(tester);
      expect(find.text('Sort & view'), findsWidgets);
      await tester.tapAt(const Offset(20, 20)); // dismiss the sheet
      await _settle(tester);

      await tester.tap(find.byTooltip('List view'));
      await _settle(tester);
      expect(find.text(title), findsOneWidget);
      await tester.tap(find.byTooltip('Grid view'));
      await _settle(tester);
      await _flushIo(tester);

      // Settings and (empty) archive screens.
      await tester.tap(find.byTooltip('Notes settings'));
      await _settle(tester);
      expect(find.byType(NotesSettingsScreen), findsOneWidget);
      await tester.pageBack();
      await _settle(tester);
      await _flushIo(tester);

      expect(tester.takeException(), isNull);
    });
  }
}
