import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Wraps `share_plus` with sensible defaults and the iPad
/// `sharePositionOrigin` rect (required for iOS / iPad).
class ShareService {
  ShareService._();

  /// Share plain text and / or a URL.
  static Future<void> shareText({
    required BuildContext context,
    required String text,
    String? subject,
    Uri? uri,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
        uri: uri,
        sharePositionOrigin: _origin(context),
      ),
    );
  }

  /// Share one or more files by absolute path. Provide the `mimeTypes` if you
  /// know them, e.g. `['image/png']`.
  static Future<void> shareFiles({
    required BuildContext context,
    required List<String> filePaths,
    String? text,
    String? subject,
    List<String>? mimeTypes,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: filePaths.map(XFile.new).toList(),
        text: text,
        subject: subject,
        sharePositionOrigin: _origin(context),
      ),
    );
  }

  /// Share an in-memory image (PNG/JPG bytes).
  static Future<void> shareImageBytes({
    required BuildContext context,
    required Uint8List bytes,
    required String fileName,
    String? text,
    String? subject,
  }) async {
    final origin = _origin(context);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: text,
        subject: subject,
        sharePositionOrigin: origin,
      ),
    );
  }

  static Rect? _origin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    final width = box.size.width.clamp(1.0, 300.0);
    final height = box.size.height.clamp(1.0, 300.0);
    final adjusted = topLeft.translate(20, 40);
    return Rect.fromLTWH(adjusted.dx, adjusted.dy, width, height);
  }
}
