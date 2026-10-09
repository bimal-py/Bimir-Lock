import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/modules/notes/notes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;
import 'package:hive_flutter/hive_flutter.dart';

/// The seams between the app shell and the Notes module (ported from the
/// Reminder Note app). The shell calls these and knows nothing else about
/// Notes; the module fills them in.

/// Opens Notes' storage. Called once from main() before runApp.
Future<void> bootstrapNotes() async {
  await Hive.initFlutter();
  await registerNotes();
}

/// Opens the notes Hive box and registers the module's repository, use cases
/// and the app-wide [NotesCubit] with [getIt] — what Reminder Note's
/// injectable config and global bloc providers do. Hive must already be
/// initialised (`Hive.initFlutter()` in the app, `Hive.init(dir)` in tests).
/// Safe to call more than once.
Future<void> registerNotes() async {
  if (!Hive.isBoxOpen(NotesStorageKeys.boxName)) await Hive.openNotesBox();

  void lazy<T extends Object>(T Function() create) {
    if (!getIt.isRegistered<T>()) getIt.registerLazySingleton<T>(create);
  }

  void factory<T extends Object>(T Function() create) {
    if (!getIt.isRegistered<T>()) getIt.registerFactory<T>(create);
  }

  lazy<LocalNotesRepository>(LocalNotesRepositoryImpl.new);
  factory(() => GetNotesUseCase(getIt()));
  factory(() => SaveNotesUseCase(getIt()));
  factory(() => WatchNotesUseCase(getIt()));
  factory(() => GetFoldersUseCase(getIt()));
  factory(() => SaveFoldersUseCase(getIt()));
  factory(() => WatchFoldersUseCase(getIt()));
  factory(() => GetNotesSettingsUseCase(getIt()));
  factory(() => SaveNotesSettingsUseCase(getIt()));
  // One notes store for every Notes screen, loaded up front like Reminder
  // Note's eager `BlocProvider<NotesCubit>(lazy: false)`.
  lazy<NotesCubit>(() => NotesCubit()..load());
  getIt<NotesCubit>();
}

/// Localizations the Notes editor needs in the MaterialApp.
const List<LocalizationsDelegate<dynamic>> notesLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[FlutterQuillLocalizations.delegate];

/// Named routes for Notes, or null when [settings] is not a Notes route.
Route<dynamic>? notesGeneratedRoute(RouteSettings settings) {
  final Object? args = settings.arguments;
  final Widget? page = switch (settings.name) {
    NotesRoutes.home => const NotesScreen(),
    NotesRoutes.addNote => AddNoteScreen(
      note: args is NoteEntity ? args : null,
    ),
    NotesRoutes.noteDetail => NoteDetailScreen(
      note: args is NoteEntity ? args : null,
    ),
    NotesRoutes.folder => FolderScreen(folderId: args is String ? args : ''),
    NotesRoutes.notesSettings => const NotesSettingsScreen(),
    NotesRoutes.notesArchive => const ArchivedNotesScreen(),
    _ => null,
  };
  if (page == null) return null;
  // Reminder Note provides the cubit above its MaterialApp; here every Notes
  // route gets the same app-wide instance.
  return MaterialPageRoute<dynamic>(
    settings: settings,
    builder: (_) =>
        BlocProvider<NotesCubit>.value(value: getIt<NotesCubit>(), child: page),
  );
}

/// The Notes home screen's route name.
const String notesHomeRoute = '/notes';
