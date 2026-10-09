import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bimir_lock/models/user_model.dart';
import 'package:bimir_lock/utils/encryption.dart';
import 'package:bimir_lock/utils/extensions.dart';
import 'package:bimir_lock/utils/helper/storage_constants.dart';
import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class StorageHelper {
  // static SharedPreferences? _sharedPreferences;

  // Future<SharedPreferences> get sharedPreferences async {
  //   if (_sharedPreferences != null) {
  //     return _sharedPreferences!;
  //   }
  //   _sharedPreferences = await SharedPreferences.getInstance();
  //   return _sharedPreferences!;
  // }

  Future<void> setUser(User user) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs
          .setString(StorageKey.user, jsonEncode(user))
          .then((value) => log("=======>>> user added"));
    } catch (e) {
      log("=================>>>>>> Error while setting user: $e");
    }
  }

  Future<User?> getUser() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return User.fromJson(await jsonDecode(prefs.getString(StorageKey.user)!));
    } catch (e) {
      log("=================>>>>>> Error while getting user: $e");
      return null;
    }
  }

  Future<bool> removeUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }

  Future<void> saveTheme(bool darkMode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKey.userThemeKey, darkMode);
  }

  Future<bool> readTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKey.userThemeKey) ?? false;
  }

  /// "system", "light" or "dark"; "light" until one is chosen. Installs from
  /// before the System option kept only a dark on/off flag; that choice is
  /// carried over as light or dark.
  Future<String> readThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? mode = prefs.getString(StorageKey.themeModeKey);
    if (mode != null) return mode;
    final bool? legacy = prefs.getBool(StorageKey.userThemeKey);
    if (legacy == null) return "light";
    return legacy ? "dark" : "light";
  }

  Future<void> saveThemeMode(String mode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKey.themeModeKey, mode);
  }

  Future<void> saveBiometricUnlock(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKey.biometricUnlockKey, enabled);
  }

  Future<bool> readBiometricUnlock() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKey.biometricUnlockKey) ?? false;
  }

  Future<void> setEncryptedPassword(String password) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs
          .setString(StorageKey.accessPassword,
              jsonEncode(EncryptData().encryptAES(password).base64))
          .then((value) => log("=======>>> encrypted Password added"));
    } catch (e) {
      log("=================>>>>>> Error while setting encrypted password: $e");
    }
  }

  Future<String?> getEncryptedPassword() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return EncryptData().decryptAES(
        Encrypted.fromBase64(
          await jsonDecode(
            prefs.getString(StorageKey.accessPassword)!,
          ),
        ),
      );
    } catch (e) {
      log("=================>>>>>> Error while getting encrypted Password: $e");
      return null;
    }
  }

  Future<String> getImageLocation() async {
    String imageDir = await getDatabasesPath();
    String newImagePath = "$imageDir/imageFolder";
    bool isDirExist = await Directory(newImagePath).exists();
    if (!isDirExist) await Directory(newImagePath).create();
    log("image Location: $newImagePath");
    return newImagePath;
  }

  // The profile photo is stored as a FILE NAME, never a full path. iOS moves the
  // app's container to a new folder on every update (and every Xcode run), so a
  // saved absolute path points at a folder that no longer exists, while the photo
  // itself moved along with the container and is still in imageFolder.
  static String avatarFileName(String stored) {
    final int slash = stored.lastIndexOf('/');
    return slash == -1 ? stored : stored.substring(slash + 1);
  }

  // The photo as it lives on THIS install, or null when there is none. Accepts a
  // bare name and the old absolute paths, which is what recovers existing photos.
  Future<File?> resolveAvatar(String? stored) async {
    if (stored == null || stored.trim().isEmpty) return null;
    try {
      final File file =
          File("${await getImageLocation()}/${avatarFileName(stored)}");
      return await file.exists() ? file : null;
    } catch (e) {
      log("resolveAvatar failed: ${e.runtimeType}");
      return null;
    }
  }

  // Copies a picked photo in under a fresh name and returns that name. A new name
  // each time also means Flutter's image cache can never keep showing the old one.
  // The previous photo is removed only after the new one is safely written.
  Future<String> storeImage(File file, {String? replacing}) async {
    final String dir = await getImageLocation();
    final String name =
        "avatar_${DateTime.now().millisecondsSinceEpoch}${file.getExtension()}";
    final File newFile = await file.copy("$dir/$name");
    if (await newFile.length() == 0) {
      await newFile.delete();
      throw const FileSystemException("copied photo is empty");
    }
    if (replacing != null && replacing.trim().isNotEmpty) {
      final String oldName = avatarFileName(replacing);
      if (oldName != name) {
        try {
          final File old = File("$dir/$oldName");
          if (await old.exists()) await old.delete();
        } catch (e) {
          // A leftover old photo wastes a little space; it is never an error.
          log("old avatar cleanup failed: ${e.runtimeType}");
        }
      }
    }
    return name;
  }
}
