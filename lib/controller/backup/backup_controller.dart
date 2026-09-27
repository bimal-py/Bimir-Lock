import 'dart:developer';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:bimir_lock/controller/homePage/home_page_controller.dart';
import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/models/password_table.dart';
import 'package:bimir_lock/utils/extensions.dart';
import 'package:bimir_lock/utils/helper/backup_crypto.dart';
import 'package:bimir_lock/utils/helper/db_helper.dart';
import 'package:bimir_lock/utils/helper/vault_crypto.dart';
import 'package:bimir_lock/utils/helper/vault_migration.dart';
import 'package:bimir_lock/widgets/backup_dialogs.dart';
import 'package:bimir_lock/widgets/pin_input_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

/// Back up to / restore from an encrypted file the user puts wherever they like
/// (Files, iCloud Drive, Google Drive, Downloads) through the system picker.
///
/// Restore only ever ADDS passwords. It never deletes or overwrites one, and an
/// entry whose title, username and password all match an existing one is skipped.
class BackupController {
  final DataBaseHelper _db = DataBaseHelper();
  bool _busy = false;

  BuildContext? get _context => navigatorKey.currentContext;

  // ---------------------------------------------------------------- back up

  Future<void> backUp() async {
    if (_busy) return;
    _busy = true;
    try {
      await _backUp();
    } catch (e) {
      log("backup failed: ${e.runtimeType}");
      _closeProgress();
      await _message("Backup failed", "Couldn't create the backup. Nothing was changed.");
    } finally {
      _busy = false;
    }
  }

  Future<void> _backUp() async {
    if (!await _vaultReadable()) return;

    final List<PasswordTable> rows =
        (await _db.getAllPassword()).where((PasswordTable r) => !r.locked).toList();
    if (rows.isEmpty) {
      _toast("There are no passwords to back up yet.");
      return;
    }
    // Exporting every password at once is the most sensitive thing the app does.
    if (!await _confirmPin()) return;

    final BuildContext? context = _context;
    if (context == null || !context.mounted) return;
    final String? password = await showBackupPasswordDialog(context, confirm: true);
    if (password == null) return;

    final List<BackupEntry> entries = rows
        .map((PasswordTable r) => BackupEntry(
              title: r.title ?? '',
              userName: r.userName ?? '',
              password: r.password ?? '',
            ))
        .toList();

    _showProgress("Encrypting your backup…");
    final Uint8List bytes = await _seal(entries, password);
    _closeProgress();

    final Uri? saved = await FilePicker.saveFile(
      fileName: "BimirLock-backup-${DateTime.now().formatDate()}.bimirbackup",
      bytes: bytes,
      mimeType: "application/octet-stream",
    );
    if (saved == null) {
      _toast("Backup not saved.");
      return;
    }
    await _message(
      "Backup saved",
      "${entries.length} ${entries.length == 1 ? "password" : "passwords"} backed up.\n\n"
          "Keep your backup password somewhere safe. Without it the file can't be opened.",
    );
  }

  // ---------------------------------------------------------------- restore

  Future<void> restore() async {
    if (_busy) return;
    _busy = true;
    try {
      await _restore();
    } catch (e) {
      log("restore failed: ${e.runtimeType}");
      _closeProgress();
      await _message("Restore failed", "Couldn't restore that backup.");
    } finally {
      _busy = false;
    }
  }

  Future<void> _restore() async {
    if (!await _vaultReadable()) return;

    final PlatformFile? file = await FilePicker.pickFile();
    if (file == null) return;

    final int? size = file.lengthSync() ?? await file.length();
    if (size != null && size > BackupCrypto.maxFileBytes) {
      await _message("Not a backup", "That file is too large to be a Bimir Lock backup.");
      return;
    }
    final Uint8List bytes = await file.readAsBytes();
    try {
      BackupCrypto.checkFormat(bytes);
    } on BackupFormatException catch (e) {
      await _message(
        "Can't restore",
        e.message == 'newer_version'
            ? "This backup was made by a newer version of Bimir Lock. Update the app, then try again."
            : "That file isn't a Bimir Lock backup.",
      );
      return;
    }

    List<BackupEntry>? entries;
    String? error;
    while (entries == null) {
      final BuildContext? context = _context;
      if (context == null || !context.mounted) return;
      final String? password =
          await showBackupPasswordDialog(context, confirm: false, error: error);
      if (password == null) return;
      _showProgress("Unlocking the backup…");
      try {
        entries = await _open(bytes, password);
      } on BackupAuthException {
        error = "Wrong backup password, or the file was changed.";
      } on BackupFormatException {
        _closeProgress();
        await _message("Can't restore", "That backup file is damaged.");
        return;
      }
      _closeProgress();
    }

    // Merge: never delete, never overwrite, skip exact duplicates (including
    // duplicates inside the backup itself).
    final Set<String> seen = (await _db.getAllPassword())
        .map((PasswordTable r) => BackupEntry(
              title: r.title ?? '',
              userName: r.userName ?? '',
              password: r.password ?? '',
            ).identity)
        .toSet();
    final List<PasswordTable> toAdd = <PasswordTable>[];
    int skipped = 0;
    for (final BackupEntry e in entries) {
      if (!seen.add(e.identity)) {
        skipped++;
        continue;
      }
      toAdd.add(PasswordTable(title: e.title, userName: e.userName, password: e.password));
    }

    int added = 0;
    String? partial;
    if (toAdd.isNotEmpty) {
      _showProgress("Restoring passwords…");
      try {
        added = await _db.insertPasswords(toAdd);
      } catch (e) {
        log("restore insert failed: ${e.runtimeType}");
        partial = "Some passwords couldn't be restored. Try the restore again: "
            "the ones already added will be skipped.";
      }
      _closeProgress();
    }
    // insertPasswords commits whole chunks, so on failure count what landed.
    if (partial != null) {
      final Set<String> now = (await _db.getAllPassword())
          .map((PasswordTable r) => BackupEntry(
                title: r.title ?? '',
                userName: r.userName ?? '',
                password: r.password ?? '',
              ).identity)
          .toSet();
      added = toAdd
          .where((PasswordTable r) => now.contains(BackupEntry(
                title: r.title ?? '',
                userName: r.userName ?? '',
                password: r.password ?? '',
              ).identity))
          .length;
    }

    if (Get.isRegistered<HomePageController>()) {
      await Get.find<HomePageController>().loadPasswords();
    }
    await _message(
      partial == null ? "Restore complete" : "Restore incomplete",
      "Added $added ${added == 1 ? "password" : "passwords"}."
          "${skipped > 0 ? "\nSkipped $skipped already in your vault." : ""}"
          "${partial != null ? "\n\n$partial" : ""}",
    );
  }

  // ---------------------------------------------------------------- helpers

  // Static, so the isolate closure captures only its arguments.
  static Future<Uint8List> _seal(List<BackupEntry> entries, String password) =>
      Isolate.run(() => BackupCrypto.seal(entries, password));

  static Future<List<BackupEntry>> _open(Uint8List bytes, String password) =>
      Isolate.run(() => BackupCrypto.open(bytes, password));

  Future<bool> _vaultReadable() async {
    if (VaultMigration.instance.health.value == VaultKeyHealth.ok) return true;
    await _message(
      "Not available right now",
      "Bimir Lock can't read your saved passwords on this device at the moment, "
          "so backup and restore are turned off. Your saved data has not been changed.",
    );
    return false;
  }

  Future<bool> _confirmPin() async {
    final CoreController cc = Get.find<CoreController>();
    if (cc.encryptedPassword == null) {
      _toast("Set an access PIN first.");
      return false;
    }
    final BuildContext? context = _context;
    if (context == null || !context.mounted) return false;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => PinInputMenuDialog(
        message: "Enter your access pin to back up all your passwords.",
        onConfirm: (pin) {
          if (cc.encryptedPassword == pin) {
            Navigator.pop(dialogContext, true);
          } else {
            _toast("invalid pin");
          }
        },
      ),
    );
    return ok ?? false;
  }

  bool _progressOpen = false;

  void _showProgress(String message) {
    final BuildContext? context = _context;
    if (context == null || _progressOpen) return;
    _progressOpen = true;
    showBackupProgress(context, message);
  }

  void _closeProgress() {
    if (!_progressOpen) return;
    _progressOpen = false;
    navigatorKey.currentState?.pop();
  }

  Future<void> _message(String title, String message) async {
    final BuildContext? context = _context;
    if (context == null || !context.mounted) return;
    await showBackupMessage(context, title, message);
  }

  void _toast(String msg) => Fluttertoast.showToast(
      msg: msg, backgroundColor: Colors.black, textColor: Colors.white);
}
