import 'package:bimir_lock/controller/homePage/home_page_controller.dart';
import 'package:bimir_lock/utils/helper/vault_crypto.dart';
import 'package:bimir_lock/utils/helper/vault_migration.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    return Obx(() {
      final VaultKeyHealth health = controller.vaultHealth.value;
      final MigrationResult? result = controller.migrationResult.value;
      final String? readError = controller.vaultError.value;

      final List<Widget> banners = <Widget>[];
      Widget retry() => Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton(
          onPressed: controller.retryVault,
          child: const Text("Try again"),
        ),
      );

      if (health == VaultKeyHealth.keyLost) {
        banners.add(
          const Notice(
            tone: Tone.danger,
            icon: LucideIcons.lock,
            title: "Your passwords can't be unlocked on this device",
            message:
                "Your saved data has NOT been changed or deleted. Do not "
                "uninstall the app or clear its data - that would erase it "
                "permanently.",
          ),
        );
      } else if (health == VaultKeyHealth.unavailable || readError != null) {
        banners.add(
          Notice(
            tone: Tone.warning,
            icon: LucideIcons.hourglass,
            title: "Secure hardware not reachable",
            message:
                "Bimir Lock couldn't reach this device's secure hardware. Your "
                "saved passwords are unchanged; adding and editing are paused "
                "until it is available again. Do not uninstall the app or clear "
                "its data.",
            action: retry(),
          ),
        );
      }

      if (result != null && health != VaultKeyHealth.keyLost) {
        final int notSecured = result.failed + result.skippedBusy;
        if (notSecured > 0) {
          banners.add(
            Notice(
              tone: Tone.warning,
              icon: LucideIcons.shield,
              message:
                  "$notSecured of ${result.total} entries couldn't be "
                  "secured yet. They are unchanged and still readable.",
              action: retry(),
            ),
          );
        }
        if (result.damagedTitles.isNotEmpty) {
          banners.add(
            Notice(
              tone: Tone.danger,
              icon: LucideIcons.circleAlert,
              message:
                  "${result.damagedTitles.length} "
                  "${result.damagedTitles.length == 1 ? 'entry' : 'entries'} "
                  "can't be unlocked: ${result.damagedTitles.join(', ')}. "
                  "You'll need to reset those passwords with the provider.",
            ),
          );
        } else if (result.didWork && result.isClean) {
          banners.add(
            const Notice(
              tone: Tone.secure,
              icon: LucideIcons.shieldCheck,
              message:
                  "Your saved passwords are now encrypted with a key held in "
                  "this device's secure hardware. They cannot be recovered from "
                  "a backup.",
            ),
          );
        }
      }

      if (banners.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final Widget banner in banners)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: banner,
            ),
        ],
      );
    });
  }
}
