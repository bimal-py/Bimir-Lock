import 'package:bimir_lock/controller/homePage/home_page_controller.dart';
import 'package:bimir_lock/utils/helper/vault_crypto.dart';
import 'package:bimir_lock/utils/helper/vault_migration.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The user facing half of the vault's health.
///
/// Every state here is informational: the migration is mandatory and there is
/// deliberately no dialog the user can decline, because a decline would just
/// create a permanently mixed state population.
///
/// Nothing in this widget ever shows a password, an envelope or key material.
/// Titles are not encrypted, so a damaged entry can be named - that is the
/// whole point of naming it.
class VaultStatusBanner extends StatelessWidget {
  const VaultStatusBanner({super.key, required this.controller});

  final HomePageController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Obx(() {
      final VaultKeyHealth health = controller.vaultHealth.value;
      final MigrationResult? result = controller.migrationResult.value;
      final String? readError = controller.vaultError.value;

      final List<Widget> banners = <Widget>[];

      if (health == VaultKeyHealth.keyLost) {
        banners.add(_Banner(
          theme: theme,
          background: theme.colorScheme.errorContainer,
          foreground: theme.colorScheme.onErrorContainer,
          icon: Icons.lock_outline,
          message:
              "Bimir Lock can't unlock your saved passwords on this device. "
              "Your saved data has NOT been changed or deleted. Do not "
              "uninstall the app or clear its data - that would erase it "
              "permanently.",
        ));
      } else if (health == VaultKeyHealth.unavailable || readError != null) {
        banners.add(_Banner(
          theme: theme,
          background: theme.colorScheme.secondaryContainer,
          foreground: theme.colorScheme.onSecondaryContainer,
          icon: Icons.hourglass_empty,
          message:
              "Bimir Lock couldn't reach this device's secure hardware. Your "
              "saved passwords are unchanged; adding and editing are paused "
              "until it is available again.",
          onRetry: controller.retryVault,
        ));
      }

      if (result != null && health != VaultKeyHealth.keyLost) {
        final int notSecured = result.failed + result.skippedBusy;
        if (notSecured > 0) {
          banners.add(_Banner(
            theme: theme,
            background: theme.colorScheme.secondaryContainer,
            foreground: theme.colorScheme.onSecondaryContainer,
            icon: Icons.shield_outlined,
            message: "$notSecured of ${result.total} entries couldn't be "
                "secured yet. They are unchanged and still readable.",
            onRetry: controller.retryVault,
          ));
        }
        if (result.damagedTitles.isNotEmpty) {
          banners.add(_Banner(
            theme: theme,
            background: theme.colorScheme.errorContainer,
            foreground: theme.colorScheme.onErrorContainer,
            icon: Icons.report_gmailerrorred_outlined,
            message: "${result.damagedTitles.length} "
                "${result.damagedTitles.length == 1 ? 'entry' : 'entries'} "
                "can't be unlocked: ${result.damagedTitles.join(', ')}. "
                "You'll need to reset those passwords with the provider.",
          ));
        } else if (result.didWork && result.isClean) {
          banners.add(_Banner(
            theme: theme,
            background: theme.colorScheme.surfaceContainerHighest,
            foreground: theme.colorScheme.onSurface,
            icon: Icons.verified_user_outlined,
            message:
                "Your saved passwords are now encrypted with a key held in "
                "this device's secure hardware. They cannot be recovered from "
                "a backup.",
          ));
        }
      }

      if (banners.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final Widget banner in banners)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: banner,
            ),
        ],
      );
    });
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.theme,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final ThemeData theme;
  final Color background;
  final Color foreground;
  final IconData icon;
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  message,
                  style: TextStyle(color: foreground, fontSize: 13),
                ),
                if (onRetry != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        onRetry!();
                      },
                      child: Text(
                        "Retry",
                        style: TextStyle(color: foreground),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
