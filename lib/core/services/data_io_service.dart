import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// File I/O for the export / import backups. Writing the JSON to a temp file
/// (so [ShareService] can hand it to the OS share sheet) and reading a picked
/// `.json` backup on import. Sharing itself goes through `ShareService`.
class DataIoService {
  DataIoService._();

  /// Writes [data] to a temp file named [fileName] and returns its absolute path.
  static Future<String> writeJsonToTemp(
    String fileName,
    Map<String, dynamic> data,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file.path;
  }

  /// Prompts the user to pick a `.json` backup and returns its decoded map, or
  /// null if cancelled / unreadable.
  static Future<Map<String, dynamic>?> pickJson() async {
    // file_picker 13: single-file `pickFile()` replaces
    // `platform.pickFiles(withData: true)`; the bytes come from readAsBytes().
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (picked == null) return null;
    String content;
    try {
      content = utf8.decode(await picked.readAsBytes());
    } catch (_) {
      return null;
    }
    try {
      final decoded = jsonDecode(content);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
