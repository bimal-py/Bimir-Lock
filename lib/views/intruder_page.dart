import 'dart:io';

import 'package:bimir_lock/core/utils/helpers/dialog/dialog.dart';
import 'package:bimir_lock/ui/photo_preview.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:bimir_lock/utils/helper/intruder_watch.dart';
import 'package:bimir_lock/utils/helper/pin_guard.dart';
import 'package:bimir_lock/utils/helper/app_permissions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Wrong-PIN alerts: the intruder photo switch, what a run of wrong PINs
/// does, and every time the keypad locked. Opened only after the PIN, so
/// whoever was guessing cannot delete their own photo.
class IntruderPage extends StatefulWidget {
  static const String routeName = '/intruders';
  const IntruderPage({super.key});

  @override
  State<IntruderPage> createState() => _IntruderPageState();
}

class _IntruderPageState extends State<IntruderPage>
    with WidgetsBindingObserver {
  bool? _photoOn;
  bool _checking = false;

  /// The photo is switched on, but the camera was refused or turned off in the
  /// phone's settings since: locks would be listed with no photo, silently.
  bool _cameraOff = false;
  List<IntruderEvent>? _events;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    IntruderWatch.markSeen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the phone's settings, where the camera may just have been
    // allowed (or taken away).
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final bool on = await IntruderWatch.isEnabled();
    final List<IntruderEvent> events = await IntruderWatch.events();
    if (!mounted) return;
    setState(() {
      _photoOn = on;
      _events = events;
    });
    // After the page has its content: asking the phone about the camera must
    // not hold up the switch and the list.
    final bool cameraOff = on && !await AppPermissions.cameraGranted();
    if (!mounted) return;
    setState(() => _cameraOff = cameraOff);
  }

  /// Asks again while the phone still will; otherwise offers its settings.
  Future<void> _allowCamera() async {
    await AppPermissions.camera(
      context,
      why: 'Wrong PIN alerts take the photo with the front camera.',
    );
    await _load();
  }

  Future<void> _toggle(bool on) async {
    if (!on) {
      await IntruderWatch.setEnabled(false);
      setState(() {
        _photoOn = false;
        _cameraOff = false;
      });
      return;
    }
    setState(() => _checking = true);
    // Asks for the camera now, while it is the owner holding the phone; after
    // a "never", offers Settings. Then opens it once to be sure there is one.
    final bool allowed = await AppPermissions.camera(
      context,
      why: 'Wrong PIN alerts take the photo with the front camera.',
    );
    final bool ok = allowed && await IntruderWatch.checkCamera();
    if (ok) await IntruderWatch.setEnabled(true);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _photoOn = ok;
      _cameraOff = false;
    });
    // A refusal was already explained (and Settings offered) by AppPermissions.
    if (allowed && !ok) {
      showNote("This phone's front camera can't be used right now.");
    }
  }

  Future<void> _delete(IntruderEvent e) async {
    await IntruderWatch.delete(e);
    await _load();
  }

  Future<void> _clearAll() async {
    final bool sure = await DialogUtils.showConfirmationDialog(
      context,
      title: 'Clear all alerts?',
      message: 'Every alert and photo here will be deleted.',
      confirmText: 'Clear all',
      dialogType: DialogType.danger,
    );
    if (!sure) return;
    await IntruderWatch.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final BimirPalette p = BimirPalette.of(context);
    final List<IntruderEvent>? events = _events;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wrong PIN alerts'),
        actions: [
          if (events != null && events.isNotEmpty)
            TextButton(onPressed: _clearAll, child: const Text('Clear all')),
          const SizedBox(width: Space.xs),
        ],
      ),
      body: PageBody(
        top: false,
        child: ListView(
          children: [
            const SizedBox(height: Space.sm),
            Panel(
              child: SwitchListTile(
                contentPadding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.xs,
                  Space.md,
                  Space.xs,
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: p.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    LucideIcons.camera,
                    size: 18,
                    color: p.onPrimarySoft,
                  ),
                ),
                title: const Text('Take a photo'),
                subtitle: Text(
                  'Each time wrong PINs lock the keypad, the front camera photographs whoever is typing. Photos stay on this phone.',
                ),
                value: _photoOn ?? false,
                onChanged: _photoOn == null || _checking ? null : _toggle,
              ),
            ),
            if (_cameraOff) ...[
              const SizedBox(height: Space.md),
              Notice(
                tone: Tone.warning,
                icon: LucideIcons.cameraOff,
                title: 'Camera access is off',
                message:
                    'Take a photo is on, but Bimir Lock is not allowed to use the camera, so locks are listed without a photo.',
                action: TextButton(
                  onPressed: _allowCamera,
                  child: const Text('Allow camera'),
                ),
              ),
            ],
            const SizedBox(height: Space.xl),
            const _Schedule(),
            const SizedBox(height: Space.xl),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xs,
                0,
                Space.xs,
                Space.sm,
              ),
              child: Eyebrow('Recent'),
            ),
            if (events == null)
              const Padding(
                padding: EdgeInsets.all(Space.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (events.isEmpty)
              Panel(
                padding: const EdgeInsets.all(Space.lg),
                child: Row(
                  children: [
                    Icon(LucideIcons.shieldCheck, color: p.primary),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Text(
                        'No one has been locked out. Alerts appear here if it happens.',
                        style: t.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )
            else
              RowGroup(
                children: [
                  for (final IntruderEvent e in events)
                    _EventRow(event: e, onDelete: () => _delete(e)),
                ],
              ),
            const SizedBox(height: Space.xxl),
          ],
        ),
      ),
    );
  }
}

/// What a run of wrong PINs does, in order.
class _Schedule extends StatelessWidget {
  const _Schedule();

  static String _span(Duration d) => d.inMinutes >= 1
      ? '${d.inMinutes} ${d.inMinutes == 1 ? 'minute' : 'minutes'}'
      : '${d.inSeconds} seconds';

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final BimirPalette p = BimirPalette.of(context);
    // Built from PinGuard.stages, so the screen can never disagree with the
    // keypad: "1–10  Locked for 30 seconds…", "11–17  Locked for 1 minute…".
    final List<(String, String)> steps = <(String, String)>[];
    int from = 1;
    for (int i = 0; i < PinGuard.stages.length; i++) {
      final PinStage stage = PinGuard.stages[i];
      final int to = from + stage.misses - 1;
      final bool last = i == PinGuard.stages.length - 1;
      final String when = i == 0
          ? 'The ${ordinal(to)} locks the keypad for ${_span(stage.lock)}. From the ${ordinal(PinGuard.attempts - PinGuard.warnFrom)}, it says how many tries are left.'
          : last
          ? 'Every ${stage.misses} more lock it for ${_span(stage.lock)}, for as long as it goes on.'
          : '${stage.misses} more lock it for ${_span(stage.lock)}.';
      steps.add((last ? '$from+' : '$from–$to', when));
      from = to + 1;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xs, 0, Space.xs, Space.sm),
          child: Eyebrow('Wrong PINs in a row'),
        ),
        Panel(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (String count, String effect) in steps) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        count,
                        style: BimirPalette.figure(
                          context,
                          size: 14,
                          color: p.primary,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: Text(effect, style: t.bodyMedium)),
                  ],
                ),
                const SizedBox(height: Space.md),
              ],
              Text(
                'After each lock the keypad says how many tries are left. Every lock is listed below, with a photo when Take a photo is on. Your correct PIN, fingerprint or face starts the count again; closing the app does not.',
                style: t.bodySmall?.copyWith(color: p.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EventRow extends StatefulWidget {
  const _EventRow({required this.event, required this.onDelete});

  final IntruderEvent event;
  final VoidCallback onDelete;

  @override
  State<_EventRow> createState() => _EventRowState();
}

class _EventRowState extends State<_EventRow> {
  /// The thumbnail, which the large photo grows out of and shrinks back into.
  final GlobalKey _thumb = GlobalKey();

  IntruderEvent get event => widget.event;
  VoidCallback get onDelete => widget.onDelete;

  static String _when(DateTime at) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(at.year, at.month, at.day);
    final String time = DateFormat.jm().format(at);
    if (day == today) return 'Today, $time';
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $time';
    }
    return '${DateFormat('d MMM y').format(at)}, $time';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final BimirPalette p = BimirPalette.of(context);
    return FutureBuilder<File?>(
      future: IntruderWatch.photoFile(event),
      builder: (BuildContext context, AsyncSnapshot<File?> snap) {
        final File? photo = snap.data;
        return InkWell(
          onTap: photo == null
              ? null
              : () => showPhotoPreview(
                  context,
                  file: photo,
                  name:
                      '${ordinal(event.attempt)} wrong PIN · ${_when(event.at)}',
                  from: _thumb.currentContext == null
                      ? null
                      : photoRect(_thumb.currentContext!),
                ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.lg,
              Space.md,
              Space.xs,
              Space.md,
            ),
            child: Row(
              children: [
                Container(
                  key: _thumb,
                  width: 56,
                  height: 56,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    borderRadius: BorderRadius.circular(Radii.control),
                  ),
                  child: photo == null
                      ? Icon(LucideIcons.cameraOff, size: 22, color: p.muted)
                      : Image.file(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            LucideIcons.imageOff,
                            size: 22,
                            color: p.muted,
                          ),
                        ),
                ),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ordinal(event.attempt)} wrong PIN in a row',
                        style: t.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        photo == null
                            ? '${_when(event.at)} · no photo'
                            : _when(event.at),
                        style: t.bodySmall?.copyWith(color: p.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: Icon(LucideIcons.trash2, size: 20, color: p.muted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 7 → "7th", 22 → "22nd".
String ordinal(int n) {
  final int lastTwo = n % 100;
  if (lastTwo >= 11 && lastTwo <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}
