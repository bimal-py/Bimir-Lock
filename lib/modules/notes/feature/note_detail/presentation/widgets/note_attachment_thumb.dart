import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/core/core.dart';

/// Square image-attachment thumbnail with a remove badge in the top-right.
class NoteAttachmentThumb extends StatelessWidget {
  const NoteAttachmentThumb({
    super.key,
    required this.imagePath,
    this.size = 96,
    this.onRemove,
  });

  /// Bundled asset path (e.g. an [AssetRoutes] constant) for the preview.
  final String imagePath;
  final double size;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return SizedBox(
      width: size.r,
      height: size.r,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: colors.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.image,
                    color: colors.onSurfaceVariant,
                    size: 28.r,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 6.r,
            right: 6.r,
            child: InkResponse(
              onTap: onRemove,
              radius: 16.r,
              child: Container(
                padding: EdgeInsets.all(3.r),
                decoration: BoxDecoration(
                  color: colors.scrim.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.x, size: 14.r, color: colors.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
