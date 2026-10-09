import 'package:bimir_lock/controller/biometric/biometric_controller.dart';
import 'package:bimir_lock/core/utils/helpers/dialog/dialog.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:bimir_lock/utils/helper/app_reset.dart';
import 'package:bimir_lock/utils/helper/biometric_helper.dart';
import 'package:bimir_lock/utils/helper/pin_guard.dart';
import 'package:bimir_lock/views/pin/set_access_pin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Forgot PIN?". A new PIN goes only to someone who can already open the
/// vault without the PIN: the fingerprint or face enrolled for fingerprint /
/// Face ID unlock. Never the phone's own passcode — anyone who knows that
/// (family, a partner) could then reset the PIN and open every password,
/// which is exactly what the app PIN is there to stop.
///
/// With that unlock off, there is no safe way to prove it is the owner, so
/// the only way back in is to erase the app and restore from a backup file.
Future<void> forgotPin(BuildContext context) async {
  final BiometricController bc = Get.find<BiometricController>();
  await bc.refreshStatus();
  if (!context.mounted) return;
  final String how = bc.label.value;

  if (bc.canUse) {
    final bool go = await DialogUtils.showConfirmationDialog(
      context,
      title: 'Forgot your PIN?',
      message:
          'Confirm it is you with $how, then choose a new PIN. Your saved passwords stay as they are.',
      confirmText: 'Use $how',
      icon: Icons.lock_reset_rounded,
    );
    if (!go || !context.mounted) return;
    final BiometricOutcome outcome = await bc.helper.authenticate(
      'Reset your Bimir Lock PIN',
    );
    if (outcome != BiometricOutcome.success) {
      if (outcome != BiometricOutcome.canceled) {
        showNote("Couldn't confirm it is you. Please try again.");
      }
      return;
    }
    // Proven with the same thing that unlocks the vault, so the wrong-PIN
    // lock (if any) is lifted too.
    await PinGuard.recordSuccess();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PinSetupView(changing: false, resetting: true),
      ),
    );
    return;
  }

  final bool erase = await DialogUtils.showConfirmationDialog(
    context,
    title: "Your PIN can't be reset",
    message:
        "Only $how unlock can prove it is you, and it is off. Without your PIN, the way back in is to erase Bimir Lock on this phone, set it up again, and restore your passwords from a backup file.\n\nWhile you know your PIN, turn on $how unlock in Settings so this never happens.",
    confirmText: 'Erase and start again',
    cancelText: 'Not now',
    dialogType: DialogType.danger,
    icon: Icons.lock_reset_rounded,
  );
  if (!erase || !context.mounted) return;
  final bool sure = await DialogUtils.showConfirmationDialog(
    context,
    title: 'Erase everything?',
    message:
        'Every password, note and setting on this phone is deleted. Only a backup file can bring them back.',
    confirmText: 'Erase',
    dialogType: DialogType.danger,
  );
  if (!sure) return;
  if (!await AppReset.wipeAndRestart()) {
    showNote("Couldn't erase everything. Please try again.");
  }
}
