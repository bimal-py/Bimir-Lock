import 'package:bimir_lock/core/utils/helpers/dialog/dialog.dart';
import 'package:bimir_lock/controller/homePage/home_page_controller.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/models/password_table.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/unlock.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:bimir_lock/utils/helper/vault_crypto.dart';
import 'package:bimir_lock/views/homePage/add_password.dart';
import 'package:bimir_lock/views/homePage/password_detail.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';

/// Actions on one saved entry, shared by the vault list and the detail page.
/// Anything that exposes or changes a password goes through [confirmIdentity].

String entryTitle(PasswordTable e) {
  final String t = (e.title ?? '').trim();
  return t.isEmpty ? 'Untitled' : t;
}

/// Enough of a username to tell accounts apart, not enough to read it off the
/// screen over someone's shoulder: "bi•••@gmail.com", "bim•••".
String maskUser(String? user) {
  final String u = (user ?? '').trim();
  if (u.isEmpty) return 'No username';
  final int at = u.indexOf('@');
  if (at > 0) {
    final String local = u.substring(0, at);
    return '${local.substring(0, local.length < 2 ? local.length : 2)}•••${u.substring(at)}';
  }
  return '${u.substring(0, u.length < 3 ? u.length : 3)}•••';
}

bool _writesBlocked() =>
    Get.find<HomePageController>().vaultHealth.value == VaultKeyHealth.keyLost;

Future<void> openEntry(BuildContext context, PasswordTable entry) async {
  final bool ok = await confirmIdentity(
    context,
    title: 'Open ${entryTitle(entry)}',
  );
  if (!ok) return;
  navigatorKey.currentState!.pushNamed(
    PasswordDetailPage.routeName,
    arguments: PasswordDetailPageArgument(passwordTable: entry, isEdit: false),
  );
}

/// [verified] when the caller has already confirmed identity (the detail
/// page). Returns the saved entry, or null when nothing changed.
Future<PasswordTable?> editEntry(
  BuildContext context,
  PasswordTable entry, {
  bool verified = false,
}) async {
  if (entry.locked || _writesBlocked()) {
    showNote("This entry can't be edited on this device.");
    return null;
  }
  if (!verified &&
      !await confirmIdentity(context, title: 'Edit ${entryTitle(entry)}')) {
    return null;
  }
  final Object? saved = await navigatorKey.currentState!.pushNamed(
    AddPasswordPage.routeName,
    arguments: EntryFormArgs(entry: entry),
  );
  return saved is PasswordTable ? saved : null;
}

/// Returns true when the entry was deleted.
Future<bool> deleteEntry(
  BuildContext context,
  PasswordTable entry, {
  bool verified = false,
}) async {
  final bool sure = await DialogUtils.showConfirmationDialog(
    context,
    title: 'Delete ${entryTitle(entry)}?',
    message:
        'The password is removed from this phone. This cannot be undone, unless it is in a backup file.',
    confirmText: 'Delete',
    dialogType: DialogType.danger,
  );
  if (!sure || !context.mounted) return false;
  if (!verified &&
      !await confirmIdentity(context, title: 'Delete ${entryTitle(entry)}')) {
    return false;
  }
  final bool done = await Get.find<HomePageController>().deletePassword(entry);
  showNote(done ? 'Deleted' : "Couldn't delete. Please try again.");
  return done;
}

Future<void> copyEntryPassword(
  BuildContext context,
  PasswordTable entry,
) async {
  if (entry.locked || (entry.password ?? '').isEmpty) {
    showNote('Nothing to copy');
    return;
  }
  if (!await confirmIdentity(
    context,
    title: 'Copy password',
    message: entryTitle(entry),
  )) {
    return;
  }
  await copyValue(entry.password!, what: 'Password', sensitive: true);
}

/// Long-press menu on a vault row.
Future<void> showEntryActions(BuildContext context, PasswordTable entry) {
  final BimirPalette p = BimirPalette.of(context);
  final TextTheme t = Theme.of(context).textTheme;
  final bool hasUser = (entry.userName ?? '').trim().isNotEmpty;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext sheet) {
      void run(Future<void> Function() action) {
        Navigator.pop(sheet);
        action();
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.xl,
                  0,
                  Space.xl,
                  Space.md,
                ),
                child: Row(
                  children: [
                    Monogram(entryTitle(entry)),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entryTitle(entry),
                            style: t.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(maskUser(entry.userName), style: t.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(LucideIcons.lockOpen),
                title: const Text('Open'),
                onTap: () => run(() => openEntry(context, entry)),
              ),
              if (hasUser)
                ListTile(
                  leading: const Icon(LucideIcons.user),
                  title: const Text('Copy username'),
                  onTap: () => run(
                    () => copyValue(entry.userName!.trim(), what: 'Username'),
                  ),
                ),
              ListTile(
                enabled: !entry.locked,
                leading: const Icon(LucideIcons.keyRound),
                title: const Text('Copy password'),
                onTap: () => run(() => copyEntryPassword(context, entry)),
              ),
              ListTile(
                enabled: !entry.locked && !_writesBlocked(),
                leading: const Icon(LucideIcons.pencil),
                title: const Text('Edit'),
                onTap: () => run(() async {
                  await editEntry(context, entry);
                }),
              ),
              ListTile(
                leading: Icon(LucideIcons.trash2, color: p.danger),
                title: Text('Delete', style: TextStyle(color: p.danger)),
                onTap: () => run(() async {
                  await deleteEntry(context, entry);
                }),
              ),
            ],
          ),
        ),
      );
    },
  );
}
