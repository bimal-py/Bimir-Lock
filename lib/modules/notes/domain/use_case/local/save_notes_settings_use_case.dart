import 'dart:async';

import 'package:bimir_lock/common/common.dart';
import 'package:bimir_lock/modules/notes/domain/entity/entity.dart';
import 'package:bimir_lock/modules/notes/domain/repository/local/local_notes_repository.dart';

class SaveNotesSettingsUseCase extends UseCase<void, NotesSettingsEntity> {
  SaveNotesSettingsUseCase(this._repository);

  final LocalNotesRepository _repository;

  @override
  FutureOr<void> execute(NotesSettingsEntity params) =>
      _repository.saveSettings(params);
}
