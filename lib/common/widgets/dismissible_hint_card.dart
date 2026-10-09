import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A soft, one-time tip card the user can dismiss. The dismissed state is
/// persisted under [storageKey] (SharedPreferences), so a hint a user has
/// learned never nags again. Renders nothing once dismissed.
class DismissibleHintCard extends StatefulWidget {
  const DismissibleHintCard({
    super.key,
    required this.storageKey,
    required this.icon,
    required this.message,
  });

  final String storageKey;
  final IconData icon;
  final String message;

  @override
  State<DismissibleHintCard> createState() => _DismissibleHintCardState();
}

class _DismissibleHintCardState extends State<DismissibleHintCard> {
  bool? _dismissed; // null while loading

  static String _key(String k) => 'hint_dismissed_$k';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _dismissed = prefs.getBool(_key(widget.storageKey)) ?? false);
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(widget.storageKey), true);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed ?? true) return const SizedBox.shrink();
    final colors = context.colorScheme;
    final accent = context.customTheme.brandAccent;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 6.w, 10.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(widget.icon, size: 18.r, color: accent),
          10.horizontalSpace,
          Expanded(
            child: Text(
              widget.message,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Got it',
            visualDensity: VisualDensity.compact,
            icon: Icon(LucideIcons.x, size: 16.r, color: colors.onSurfaceVariant),
            onPressed: _dismiss,
          ),
        ],
      ),
    );
  }
}
