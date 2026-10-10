import 'dart:io' show Platform;

import 'package:bimir_lock/controller/autofill/autofill_controller.dart';
import 'package:bimir_lock/core/utils/helpers/dialog/dialog.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide ContextExtensionss;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How to switch on and use AutoFill: on iPhone and iPad the switch lives in
/// the phone's settings and nothing in the app would otherwise say so; on
/// Android it is the system's service picker.
///
/// True when "Turn on" was chosen (only offered while AutoFill is off).
Future<bool> showAutofillGuide(
  BuildContext context, {
  required bool enabled,
  bool? ios,
}) async {
  final bool? go = await showDialog<bool>(
    context: context,
    builder: (_) => CenterPopup(
      child: _AutofillGuide(enabled: enabled, ios: ios ?? Platform.isIOS),
    ),
  );
  return go ?? false;
}

/// Shows the guide, and when "Turn on" is chosen, takes the phone's shortest
/// way to switching AutoFill on. Used by the Settings notice and row, and by
/// the one-time prompt on the vault.
Future<void> offerAutofill(BuildContext context) async {
  final AutofillController ac = Get.find<AutofillController>();
  await ac.refreshStatus();
  if (!context.mounted) return;
  if (!await showAutofillGuide(context, enabled: ac.on)) return;
  await ac.turnOn();
  if (ac.on) showNote('AutoFill is on for Bimir Lock.');
}

/// Offers AutoFill once, on the vault, so it is not left for people to find in
/// Settings: shown before the Wrong PIN alerts prompt and the tips, only where
/// the phone supports it and it is still off, and never again whatever is
/// chosen. Settings keeps a notice for as long as it stays off.
class AutofillPrompt {
  AutofillPrompt._();

  static const String shownKey = 'autofill_prompt_shown';

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
      if (!Get.isRegistered<AutofillController>()) return;
      final AutofillController ac = Get.find<AutofillController>();
      await ac.refreshStatus();
      if (!ac.available) return;
      await prefs.setBool(shownKey, true);
      if (ac.on || !context.mounted) return;
      await offerAutofill(context);
    } finally {
      _busy = false;
    }
  }
}

class _AutofillGuide extends StatelessWidget {
  const _AutofillGuide({required this.enabled, required this.ios});

  final bool enabled;
  final bool ios;

  /// What to do, in order; the switching-on steps are left out once it is on.
  List<String> get _steps => ios
      ? <String>[
          if (!enabled) ...[
            "In the iPhone's Settings, open General › AutoFill & Passwords "
                '(iOS 17 and earlier: Passwords › Password Options).',
            'Turn on Bimir Lock.',
          ],
          'In a sign-in field, tap Passwords or the key above the keyboard '
              'and choose Bimir Lock.',
          'Confirm with Face ID, Touch ID or your passcode, then pick the '
              'account.',
        ]
      : <String>[
          if (!enabled) ...[
            'Tap Turn on, and choose Bimir Lock in the list your phone shows.',
          ],
          'In a sign-in form in another app, tap the field and pick your '
              'account from Bimir Lock.',
          'Confirm with your fingerprint, face or screen lock.',
          'Sign in somewhere new and Bimir Lock offers to save it.',
        ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme s = Theme.of(context).colorScheme;
    final TextTheme t = Theme.of(context).textTheme;
    return AppDialog(
      icon: LucideIcons.textCursorInput,
      accent: s.primary,
      title: enabled ? 'AutoFill is on' : 'Fill passwords with AutoFill',
      message: ios
          ? 'Bimir Lock can fill your saved passwords in Safari and other apps.'
          : 'Bimir Lock can fill your saved passwords in other apps and browsers, and offer to save new ones.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (int i, String step) in _steps.indexed) _Step(i + 1, step),
          if (ios) ...[
            const SizedBox(height: Space.sm),
            Text(
              'iPhone lets Bimir Lock fill passwords, not save new ones. Add '
              'new passwords here in the app.',
              style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
            ),
          ],
        ],
      ),
      actions: enabled
          ? DialogActions(
              confirmText: 'OK',
              onConfirm: () => Navigator.of(context).pop(false),
            )
          : DialogActions(
              confirmText: 'Turn on',
              cancelText: 'Not now',
              onConfirm: () => Navigator.of(context).pop(true),
              onCancel: () => Navigator.of(context).pop(false),
            ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.text);

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme s = Theme.of(context).colorScheme;
    final TextTheme t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: s.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: t.labelSmall?.copyWith(
                color: s.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(child: Text(text, style: t.bodyMedium)),
        ],
      ),
    );
  }
}
