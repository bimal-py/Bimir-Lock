import 'package:bimir_lock/controller/autofill/autofill_controller.dart';
import 'package:bimir_lock/controller/biometric/biometric_controller.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/modules/notes/notes_bootstrap.dart';
import 'package:bimir_lock/utils/helper/storage_helper.dart';
import 'package:bimir_lock/utils/pages.dart';
import 'package:bimir_lock/views/splash_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide ContextExtensionss;
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //for upgrade
  if (kDebugMode) {
    await Upgrader.clearSavedSettings();
  }
  await bootstrapNotes();
  CoreController.launchTheme = CoreController.themeModeFrom(
    await StorageHelper().readThemeMode(),
  );
  runApp(
    // Same design canvas as the Reminder Note app, whose Notes screens (and
    // design system) Bimir Lock shares.
    ScaleKitBuilder(designWidth: 425, designHeight: 691, child: BimirLock()),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class BimirLock extends StatelessWidget {
  BimirLock({super.key});
  final CoreController cc = Get.put(CoreController());
  final AutofillController ac = Get.put(AutofillController(), permanent: true);
  final BiometricController bc = Get.put(
    BiometricController(),
    permanent: true,
  );

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => MaterialApp(
        title: 'Bimir Lock',
        navigatorKey: navigatorKey,
        theme: ThemeConfigs.lightTheme(context: context),
        darkTheme: ThemeConfigs.darkTheme(context: context),
        themeMode: cc.themeMode.value,
        localizationsDelegates: notesLocalizationsDelegates,
        // Only the splash. An initialRoute of "/splashPage" would also put a
        // route for "/" under it, which the back button could reach.
        onGenerateInitialRoutes: (_) => <Route<dynamic>>[
          generatedRoute(const RouteSettings(name: SplashPage.routeName))!,
        ],
        debugShowCheckedModeBanner: false,
        onGenerateRoute: generatedRoute,
        // Honour the phone's text size, bounded so very large system text
        // enlarges the app without breaking its scaled layouts.
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(
              context,
            ).textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.5),
          ),
          // What shows between two launch screens while the logo glides,
          // instead of the window's black.
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: child!,
          ),
        ),
      ),
    );
  }
}
