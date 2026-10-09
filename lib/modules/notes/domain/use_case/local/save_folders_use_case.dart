import 'dart:async';

import 'package:bimir_lock/common/common.dart';
import 'package:bimir_lock/modules/notes/domain/entity/entity.dart';
import 'package:bimir_lock/modules/notes/domain/repository/local/local_notes_repository.dart';

class SaveFoldersUseCase extends UseCase<void, List<NoteFolderEntity>> {
  SaveFoldersUseCase(this._repository);

  final LocalNotesRepository _repository;

  @override
  FutureOr<void> execute(List<NoteFolderEntity> params) =>
      _repository.saveFolders(params);
}
