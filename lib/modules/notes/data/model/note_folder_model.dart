import 'dart:convert';

class NoteFolderModel {
  final String? id;
  final String? name;
  final String? parentId;
  final String? colorName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NoteFolderModel({
    this.id,
    this.name,
    this.parentId,
    this.colorName,
    this.createdAt,
    this.updatedAt,
  });

  NoteFolderModel copyWith({
    String? id,
    String? name,
    String? parentId,
    String? colorName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => NoteFolderModel(
    id: id ?? this.id,
    name: name ?? this.name,
    parentId: parentId ?? this.parentId,
    colorName: colorName ?? this.colorName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory NoteFolderModel.fromRawJson(String str) =>
      NoteFolderModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory NoteFolderModel.fromJson(Map<String, dynamic> json) =>
      NoteFolderModel(
        id: json["id"]?.toString(),
        name: json["name"],
        parentId: json["parent_id"]?.toString(),
        colorName: json["color_name"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "parent_id": parentId,
    "color_name": colorName,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}
