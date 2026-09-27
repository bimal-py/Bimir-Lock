import 'package:bimir_lock/controller/autofill/autofill_controller.dart';
import 'package:bimir_lock/controller/biometric/biometric_controller.dart';
import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/utils/app_theme.dart';
import 'package:bimir_lock/utils/pages.dart';
import 'package:bimir_lock/views/splash_page.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //for upgrade
  if (kDebugMode) {
    await Upgrader.clearSavedSettings();
  }
  runApp(BimirLock());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class BimirLock extends StatelessWidget {
  BimirLock({super.key});
  final CoreController cc = Get.put(CoreController());
  final AutofillController ac = Get.put(AutofillController(), permanent: true);
  final BiometricController bc =
      Get.put(BiometricController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => MaterialApp(
        navigatorKey: navigatorKey,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: cc.themeMode.value,
        // routes: routes,
        initialRoute: SplashPage.routeName,
        debugShowCheckedModeBanner: false,
        onGenerateRoute: generatedRoute,
      ),
    );
  }
}
