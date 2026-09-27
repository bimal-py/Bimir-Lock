import 'dart:io';

import 'package:intl/intl.dart';

extension DateFormatter on DateTime {
  String formatDate() {
    return DateFormat('yyyy-MM-dd').format(this);
  }
}

extension GetExtension on File {
  String getExtension() {
    final int dot = path.lastIndexOf('.');
    // No dot, or a dot in a folder name: fall back rather than throw.
    if (dot == -1 || dot < path.lastIndexOf('/')) return ".jpg";
    return path.substring(dot, path.length);
  }
}
