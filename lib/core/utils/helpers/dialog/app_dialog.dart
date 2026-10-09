import 'package:flutter/material.dart';

/// Scales and fades a dialog in, as the Callbreak Tracker app's popups do.
class CenterPopup extends StatefulWidget {
  const CenterPopup({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutBack,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  State<CenterPopup> createState() => _CenterPopupState();
}

class _CenterPopupState extends State<CenterPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.9,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
          ? _controller.value = 1
          : _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(opacity: _fade, child: widget.child),
    );
  }
}

/// The app's one dialog look (from the Callbreak Tracker app): an icon in a
/// soft circle of its colour, a centred bold title and message, anything
/// extra in [body], then [actions]. Scrolls instead of overflowing when a
/// long message meets a short screen or large text.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    this.message,
    this.body,
    this.actions,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String? message;
  final Widget? body;

  /// Usually a [DialogActions] row.
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final ColorScheme s = Theme.of(context).colorScheme;
    final TextTheme t = Theme.of(context).textTheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: s.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: accent, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: t.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: s.onSurface,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
                ),
              ],
              if (body != null) ...[const SizedBox(height: 16), body!],
              if (actions != null) ...[const SizedBox(height: 20), actions!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Cancel (outlined) and the action (filled, red when [destructive]) side by
/// side, or the action alone across the width when there is no cancel.
class DialogActions extends StatelessWidget {
  const DialogActions({
    super.key,
    required this.confirmText,
    required this.onConfirm,
    this.cancelText,
    this.onCancel,
    this.destructive = false,
    this.busy = false,
  });

  final String confirmText;

  /// Null disables the button (e.g. while working).
  final VoidCallback? onConfirm;

  /// Null leaves the cancel button out.
  final String? cancelText;
  final VoidCallback? onCancel;
  final bool destructive;

  /// Shows a small spinner in the action button.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final ColorScheme s = Theme.of(context).colorScheme;
    const Size min = Size(0, 48);
    final Widget confirm = FilledButton(
      onPressed: busy ? null : onConfirm,
      style: FilledButton.styleFrom(
        minimumSize: min,
        backgroundColor: destructive ? s.error : null,
        foregroundColor: destructive ? s.onError : null,
      ),
      child: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(confirmText, textAlign: TextAlign.center),
    );
    if (cancelText == null) {
      return SizedBox(width: double.infinity, child: confirm);
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel ?? () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(minimumSize: min),
            child: Text(cancelText!, textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: confirm),
      ],
    );
  }
}
