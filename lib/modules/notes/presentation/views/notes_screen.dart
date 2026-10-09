import 'package:flutter/material.dart';
import 'package:bimir_lock/modules/notes/presentation/widgets/widgets.dart';

/// "Notes" tab — the root of the notes browser (folders + notes). All of the
/// listing, search, sort/view, multi-select and folder management lives in the
/// shared [NotesBrowser], which folder screens reuse with a folder id.
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) => const NotesBrowser();
}
