import 'dart:async';
import 'dart:math' as math;

import 'package:bimir_lock/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// First-time tips: a short tour per screen that dims everything except the
/// thing being explained, shown the first time someone reaches that screen
/// and never again, until they ask for the tips back in Settings.
/// (Ported from the Callbreak Tracker app's coach marks.)

/// Every tour, by the name its "seen" flag is kept under. In one place so no
/// two screens can share a flag.
abstract final class CoachTours {
  /// The vault's list tips (Checkup, rows, search, Add). Kept under the
  /// original id, so whoever saw the old all-in-one tour is not shown them
  /// again.
  static const String vault = 'vault';

  /// The vault's always-there tips (Notes, Settings, the first Add), shown on
  /// the very first visit even when there is nothing saved yet.
  static const String vaultBasics = 'vault_basics';
  static const String entryForm = 'entry_form';
  static const String entryDetail = 'entry_detail';
  static const String settings = 'settings';

  static const List<String> all = <String>[
    vault,
    vaultBasics,
    entryForm,
    entryDetail,
    settings,
  ];
}

/// Marks a widget a tip can point at. Found by [id], so the screen running a
/// tour does not have to thread keys down to buttons it does not build.
class CoachTarget extends StatefulWidget {
  const CoachTarget({required this.id, required this.child, super.key});

  final String id;
  final Widget child;

  @override
  State<CoachTarget> createState() => _CoachTargetState();
}

class _CoachTargetState extends State<CoachTarget> {
  @override
  void initState() {
    super.initState();
    CoachMarks._targets[widget.id] = this;
  }

  @override
  void didUpdateWidget(covariant CoachTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _forget(oldWidget.id);
      CoachMarks._targets[widget.id] = this;
    }
  }

  @override
  void dispose() {
    _forget(widget.id);
    super.dispose();
  }

  void _forget(String id) {
    if (identical(CoachMarks._targets[id], this)) {
      CoachMarks._targets.remove(id);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// One tip: what it points at, and what it says.
class CoachStep {
  const CoachStep({
    required this.targetId,
    required this.title,
    required this.body,
    this.circle = false,
  });

  final String targetId;
  final String title;
  final String body;

  /// A round hole rather than a box, for icon buttons and avatars.
  final bool circle;
}

/// Remembers which tours have been shown.
abstract class CoachMarkStore {
  Future<bool> hasSeen(String tourId);
  Future<void> markSeen(String tourId);
  Future<void> reset();
}

class PrefsCoachMarkStore implements CoachMarkStore {
  const PrefsCoachMarkStore();

  static const String _prefix = 'coach_seen_';

  @override
  Future<bool> hasSeen(String tourId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_prefix$tourId') ?? false;
    } catch (_) {
      // Storage not reachable: a tour that could not be remembered would show
      // every time, so show none.
      return true;
    }
  }

  @override
  Future<void> markSeen(String tourId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefix$tourId', true);
    } catch (_) {}
  }

  @override
  Future<void> reset() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    for (final String id in CoachTours.all) {
      await prefs.remove('$_prefix$id');
    }
  }
}

class CoachMarks {
  const CoachMarks._();

  static final Map<String, _CoachTargetState> _targets =
      <String, _CoachTargetState>{};
  static bool _showing = false;

  /// Swapped out by tests.
  static CoachMarkStore store = const PrefsCoachMarkStore();

  static Future<void> resetAll() => store.reset();

  /// For tests, which tear an app down with a tour still open.
  @visibleForTesting
  static void debugReset() {
    _showing = false;
    _targets.clear();
  }

  /// Shows [steps] the first time someone reaches [tourId]. Steps whose
  /// target is not on screen are left out. Waits [delay] for the screen's own
  /// entrance, and only goes ahead if that screen is still in front.
  static Future<void> showOnce(
    BuildContext context, {
    required String tourId,
    required List<CoachStep> steps,
    Duration delay = const Duration(milliseconds: 600),
  }) => showParts(
    context,
    parts: <(String, List<CoachStep>)>[(tourId, steps)],
    delay: delay,
  );

  /// [showOnce] for a screen whose tips become relevant at different times:
  /// each part (a tour id and its steps) is remembered on its own, and only
  /// once at least one of its steps was actually on screen to show. Unseen
  /// parts that are on screen run together as one tour, in the order given.
  static Future<void> showParts(
    BuildContext context, {
    required List<(String, List<CoachStep>)> parts,
    Duration delay = const Duration(milliseconds: 600),
  }) async {
    if (_showing) return;
    final List<(String, List<CoachStep>)> unseen = <(String, List<CoachStep>)>[
      for (final (String, List<CoachStep>) part in parts)
        if (!await store.hasSeen(part.$1)) part,
    ];
    if (unseen.isEmpty) return;
    await Future<void>.delayed(delay);
    if (!context.mounted || _showing) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;

    final List<CoachStep> live = <CoachStep>[];
    final List<String> shown = <String>[];
    for (final (String id, List<CoachStep> steps) in unseen) {
      final Iterable<CoachStep> here = steps.where(
        (CoachStep step) => _targets[step.targetId]?.mounted ?? false,
      );
      if (here.isEmpty) continue;
      live.addAll(here);
      shown.add(id);
    }
    if (live.isEmpty) return;

    _showing = true;
    // Remembered as soon as it is shown: a tour walked away from half-way has
    // still been seen.
    for (final String id in shown) {
      unawaited(store.markSeen(id));
    }
    try {
      if (!context.mounted) return;
      await Navigator.of(context, rootNavigator: true).push(_CoachRoute(live));
    } finally {
      _showing = false;
    }
  }
}

class _CoachRoute extends PopupRoute<void> {
  _CoachRoute(this.steps);

  final List<CoachStep> steps;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _CoachOverlay(steps: steps);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(opacity: animation, child: child);
}

class _CoachOverlay extends StatefulWidget {
  const _CoachOverlay({required this.steps});

  final List<CoachStep> steps;

  @override
  State<_CoachOverlay> createState() => _CoachOverlayState();
}

class _CoachOverlayState extends State<_CoachOverlay> {
  int _index = 0;
  Rect? _hole;

  static const double _holePadding = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _show(0));
  }

  /// Scrolls the target into view if it is in a list, then frames it. A
  /// target that has gone since the tour began is stepped over.
  Future<void> _show(int index) async {
    for (int i = index; i < widget.steps.length; i++) {
      final _CoachTargetState? target =
          CoachMarks._targets[widget.steps[i].targetId];
      if (target == null || !target.mounted) continue;
      await Scrollable.ensureVisible(
        target.context,
        alignment: 0.4,
        duration: const Duration(milliseconds: 250),
      );
      if (!mounted) return;
      if (!target.mounted) continue;
      final RenderObject? box = target.context.findRenderObject();
      if (box is! RenderBox ||
          !box.attached ||
          !box.hasSize ||
          box.size.isEmpty) {
        continue;
      }
      final Rect rect = box.localToGlobal(Offset.zero) & box.size;
      setState(() {
        _index = i;
        _hole = rect.inflate(_holePadding);
      });
      return;
    }
    _close();
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      _close();
    } else {
      _show(_index + 1);
    }
  }

  void _close() {
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final Rect? hole = _hole;
    final CoachStep step = widget.steps[_index];
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final BimirPalette p = BimirPalette.of(context);

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _next,
        child: Stack(
          children: [
            Positioned.fill(
              child: hole == null
                  ? CustomPaint(
                      painter: _ScrimPainter(
                        hole: null,
                        circle: false,
                        edge: p.primary,
                      ),
                    )
                  : TweenAnimationBuilder<Rect?>(
                      tween: RectTween(begin: hole, end: hole),
                      duration: Motion.reduced(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      builder: (BuildContext context, Rect? rect, _) =>
                          CustomPaint(
                            painter: _ScrimPainter(
                              hole: rect,
                              circle: step.circle,
                              edge: p.primary,
                            ),
                          ),
                    ),
            ),
            if (hole != null)
              CustomSingleChildLayout(
                delegate: _CardLayout(hole: hole, padding: padding),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _TipCard(
                    key: ValueKey<int>(_index),
                    step: step,
                    position: _index + 1,
                    count: widget.steps.length,
                    onNext: _next,
                    onSkip: _close,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Darkens everything but the thing being pointed at, and outlines the hole
/// in the accent.
class _ScrimPainter extends CustomPainter {
  const _ScrimPainter({
    required this.hole,
    required this.circle,
    required this.edge,
  });

  final Rect? hole;
  final bool circle;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect screen = Offset.zero & size;
    final Paint scrim = Paint()..color = Colors.black.withValues(alpha: 0.78);
    final Rect? rect = hole;
    if (rect == null) {
      canvas.drawRect(screen, scrim);
      return;
    }
    final Path shape = circle
        ? (Path()..addOval(
            Rect.fromCircle(
              center: rect.center,
              radius: math.max(rect.width, rect.height) / 2,
            ),
          ))
        : (Path()..addRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(Radii.card)),
          ));
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(screen), shape),
      scrim,
    );
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = edge,
    );
  }

  @override
  bool shouldRepaint(covariant _ScrimPainter old) =>
      old.hole != hole || old.circle != circle || old.edge != edge;
}

/// Puts the tip under what it points at, or over it when there is no room
/// below, and never off the side of the screen.
class _CardLayout extends SingleChildLayoutDelegate {
  const _CardLayout({required this.hole, required this.padding});

  final Rect hole;
  final EdgeInsets padding;

  static const double _margin = 16;
  static const double _gap = 12;
  static const double _maxWidth = 340;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final double width = math.min(
      constraints.maxWidth - _margin * 2,
      _maxWidth,
    );
    return BoxConstraints.loose(Size(width, constraints.maxHeight));
  }

  @override
  Offset getPositionForChild(Size size, Size child) {
    final double x = (hole.center.dx - child.width / 2)
        .clamp(_margin, math.max(_margin, size.width - child.width - _margin))
        .toDouble();
    final double below = hole.bottom + _gap;
    if (below + child.height <= size.height - padding.bottom - _margin) {
      return Offset(x, below);
    }
    final double above = hole.top - _gap - child.height;
    if (above >= padding.top + _margin) return Offset(x, above);
    return Offset(x, size.height - padding.bottom - _margin - child.height);
  }

  @override
  bool shouldRelayout(covariant _CardLayout old) =>
      old.hole != hole || old.padding != padding;
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.step,
    required this.position,
    required this.count,
    required this.onNext,
    required this.onSkip,
    super.key,
  });

  final CoachStep step;
  final int position;
  final int count;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final BimirPalette p = BimirPalette.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final bool isLast = position == count;

    return Semantics(
      container: true,
      liveRegion: true,
      child: GestureDetector(
        // Taps on the card itself are for its buttons, not "next".
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.md,
            Space.sm,
            Space.xs,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title, style: t.titleMedium),
              const SizedBox(height: Space.xs),
              Text(step.body, style: t.bodyMedium?.copyWith(color: p.muted)),
              const SizedBox(height: Space.xs),
              Row(
                children: [
                  if (count > 1)
                    Text(
                      '$position/$count',
                      style: BimirPalette.figure(context, size: 12),
                    ),
                  // Buttons drop under each other rather than overflow when
                  // the system text is very large.
                  Expanded(
                    child: OverflowBar(
                      alignment: MainAxisAlignment.end,
                      overflowAlignment: OverflowBarAlignment.end,
                      children: [
                        if (!isLast)
                          TextButton(
                            onPressed: onSkip,
                            style: TextButton.styleFrom(foregroundColor: p.muted),
                            child: const Text('Skip'),
                          ),
                        TextButton(
                          onPressed: onNext,
                          child: Text(isLast ? 'Got it' : 'Next'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
