import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/core/core.dart';

/// Voice-note row: a play control next to a static waveform. Playback is
/// placeholder until audio is wired.
class NoteVoicePlayer extends StatelessWidget {
  const NoteVoicePlayer({super.key, this.onPlay});

  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          InkResponse(
            onTap: onPlay,
            radius: 24.r,
            child: Icon(LucideIcons.play, size: 26.r, color: colors.onSurface),
          ),
          14.horizontalSpace,
          Expanded(
            child: CustomPaint(
              size: Size(double.infinity, 36.h),
              painter: _WaveformPainter(
                played: colors.onSurface,
                remaining: colors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({required this.played, required this.remaining});

  final Color played;
  final Color remaining;

  // Deterministic bar heights (0..1) so the waveform is stable across rebuilds.
  static const List<double> _bars = [
    0.30,
    0.55,
    0.80,
    0.45,
    0.65,
    1.00,
    0.50,
    0.35,
    0.70,
    0.85,
    0.40,
    0.60,
    0.95,
    0.55,
    0.30,
    0.75,
    0.50,
    0.65,
    0.45,
    0.90,
    0.35,
    0.55,
    0.70,
    0.40,
    0.80,
    0.50,
    0.60,
    0.30,
    0.45,
    0.25,
  ];

  // Fraction of the clip considered "played" (just colours the bars).
  static const double _progress = 0.7;

  @override
  void paint(Canvas canvas, Size size) {
    final count = _bars.length;
    final slot = size.width / count;
    final barWidth = slot * 0.4;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;
    final mid = size.height / 2;
    final playedUntil = size.width * _progress;

    for (var i = 0; i < count; i++) {
      final x = slot * i + slot / 2;
      final half = (_bars[i] * size.height) / 2;
      paint.color = x <= playedUntil ? played : remaining;
      canvas.drawLine(Offset(x, mid - half), Offset(x, mid + half), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.played != played || oldDelegate.remaining != remaining;
}
