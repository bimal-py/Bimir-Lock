import 'dart:async';

import 'package:bimir_lock/common/common.dart';
import 'package:bimir_lock/modules/notes/domain/entity/entity.dart';
import 'package:bimir_lock/modules/notes/domain/repository/local/local_notes_repository.dart';

class GetNotesSettingsUseCase extends UseCase<NotesSettingsEntity, NoParams> {
  GetNotesSettingsUseCase(this._repository);

  final LocalNotesRepository _repository;

  @override
  FutureOr<NotesSettingsEntity> execute(NoParams params) =>
      _repository.getSettings();
}
