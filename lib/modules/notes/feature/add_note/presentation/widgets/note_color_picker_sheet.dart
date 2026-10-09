import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/modules/notes/utils/utils.dart';

/// Bottom sheet that lets the user tag a note with a [NoteColor]. Returns the
/// chosen colour, or null if dismissed.
class NoteColorPickerSheet extends StatelessWidget {
  const NoteColorPickerSheet({super.key, required this.current});

  final NoteColor current;

  static Future<NoteColor?> show(BuildContext context, NoteColor current) {
    return showModalBottomSheet<NoteColor>(
      context: context,
      showDragHandle: true,
      builder: (_) => NoteColorPickerSheet(current: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Note colour',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colorScheme.onSurface,
              ),
            ),
            16.verticalSpace,
            Wrap(
              spacing: 16.w,
              runSpacing: 16.h,
              children: [
                for (final color in NoteColor.values)
                  _Swatch(
                    color: color,
                    selected: color == current,
                    onTap: () => Navigator.of(context).pop(color),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final NoteColor color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final accent = color.accent(context);
    return InkResponse(
      onTap: onTap,
      radius: 32.r,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46.r,
            height: 46.r,
            decoration: BoxDecoration(
              color: color.muted(context),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? accent : colors.outlineVariant,
                width: selected ? 2.5 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: selected
                ? Icon(LucideIcons.check, size: 20.r, color: accent)
                : (color == NoteColor.none
                      ? Icon(
                          LucideIcons.ban,
                          size: 18.r,
                          color: colors.onSurfaceVariant,
                        )
                      : CircleAvatar(radius: 9.r, backgroundColor: accent)),
          ),
          6.verticalSpace,
          Text(
            color.label,
            style: context.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
