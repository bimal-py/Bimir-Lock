import 'package:flutter/material.dart';
import 'package:bimir_lock/modules/notes/presentation/widgets/widgets.dart';

/// Contents of a single notes folder — the same browser as the Notes tab, scoped
/// to one folder via [folderId]. Pushed from a folder card, so it keeps the back
/// arrow and can recurse into sub-folders.
class FolderScreen extends StatelessWidget {
  const FolderScreen({super.key, required this.folderId});

  final String folderId;

  @override
  Widget build(BuildContext context) => NotesBrowser(folderId: folderId);
}
