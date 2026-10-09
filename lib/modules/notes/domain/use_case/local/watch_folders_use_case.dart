import 'package:bimir_lock/common/common.dart';
import 'package:bimir_lock/modules/notes/domain/entity/entity.dart';
import 'package:bimir_lock/modules/notes/domain/repository/local/local_notes_repository.dart';

class WatchFoldersUseCase
    extends StreamUseCase<List<NoteFolderEntity>, NoParams> {
  WatchFoldersUseCase(this._repository);

  final LocalNotesRepository _repository;

  @override
  Stream<List<NoteFolderEntity>> execute(NoParams params) =>
      _repository.watchFolders();
}
