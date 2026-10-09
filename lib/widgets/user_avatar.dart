import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// The one place a profile photo is drawn. A missing or unreadable file falls back
// to the person icon instead of throwing out of the image loader.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.file,
    this.iconColor,
    this.iconSize,
  });

  final File? file;
  final Color? iconColor;
  // Null means fill the available space.
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final File? photo = file;
    if (photo == null) return _fallback();
    return Image.file(
      photo,
      key: ValueKey<String>(photo.path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() {
    final Icon icon = Icon(
      LucideIcons.user,
      color: iconColor,
      size: iconSize,
    );
    return iconSize == null ? FittedBox(child: icon) : Center(child: icon);
  }
}
