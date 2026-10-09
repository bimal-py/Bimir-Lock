// Renders every screen at several sizes, text scales and both themes.
//
//   * Always: fails on any layout overflow (RenderFlex overflow etc.), so a
//     screen that breaks on a small phone, in landscape or with large system
//     text is caught without a device.
//   * With SCREENSHOT_DIR=/some/dir (and FONT_DIR pointing at Flutter's
//     bin/cache/artifacts/material_fonts), it also writes a PNG per case so the
//     design can be looked at.
//
//   SCREENSHOT_DIR=/tmp/shots FONT_DIR=$FLUTTER_ROOT/bin/cache/artifacts/material_fonts \
//     flutter test test/screens_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bimir_lock/controller/autofill/autofill_controller.dart';
import 'package:bimir_lock/controller/biometric/biometric_controller.dart';
import 'package:bimir_lock/controller/homePage/home_page_controller.dart';
import 'package:bimir_lock/ui/coach_marks.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/models/password_table.dart';
import 'package:bimir_lock/modules/notes/notes.dart';
import 'package:bimir_lock/modules/notes/notes_bootstrap.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bimir_lock/models/user_model.dart';
import 'package:bimir_lock/utils/pages.dart';
import 'package:bimir_lock/views/homePage/add_password.dart';
import 'package:bimir_lock/views/homePage/home_page.dart';
import 'package:bimir_lock/views/homePage/password_detail.dart';
import 'package:bimir_lock/views/introScreen/introduction_page.dart';
import 'package:bimir_lock/views/introScreen/welcome_page.dart';
import 'package:bimir_lock/views/intruder_page.dart';
import 'package:bimir_lock/ui/photo_preview.dart';
import 'package:bimir_lock/ui/site_field.dart';
import 'package:bimir_lock/ui/intruder_prompt.dart';
import 'package:bimir_lock/widgets/backup_dialogs.dart';
import 'package:bimir_lock/views/pin/set_access_pin.dart';
import 'package:bimir_lock/views/settings_page.dart';
import 'package:bimir_lock/views/user/add_user_detail.dart';
import 'package:bimir_lock/views/faq/faq_page.dart';
import 'package:bimir_lock/views/quotes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide ContextExtensionss;
import 'package:shared_preferences/shared_preferences.dart';

final String? _shotDir = Platform.environment['SCREENSHOT_DIR'];
final String? _fontDir = Platform.environment['FONT_DIR'];

class _FakeCore extends CoreController {
  _FakeCore({User? user, String? pin, ThemeMode mode = ThemeMode.light}) {
    currentUser.value = user;
    encryptedPassword = pin;
    themeMode.value = mode;
  }

  // No storage or database in a widget test.
  @override
  // ignore: must_call_super
  void onInit() {}
}

/// Tours off unless a test asks for one.
class _Tours implements CoachMarkStore {
  _Tours({Set<String> unseen = const <String>{}}) : unseen = <String>{...unseen};
  final Set<String> unseen;
  @override
  Future<bool> hasSeen(String tourId) async => !unseen.contains(tourId);
  @override
  Future<void> markSeen(String tourId) async => unseen.remove(tourId);
  @override
  Future<void> reset() async {}
}

class _FakeHome extends HomePageController {
  _FakeHome(this.sample);
  final List<PasswordTable> sample;

  @override
  Future loadPasswords() async {
    passwords?.value = sample;
  }
}

List<PasswordTable> _sample() {
  int id = 0;
  PasswordTable e(String t, String u, String p, [String? note]) =>
      PasswordTable(id: ++id, title: t, userName: u, password: p, note: note);
  return <PasswordTable>[
    e('Gmail', 'sita.sharma@gmail.com', 'vN7#qT2!mLp9@xR4'),
    e('GitHub', 'sitasharma', 'Hk4\$wP8^zQ2&nV6j'),
    e('eSewa', '9841234567', 'password123'),
    e('Khalti', '9841234567', 'Summer2024'),
    e('Netflix', 'sita.sharma@gmail.com', 'Summer2024',
        'Family plan, renews on the 3rd.\nProfile lock PIN is on the fridge.'),
    e('Home Wi-Fi', 'router', 'kR9#vM2!pX7@wQ4&zT8'),
    e('Instagram', 'sita.clicks', 'Tr7#qLm2Zx'),
    e('Daraz', 'sita.sharma@gmail.com', 'Bz8!rW3@kN5#'),
    e('Figma', 'sita@studio.np', 'Jq6&tY9*mC4^'),
    e('Amazon', 'sita.sharma@gmail.com', 'Pw5%hG8!vD2='),
    e('Bank of Kathmandu', 'SITA0427', 'Ux3@nB7#fK1?'),
    e('Zoom', 'sita@studio.np', 'Lm4^cX8&sR6+'),
  ];
}

class _Case {
  const _Case(this.name, this.size, {this.textScale = 1.0, this.dark = false});
  final String name;
  final Size size;
  final double textScale;
  final bool dark;
}

const List<_Case> _cases = <_Case>[
  _Case('phone', Size(390, 844)),
  _Case('phone-dark', Size(390, 844), dark: true),
  _Case('small', Size(320, 568)),
  _Case('bigtext', Size(390, 844), textScale: 2.0),
  _Case('small-bigtext', Size(320, 568), textScale: 1.6),
  _Case('landscape', Size(844, 390)),
  _Case('tablet', Size(820, 1180), dark: true),
];

/// Where a package's files are, from .dart_tool/package_config.json.
String? _packageDir(String name) {
  final File cfg = File('.dart_tool/package_config.json');
  if (!cfg.existsSync()) return null;
  final RegExp entry = RegExp('"name":\\s*"$name",\\s*"rootUri":\\s*"([^"]+)"');
  final Match? m = entry.firstMatch(cfg.readAsStringSync());
  if (m == null) return null;
  final String uri = m.group(1)!;
  return uri.startsWith('file://') ? Uri.parse(uri).toFilePath() : uri;
}

Future<void> _loadFonts() async {
  final String? dir = _fontDir;
  if (dir == null) return;
  Future<void> family(String name, List<String> files) async {
    final FontLoader loader = FontLoader(name);
    for (final String f in files) {
      if (!File(f).existsSync()) return;
      loader.addFont(Future<ByteData>.value(ByteData.sublistView(File(f).readAsBytesSync())));
    }
    await loader.load();
  }

  await family('Roboto', <String>['$dir/Roboto-Regular.ttf', '$dir/Roboto-Medium.ttf', '$dir/Roboto-Bold.ttf']);
  await family('MaterialIcons', <String>['$dir/MaterialIcons-Regular.otf']);
  await family('GoogleSans', <String>[
    'assets/fonts/GoogleSansFlex-Regular.ttf',
    'assets/fonts/GoogleSansFlex-Medium.ttf',
    'assets/fonts/GoogleSansFlex-SemiBold.ttf',
    'assets/fonts/GoogleSansFlex-Bold.ttf',
  ]);
  await family('JetBrainsMono', <String>['assets/fonts/JetBrainsMono-Regular.ttf']);
  final String? lucide = _packageDir('lucide_icons_flutter');
  if (lucide != null) {
    await family('packages/lucide_icons_flutter/Lucide', <String>['$lucide/assets/lucide.ttf']);
  }
  final String? fa = _packageDir('font_awesome_flutter');
  if (fa != null) {
    final String f = '$fa/lib/fonts';
    await family('packages/font_awesome_flutter/FontAwesomeBrands', <String>['$f/Font-Awesome-7-Brands-Regular-400.otf']);
    await family('packages/font_awesome_flutter/FontAwesomeRegular', <String>['$f/Font-Awesome-7-Free-Regular-400.otf']);
    await family('packages/font_awesome_flutter/FontAwesomeSolid', <String>['$f/Font-Awesome-7-Free-Solid-900.otf']);
  }
}

final GlobalKey _boundary = GlobalKey();

Future<void> _pumpApp(
  WidgetTester tester,
  _Case c, {
  required String route,
  Object? arguments,
  User? user,
  String? pin = '4826',
  List<PasswordTable>? entries,
  Set<String> tours = const <String>{},
  Map<String, Object> prefs = const <String, Object>{},
}) async {
  tester.view.physicalSize = c.size * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = c.textScale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAllTestValues();
  });

  Get.reset();
  IntruderPrompt.debugReset();
  // The one-time Wrong PIN alerts prompt counts as seen unless a case says
  // otherwise, so it does not cover every vault render.
  SharedPreferences.setMockInitialValues(<String, Object>{
    IntruderPrompt.shownKey: true,
    ...prefs,
  });
  final _FakeCore core = _FakeCore(
    user: user,
    pin: pin,
    mode: c.dark ? ThemeMode.dark : ThemeMode.light,
  );
  Get.put<CoreController>(core);
  Get.put(BiometricController(), permanent: true);
  Get.put(AutofillController(), permanent: true);
  Get.put<HomePageController>(_FakeHome(entries ?? _sample()));
  CoachMarks.debugReset();
  CoachMarks.store = _Tours(unseen: tours);

  await tester.pumpWidget(
    ScaleKitBuilder(
      designWidth: 425,
      designHeight: 691,
      child: Builder(
        builder: (BuildContext ctx) => RepaintBoundary(
          key: _boundary,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            theme: ThemeConfigs.lightTheme(context: ctx),
            darkTheme: ThemeConfigs.darkTheme(context: ctx),
            themeMode: core.themeMode.value,
            localizationsDelegates: notesLocalizationsDelegates,
            debugShowCheckedModeBanner: false,
            onGenerateRoute: generatedRoute,
            onGenerateInitialRoutes: (String _) => <Route<dynamic>>[
              generatedRoute(RouteSettings(name: route, arguments: arguments))!,
            ],
            builder: (BuildContext context, Widget? child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.of(context)
                    .textScaler
                    .clamp(minScaleFactor: 0.9, maxScaleFactor: 1.5),
              ),
              child: child!,
            ),
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (int i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  final String? dir = _shotDir;
  if (dir == null) return;
  await tester.runAsync(() async {
    final RenderRepaintBoundary b =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await b.toImage(pixelRatio: 2);
    final ByteData? png = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    Directory(dir).createSync(recursive: true);
    File('$dir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

final User _user = User(userName: 'Sita Sharma', dob: '1996-04-27');

void main() {
  setUpAll(() async {
    await _loadFonts();
    Hive.init(Directory.systemTemp.createTempSync('bimir_screens_').path);
    await registerNotes();
  });
  tearDownAll(() async {
    await Hive.close().timeout(const Duration(seconds: 2), onTimeout: () => const <void>[]);
  });

  for (final _Case c in _cases) {
    group(c.name, () {
      testWidgets('welcome', (WidgetTester tester) async {
        await _pumpApp(tester, c, route: WelcomePage.routeName, user: _user);
        await _shot(tester, '${c.name}-01-welcome');
        // Leave before the timer hands over to the vault.
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('onboarding', (WidgetTester tester) async {
        await _pumpApp(tester, c, route: IntroductionPage.routeName, pin: null);
        await tester.tap(find.byTooltip('Show'));
        await _settle(tester);
        await _shot(tester, '${c.name}-02-onboarding-1');
        // Half way between two slides: they must not touch.
        final TestGesture swipe = await tester.startGesture(
          tester.getCenter(find.byType(PageView)),
        );
        await swipe.moveBy(Offset(-c.size.width * 0.45, 0));
        await tester.pump();
        await _shot(tester, '${c.name}-02b-onboarding-swipe');
        await swipe.moveBy(Offset(c.size.width * 0.45, 0));
        await swipe.up();
        await _settle(tester);
        await tester.tap(find.text('Next'));
        await _settle(tester);
        await tester.tap(find.text('Next'));
        await _settle(tester);
        await _shot(tester, '${c.name}-03-onboarding-3');
      });

      testWidgets('profile (first run)', (WidgetTester tester) async {
        await _pumpApp(
          tester,
          c,
          route: AddUserDetailPage.routeName,
          pin: null,
        );
        await _shot(tester, '${c.name}-04-profile');
      });

      testWidgets('pin setup', (WidgetTester tester) async {
        await _pumpApp(
          tester,
          c,
          route: SetAccessPinPage.routeName,
          arguments: const PinSetupArgs(onboarding: true),
          user: _user,
          pin: null,
        );
        await tester.tap(find.text('4'));
        await tester.tap(find.text('8'));
        await _settle(tester);
        await _shot(tester, '${c.name}-05-pin-setup');
      });

      testWidgets('vault', (WidgetTester tester) async {
        await _pumpApp(tester, c, route: HomePage.routeName, user: _user);
        await _shot(tester, '${c.name}-06-vault');
      });

      testWidgets('vault empty', (WidgetTester tester) async {
        await _pumpApp(
          tester,
          c,
          route: HomePage.routeName,
          user: _user,
          entries: <PasswordTable>[],
        );
        await _shot(tester, '${c.name}-07-vault-empty');
      });

      testWidgets('unlock sheet', (WidgetTester tester) async {
        await _pumpApp(tester, c, route: HomePage.routeName, user: _user);
        // The list is lazy: scroll until the row exists, then place it well
        // clear of the floating button, which covers the bottom edge.
        await tester.scrollUntilVisible(find.text('Amazon'), 200,
            scrollable: find.byType(Scrollable).first);
        await Scrollable.ensureVisible(tester.element(find.text('Amazon')),
            alignment: 0.3);
        await _settle(tester);
        await tester.tap(find.text('Amazon'));
        await _settle(tester);
        await tester.tap(find.text('1').last);
        await tester.tap(find.text('9').last);
        await _settle(tester);
        await _shot(tester, '${c.name}-08-unlock');
      });

      testWidgets('detail', (WidgetTester tester) async {
        final List<PasswordTable> rows = _sample();
        await _pumpApp(
          tester,
          c,
          route: PasswordDetailPage.routeName,
          user: _user,
          entries: rows,
          arguments: PasswordDetailPageArgument(
            passwordTable: rows[4],
            isEdit: false,
          ),
        );
        await tester.tap(find.byTooltip('Show'));
        await _settle(tester);
        await _shot(tester, '${c.name}-09-detail');
      });

      testWidgets('new password', (WidgetTester tester) async {
        await _pumpApp(
          tester,
          c,
          route: AddPasswordPage.routeName,
          user: _user,
        );
        await tester.enterText(find.byType(TextFormField).at(0), 'Spotify');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'sita.sharma@gmail.com',
        );
        final Finder gen = find.text('Generate a password');
        await tester.ensureVisible(gen);
        await tester.tap(gen);
        await _settle(tester);
        FocusManager.instance.primaryFocus?.unfocus();
        await _settle(tester);
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await _settle(tester);
        await _shot(tester, '${c.name}-10-new-password');
      });

      testWidgets('settings', (WidgetTester tester) async {
        await _pumpApp(tester, c, route: SettingsPage.routeName, user: _user);
        await _shot(tester, '${c.name}-11-settings');
        await tester.drag(find.byType(ListView), const Offset(0, -2000));
        await _settle(tester);
        await _shot(tester, '${c.name}-12-settings-end');
      });

      testWidgets('unlock after a lock says the tries left', (WidgetTester tester) async {
        // 10 wrong PINs locked the keypad once; that lock has run out.
        await _pumpApp(
          tester,
          c,
          route: HomePage.routeName,
          user: _user,
          prefs: <String, Object>{'pin_failures': 10},
        );
        await tester.scrollUntilVisible(find.text('Amazon'), 200,
            scrollable: find.byType(Scrollable).first);
        await Scrollable.ensureVisible(tester.element(find.text('Amazon')),
            alignment: 0.3);
        await _settle(tester);
        await tester.tap(find.text('Amazon'));
        await _settle(tester);
        expect(find.text('7 tries left before a 1-minute lock.'), findsOneWidget);
        await _shot(tester, '${c.name}-27-unlock-tries-left');
      });

      testWidgets('recent quotes', (WidgetTester tester) async {
        await _pumpApp(
          tester,
          c,
          route: QuotesPage.routeName,
          user: _user,
          prefs: <String, Object>{
            'quote_history': <String>[
              for (final (String text, String author, String? source, int hoursAgo)
                  in <(String, String, String?, int)>[
                    ('Three may keep a secret, if two of them are dead.', 'Benjamin Franklin', "Poor Richard's Almanack, 1735", 1),
                    ('Amateurs hack systems, professionals hack people.', 'Bruce Schneier', null, 26),
                    ('Distrust and caution are the parents of security.', 'Benjamin Franklin', null, 80),
                  ])
                jsonEncode(<String, Object?>{
                  'text': text,
                  'author': author,
                  'source': source,
                  'at': DateTime.now()
                      .subtract(Duration(hours: hoursAgo))
                      .millisecondsSinceEpoch,
                }),
            ],
          },
        );
        expect(find.text('Recent quotes'), findsOneWidget);
        await _shot(tester, '${c.name}-28-recent-quotes');
      });

      testWidgets('wrong PIN alerts prompt', (WidgetTester tester) async {
        await _pumpApp(
          tester,
          c,
          route: HomePage.routeName,
          user: _user,
          prefs: <String, Object>{IntruderPrompt.shownKey: false},
        );
        expect(find.text('See who tries to get in'), findsOneWidget);
        await _shot(tester, '${c.name}-26-intruder-prompt');
      });

      testWidgets('faq', (WidgetTester tester) async {
        await _pumpApp(tester, c, route: FaqPage.routeName, user: _user);
        await _shot(tester, '${c.name}-24-faq');
        await tester.enterText(find.byType(TextField), 'forgot my pin');
        await _settle(tester);
        expect(find.text('Best match'), findsOneWidget);
        await _shot(tester, '${c.name}-25-faq-search');
      });

      testWidgets('vault tour', (WidgetTester tester) async {
        await _pumpApp(tester, c,
            route: HomePage.routeName,
            user: _user,
            tours: <String>{CoachTours.vault, CoachTours.vaultBasics});
        for (int i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        // Passwords already saved: every tip in one tour.
        expect(find.text('1/6'), findsOneWidget);
        await _shot(tester, '${c.name}-13-vault-tour');
        await tester.tap(find.text('Next'));
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await _shot(tester, '${c.name}-14-vault-tour-2');
        await tester.tap(find.text('Skip'));
        await _settle(tester);
      });

      testWidgets('site suggestions', (WidgetTester tester) async {
        await _pumpApp(tester, c, route: AddPasswordPage.routeName, user: _user);
        await tester.enterText(find.byType(TextFormField).at(0), 'Ba');
        await _settle(tester);
        await _shot(tester, '${c.name}-17-site-suggestions');
        await tester.tap(find.text('Bank').last);
        await _settle(tester);
        expect(find.text('Username or customer ID'), findsOneWidget);
        // The list closes on a pick, and stays closed back in the field...
        expect(find.byType(SiteSuggestions), findsNothing);
        await tester.tap(find.byType(TextFormField).at(0));
        await _settle(tester);
        expect(find.byType(SiteSuggestions), findsNothing);
        // ...until the name is edited.
        await tester.enterText(find.byType(TextFormField).at(0), 'Ba');
        await _settle(tester);
        expect(find.byType(SiteSuggestions), findsOneWidget);
      });

      testWidgets('empty vault: basics now, list tips after the first save',
          (WidgetTester tester) async {
        await _pumpApp(tester, c,
            route: HomePage.routeName,
            user: _user,
            entries: <PasswordTable>[],
            tours: <String>{CoachTours.vault, CoachTours.vaultBasics});
        for (int i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        // First Add, Notes, Settings; never the hidden round Add button.
        expect(find.text('Add your first password'), findsOneWidget);
        expect(find.text('1/3'), findsOneWidget);
        expect(find.text('Add a password'), findsNothing);
        await _shot(tester, '${c.name}-22-empty-vault-tour');
        await tester.tap(find.text('Skip'));
        await _settle(tester);

        Get.find<HomePageController>().passwords!.value = _sample();
        for (int i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        // Checkup, rows, search, Add; Notes and Settings were already shown.
        expect(find.text('1/4'), findsOneWidget);
        await tester.tap(find.text('Skip'));
        await _settle(tester);
      });

      testWidgets('whoever saw the old tour sees none of it again',
          (WidgetTester tester) async {
        await _pumpApp(tester, c,
            route: HomePage.routeName,
            user: _user,
            tours: <String>{CoachTours.vaultBasics});
        for (int i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('Skip'), findsNothing);
      });

      testWidgets('dialogs', (WidgetTester tester) async {
        await _pumpApp(tester, c, route: HomePage.routeName, user: _user);
        DialogUtils.showConfirmationDialog(
          navigatorKey.currentContext!,
          title: 'Delete Nepal Investment Mega Bank?',
          message:
              'The password is removed from this phone. This cannot be undone, unless it is in a backup file.',
          confirmText: 'Delete',
          dialogType: DialogType.danger,
        );
        await _settle(tester);
        await _shot(tester, '${c.name}-20-dialog-delete');
        await tester.tap(find.text('Cancel'));
        await _settle(tester);
        showBackupPasswordDialog(navigatorKey.currentContext!, confirm: true);
        await _settle(tester);
        await _shot(tester, '${c.name}-21-dialog-backup');
        await tester.tap(find.text('Cancel'));
        await _settle(tester);
      });

      testWidgets('vault with an alert', (WidgetTester tester) async {
        await _pumpApp(tester, c,
            route: HomePage.routeName,
            user: _user,
            prefs: <String, Object>{'intruder_unseen': 2});
        await _shot(tester, '${c.name}-18-vault-alert');
      });

      testWidgets('wrong PIN alerts', (WidgetTester tester) async {
        final int now = DateTime(2026, 10, 9, 15, 42).millisecondsSinceEpoch;
        await _pumpApp(tester, c,
            route: IntruderPage.routeName,
            user: _user,
            prefs: <String, Object>{
              'intruder_log':
                  '[{"at":$now,"attempt":17,"photo":null},{"at":${now - 60000},"attempt":10,"photo":null}]',
            });
        await _shot(tester, '${c.name}-19-alerts');

        // A photo opened large over the blurred page. The logo stands in for
        // a camera shot.
        final File photo = File('assets/brand/mark.png');
        await tester.runAsync(() => precacheImage(
              FileImage(photo),
              navigatorKey.currentContext!,
            ));
        showPhotoPreview(
          navigatorKey.currentContext!,
          file: photo,
          name: '8th wrong PIN · Today, 3:42 PM',
        );
        await _settle(tester);
        await _shot(tester, '${c.name}-23-photo-preview');
        // Tapping off the photo closes it.
        await tester.tapAt(const Offset(8, 8));
        await _settle(tester);
        expect(find.text('8th wrong PIN · Today, 3:42 PM'), findsNothing);
      });

      testWidgets('notes', (WidgetTester tester) async {
        await _pumpApp(tester, c, route: notesHomeRoute, user: _user);
        await _shot(tester, '${c.name}-15-notes');
      });

      testWidgets('note editor', (WidgetTester tester) async {
        await _pumpApp(tester, c, route: NotesRoutes.addNote, user: _user);
        await _shot(tester, '${c.name}-16-note-editor');
      });
    });
  }
}
