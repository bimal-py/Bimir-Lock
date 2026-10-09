import 'package:flutter/material.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/modules/notes/feature/note_detail/presentation/widgets/note_attachment_thumb.dart';
import 'package:bimir_lock/modules/notes/feature/note_detail/presentation/widgets/note_attachment_tile.dart';

/// Body of the Attachments section: file rows stacked over a wrapping row of
/// image thumbnails.
class NoteAttachmentsBlock extends StatelessWidget {
  const NoteAttachmentsBlock({super.key});

  // TODO: wire data — placeholder attachments until the data layer lands.
  static const List<String> _files = [
    'ProjectX_Invoice_June2025.pdf',
    'ExpenseReport_May2025.xlsx',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, file) in _files.indexed) ...[
          if (index > 0) 12.verticalSpace,
          NoteAttachmentTile(
            fileName: file,
            onRemove: () {}, // TODO: wire data — remove attachment
          ),
        ],
        16.verticalSpace,
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: [
            for (var i = 0; i < 2; i++)
              NoteAttachmentThumb(
                imagePath: AssetRoutes.defaultImage,
                onRemove: () {}, // TODO: wire data — remove image
              ),
          ],
        ),
      ],
    );
  }
}
