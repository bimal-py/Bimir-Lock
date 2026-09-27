import 'dart:async';

import 'package:bimir_lock/models/password_table.dart';
import 'package:bimir_lock/utils/helper/db_helper.dart';
import 'package:bimir_lock/utils/helper/vault_crypto.dart';
import 'package:bimir_lock/utils/helper/vault_migration.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

class HomePageController extends GetxController with WidgetsBindingObserver {
  TextEditingController searchEditingController = TextEditingController();
  DataBaseHelper dbHelper = DataBaseHelper();
  RxList<PasswordTable>? passwords = RxList();
  RxList<PasswordTable> searchedPasswords = RxList();

  final RxBool _isLoading = false.obs;
  bool get loading => _isLoading.value;

  /// Set when the vault could not be read. The existing list is NEVER cleared
  /// when this happens: showing "no passwords" to a user whose passwords are
  /// still on disk is what makes them clear app data, and that is what turns a
  /// transient problem into permanent loss.
  final RxnString vaultError = RxnString();
  Rx<VaultKeyHealth> get vaultHealth => VaultMigration.instance.health;
  Rxn<MigrationResult> get migrationResult => VaultMigration.instance.lastResult;

  Timer? debounce;
  final RxString _searchedValue = "".obs;
  String get searchedValue => _searchedValue.value;

  bool _observerAdded = false;

  @override
  void onInit() {
    if (!_observerAdded) {
      WidgetsBinding.instance.addObserver(this);
      _observerAdded = true;
    }
    loadPasswords();
    super.onInit();
  }

  // GetX calls onClose, not dispose, so the cleanup has to live here.
  @override
  void onClose() {
    if (_observerAdded) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAdded = false;
    }
    debounce?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // A password may have been saved by the autofill service while we were away.
    if (state == AppLifecycleState.resumed) {
      loadPasswords();
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  Future loadPasswords() async {
    _isLoading.value = true;
    try {
      passwords?.value = await dbHelper.getAllPassword();
      vaultError.value = null;
    } on VaultKeyUnavailable catch (e) {
      // Fail closed and stay honest: keep whatever is already on screen and
      // say what happened. Never replace it with an empty list.
      vaultError.value = e.code;
    } catch (e) {
      vaultError.value = e.runtimeType.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  /// Re-probes the key after a transient failure and reloads.
  Future<void> retryVault() async {
    await VaultMigration.instance.retry();
    await loadPasswords();
  }

  void searchPassword(String value) {
    _isLoading.value = true;
    _searchedValue.value = value.toLowerCase();
    if (debounce?.isActive ?? false) debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () {
      //after 0.5 s
      //search password by email/ link name
      if (_searchedValue.value.isEmpty) {
        loadPasswords();
        searchedPasswords.value = [];
      } else {
        searchedPasswords.value = [];
        List<PasswordTable> allSearchedPasswords = [];
        if (passwords != null) {
          for (PasswordTable each in passwords!) {
            // if (each.email != null &&
            //     each.email!.toLowerCase().trim().contains(_searchedValue.value)) {
            //   // searchedPasswords.add(each);
            //   allSearchedPasswords.add(each);
            // }
            if (each.userName != null &&
                each.userName!
                    .toLowerCase()
                    .trim()
                    .contains(_searchedValue.value)) {
              // searchedPasswords.add(each);
              allSearchedPasswords.add(each);
            }
            if (each.title != null &&
                each.title!
                    .toLowerCase()
                    .trim()
                    .contains(_searchedValue.value)) {
              // searchedPasswords.add(each);
              allSearchedPasswords.add(each);
            }
          }
        }
        searchedPasswords.value = allSearchedPasswords.toSet().toList();
        _isLoading.value = false;
      }
    });
  }

  Future<bool> deletePassword(PasswordTable passwordTable) async {
    var success = await dbHelper.deletePassword(passwordTable);
    return success;
    // if (success) {
    //   Fluttertoast.showToast(msg: "Password deleted successfully");
    // } else {
    //   Fluttertoast.showToast(msg: "Error encountered while deleting password");
    // }
  }

  Future<bool> editPassword(PasswordTable passwordTable) async {
    var success = await dbHelper.updatePassword(passwordTable);
    return success;
  }
}
