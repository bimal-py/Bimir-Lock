import 'package:flutter/material.dart';
import 'package:flutter_scale_kit/flutter_scale_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/common/widgets/text_field/app_text_field.dart';
import 'package:bimir_lock/core/utils/extensions/context_extension.dart';

/// Password variant of [AppTextField] with a show/hide toggle. Kept for the
/// auth flow that lands later (Supabase); local account-setup doesn't use it.
class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.textInputAction,
    this.validator,
    this.autovalidateMode,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      controller: widget.controller,
      hint: widget.hint,
      errorText: widget.errorText,
      focusNode: widget.focusNode,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      obscureText: _obscure,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      autofillHints: const [AutofillHints.password],
      suffix: IconButton(
        icon: Icon(
          _obscure ? LucideIcons.eye : LucideIcons.eyeOff,
          size: 20.r,
          color: context.colorScheme.onSurfaceVariant,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
