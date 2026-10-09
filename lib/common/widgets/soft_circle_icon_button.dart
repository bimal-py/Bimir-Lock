import 'package:flutter/material.dart';
import 'package:bimir_lock/core/core.dart';

/// Round icon button with a soft lavender/primary-container background
/// and a dark glyph — matches the "+" / "✓" look the user pinned as
/// the standard for top-right confirm actions across the app.
class SoftCircleIconButton extends StatelessWidget {
  const SoftCircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 44,
    this.iconSize = 20,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;

  /// Override the soft pill colour. Defaults to a 20%-opacity tint of
  /// the theme's primary so it sits on any backdrop.
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final bg = background ?? scheme.primary.withValues(alpha: 0.18);
    final fg = foreground ?? scheme.onSurface;
    final button = Material(
      color: bg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: size.r,
          height: size.r,
          child: Center(child: Icon(icon, color: fg, size: iconSize.r)),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
