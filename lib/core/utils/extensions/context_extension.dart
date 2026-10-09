import 'package:flutter/material.dart';
import 'package:bimir_lock/core/theme/extension/custom_theme_extension.dart';
import 'package:bimir_lock/core/utils/helpers/custom_snackbar.dart';

extension BuildContextExtension on BuildContext {
  ScaffoldState get scaffold => Scaffold.of(this);
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  CustomThemeExtension get customTheme =>
      Theme.of(this).extension<CustomThemeExtension>()!;

  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  void showInfoToast(String message) =>
      CustomSnackbar.show(type: ToastType.info, message: message);

  void showSuccessToast(String message) =>
      CustomSnackbar.show(type: ToastType.success, message: message);

  void showErrorToast(String message) =>
      CustomSnackbar.show(type: ToastType.error, message: message);
}
