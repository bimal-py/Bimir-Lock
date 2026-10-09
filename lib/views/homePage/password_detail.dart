import 'dart:async';

import 'package:bimir_lock/controller/homePage/home_page_controller.dart';
import 'package:bimir_lock/models/password_table.dart';
import 'package:bimir_lock/ui/coach_marks.dart';
import 'package:bimir_lock/ui/password_tools.dart';
import 'package:bimir_lock/ui/secret.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:bimir_lock/utils/helper/vault_crypto.dart';
import 'package:bimir_lock/utils/helper/vault_health.dart';
import 'package:bimir_lock/views/homePage/entry_actions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide ContextExtensionss;
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PasswordDetailPageArgument {
  PasswordDetailPageArgument({
    required this.passwordTable,
    required this.isEdit,
  });
  final PasswordTable passwordTable;
  final bool isEdit;
}

/// One entry, after the PIN. The password starts hidden, shows with a tap,
/// and hides itself again after 30 seconds so it is not left on screen.
class PasswordDetailPage extends StatefulWidget {
  static const String routeName = "/passwordDetailPage";
  const PasswordDetailPage({super.key});

  @override
  State<PasswordDetailPage> createState() => _PasswordDetailPageState();
}

class _PasswordDetailPageState extends State<PasswordDetailPage>
    with WidgetsBindingObserver {
  static const Duration _showFor = Duration(seconds: 30);

  final HomePageController _home = Get.find<HomePageController>();
  PasswordTable? _entry;
  bool _revealed = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || (_entry?.locked ?? true)) return;
      CoachMarks.showOnce(
        context,
        tourId: CoachTours.entryDetail,
        steps: const [
          CoachStep(
            targetId: 'detail.fields',
            title: 'Unlocked',
            body:
                'Tap the password to show it; it hides again after 30 seconds. A copied password is wiped from the clipboard after 30 seconds too.',
          ),
        ],
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entry != null) return;
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    if (args is PasswordDetailPageArgument) _entry = args.passwordTable;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Leaving the app hides the password, so the app switcher's snapshot and
    // whoever picks the phone up next do not see it.
    if (state != AppLifecycleState.resumed && _revealed) _setRevealed(false);
  }

  void _setRevealed(bool on) {
    _hideTimer?.cancel();
    setState(() => _revealed = on);
    if (on) {
      _hideTimer = Timer(_showFor, () {
        if (mounted) _setRevealed(false);
      });
    }
  }

  Future<void> _edit() async {
    final PasswordTable? saved = await editEntry(
      context,
      _entry!,
      verified: true,
    );
    if (saved != null && mounted) {
      setState(() {
        _entry = saved;
        _revealed = false;
      });
    }
  }

  Future<void> _delete() async {
    if (await deleteEntry(context, _entry!, verified: true) && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final PasswordTable? e = _entry;
    if (e == null) return const Scaffold();
    final BimirPalette p = BimirPalette.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final bool locked = e.locked;
    final bool readOnly =
        locked || _home.vaultHealth.value == VaultKeyHealth.keyLost;
    final String password = e.password ?? '';
    final String user = (e.userName ?? '').trim();
    final String note = (e.note ?? '').trim();
    final VaultHealth health = _home.health.value;
    final int shared = health.sharedWith(e);
    final Strength strength = estimateStrength(password);

    final ColorScheme sc = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(),
      body: PageBody(
        top: false,
        child: ListView(
          children: [
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Monogram(entryTitle(e), size: 56),
                const SizedBox(width: Space.lg),
                Expanded(child: Text(entryTitle(e), style: t.headlineMedium)),
              ],
            ),
            const SizedBox(height: Space.xl),
            if (locked)
              const Notice(
                tone: Tone.danger,
                icon: LucideIcons.lock,
                title: "This entry can't be unlocked on this device",
                message:
                    "It has not been changed or deleted. You'll need to reset this password with the provider.",
              )
            else ...[
              CoachTarget(
                id: 'detail.fields',
                child: RowGroup(
                  children: [
                    _Field(
                      label: 'Username',
                      value: Text(
                        user.isEmpty ? 'None' : user,
                        style: t.bodyLarge?.copyWith(color: user.isEmpty ? p.muted : null),
                      ),
                      actions: [
                        if (user.isNotEmpty)
                          IconButton(
                            tooltip: 'Copy username',
                            icon: const Icon(LucideIcons.copy, size: 20),
                            onPressed: () => copyValue(user, what: 'Username'),
                          ),
                      ],
                    ),
                    _Field(
                      label: 'Password',
                      value: GestureDetector(
                        onTap: () => _setRevealed(!_revealed),
                        child: SecretText(value: password, revealed: _revealed, size: 17),
                      ),
                      actions: [
                        IconButton(
                          tooltip: _revealed ? 'Hide' : 'Show',
                          icon: Icon(_revealed ? LucideIcons.eyeOff : LucideIcons.eye, size: 20),
                          onPressed: () => _setRevealed(!_revealed),
                        ),
                        IconButton(
                          tooltip: 'Copy password',
                          icon: const Icon(LucideIcons.copy, size: 20),
                          onPressed: () => copyValue(password, what: 'Password', sensitive: true),
                        ),
                      ],
                    ),
                    if (e.noteLocked)
                      _Field(
                        label: 'Note',
                        value: Text(
                          "Can't be opened on this device",
                          style: t.bodyLarge?.copyWith(color: p.muted),
                        ),
                      )
                    else if (note.isNotEmpty)
                      _Field(
                        label: 'Note',
                        value: SelectableText(note, style: t.bodyLarge),
                        actions: [
                          IconButton(
                            tooltip: 'Copy note',
                            icon: const Icon(LucideIcons.copy, size: 20),
                            // Notes hold recovery codes: wiped like a password.
                            onPressed: () => copyValue(note, what: 'Note', sensitive: true),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Space.sm),
              AnimatedOpacity(
                opacity: _revealed ? 1 : 0,
                duration: Motion.base,
                child: Padding(
                  padding: const EdgeInsets.only(left: Space.xs),
                  child: Text('Hides again after 30 seconds.', style: t.bodySmall),
                ),
              ),
              const SizedBox(height: Space.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Strength', style: t.labelLarge?.copyWith(color: p.muted)),
                    const SizedBox(height: Space.sm),
                    StrengthMeter(password: password),
                  ],
                ),
              ),
              if (shared > 0) ...[
                const SizedBox(height: Space.lg),
                Notice(
                  tone: Tone.danger,
                  icon: LucideIcons.repeat2,
                  title: 'Used on ${shared + 1} sites',
                  message:
                      'If any one of them leaks, all of them are exposed. Give this account its own password.',
                ),
              ] else if (strength.segments <= 1) ...[
                const SizedBox(height: Space.lg),
                const Notice(
                  tone: Tone.warning,
                  icon: LucideIcons.triangleAlert,
                  title: 'Easy to guess',
                  message:
                      'Short, common or patterned passwords fall quickly. A generated one takes a second.',
                ),
              ],
            ],
            const SizedBox(height: Space.xl),
            Row(
              children: [
                if (!readOnly) ...[
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _edit,
                      icon: const Icon(LucideIcons.pencil, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: sc.error,
                      side: BorderSide(color: sc.error.withValues(alpha: 0.5)),
                    ),
                    icon: const Icon(LucideIcons.trash2, size: 18),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.xxl),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, this.actions = const []});

  final String label;
  final Widget value;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.xs, Space.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
                const SizedBox(height: 2),
                value,
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
