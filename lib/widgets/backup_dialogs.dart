import 'package:flutter/material.dart';

// Minimal on purpose: the app UI is being redesigned. The rules live here too,
// so a new design only has to call showBackupPasswordDialog().

const int minBackupPasswordLength = 10;

/// Asks for the backup password. With [confirm] (creating a backup) it asks
/// twice and explains that a forgotten password cannot be recovered. Returns
/// null when cancelled.
Future<String?> showBackupPasswordDialog(BuildContext context,
    {required bool confirm, String? error}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _BackupPasswordDialog(confirm: confirm, error: error),
  );
}

/// A non-dismissible "working..." dialog. Close it with Navigator.pop.
void showBackupProgress(BuildContext context, String message) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
                width: 24, height: 24, child: CircularProgressIndicator()),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
}

Future<void> showBackupMessage(
    BuildContext context, String title, String message) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text("Ok"),
        ),
      ],
    ),
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
      icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
      onPressed: () => setState(() => _hidden = !_hidden),
    );
    return AlertDialog(
      title: Text(widget.confirm ? "Backup password" : "Enter backup password"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.confirm)
                const Text(
                  "This password locks the backup file. You'll need it to restore on any phone.\n\n"
                  "If you forget it, the backup can't be opened by anyone, including you. "
                  "It is separate from your app PIN.",
                ),
              if (widget.error != null) ...[
                Text(widget.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _hidden,
                autofocus: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(labelText: "Backup password", suffixIcon: eye),
                validator: (value) {
                  final String v = value ?? '';
                  if (v.isEmpty) return "Enter a password";
                  if (widget.confirm && v.length < minBackupPasswordLength) {
                    return "Use at least $minBackupPasswordLength characters";
                  }
                  return null;
                },
                onFieldSubmitted: (_) => widget.confirm ? null : _submit(),
              ),
              if (widget.confirm)
                TextFormField(
                  controller: _repeat,
                  obscureText: _hidden,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: "Repeat password"),
                  validator: (value) =>
                      value == _password.text ? null : "Passwords don't match",
                  onFieldSubmitted: (_) => _submit(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(widget.confirm ? "Create backup" : "Restore"),
        ),
      ],
    );
  }
}
