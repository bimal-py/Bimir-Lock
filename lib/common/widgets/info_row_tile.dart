import 'package:flutter/material.dart';
import 'package:bimir_lock/core/core.dart';

/// Two-line tile for displaying a labelled value (key + stringified value).
/// Shared between modules that render flat key/value tables.
class InfoRowTile extends StatelessWidget {
  const InfoRowTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListTile(
        dense: true,
        title: Text(
          label,
          style: context.textTheme.labelMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
