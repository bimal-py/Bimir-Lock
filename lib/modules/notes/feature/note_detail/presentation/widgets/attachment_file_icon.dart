import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/core/core.dart';

/// Picks a glyph + tint for a file based on its extension. PDFs read in the
/// theme's error red, spreadsheets in success green, everything else neutral.
class AttachmentFileIcon extends StatelessWidget {
  const AttachmentFileIcon({super.key, required this.fileName, this.size = 26});

  final String fileName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final custom = context.customTheme;
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';

    final (IconData icon, Color color) = switch (ext) {
      'pdf' => (LucideIcons.fileText, colors.error),
      'xls' || 'xlsx' || 'csv' => (LucideIcons.fileSpreadsheet, custom.success),
      'doc' || 'docx' => (LucideIcons.fileText, colors.primary),
      _ => (LucideIcons.file, colors.onSurfaceVariant),
    };

    return Icon(icon, size: size.r, color: color);
  }
}
