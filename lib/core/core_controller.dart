import 'dart:async';
import 'dart:io';

import 'package:bimir_lock/utils/helper/db_helper.dart';
import 'package:bimir_lock/utils/helper/storage_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/user_model.dart';

class CoreController extends GetxController {
  DataBaseHelper dataBaseHelper = DataBaseHelper();
  StorageHelper storageHelper = StorageHelper();
  Rx<User?> currentUser = Rxn<User>();
  String? encryptedPassword;

  final Completer<void> _ready = Completer<void>();

  /// Completes once the user, theme, PIN state and database are loaded. The
  /// launch screen waits on this instead of a fixed delay.
  Future<void> get ready => _ready.future;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      await loadCurrentUser();
      await loadInitialTheme();
      await loadEncryptedPassword();
      await dataBaseHelper.getDatabase;
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  // The profile photo resolved for THIS install. Widgets read this, never
  // userAvatar directly: the stored value is only a file name.
  Rxn<File> avatarFile = Rxn<File>();

  Future<void> loadCurrentUser() async {
    final User? user = await storageHelper.getUser();
    final String? stored = user?.userAvatar;
    if (user != null && stored != null && stored.contains('/')) {
      // One-time upgrade from the old absolute path. Harmless to repeat.
      user.userAvatar = StorageHelper.avatarFileName(stored);
      await storageHelper.setUser(user);
    }
    avatarFile.value = await storageHelper.resolveAvatar(user?.userAvatar);
    currentUser.value = user;
    update();
  }

  bool isUserLoggedIn() {
    return currentUser.value != null;
  }

  /// First word of the user's name, capitalised, or null.
  String? get firstName {
    final String name = currentUser.value?.userName?.trim() ?? '';
    if (name.isEmpty) return null;
    final String first = name.split(RegExp(r'\s+')).first;
    return first[0].toUpperCase() + first.substring(1);
  }

  void logOut() async {
    await dataBaseHelper.deleteAllPassword();
    await storageHelper.removeUser();
    loadCurrentUser();
    // route to intro page
  }

  /// Read in main() before the first frame, so a chosen dark theme does not
  /// flash light first. Light until one is chosen.
  static ThemeMode launchTheme = ThemeMode.light;

  static ThemeMode themeModeFrom(String stored) => switch (stored) {
    "dark" => ThemeMode.dark,
    "system" => ThemeMode.system,
    _ => ThemeMode.light,
  };

  Rx<ThemeMode> themeMode = launchTheme.obs;

  Future<void> loadInitialTheme() async {
    themeMode.value = themeModeFrom(await storageHelper.readThemeMode());
  }

  Future<void> loadEncryptedPassword() async {
    String? pass = await storageHelper.getEncryptedPassword();
    encryptedPassword = pass;
  }

  void toggleThemeMode(ThemeMode theme) {
    themeMode.value = theme;
    storageHelper.saveThemeMode(theme.name);
  }
}
