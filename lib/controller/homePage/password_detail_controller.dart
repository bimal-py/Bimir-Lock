import 'package:bimir_lock/models/password_table.dart';
import 'package:bimir_lock/utils/helper/db_helper.dart';
import 'package:bimir_lock/utils/helper/vault_crypto.dart';
import 'package:bimir_lock/utils/helper/vault_migration.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PasswordDetailController extends GetxController {
  TextEditingController titleController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  DataBaseHelper dbHelper = DataBaseHelper();
  RxBool isEdit = false.obs;

  /// This row's stored value could not be opened. Its bytes must be left
  /// exactly as they are: no edit, no save, no copy.
  RxBool locked = false.obs;

  int? id;

  Rx<VaultKeyHealth> get vaultHealth => VaultMigration.instance.health;

  /// True when writing this row would either destroy an unreadable value or be
  /// impossible to encrypt. The whole detail page goes read only.
  bool get readOnly =>
      locked.value || vaultHealth.value == VaultKeyHealth.keyLost;

  void onEditTap() {
    if (readOnly) return;
    isEdit.value = true;
  }

  void onCancelTap() {
    isEdit.value = false;
  }

  Future<bool> onDeleteTap(PasswordTable passwordTable) async {
    var success = await dbHelper.deletePassword(passwordTable);
    return success;
  }

  Future<bool> onSaveTap() async {
    // Guard FIRST, before a PasswordTable is even built. A locked row's field
    // is deliberately empty on screen, and saving would replace the only copy
    // of the real value with "".
    if (readOnly) return false;

    PasswordTable passwordTable = PasswordTable(
      id: id,
      title: titleController.text,
      userName: userNameController.text,
      password: passwordController.text,
    );
    return dbHelper.updatePassword(passwordTable);
  }
}
