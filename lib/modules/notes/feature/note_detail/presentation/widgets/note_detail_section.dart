import 'package:flutter/material.dart';
import 'package:bimir_lock/core/core.dart';

/// White rounded card with a bold heading and arbitrary content below — the
/// repeating block used for Title / Description / Attachments / Voice Notes.
class NoteDetailSection extends StatelessWidget {
  const NoteDetailSection({
    super.key,
    required this.heading,
    required this.child,
  });

  final String heading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heading,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colorScheme.onSurface,
              ),
            ),
            12.verticalSpace,
            child,
          ],
        ),
      ),
    );
  }
}
