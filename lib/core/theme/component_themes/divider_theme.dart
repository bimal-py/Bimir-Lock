import 'package:flutter/material.dart';

class DividerThemeBuilder {
  DividerThemeBuilder._();

  static DividerThemeData build({required ColorScheme colorScheme}) {
    return DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    );
  }
}
