import 'package:equatable/equatable.dart';
import 'package:bimir_lock/modules/notes/utils/utils.dart';

/// User preferences for the notes list — order, whether pinned notes float to
/// the top, and the default colour applied to new notes.
class NotesSettingsEntity extends Equatable {
  final NoteSortOrder? sortOrder;
  final bool? pinnedFirst;

  /// Whether folders or notes lead the grid.
  final NoteGrouping? grouping;

  /// Grid or list layout for the listing.
  final NoteViewMode? viewMode;

  /// Persisted as the [NoteColor.name].
  final String? defaultColorName;

  const NotesSettingsEntity({
    this.sortOrder,
    this.pinnedFirst,
    this.grouping,
    this.viewMode,
    this.defaultColorName,
  });

  NoteSortOrder get order => sortOrder ?? NoteSortOrder.newest;
  bool get keepPinnedFirst => pinnedFirst ?? true;
  NoteGrouping get group => grouping ?? NoteGrouping.foldersFirst;
  NoteViewMode get view => viewMode ?? NoteViewMode.grid;
  NoteColor get defaultColor => NoteColor.fromName(defaultColorName);

  NotesSettingsEntity copyWith({
    NoteSortOrder? sortOrder,
    bool? pinnedFirst,
    NoteGrouping? grouping,
    NoteViewMode? viewMode,
    String? defaultColorName,
  }) => NotesSettingsEntity(
    sortOrder: sortOrder ?? this.sortOrder,
    pinnedFirst: pinnedFirst ?? this.pinnedFirst,
    grouping: grouping ?? this.grouping,
    viewMode: viewMode ?? this.viewMode,
    defaultColorName: defaultColorName ?? this.defaultColorName,
  );

  @override
  List<Object?> get props => [
    sortOrder,
    pinnedFirst,
    grouping,
    viewMode,
    defaultColorName,
  ];
}
