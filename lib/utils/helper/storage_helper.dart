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

  Future<String> storeImage(File file) async {
    var newPath = await file.getNewDbFilePath();
    log("file path ==> $newPath");
    log(file.path);
    File newFile = await file.copy(newPath);
    log("newf ile ==> $newFile");
    return newFile.path;
  }
}
