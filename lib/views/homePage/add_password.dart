import 'package:bimir_lock/core/utils/helpers/dialog/dialog.dart';
import 'package:bimir_lock/controller/homePage/home_page_controller.dart';
import 'package:bimir_lock/models/password_table.dart';
import 'package:bimir_lock/ui/coach_marks.dart';
import 'package:bimir_lock/ui/password_tools.dart';
import 'package:bimir_lock/ui/secret.dart';
import 'package:bimir_lock/ui/site_field.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:bimir_lock/utils/helper/db_helper.dart';
import 'package:bimir_lock/utils/helper/site_book.dart';
import 'package:bimir_lock/utils/helper/vault_crypto.dart';
import 'package:bimir_lock/utils/validators.dart';
import 'package:bimir_lock/views/homePage/entry_actions.dart';
import 'package:bimir_lock/utils/helper/review_prompt.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';

class EntryFormArgs {
  const EntryFormArgs({this.entry});

  /// The entry being edited, or null for a new one.
  final PasswordTable? entry;
}

/// New entry, or editing one. The site field suggests names as you type, the
/// password field colours digits and symbols while visible, rates the
/// password as you type, warns when another entry already uses it, and can
/// generate one. A note is optional.
class AddPasswordPage extends StatefulWidget {
  static const String routeName = "/addPasswordPage";

  const AddPasswordPage({super.key});

  @override
  State<AddPasswordPage> createState() => _AddPasswordPageState();
}

class _AddPasswordPageState extends State<AddPasswordPage> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _user = TextEditingController();
  final SecretEditingController _password = SecretEditingController();
  final TextEditingController _note = TextEditingController();
  final HomePageController _home = Get.find<HomePageController>();

  PasswordTable? _editing;
  bool _hidden = true;
  bool _saving = false;
  bool _generator = false;
  double _length = 20;
  bool _digits = true;
  bool _symbols = true;
  bool _started = false;
  String _initial = '';
  List<Site> _sites = SiteBook.all();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    _editing = args is EntryFormArgs ? args.entry : null;
    if (_editing != null) {
      _title.text = _editing!.title ?? '';
      _user.text = _editing!.userName ?? '';
      _password.text = _editing!.password ?? '';
      _note.text = _editing!.note ?? '';
    }
    _initial = _snapshot;
    _loadSites();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CoachMarks.showOnce(
        context,
        tourId: CoachTours.entryForm,
        steps: const [
          CoachStep(
            targetId: 'form.generator',
            title: 'Let it make one',
            body:
                'A long random password from the phone\'s secure generator. Pick the length; it fills the field for you.',
          ),
        ],
      );
    });
  }

  Future<void> _loadSites() async {
    final List<String> learned = await SiteBook.learned();
    if (!mounted) return;
    setState(() {
      _sites = SiteBook.all(
        learned: learned,
        inVault: (_home.passwords ?? <PasswordTable>[]).map(
          (PasswordTable e) => e.title ?? '',
        ),
      );
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _user.dispose();
    _password.dispose();
    _note.dispose();
    super.dispose();
  }

  String get _snapshot =>
      '${_title.text}\u0000${_user.text}\u0000${_password.text}\u0000${_note.text}';
  bool get _dirty => _snapshot != _initial;

  void _generate() {
    setState(() {
      _password.text = generatePassword(
        length: _length.round(),
        digits: _digits,
        symbols: _symbols,
      );
      // You should see what was made for you.
      _hidden = false;
    });
  }

  /// Other entries that already use this password.
  List<String> _sharedWith(String pw) {
    if (pw.isEmpty) return const <String>[];
    return (_home.passwords ?? <PasswordTable>[])
        .where(
          (PasswordTable e) =>
              !e.locked &&
              e.password == pw &&
              (e.id == null || e.id != _editing?.id),
        )
        .map(entryTitle)
        .toList();
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final PasswordTable row = PasswordTable(
      id: _editing?.id,
      title: _title.text.trim(),
      userName: _user.text.trim(),
      password: _password.text,
      note: _note.text.trim().isEmpty ? null : _note.text,
      // An unreadable note is kept exactly as it is on disk.
      noteLocked: _editing?.noteLocked ?? false,
    );
    final DataBaseHelper db = DataBaseHelper();
    try {
      if (_editing == null) {
        await db.insertPassword(row);
      } else if (!await db.updatePassword(row)) {
        throw StateError('not updated');
      }
    } on VaultKeyUnavailable catch (_) {
      // Nothing was written: better a save the user can retry than a
      // password stored in a form we cannot read back.
      if (mounted) setState(() => _saving = false);
      showNote(
        "Couldn't secure this password on this device. Nothing was saved. Please try again.",
      );
      return;
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      showNote("Couldn't save this password. Please try again.");
      return;
    }
    // A name the suggestions did not know is offered next time.
    await SiteBook.learn(row.title ?? '');
    await _home.loadPasswords();
    if (!mounted) return;
    showNote(_editing == null ? 'Saved' : 'Changes saved');
    _initial = _snapshot;
    Navigator.of(context).pop(row);
    // A good moment for the store's rating sheet, if its rules allow (5 opens,
    // 3 days, 120 days between asks, once a version). Shown over the vault.
    ReviewPrompt.afterSuccess();
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    return DialogUtils.showConfirmationDialog(
      context,
      title: 'Discard changes?',
      message: 'What you typed here will not be saved.',
      confirmText: 'Discard',
      cancelText: 'Keep editing',
      dialogType: DialogType.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    final BimirPalette p = BimirPalette.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final bool editing = _editing != null;

    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (bool didPop, Object? _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          _initial = _snapshot;
          Navigator.of(context).pop();
        }
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(editing ? 'Edit password' : 'Add password'),
          ),
          body: PageBody(
            top: false,
            maxWidth: Space.maxNarrow + Space.gutter * 2,
            child: Form(
              key: _form,
              onChanged: () => setState(() {}),
              child: ListView(
                children: [
                  const SizedBox(height: Space.sm),
                  SiteNameField(
                    controller: _title,
                    sites: _sites,
                    autofocus: !editing,
                    validator: Validators.checkFieldEmpty,
                  ),
                  const SizedBox(height: Space.lg),
                  TextFormField(
                    controller: _user,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      // "Network name" for Wi-Fi, "Mobile number or ID" for
                      // a wallet, and so on.
                      labelText:
                          SiteBook.find(_title.text)?.kind.userLabel ??
                          'Username or email',
                    ),
                    validator: Validators.checkFieldEmpty,
                  ),
                  const SizedBox(height: Space.lg),
                  TextFormField(
                    controller: _password,
                    obscureText: _hidden,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    style: BimirPalette.secret(context, size: 16),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        tooltip: _hidden ? 'Show' : 'Hide',
                        icon: Icon(
                          _hidden
                              ? LucideIcons.eye
                              : LucideIcons.eyeOff,
                        ),
                        onPressed: () => setState(() => _hidden = !_hidden),
                      ),
                    ),
                    validator: Validators.checkPasswordField,
                  ),
                  const SizedBox(height: Space.md),
                  StrengthMeter(password: _password.text),
                  Builder(
                    builder: (BuildContext context) {
                      final List<String> shared = _sharedWith(_password.text);
                      if (shared.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: Space.md),
                        child: Notice(
                          tone: Tone.warning,
                          icon: LucideIcons.repeat2,
                          message:
                              'Also used for ${_list(shared)}. '
                              'If one of those leaks, this one is exposed too.',
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: Space.lg),
                  CoachTarget(
                    id: 'form.generator',
                    child: _GeneratorPanel(
                      open: _generator,
                      length: _length,
                      digits: _digits,
                      symbols: _symbols,
                      onToggle: () {
                        setState(() => _generator = !_generator);
                        if (_generator) _generate();
                      },
                      onLength: (double v) {
                        _length = v;
                        _generate();
                      },
                      onDigits: (bool v) {
                        _digits = v;
                        _generate();
                      },
                      onSymbols: (bool v) {
                        _symbols = v;
                        _generate();
                      },
                      onAgain: _generate,
                    ),
                  ),
                  const SizedBox(height: Space.lg),
                  TextFormField(
                    controller: _note,
                    enabled: !(_editing?.noteLocked ?? false),
                    minLines: 3,
                    maxLines: 6,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    // Notes hold recovery codes and security answers: keep
                    // them out of the keyboard's learned words.
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Note (optional)',
                      hintText: 'Recovery codes, security questions, PIN hints…',
                      alignLabelWithHint: true,
                      helperText: (_editing?.noteLocked ?? false)
                          ? "This entry's note can't be opened on this device. It is kept as it is."
                          : null,
                      helperMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: Space.xxl),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(editing ? 'Save changes' : 'Save password'),
                  ),
                  const SizedBox(height: Space.md),
                  Text(
                    'Encrypted before it is written to this phone.',
                    style: t.bodySmall?.copyWith(color: p.muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Space.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _list(List<String> names) {
    if (names.length == 1) return names.first;
    if (names.length == 2) return '${names[0]} and ${names[1]}';
    return '${names[0]}, ${names[1]} and ${names.length - 2} more';
  }
}

class _GeneratorPanel extends StatelessWidget {
  const _GeneratorPanel({
    required this.open,
    required this.length,
    required this.digits,
    required this.symbols,
    required this.onToggle,
    required this.onLength,
    required this.onDigits,
    required this.onSymbols,
    required this.onAgain,
  });

  final bool open;
  final double length;
  final bool digits;
  final bool symbols;
  final VoidCallback onToggle;
  final ValueChanged<double> onLength;
  final ValueChanged<bool> onDigits;
  final ValueChanged<bool> onSymbols;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final BimirPalette p = BimirPalette.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    return Panel(
      borderColor: open ? p.borderStrong : p.border,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Row(
                children: [
                  Icon(LucideIcons.wandSparkles, color: p.primary),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Generate a password', style: t.titleSmall),
                        Text(
                          'Random, from this phone\'s secure generator',
                          style: t.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: Motion.base,
                    child: Icon(LucideIcons.chevronDown, color: p.muted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: Motion.reduced(context) ? Duration.zero : Motion.base,
            curve: Motion.curve,
            alignment: Alignment.topCenter,
            child: !open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.lg,
                      0,
                      Space.lg,
                      Space.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: Space.md),
                        Row(
                          children: [
                            Text('Length', style: t.bodyMedium),
                            const Spacer(),
                            Text(
                              '${length.round()}',
                              style: BimirPalette.figure(
                                context,
                                size: 15,
                                color: p.foreground,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: length,
                          min: 8,
                          max: 64,
                          divisions: 56,
                          label: '${length.round()}',
                          semanticFormatterCallback: (double v) =>
                              '${v.round()} characters',
                          onChanged: onLength,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Numbers'),
                          value: digits,
                          onChanged: onDigits,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Symbols'),
                          value: symbols,
                          onChanged: onSymbols,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: onAgain,
                            icon: const Icon(LucideIcons.refreshCw, size: 18),
                            label: const Text('Another one'),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
