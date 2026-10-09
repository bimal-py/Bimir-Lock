import 'dart:convert';

class NoteModel {
  final String? id;
  final String? title;
  final String? body;
  final String? plainText;
  final String? colorName;
  final bool? isPinned;
  final bool? isArchived;
  final String? folderId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NoteModel({
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

  NoteModel copyWith({
    String? id,
    String? title,
    String? body,
    String? plainText,
    String? colorName,
    bool? isPinned,
    bool? isArchived,
    String? folderId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => NoteModel(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    plainText: plainText ?? this.plainText,
    colorName: colorName ?? this.colorName,
    isPinned: isPinned ?? this.isPinned,
    isArchived: isArchived ?? this.isArchived,
    folderId: folderId ?? this.folderId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory NoteModel.fromRawJson(String str) =>
      NoteModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
    id: json["id"]?.toString(),
    title: json["title"],
    body: json["body"],
    plainText: json["plain_text"],
    colorName: json["color_name"],
    isPinned: json["is_pinned"],
    isArchived: json["is_archived"],
    folderId: json["folder_id"]?.toString(),
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null
        ? null
        : DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "body": body,
    "plain_text": plainText,
    "color_name": colorName,
    "is_pinned": isPinned,
    "is_archived": isArchived,
    "folder_id": folderId,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}
