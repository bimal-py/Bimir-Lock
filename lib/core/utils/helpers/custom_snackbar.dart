import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum ToastType { success, error, info }

/// Lightweight, context-free toast helper. Prefer this over
/// `ScaffoldMessenger.showSnackBar(...)` so messages render without needing a
/// Scaffold in scope and survive navigation between routes.
///
/// Use directly:
/// ```dart
/// CustomSnackbar.show(type: ToastType.success, message: 'Saved');
/// ```
/// Or via the [BuildContext] extensions: `context.showSuccessToast(...)`.
class CustomSnackbar {
  CustomSnackbar._();

  static Future<bool?> cancel() => Fluttertoast.cancel();

  static Future<bool?>? show({
    required ToastType type,
    required String message,
    Toast? toastLength,
    int timeInSecForIosWeb = 2,
    double fontSize = 14,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Color? backgroundColor,
    Color? textColor,
  }) async {
    backgroundColor ??= _backgroundFor(type);
    textColor ??= Colors.white;
    await Fluttertoast.cancel();
    return Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength ?? Toast.LENGTH_SHORT,
      timeInSecForIosWeb: timeInSecForIosWeb,
      fontSize: fontSize,
      gravity: gravity,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }

  static Color _backgroundFor(ToastType type) => switch (type) {
    ToastType.success => Colors.green.shade600,
    ToastType.error => Colors.red.shade600,
    ToastType.info => Colors.orange.shade700,
  };
}
