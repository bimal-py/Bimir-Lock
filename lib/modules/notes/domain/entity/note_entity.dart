import 'package:equatable/equatable.dart';
import 'package:bimir_lock/modules/notes/utils/utils.dart';

/// A note. Local-first today (persisted in Hive); the same shape maps onto a
/// Supabase `notes` row when remote sync lands.
///
/// [body] holds the rich content as **Quill Delta JSON** (the format the
/// diaryvault Play Store app uses); [plainText] is the same content flattened to
/// text, stored alongside for fast search and list previews.
class NoteEntity extends Equatable {
  final String? id;
  final String? title;
  final String? body;
  final String? plainText;

  /// Persisted as the [NoteColor.name]; resolve via [color].
  final String? colorName;
  final bool? isPinned;
  final bool? isArchived;

  /// Id of the folder this note lives in; `null` means the root level.
  final String? folderId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NoteEntity({
    this.id,
    this.title,
    this.body,
    this.plainText,
    this.colorName,
    this.isPinned,
    this.isArchived,
    this.folderId,
    this.createdAt,
    this.updatedAt,
  });

  NoteColor get color => NoteColor.fromName(colorName);

  bool get pinned => isPinned ?? false;

  bool get archived => isArchived ?? false;

  bool get isEmpty =>
      (title?.trim().isEmpty ?? true) && (plainText?.trim().isEmpty ?? true);

  /// First non-empty line of the flattened text — card subtitle / title fallback.
  String get preview {
    final text = plainText?.trim() ?? '';
    if (text.isEmpty) return '';
    return text
        .split('\n')
        .firstWhere((l) => l.trim().isNotEmpty, orElse: () => text);
  }

  /// Title to render, falling back to the preview then a generic label.
  String get displayTitle {
    final t = title?.trim() ?? '';
    if (t.isNotEmpty) return t;
    final p = preview;
    return p.isNotEmpty ? p : NotesStrings.untitled;
  }

  NoteEntity copyWith({
    String? id,
    String? title,
    String? body,
    String? plainText,
    String? colorName,
    bool? isPinned,
    bool? isArchived,
    String? folderId,
    bool clearFolder = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => NoteEntity(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    plainText: plainText ?? this.plainText,
    colorName: colorName ?? this.colorName,
    isPinned: isPinned ?? this.isPinned,
    isArchived: isArchived ?? this.isArchived,
    folderId: clearFolder ? null : (folderId ?? this.folderId),
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    plainText,
    colorName,
    isPinned,
    isArchived,
    folderId,
    createdAt,
    updatedAt,
  ];
}
