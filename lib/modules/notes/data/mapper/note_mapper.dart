import 'dart:convert';

import 'package:bimir_lock/modules/notes/data/model/model.dart';
import 'package:bimir_lock/modules/notes/domain/entity/entity.dart';

class NoteMapper {
  NoteMapper._();

  static NoteEntity toEntity(NoteModel model) {
    return NoteEntity(
      id: model.id,
      title: model.title,
      body: model.body,
      plainText: model.plainText,
      colorName: model.colorName,
      isPinned: model.isPinned,
      isArchived: model.isArchived,
      folderId: model.folderId,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  static NoteModel toModel(NoteEntity entity) {
    return NoteModel(
      id: entity.id,
      title: entity.title,
      body: entity.body,
      plainText: entity.plainText,
      colorName: entity.colorName,
      isPinned: entity.isPinned,
      isArchived: entity.isArchived,
      folderId: entity.folderId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static NoteEntity fromJsonToEntity(Map<String, dynamic> json) {
    return toEntity(NoteModel.fromJson(json));
  }

  static NoteEntity fromRawJsonToEntity(String rawJson) {
    return toEntity(NoteModel.fromJson(jsonDecode(rawJson)));
  }

  static Map<String, dynamic> toJsonFromEntity(NoteEntity entity) {
    return toModel(entity).toJson();
  }

  static String toRawJsonFromEntity(NoteEntity entity) {
    return jsonEncode(toModel(entity).toJson());
  }

  static List<NoteEntity> fromJsonListToEntityList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => fromJsonToEntity(json as Map<String, dynamic>))
        .toList();
  }

  static List<NoteEntity> fromRawJsonListToEntityList(String rawJsonList) {
    final List<dynamic> jsonList = jsonDecode(rawJsonList);
    return jsonList
        .map((json) => fromJsonToEntity(json as Map<String, dynamic>))
        .toList();
  }

  static List<Map<String, dynamic>> toJsonListFromEntityList(
    List<NoteEntity> entities,
  ) {
    return entities.map((entity) => toJsonFromEntity(entity)).toList();
  }

  static String toRawJsonListFromEntityList(List<NoteEntity> entities) {
    final List<Map<String, dynamic>> jsonList = entities
        .map((entity) => toJsonFromEntity(entity))
        .toList();
    return jsonEncode(jsonList);
  }
}
