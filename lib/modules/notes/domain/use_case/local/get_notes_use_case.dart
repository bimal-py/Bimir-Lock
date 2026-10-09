import 'dart:async';

import 'package:bimir_lock/common/common.dart';
import 'package:bimir_lock/modules/notes/domain/entity/entity.dart';
import 'package:bimir_lock/modules/notes/domain/repository/local/local_notes_repository.dart';

class GetNotesUseCase extends UseCase<List<NoteEntity>, NoParams> {
  GetNotesUseCase(this._repository);

  final LocalNotesRepository _repository;

  @override
  FutureOr<List<NoteEntity>> execute(NoParams params) => _repository.getNotes();
}
