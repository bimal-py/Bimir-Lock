import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/core/core.dart';

/// Label-less search input: a leading magnifier, a hint, and an optional
/// trailing control (e.g. a voice/mic button). Leans on the global
/// `inputDecorationTheme` for fill, radius, and focus states so it matches
/// every other field in the app. Generic on purpose — reused by any list that
/// needs a "search this list" bar (notes today, reminders later).
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hint = 'Search for ...',
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String hint;

  /// Optional trailing widget (a voice button, a clear button, …).
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: context.textTheme.bodyMedium?.copyWith(color: colors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(
          LucideIcons.search,
          size: 20.r,
          color: colors.onSurfaceVariant,
        ),
        suffixIcon: suffix,
      ),
    );
  }
}
