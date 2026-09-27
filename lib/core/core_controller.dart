import 'dart:developer';

import 'package:bimir_lock/models/quote_model.dart';
import 'package:bimir_lock/utils/helper/db_helper.dart';
import 'package:bimir_lock/utils/helper/storage_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/user_model.dart';

class CoreController extends GetxController {
  DataBaseHelper dataBaseHelper = DataBaseHelper();
  StorageHelper storageHelper = StorageHelper();
  Rx<Quote?> initialQuote = Quote().obs;
  Rx<User?> currentUser = Rxn<User>();
  String? encryptedPassword;

  @override
  void onInit() async {
    await loadCurrentUser();
    await loadInitQuote();
    await loadInitialTheme();
    await loadEncryptedPassword();
    await dataBaseHelper.getDatabase;
    super.onInit();
  }

  Future<void> loadCurrentUser() async {
    currentUser.value = await storageHelper.getUser();
  }

  Future loadInitQuote() async {
    initialQuote.value = await dataBaseHelper.getinitialQuotes();
    return initialQuote.value ??
        Quote(
          quote: "The body achieves what the mind believes.",
          author: "Erin Gray",
        );
  }

  bool isUserLoggedIn() {
    return currentUser.value != null;
  }

  void logOut() async {
    await dataBaseHelper.deleteAllPassword();
    await storageHelper.removeUser();
    loadCurrentUser();
    // route to intro page
  }

  Rx<ThemeMode> themeMode = ThemeMode.light.obs;

  Future<void> loadInitialTheme() async {
    bool darkMode = await storageHelper.readTheme();
    log("dark mode: $darkMode");
    if (darkMode) {
      toggleThemeMode(ThemeMode.dark);
    } else {
      toggleThemeMode(ThemeMode.light);
    }
  }

  Future<void> loadEncryptedPassword() async {
    String? pass = await storageHelper.getEncryptedPassword();
    encryptedPassword = pass;
  }

  void toggleThemeMode(ThemeMode theme) {
    themeMode.value = theme;
    saveTheme(theme);
  }

  Future<void> saveTheme(ThemeMode mode) async {
    bool darkMode = (mode == ThemeMode.dark);
    await storageHelper.saveTheme(darkMode);
  }
}
