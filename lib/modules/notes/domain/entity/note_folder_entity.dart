import 'package:equatable/equatable.dart';
import 'package:bimir_lock/modules/notes/utils/utils.dart';

/// A notes folder. Folders nest arbitrarily via [parentId] (`null` = a root
/// folder); notes point back at a folder through [NoteEntity.folderId]. Stored
/// in the same Hive box as notes, under its own key.
class NoteFolderEntity extends Equatable {
  final String? id;
  final String? name;

  /// Parent folder id; `null` means this folder sits at the root level.
  final String? parentId;

  /// Persisted as the [NoteColor.name]; resolve via [color].
  final String? colorName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NoteFolderEntity({
    this.id,
    this.name,
    this.parentId,
    this.colorName,
    this.createdAt,
    this.updatedAt,
  });

  NoteColor get color => NoteColor.fromName(colorName);

  String get displayName {
    final n = name?.trim() ?? '';
    return n.isEmpty ? NotesStrings.untitledFolder : n;
  }

  NoteFolderEntity copyWith({
    String? id,
    String? name,
    String? parentId,
    bool clearParent = false,
    String? colorName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => NoteFolderEntity(
    id: id ?? this.id,
    name: name ?? this.name,
    parentId: clearParent ? null : (parentId ?? this.parentId),
    colorName: colorName ?? this.colorName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    parentId,
    colorName,
    createdAt,
    updatedAt,
  ];
}
