import 'package:bimir_lock/common/common.dart';
import 'package:bimir_lock/modules/notes/domain/entity/entity.dart';
import 'package:bimir_lock/modules/notes/domain/repository/local/local_notes_repository.dart';

class WatchNotesUseCase extends StreamUseCase<List<NoteEntity>, NoParams> {
  WatchNotesUseCase(this._repository);

  final LocalNotesRepository _repository;

  @override
  Stream<List<NoteEntity>> execute(NoParams params) => _repository.watchNotes();
}
