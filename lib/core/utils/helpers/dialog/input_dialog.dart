import 'package:flutter/material.dart';
import 'package:bimir_lock/core/utils/helpers/dialog/app_dialog.dart';
import 'package:bimir_lock/core/utils/helpers/dialog/dialog_type.dart';

/// A single-field input dialog in the app's dialog look ([AppDialog]): the
/// type's icon, title, optional message, a text field, and an even
/// Cancel/Save button row. Pops the entered text on save, or null on cancel.
class InputDialog extends StatefulWidget {
  const InputDialog({
    super.key,
    required this.title,
    this.message,
    this.initialValue,
    this.hintText,
    this.confirmText = 'Save',
    this.cancelText,
    this.keyboardType,
    this.dialogType = DialogType.question,
    this.validator,
  });

  final String title;
  final String? message;
  final String? initialValue;
  final String? hintText;
  final String confirmText;
  final String? cancelText;
  final TextInputType? keyboardType;
  final DialogType dialogType;
  final String? Function(String value)? validator;

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text;
    final error = widget.validator?.call(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      icon: widget.dialogType.icon,
      accent: widget.dialogType.accentColor(context),
      title: widget.title,
      message: widget.message,
      body: TextField(
        controller: _controller,
        keyboardType: widget.keyboardType,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        decoration: InputDecoration(
          hintText: widget.hintText,
          errorText: _error,
        ),
      ),
      actions: DialogActions(
        confirmText: widget.confirmText,
        onConfirm: _submit,
        cancelText: widget.cancelText ?? 'Cancel',
      ),
    );
  }
}
