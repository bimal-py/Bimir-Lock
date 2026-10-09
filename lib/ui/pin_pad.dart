import 'dart:math';

import 'package:bimir_lock/core/theme/colors/app_colors.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';

enum PinCellState { idle, success, error }

/// The app's own keypad, laid out like the one on a safe: rectangular keys,
/// monospace digits, a row of cells that fill as you type. There is no text
/// field behind it, so the system keyboard never sees (or learns) the PIN.
///
/// When [length] digits are in, [onCompleted] decides. Returning false shakes
/// the cells, buzzes and clears them for another try.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.onCompleted,
    this.length = 4,
    this.enabled = true,
    this.header,
    this.leadingKey,
    this.footer,
  });

  final Future<bool> Function(String pin) onCompleted;
  final int length;
  final bool enabled;

  /// Shown above the cells (or beside the keys in landscape).
  final Widget? header;

  /// The bottom-left key, typically fingerprint / Face ID.
  final PinPadKey? leadingKey;

  /// Under the keys, e.g. "Forgot PIN?".
  final Widget? footer;

  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadKey {
  const PinPadKey({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Defaults to the pad's own [PinPad.enabled]. Fingerprint / Face ID stays
  /// usable while wrong PINs have the digits locked.
  final bool? enabled;
}

class PinPadState extends State<PinPad> with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _checking = false;
  PinCellState _state = PinCellState.idle;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  /// Empties the cells (e.g. between "new PIN" and "repeat it").
  void clear() => setState(() {
    _pin = '';
    _state = PinCellState.idle;
  });

  /// Rejects what is in the cells: shake, buzz, clear.
  Future<void> reject() async {
    // Keys pressed mid-shake would land in cells that are about to clear.
    _checking = true;
    HapticFeedback.heavyImpact();
    setState(() => _state = PinCellState.error);
    if (!Motion.reduced(context)) await _shake.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _checking = false;
    if (mounted) clear();
  }

  void _press(String digit) {
    if (!widget.enabled || _checking || _pin.length >= widget.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      _state = PinCellState.idle;
      _pin += digit;
    });
    if (_pin.length == widget.length) _submit();
  }

  void _backspace({bool all = false}) {
    if (!widget.enabled || _checking || _pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = all ? '' : _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    _checking = true;
    final bool ok = await widget.onCompleted(_pin);
    if (!mounted) return;
    if (ok) {
      _checking = false;
      HapticFeedback.mediumImpact();
      setState(() => _state = PinCellState.success);
    } else {
      await reject();
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final String? ch = event.character;
    if (ch != null && RegExp(r'^\d$').hasMatch(ch)) {
      _press(ch);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _backspace();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final bool sideBySide = screen.width > screen.height && screen.height < 520;

    final Widget cells = AnimatedBuilder(
      animation: _shake,
      builder: (BuildContext context, Widget? child) {
        final double t = _shake.value;
        return Transform.translate(
          offset: Offset(sin(t * pi * 6) * 10 * (1 - t), 0),
          child: child,
        );
      },
      child: _Cells(length: widget.length, filled: _pin.length, state: _state),
    );

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          final Widget keys = _Keys(
            enabled: widget.enabled,
            onDigit: _press,
            onBackspace: () => _backspace(),
            onClear: () => _backspace(all: true),
            leading: widget.leadingKey,
            canDelete: _pin.isNotEmpty,
          );
          if (sideBySide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.header != null) widget.header!,
                      const SizedBox(height: Space.lg),
                      cells,
                    ],
                  ),
                ),
                const SizedBox(width: Space.xl),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      keys,
                      if (widget.footer != null) widget.footer!,
                    ],
                  ),
                ),
              ],
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.header != null) widget.header!,
              const SizedBox(height: Space.xl),
              cells,
              const SizedBox(height: Space.xl),
              keys,
              if (widget.footer != null) ...[
                const SizedBox(height: Space.sm),
                widget.footer!,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Cells extends StatelessWidget {
  const _Cells({
    required this.length,
    required this.filled,
    required this.state,
  });

  final int length;
  final int filled;
  final PinCellState state;

  @override
  Widget build(BuildContext context) {
    final BimirPalette p = BimirPalette.of(context);
    final Color accent = switch (state) {
      PinCellState.idle => p.primary,
      PinCellState.success => p.success,
      PinCellState.error => p.danger,
    };
    return Semantics(
      liveRegion: true,
      label: '$filled of $length digits entered',
      child: ExcludeSemantics(
        // Dots, as on the phone's own lock screen: filled for each digit typed.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < length; i++) ...[
              if (i > 0) const SizedBox(width: Space.lg),
              AnimatedContainer(
                duration: Motion.fast,
                curve: Curves.easeOutBack,
                width: i < filled ? 16 : 14,
                height: i < filled ? 16 : 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < filled
                      ? (state == PinCellState.idle ? p.primary : accent)
                      : Colors.transparent,
                  border: Border.all(
                    color: state == PinCellState.idle ? p.borderStrong : accent,
                    width: i < filled ? 0 : 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Keys extends StatelessWidget {
  const _Keys({
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    required this.canDelete,
    this.leading,
  });

  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final bool canDelete;
  final PinPadKey? leading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        // Round keys like the phone's own PIN pad: as big as fits, never
        // smaller than a 52 px target, never bigger than 76.
        final double screenH = MediaQuery.sizeOf(context).height;
        final double width = min(box.maxWidth, 320);
        final double gap = width < 280 ? Space.md : Space.xl;
        final double keyW =
            ((width - gap * 2) / 3).clamp(52, screenH < 520 ? 56 : 76);
        final double keyH = keyW;

        Widget row(List<Widget> keys) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < keys.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              SizedBox(width: keyW, height: keyH, child: keys[i]),
            ],
          ],
        );

        Widget digit(String d) =>
            _Key(label: d, enabled: enabled, onTap: () => onDigit(d));

        return MediaQuery.withNoTextScaling(
          // The keys are a fixed grid sized for large text already; letting the
          // digits grow with the system font would push them out of the keys.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              row([digit('1'), digit('2'), digit('3')]),
              SizedBox(height: gap * 0.6),
              row([digit('4'), digit('5'), digit('6')]),
              SizedBox(height: gap * 0.6),
              row([digit('7'), digit('8'), digit('9')]),
              SizedBox(height: gap * 0.6),
              row([
                leading == null
                    ? const SizedBox.shrink()
                    : _Key(
                        icon: leading!.icon,
                        semantic: leading!.label,
                        enabled: leading!.enabled ?? enabled,
                        quiet: true,
                        onTap: leading!.onTap,
                      ),
                digit('0'),
                _Key(
                  icon: LucideIcons.delete,
                  semantic: 'Delete',
                  enabled: enabled && canDelete,
                  quiet: true,
                  onTap: onBackspace,
                  onLongPress: onClear,
                ),
              ]),
            ],
          ),
        );
      },
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    this.label,
    this.icon,
    this.semantic,
    required this.enabled,
    required this.onTap,
    this.onLongPress,
    this.quiet = false,
  });

  final String? label;
  final IconData? icon;
  final String? semantic;
  final bool enabled;
  final bool quiet;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final BimirPalette p = BimirPalette.of(context);
    final Color fg = enabled ? p.foreground : p.muted.withValues(alpha: 0.5);
    return Semantics(
      button: true,
      label: semantic ?? label,
      enabled: enabled,
      child: Material(
        color: quiet ? Colors.transparent : p.surfaceMuted,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          highlightColor: p.primary.withValues(alpha: 0.12),
          child: Center(
            child: ExcludeSemantics(
              child: icon != null
                  ? Icon(icon, size: 24, color: fg)
                  : Text(
                      label!,
                      style: TextStyle(
                        fontFamily: AppFonts.sans,
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        color: fg,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
