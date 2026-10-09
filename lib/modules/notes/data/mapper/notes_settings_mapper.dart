import 'dart:convert';

import 'package:bimir_lock/modules/notes/data/model/model.dart';
import 'package:bimir_lock/modules/notes/domain/entity/entity.dart';
import 'package:bimir_lock/modules/notes/utils/utils.dart';

class NotesSettingsMapper {
  NotesSettingsMapper._();

  static NotesSettingsEntity toEntity(NotesSettingsModel model) {
    return NotesSettingsEntity(
      sortOrder: NoteSortOrder.fromName(model.sortOrder),
      pinnedFirst: model.pinnedFirst,
      grouping: model.grouping == null
          ? null
          : NoteGrouping.fromName(model.grouping),
      viewMode: model.viewMode == null
          ? null
          : NoteViewMode.fromName(model.viewMode),
      defaultColorName: model.defaultColorName,
    );
  }

  static NotesSettingsModel toModel(NotesSettingsEntity entity) {
    return NotesSettingsModel(
      sortOrder: entity.sortOrder?.name,
      pinnedFirst: entity.pinnedFirst,
      grouping: entity.grouping?.name,
      viewMode: entity.viewMode?.name,
      defaultColorName: entity.defaultColorName,
    );
  }

  static NotesSettingsEntity fromJsonToEntity(Map<String, dynamic> json) {
    return toEntity(NotesSettingsModel.fromJson(json));
  }

  static NotesSettingsEntity fromRawJsonToEntity(String rawJson) {
    return toEntity(NotesSettingsModel.fromJson(jsonDecode(rawJson)));
  }

  static Map<String, dynamic> toJsonFromEntity(NotesSettingsEntity entity) {
    return toModel(entity).toJson();
  }

  static String toRawJsonFromEntity(NotesSettingsEntity entity) {
    return jsonEncode(toModel(entity).toJson());
  }

  static List<NotesSettingsEntity> fromJsonListToEntityList(
    List<dynamic> jsonList,
  ) {
    return jsonList
        .map((json) => fromJsonToEntity(json as Map<String, dynamic>))
        .toList();
  }

  static List<NotesSettingsEntity> fromRawJsonListToEntityList(
    String rawJsonList,
  ) {
    final List<dynamic> jsonList = jsonDecode(rawJsonList);
    return jsonList
        .map((json) => fromJsonToEntity(json as Map<String, dynamic>))
        .toList();
  }

  static List<Map<String, dynamic>> toJsonListFromEntityList(
    List<NotesSettingsEntity> entities,
  ) {
    return entities.map((entity) => toJsonFromEntity(entity)).toList();
  }

  static String toRawJsonListFromEntityList(
    List<NotesSettingsEntity> entities,
  ) {
    final List<Map<String, dynamic>> jsonList = entities
        .map((entity) => toJsonFromEntity(entity))
        .toList();
    return jsonEncode(jsonList);
  }
}
