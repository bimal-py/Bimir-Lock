import 'dart:convert';

class NotesSettingsModel {
  final String? sortOrder;
  final bool? pinnedFirst;
  final String? grouping;
  final String? viewMode;
  final String? defaultColorName;

  NotesSettingsModel({
    this.sortOrder,
    this.pinnedFirst,
    this.grouping,
    this.viewMode,
    this.defaultColorName,
  });

  NotesSettingsModel copyWith({
    String? sortOrder,
    bool? pinnedFirst,
    String? grouping,
    String? viewMode,
    String? defaultColorName,
  }) => NotesSettingsModel(
    sortOrder: sortOrder ?? this.sortOrder,
    pinnedFirst: pinnedFirst ?? this.pinnedFirst,
    grouping: grouping ?? this.grouping,
    viewMode: viewMode ?? this.viewMode,
    defaultColorName: defaultColorName ?? this.defaultColorName,
  );

  factory NotesSettingsModel.fromRawJson(String str) =>
      NotesSettingsModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory NotesSettingsModel.fromJson(Map<String, dynamic> json) =>
      NotesSettingsModel(
        sortOrder: json["sort_order"],
        pinnedFirst: json["pinned_first"],
        grouping: json["grouping"],
        viewMode: json["view_mode"],
        defaultColorName: json["default_color_name"],
      );

  Map<String, dynamic> toJson() => {
    "sort_order": sortOrder,
    "pinned_first": pinnedFirst,
    "grouping": grouping,
    "view_mode": viewMode,
    "default_color_name": defaultColorName,
  };
}
