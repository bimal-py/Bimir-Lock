import 'package:bimir_lock/core/utils/helpers/dialog/dialog.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// The backup password rules live here, so every caller gets the same dialog.

const int minBackupPasswordLength = 10;

/// Asks for the backup password. With [confirm] (creating a backup) it asks
/// twice and explains that a forgotten password cannot be recovered. Returns
/// null when cancelled.
Future<String?> showBackupPasswordDialog(
  BuildContext context, {
  required bool confirm,
  String? error,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => CenterPopup(
      child: _BackupPasswordDialog(confirm: confirm, error: error),
    ),
  );
}

/// A non-dismissible "working..." dialog. Close it with Navigator.pop.
void showBackupProgress(BuildContext context, String message) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: CenterPopup(
        child: AppDialog(
          icon: Icons.lock_outline_rounded,
          accent: Theme.of(context).colorScheme.primary,
          title: message,
          body: const SizedBox(
            width: 140,
            child: LinearProgressIndicator(minHeight: 3),
          ),
        ),
      ),
    ),
  );
}

Future<void> showBackupMessage(
  BuildContext context,
  String title,
  String message, {
  DialogType type = DialogType.info,
}) {
  return DialogUtils.showInformationDialog(
    context,
    title: title,
    message: message,
    dialogType: type,
  );
}

class _BackupPasswordDialog extends StatefulWidget {
  const _BackupPasswordDialog({required this.confirm, this.error});

  final bool confirm;
  final String? error;

  @override
  State<_BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<_BackupPasswordDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _repeat = TextEditingController();
  bool _hidden = true;

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget eye = IconButton(
      icon: Icon(_hidden ? LucideIcons.eye : LucideIcons.eyeOff),
      onPressed: () => setState(() => _hidden = !_hidden),
    );
    return AppDialog(
      icon: Icons.key_rounded,
      accent: Theme.of(context).colorScheme.primary,
      title: widget.confirm ? "Backup password" : "Enter backup password",
      message: widget.confirm
          ? "This password locks the backup file. You'll need it to restore on any phone. It is separate from your app PIN."
          : null,
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.confirm) ...[
              const Notice(
                tone: Tone.warning,
                icon: LucideIcons.info,
                message:
                    "If you forget it, the backup can't be opened by anyone, including you.",
              ),
              const SizedBox(height: Space.lg),
            ],
            if (widget.error != null) ...[
              Text(
                widget.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: BimirPalette.of(context).danger),
              ),
              const SizedBox(height: Space.md),
            ],
            TextFormField(
              controller: _password,
              obscureText: _hidden,
              autofocus: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: "Backup password",
                suffixIcon: eye,
              ),
              validator: (value) {
                final String v = value ?? '';
                if (v.isEmpty) return "Enter a password";
                if (widget.confirm && v.length < minBackupPasswordLength) {
                  return "Use at least $minBackupPasswordLength characters";
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => widget.confirm ? null : _submit(),
            ),
            if (widget.confirm) ...[
              const SizedBox(height: Space.md),
              StrengthMeter(password: _password.text),
              const SizedBox(height: Space.lg),
              TextFormField(
                controller: _repeat,
                obscureText: _hidden,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: "Repeat password",
                ),
                validator: (value) =>
                    value == _password.text ? null : "Passwords don't match",
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ],
        ),
      ),
      actions: DialogActions(
        confirmText: widget.confirm ? "Create backup" : "Restore",
        onConfirm: _submit,
        cancelText: "Cancel",
      ),
    );
  }
}
