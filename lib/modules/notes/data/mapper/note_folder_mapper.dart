import 'dart:convert';

import 'package:bimir_lock/modules/notes/data/model/model.dart';
import 'package:bimir_lock/modules/notes/domain/entity/entity.dart';

class NoteFolderMapper {
  NoteFolderMapper._();

  static NoteFolderEntity toEntity(NoteFolderModel model) {
    return NoteFolderEntity(
      id: model.id,
      name: model.name,
      parentId: model.parentId,
      colorName: model.colorName,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  static NoteFolderModel toModel(NoteFolderEntity entity) {
    return NoteFolderModel(
      id: entity.id,
      name: entity.name,
      parentId: entity.parentId,
      colorName: entity.colorName,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static NoteFolderEntity fromJsonToEntity(Map<String, dynamic> json) {
    return toEntity(NoteFolderModel.fromJson(json));
  }

  static NoteFolderEntity fromRawJsonToEntity(String rawJson) {
    return toEntity(NoteFolderModel.fromJson(jsonDecode(rawJson)));
  }

  static Map<String, dynamic> toJsonFromEntity(NoteFolderEntity entity) {
    return toModel(entity).toJson();
  }

  static String toRawJsonFromEntity(NoteFolderEntity entity) {
    return jsonEncode(toModel(entity).toJson());
  }

  static List<NoteFolderEntity> fromJsonListToEntityList(
    List<dynamic> jsonList,
  ) {
    return jsonList
        .map((json) => fromJsonToEntity(json as Map<String, dynamic>))
        .toList();
  }

  static List<NoteFolderEntity> fromRawJsonListToEntityList(
    String rawJsonList,
  ) {
    final List<dynamic> jsonList = jsonDecode(rawJsonList);
    return jsonList
        .map((json) => fromJsonToEntity(json as Map<String, dynamic>))
        .toList();
  }

  static List<Map<String, dynamic>> toJsonListFromEntityList(
    List<NoteFolderEntity> entities,
  ) {
    return entities.map((entity) => toJsonFromEntity(entity)).toList();
  }

  static String toRawJsonListFromEntityList(List<NoteFolderEntity> entities) {
    final List<Map<String, dynamic>> jsonList = entities
        .map((entity) => toJsonFromEntity(entity))
        .toList();
    return jsonEncode(jsonList);
  }
}
