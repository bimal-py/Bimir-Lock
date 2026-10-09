import 'dart:async';

import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/ui/password_tools.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/utils/image_path.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Building blocks shared by Bimir's screens, in the Material 3 language the
/// app shares with Reminder Note. Each exists for a job; none is decoration.

/// Safe area + a centred column capped at [maxWidth], so phones get
/// full-width content and tablets / landscape get a readable column.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.child,
    this.padding,
    this.top = true,
    this.bottom = true,
    this.maxWidth = Space.maxContent,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool top;
  final bool bottom;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding:
                padding ?? const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Small uppercase label above a group (same as the Settings section headers).
class Eyebrow extends StatelessWidget {
  // [comment] is accepted for older call sites and ignored.
  const Eyebrow(this.text, {super.key, this.color, this.comment = true});

  final String text;
  final Color? color;
  final bool comment;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// The brand mark (the ब/B monogram) in its own colours.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      ImagePath.brandMark,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'Bimir Lock',
    );
  }
}

/// A round letter avatar, tinted per title (the way Google apps show a site
/// without an icon), so a long list can be scanned by colour as well as name.
class Monogram extends StatelessWidget {
  const Monogram(this.title, {super.key, this.size = 40});

  final String title;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final String t = title.trim();
    final String letter = t.isEmpty ? '•' : t.characters.first.toUpperCase();
    // A stable hue per title; tone and chroma fixed so every avatar has the
    // same weight and stays readable in light and dark. Low chroma: tinted
    // greys rather than a rainbow, so the crimson stays the one real colour.
    int h = 0;
    for (final int c in t.toLowerCase().codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    final double hue = (h % 360).toDouble();
    final Color bg = Color(Hct.from(hue, 14, dark ? 32 : 93).toInt());
    final Color fg = Color(Hct.from(hue, dark ? 30 : 40, dark ? 86 : 34).toInt());
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Center(
          child: MediaQuery.withNoTextScaling(
            child: Text(
              letter,
              style: TextStyle(
                fontFamily: AppFonts.sans,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum Tone { neutral, secure, warning, danger }

/// A dot and a line of text that states a condition in words.
class StatusLine extends StatelessWidget {
  const StatusLine(this.text, {super.key, this.tone = Tone.neutral});

  final String text;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final BimirPalette p = BimirPalette.of(context);
    final Color c = switch (tone) {
      Tone.neutral => p.muted,
      Tone.secure => p.success,
      Tone.warning => p.warning,
      Tone.danger => p.danger,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: (MediaQuery.textScalerOf(context).scale(13) * 1.5 - 8) / 2,
          ),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: Space.sm),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c),
          ),
        ),
      ],
    );
  }
}

/// A tinted card that states a condition.
class Notice extends StatelessWidget {
  const Notice({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.tone = Tone.neutral,
    this.action,
  });

  final String message;
  final String? title;
  final IconData? icon;
  final Tone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final BimirPalette p = BimirPalette.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final (Color fg, Color bg) = switch (tone) {
      Tone.neutral => (p.muted, p.surfaceMuted),
      Tone.secure => (p.onPrimarySoft, p.primarySoft),
      Tone.warning => (p.warning, p.warningSoft),
      Tone.danger => (p.danger, p.dangerSoft),
    };
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: Space.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: t.titleSmall?.copyWith(color: p.foreground),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: t.bodyMedium?.copyWith(color: p.foreground),
                ),
                if (action != null) ...[
                  const SizedBox(height: Space.xs),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Four segments and a word: red for weak, amber for fair, brand for strong.
class StrengthMeter extends StatelessWidget {
  const StrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final BimirPalette p = BimirPalette.of(context);
    final Strength s = estimateStrength(password);
    final Color c = switch (s.segments) {
      0 => p.border,
      1 => p.danger,
      2 => p.warning,
      _ => p.primary,
    };
    return Semantics(
      label: s == Strength.empty
          ? 'No password yet'
          : 'Password strength: ${s.label}',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) => Row(
            children: [
              for (int i = 0; i < 4; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: Motion.fast,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < s.segments ? c : p.surfaceMuted,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                if (i < 3) const SizedBox(width: Space.xs),
              ],
              const SizedBox(width: Space.md),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: box.maxWidth * 0.2 < 72 ? box.maxWidth * 0.2 : 72,
                  maxWidth: box.maxWidth * 0.45,
                ),
                child: Text(
                  s.label,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: s.segments == 0 ? p.muted : c,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round icon button with a soft fill (the Reminder Note app-bar button).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme s = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: s.surfaceContainerHigh,
          shape: CircleBorder(side: BorderSide(color: s.outlineVariant)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 44,
              child: Icon(icon, size: 20, color: s.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

/// A card surface (the shared Card style). It is a Material, so ripples from
/// rows, switches and buttons inside it show.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding, this.borderColor});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme s = Theme.of(context).colorScheme;
    return Material(
      color: s.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: borderColor ?? s.outlineVariant),
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}

/// A titled card of rows with inset dividers (settings, detail fields).
class RowGroup extends StatelessWidget {
  const RowGroup({super.key, required this.children, this.title});

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xs, 0, Space.xs, Space.sm),
            child: Eyebrow(title!),
          ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    indent: Space.lg,
                    endIndent: Space.lg,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One row in a [RowGroup]: icon in a soft square, title, detail, trailing.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final ColorScheme s = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.xs,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: danger ? s.errorContainer : s.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: danger ? s.onErrorContainer : s.onPrimaryContainer,
        ),
      ),
      title: Text(title, style: danger ? TextStyle(color: s.error) : null),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing:
          trailing ??
          (onTap != null
              ? Icon(LucideIcons.chevronRight, color: s.onSurfaceVariant)
              : null),
    );
  }
}

/// Centred empty / notice state: an icon in a soft circle, words, an action.
class EmptyMessage extends StatelessWidget {
  const EmptyMessage({
    super.key,
    required this.title,
    required this.body,
    this.action,
    this.icon,
    this.secondary,
  });

  final String title;
  final String body;
  final Widget? action;
  final Widget? secondary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final ColorScheme s = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: s.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: s.onPrimaryContainer),
            ),
            const SizedBox(height: Space.lg),
          ],
          Text(title, style: t.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: Space.sm),
          Text(
            body,
            style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: Space.xl), action!],
          if (secondary != null) ...[
            const SizedBox(height: Space.sm),
            secondary!,
          ],
        ],
      ),
    );
  }
}

/// Short confirmation at the bottom of the screen.
void showNote(String message) {
  CustomSnackbar.show(
    type: ToastType.info,
    message: message,
    backgroundColor: const Color(0xFF2B2A2E),
  );
}

Timer? _clipboardTimer;

/// Copies a value. Passwords ([sensitive]) are wiped from the clipboard again
/// after 30 seconds, if they are still what is on it, so they do not linger for
/// every other app to read.
Future<void> copyValue(
  String value, {
  required String what,
  bool sensitive = false,
}) async {
  await Clipboard.setData(ClipboardData(text: value));
  HapticFeedback.selectionClick();
  _clipboardTimer?.cancel();
  if (!sensitive) {
    showNote('$what copied');
    return;
  }
  showNote('$what copied · clears in 30 s');
  _clipboardTimer = Timer(const Duration(seconds: 30), () async {
    try {
      final ClipboardData? now = await Clipboard.getData(Clipboard.kTextPlain);
      if (now?.text == value) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    } catch (_) {}
  });
}
