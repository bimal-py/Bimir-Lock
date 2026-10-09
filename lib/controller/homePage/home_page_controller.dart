import 'package:bimir_lock/models/password_table.dart';
import 'package:bimir_lock/utils/helper/db_helper.dart';
import 'package:bimir_lock/utils/helper/intruder_watch.dart';
import 'package:bimir_lock/utils/helper/vault_crypto.dart';
import 'package:bimir_lock/utils/helper/vault_health.dart';
import 'package:bimir_lock/utils/helper/vault_migration.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

enum VaultFilter { all, weak, reused }

class HomePageController extends GetxController with WidgetsBindingObserver {
  TextEditingController searchEditingController = TextEditingController();
  DataBaseHelper dbHelper = DataBaseHelper();
  RxList<PasswordTable>? passwords = RxList();

  final RxBool _isLoading = false.obs;

  /// True only for the very first read, so coming back to the app does not
  /// flash a spinner over a list that is already on screen.
  bool get loading => _isLoading.value && !_loadedOnce;
  bool _loadedOnce = false;

  /// Set when the vault could not be read. The existing list is NEVER cleared
  /// when this happens: showing "no passwords" to a user whose passwords are
  /// still on disk is what makes them clear app data, and that is what turns a
  /// transient problem into permanent loss.
  final RxnString vaultError = RxnString();
  Rx<VaultKeyHealth> get vaultHealth => VaultMigration.instance.health;
  Rxn<MigrationResult> get migrationResult =>
      VaultMigration.instance.lastResult;

  /// Weak and reused passwords, recomputed whenever the list changes.
  final Rx<VaultHealth> health = VaultHealth.empty.obs;
  final Rx<VaultFilter> filter = VaultFilter.all.obs;

  /// True once the list has scrolled under the pinned search bar.
  final RxBool listScrolled = false.obs;

  final RxString _searchedValue = "".obs;
  String get searchedValue => _searchedValue.value;

  bool _observerAdded = false;

  @override
  void onInit() {
    if (!_observerAdded) {
      WidgetsBinding.instance.addObserver(this);
      _observerAdded = true;
    }
    ever<List<PasswordTable>>(passwords!, (_) => _recount());
    loadPasswords();
    IntruderWatch.refresh();
    super.onInit();
  }

  // GetX calls onClose, not dispose, so the cleanup has to live here.
  @override
  void onClose() {
    if (_observerAdded) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAdded = false;
    }
    searchEditingController.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // A password may have been saved by the autofill service while we were away.
    if (state == AppLifecycleState.resumed) {
      loadPasswords();
      IntruderWatch.refresh();
    }
  }

  void _recount() {
    health.value = VaultHealth.of(passwords ?? const <PasswordTable>[]);
    // A filter with nothing left in it would show an empty list for no reason.
    if (filter.value == VaultFilter.weak && health.value.weak.isEmpty ||
        filter.value == VaultFilter.reused && health.value.reused.isEmpty) {
      filter.value = VaultFilter.all;
    }
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
      _loadedOnce = true;
      _isLoading.value = false;
    }
  }

  /// Re-probes the key after a transient failure and reloads.
  Future<void> retryVault() async {
    await VaultMigration.instance.retry();
    await loadPasswords();
  }

  /// In memory, so it filters as you type.
  void searchPassword(String value) {
    _searchedValue.value = value.toLowerCase().trim();
  }

  void clearSearch() {
    searchEditingController.clear();
    searchPassword('');
  }

  /// What the list shows: search and filter applied, sorted by title.
  List<PasswordTable> get visible {
    final String q = _searchedValue.value;
    final VaultHealth h = health.value;
    final Iterable<PasswordTable> rows = (passwords ?? <PasswordTable>[]).where(
      (e) {
        if (filter.value == VaultFilter.weak && !h.isWeak(e)) return false;
        if (filter.value == VaultFilter.reused && !h.isReused(e)) return false;
        if (q.isEmpty) return true;
        return (e.title ?? '').toLowerCase().contains(q) ||
            (e.userName ?? '').toLowerCase().contains(q);
      },
    );
    return rows.toList()..sort(
      (a, b) => (a.title ?? '').toLowerCase().compareTo(
        (b.title ?? '').toLowerCase(),
      ),
    );
  }

  Future<bool> deletePassword(PasswordTable passwordTable) async {
    final bool success = await dbHelper.deletePassword(passwordTable);
    if (success) passwords?.remove(passwordTable);
    return success;
  }

  Future<bool> editPassword(PasswordTable passwordTable) async {
    var success = await dbHelper.updatePassword(passwordTable);
    return success;
  }
}
