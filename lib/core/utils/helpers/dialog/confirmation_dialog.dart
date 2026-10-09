import 'package:flutter/material.dart';
import 'package:bimir_lock/core/utils/helpers/dialog/app_dialog.dart';
import 'package:bimir_lock/core/utils/helpers/dialog/dialog_type.dart';

/// A yes/no (or OK-only) prompt in the app's dialog look. Pops true when
/// confirmed, false when cancelled.
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText,
    this.showCancelButton = true,
    this.dialogType = DialogType.question,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmText;
  final String? cancelText;
  final bool showCancelButton;
  final DialogType dialogType;

  /// Overrides the type's icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      icon: icon ?? dialogType.icon,
      accent: dialogType.accentColor(context),
      title: title,
      message: message,
      actions: DialogActions(
        confirmText: confirmText,
        onConfirm: () => Navigator.of(context).pop(true),
        cancelText: showCancelButton ? (cancelText ?? 'Cancel') : null,
        onCancel: () => Navigator.of(context).pop(false),
        destructive: dialogType.destructive,
      ),
    );
  }
}
