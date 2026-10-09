import 'package:flutter/material.dart';
import 'package:bimir_lock/core/core.dart';

/// Reminder Note's `showRewardedGate` without the ad: the same confirm dialog
/// (title, message, confirm/cancel labels, dialog type) and [onProceed] runs on
/// Confirm. Cancel or a barrier dismiss aborts quietly.
Future<void> showConfirmGate(
  BuildContext context, {
  required VoidCallback onProceed,
  required String title,
  required String message,
  String confirmText = 'Continue',
  String cancelText = 'Cancel',
  DialogType dialogType = DialogType.info,
}) async {
  final proceed = await DialogUtils.showConfirmationDialog(
    context,
    title: title,
    message: message,
    confirmText: confirmText,
    cancelText: cancelText,
    dialogType: dialogType,
  );
  if (!proceed) return; // Cancel / dismiss → abort quietly.
  if (!context.mounted) return;
  onProceed();
}
