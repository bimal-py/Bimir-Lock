import 'package:flutter/material.dart';
import 'package:bimir_lock/core/core.dart';

/// Label-less, chrome-less text field for editor surfaces (note title /
/// description). The global `inputDecorationTheme` still paints a fill and
/// `enabled`/`focused` borders, so they're all nullified here explicitly —
/// `border: InputBorder.none` alone is not enough. The result is plain text on
/// the page with just a hint, sized by [style].
class AppPlainTextField extends StatelessWidget {
  const AppPlainTextField({
    super.key,
    required this.hint,
    this.controller,
    this.style,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.autofocus = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
    this.onChanged,
  });

  final String hint;
  final TextEditingController? controller;
  final TextStyle? style;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final effectiveStyle =
        style ?? context.textTheme.bodyMedium?.copyWith(color: colors.onSurface);
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType ?? TextInputType.multiline,
      textCapitalization: textCapitalization,
      maxLines: expands ? null : maxLines,
      minLines: expands ? null : minLines,
      expands: expands,
      textAlignVertical: TextAlignVertical.top,
      onChanged: onChanged,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: effectiveStyle,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: effectiveStyle?.copyWith(color: colors.onSurfaceVariant),
        filled: false,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
      ),
    );
  }
}
