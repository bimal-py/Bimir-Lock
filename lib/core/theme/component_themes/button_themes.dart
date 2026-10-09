import 'package:flutter/material.dart';
import 'package:flutter_scale_kit/flutter_scale_kit.dart';

class ButtonThemes {
  ButtonThemes._();

  static ElevatedButtonThemeData elevated({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required BorderRadius radius,
  }) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: Size.fromHeight(48.h),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: textTheme.labelLarge,
      ),
    );
  }

  static FilledButtonThemeData filled({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required BorderRadius radius,
  }) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(48.h),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: textTheme.labelLarge,
      ),
    );
  }

  static OutlinedButtonThemeData outlined({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required BorderRadius radius,
  }) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(48.h),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: textTheme.labelLarge,
        side: BorderSide(color: colorScheme.outline),
      ),
    );
  }

  static TextButtonThemeData text({required TextTheme textTheme}) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
    );
  }
}
