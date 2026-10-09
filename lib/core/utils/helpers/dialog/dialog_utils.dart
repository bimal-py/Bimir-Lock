import 'package:flutter/material.dart';
import 'package:bimir_lock/core/utils/helpers/dialog/app_dialog.dart';
import 'package:bimir_lock/core/utils/helpers/dialog/confirmation_dialog.dart';
import 'package:bimir_lock/core/utils/helpers/dialog/dialog_type.dart';
import 'package:bimir_lock/core/utils/helpers/dialog/input_dialog.dart';

class DialogUtils {
  const DialogUtils._();

  /// A single-field input dialog. Returns the entered text, or null if the
  /// user cancels / dismisses.
  static Future<String?> showInputDialog(
    BuildContext context, {
    required String title,
    String? message,
    String? initialValue,
    String? hintText,
    String confirmText = 'Save',
    String? cancelText,
    TextInputType? keyboardType,
    DialogType dialogType = DialogType.question,
    String? Function(String value)? validator,
    bool useRootNavigator = true,
  }) {
    return showDialog<String>(
      context: context,
      useRootNavigator: useRootNavigator,
      builder: (_) => CenterPopup(
        child: InputDialog(
        title: title,
        message: message,
        initialValue: initialValue,
        hintText: hintText,
        confirmText: confirmText,
        cancelText: cancelText,
        keyboardType: keyboardType,
        dialogType: dialogType,
        validator: validator,
        ),
      ),
    );
  }

  /// Yes/no prompt. True when confirmed; false when cancelled or dismissed.
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    String? cancelText,
    bool showCancelButton = true,
    DialogType dialogType = DialogType.question,
    IconData? icon,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator,
      builder: (_) => CenterPopup(
        child: ConfirmationDialog(
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          showCancelButton: showCancelButton,
          dialogType: dialogType,
          icon: icon,
        ),
      ),
    );
    return result ?? false;
  }

  /// A message with one button.
  static Future<void> showInformationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'OK',
    DialogType dialogType = DialogType.info,
    IconData? icon,
    bool useRootNavigator = true,
  }) {
    return showConfirmationDialog(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      showCancelButton: false,
      dialogType: dialogType,
      icon: icon,
      useRootNavigator: useRootNavigator,
    );
  }
}
