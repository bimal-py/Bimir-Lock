import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/core/core.dart';

/// A single note tile in the notes grid. Shows a soft accent icon badge, a
/// title, a timestamp and (optionally) an attachment clip. When the screen is
/// in multi-select mode it overlays a selection ring; folder-style notes get a
/// folded-corner accent and a file-count subtitle instead of a clip.
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.icon,
    required this.title,
    required this.dateLabel,
    this.subtitle,
    this.hasAttachment = false,
    this.isFolder = false,
    this.selectionMode = false,
    this.selected = false,
    this.pinned = false,
    this.accentColor,
    this.accentMutedColor,
    this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String title;
  final String dateLabel;

  /// Secondary line under the title — e.g. "5 Files" for folder notes.
  final String? subtitle;
  final bool hasAttachment;
  final bool isFolder;
  final bool selectionMode;
  final bool selected;
  final bool pinned;

  /// Per-note accent (its [NoteColor]); falls back to the brand accent.
  final Color? accentColor;
  final Color? accentMutedColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final custom = context.customTheme;
    final accent = accentColor ?? custom.brandAccent;
    final accentMuted = accentMutedColor ?? custom.brandAccentMuted;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(14.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(11.r),
                        decoration: BoxDecoration(
                          color: accentMuted,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: accent, size: 22.r),
                      ),
                      const Spacer(),
                      if (pinned && !selectionMode)
                        Icon(LucideIcons.pin, size: 15.r, color: accent),
                    ],
                  ),
                  12.verticalSpace,
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    4.verticalSpace,
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dateLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (hasAttachment) ...[
                        6.horizontalSpace,
                        Icon(LucideIcons.paperclip, size: 16.r, color: accent),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isFolder)
              Positioned(
                top: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(28.r, 28.r),
                  painter: _FoldedCornerPainter(custom.brandAccentMuted),
                ),
              ),
            if (selectionMode)
              Positioned(
                top: 10.r,
                right: 10.r,
                child: _SelectionIndicator(selected: selected),
              ),
          ],
        ),
      ),
    );
  }
}

/// Empty ring when unselected, filled primary check when selected.
class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      width: 22.r,
      height: 22.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.primary : colors.surface,
        border: Border.all(
          color: selected ? colors.primary : colors.outline,
          width: 1.5,
        ),
      ),
      child: selected
          ? Icon(LucideIcons.check, size: 14.r, color: colors.onPrimary)
          : null,
    );
  }
}

/// Soft folded-page triangle pinned to a card's top-right corner.
class _FoldedCornerPainter extends CustomPainter {
  const _FoldedCornerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_FoldedCornerPainter oldDelegate) =>
      oldDelegate.color != color;
}
