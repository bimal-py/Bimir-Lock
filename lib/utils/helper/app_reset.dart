import 'dart:developer';
import 'dart:io';

import 'package:bimir_lock/controller/biometric/biometric_controller.dart';
import 'package:bimir_lock/controller/homePage/home_page_controller.dart';
import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/core/di/di.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/modules/notes/notes.dart';
import 'package:bimir_lock/utils/helper/db_helper.dart';
import 'package:bimir_lock/utils/helper/intruder_watch.dart';
import 'package:bimir_lock/utils/helper/storage_helper.dart';
import 'package:bimir_lock/views/introScreen/introduction_page.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Erases everything Bimir Lock keeps on this phone, as if it had just been
/// installed. Offered in Settings → Debug (debug builds), and as the last
/// resort of "Forgot PIN?" when fingerprint / Face ID unlock is off.
///
/// The vault key and its check value (in VaultMeta) are deliberately kept:
/// they are a matched pair, and an empty vault under the same key is a clean
/// start. Removing only one of them is what would make the app think the
/// vault was damaged.
class AppReset {
  AppReset._();

  static Future<void> wipe() async {
    // Saved passwords and their notes.
    if (!await DataBaseHelper().deleteAllPassword()) {
      throw StateError('passwords not deleted');
    }
    // Notes (Hive). Clearing keeps the box open, so the Notes screens just
    // see an empty store instead of a closed one.
    if (Hive.isBoxOpen(NotesStorageKeys.boxName)) await Hive.clearNotesBox();
    // Files: intruder photos, the profile photo, anything shared or exported.
    await IntruderWatch.clear();
    await _empty(Directory(await StorageHelper().getImageLocation()));
    await _empty(await getTemporaryDirectory());
    // Every preference: profile, PIN, theme, fingerprint / Face ID switch,
    // tips seen, wrong-PIN count, alerts, remembered site names.
    await (await SharedPreferences.getInstance()).clear();
  }

  /// [wipe], then puts what is held in memory back to a fresh install's
  /// state and starts first-run setup. False when the wipe failed (nothing is
  /// navigated then).
  static Future<bool> wipeAndRestart() async {
    try {
      await wipe();
    } catch (e) {
      log('reset failed: ${e.runtimeType}');
      return false;
    }
    final CoreController cc = Get.find<CoreController>();
    await cc.loadCurrentUser();
    await cc.loadEncryptedPassword();
    await cc.loadInitialTheme();
    if (Get.isRegistered<BiometricController>()) {
      await Get.find<BiometricController>().refreshStatus();
    }
    if (Get.isRegistered<HomePageController>()) {
      final HomePageController home = Get.find<HomePageController>();
      home.clearSearch();
      await home.loadPasswords();
    }
    if (getIt.isRegistered<NotesCubit>()) await getIt<NotesCubit>().load();
    navigatorKey.currentState!.pushNamedAndRemoveUntil(
      IntroductionPage.routeName,
      (route) => false,
    );
    return true;
  }

  static Future<void> _empty(Directory dir) async {
    if (!dir.existsSync()) return;
    for (final FileSystemEntity e in dir.listSync()) {
      try {
        await e.delete(recursive: true);
      } catch (e) {
        log('reset: could not delete a file: ${e.runtimeType}');
      }
    }
  }
}
