import 'dart:convert';

import 'package:flutter/widgets.dart' show TextSelection;
import 'package:flutter_quill/flutter_quill.dart';

/// Quill document <-> stored-note-body helpers. The note body is persisted as
/// Quill **Delta JSON** (the same format diaryvault ships to the Play Store);
/// [documentFromBody] also migrates a legacy plain-text body into a document.
class NoteQuill {
  NoteQuill._();

  static Document documentFromBody(String? body) {
    final raw = body?.trim() ?? '';
    if (raw.isEmpty) return Document();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return Document.fromJson(decoded);
    } catch (_) {
      // Not Delta JSON — fall through and treat it as plain text.
    }
    return Document()..insert(0, raw);
  }

  static QuillController controller(String? body, {bool readOnly = false}) =>
      QuillController(
        document: documentFromBody(body),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: readOnly,
      );

  /// Serializes the document to Delta JSON for storage.
  static String bodyOf(Document document) =>
      jsonEncode(document.toDelta().toJson());

  /// The document's plain text (trimmed) — stored alongside the body for fast
  /// search and previews.
  static String plainTextOf(Document document) => document.toPlainText().trim();
}
