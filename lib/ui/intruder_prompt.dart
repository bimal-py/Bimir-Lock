import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/core/utils/helpers/dialog/dialog.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:bimir_lock/utils/helper/app_permissions.dart';
import 'package:bimir_lock/utils/helper/intruder_watch.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide ContextExtensionss;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offers the Wrong PIN alerts photo once, on the vault, so it can be on from
/// the start instead of waiting to be found in Settings. Shown after the quote
/// screen and before the vault's tips, only once a PIN exists (the photo is
/// taken when wrong PINs lock the keypad), and never again whatever is chosen.
/// People who already switched the photo on never see it.
class IntruderPrompt {
  IntruderPrompt._();

  static const String shownKey = 'intruder_prompt_shown';

  /// The vault calls this twice when it loads (read, then list); only one
  /// dialog may come of it.
  static bool _busy = false;

  /// A test that ends with the dialog still open never clears [_busy].
  @visibleForTesting
  static void debugReset() => _busy = false;

  static Future<void> maybeShow(BuildContext context) async {
    if (_busy) return;
    _busy = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(shownKey) ?? false) return;
      final String? pin = Get.isRegistered<CoreController>()
          ? Get.find<CoreController>().encryptedPassword
          : null;
      if (pin == null || pin.isEmpty) return;
      if (await IntruderWatch.isEnabled()) {
        await prefs.setBool(shownKey, true);
        return;
      }
      if (!context.mounted) return;
      final bool? photo = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const CenterPopup(child: _IntruderPromptDialog()),
      );
      await prefs.setBool(shownKey, true);
      if (!context.mounted) return;
      await _apply(context, photo ?? false);
    } finally {
      _busy = false;
    }
  }

  static Future<void> _apply(BuildContext context, bool photo) async {
    if (!photo) {
      await IntruderWatch.setEnabled(false);
      showNote(
        'You can turn it on any time in Settings › Security › Wrong PIN alerts.',
      );
      return;
    }
    // The camera is asked for now, with the owner holding the phone — never by
    // the keypad, in front of whoever is guessing.
    final bool allowed = await AppPermissions.camera(
      context,
      why: 'Wrong PIN alerts take the photo with the front camera.',
    );
    final bool ok = allowed && await IntruderWatch.checkCamera();
    await IntruderWatch.setEnabled(ok);
    showNote(
      ok
          ? 'Wrong PIN alerts will take a photo.'
          : 'The photo is off. Turn it on in Settings › Security › Wrong PIN alerts.',
    );
  }
}

class _IntruderPromptDialog extends StatefulWidget {
  const _IntruderPromptDialog();

  @override
  State<_IntruderPromptDialog> createState() => _IntruderPromptDialogState();
}

class _IntruderPromptDialogState extends State<_IntruderPromptDialog> {
  /// On to start with: that is the point of asking up front.
  bool _photo = true;

  @override
  Widget build(BuildContext context) {
    final ColorScheme s = Theme.of(context).colorScheme;
    final BimirPalette p = BimirPalette.of(context);
    return AppDialog(
      icon: LucideIcons.camera,
      accent: s.primary,
      title: 'See who tries to get in',
      message:
          'If someone keeps entering wrong PINs, the keypad locks, and Bimir Lock '
          'can photograph them with the front camera. Photos stay on this phone, '
          'and only you can open them.',
      body: Panel(
        child: SwitchListTile(
          contentPadding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.xs,
            Space.md,
            Space.xs,
          ),
          title: const Text('Take a photo'),
          subtitle: Text(
            _photo
                ? 'Bimir Lock will ask for the camera next'
                : 'Off. You can turn it on later in Settings',
            style: TextStyle(color: p.muted),
          ),
          value: _photo,
          onChanged: (bool v) => setState(() => _photo = v),
        ),
      ),
      actions: DialogActions(
        confirmText: 'Continue',
        onConfirm: () => Navigator.of(context).pop(_photo),
      ),
    );
  }
}
