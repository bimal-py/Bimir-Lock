import 'package:flutter/material.dart';
import 'package:bimir_lock/core/core.dart';

/// Body of the Description section: an intro paragraph, a lead-in line, and a
/// bullet list. Content is placeholder until the data layer is wired.
class NoteDetailDescription extends StatelessWidget {
  const NoteDetailDescription({super.key});

  // TODO: wire data — placeholder description.
  static const String _intro =
      'Prepare and send the final invoice for Project X to the client by '
      '5:00 PM.';
  static const String _leadIn = 'Make sure to:';
  static const List<String> _bullets = [
    'Double-check itemized charges',
    'Include payment terms (Net 7)',
    'Attach any required receipts or supporting documents',
    'Send via client’s preferred email: client@example.com',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final body = context.textTheme.bodyMedium?.copyWith(
      color: colors.onSurface,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_intro, style: body),
        16.verticalSpace,
        Text(_leadIn, style: body),
        8.verticalSpace,
        for (final bullet in _bullets)
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: body),
                Expanded(child: Text(bullet, style: body)),
              ],
            ),
          ),
      ],
    );
  }
}
