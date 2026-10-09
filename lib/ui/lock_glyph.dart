import 'package:bimir_lock/ui/tokens.dart';
import 'package:flutter/material.dart';

/// A padlock drawn in the same stroke weight as the outline icons. The shackle
/// lifts when [open] becomes true, so unlocking something is something you
/// see happen rather than a screen that just appears.
class LockGlyph extends StatelessWidget {
  const LockGlyph({
    super.key,
    this.open = false,
    this.size = 40,
    this.color,
    this.strokeWidth,
  });

  final bool open;
  final double size;
  final Color? color;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? BimirPalette.of(context).foreground;
    return Semantics(
      label: open ? 'Unlocked' : 'Locked',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: open ? 1 : 0),
        duration: Motion.reduced(context) ? Duration.zero : Motion.slow,
        curve: Curves.easeOutBack,
        builder: (BuildContext context, double t, _) => CustomPaint(
          size: Size.square(size),
          painter: _LockPainter(
            open: t,
            color: c,
            stroke: strokeWidth ?? (size / 16).clamp(1.5, 3.5),
          ),
        ),
      ),
    );
  }
}

class _LockPainter extends CustomPainter {
  _LockPainter({required this.open, required this.color, required this.stroke});

  final double open;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    // Body: the lower 55%.
    final Rect body = Rect.fromLTWH(w * 0.16, h * 0.42, w * 0.68, h * 0.50);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(w * 0.08)),
      line,
    );

    // Keyhole: a dot and a short slot.
    final Paint fill = Paint()..color = color;
    final Offset hole = Offset(w * 0.5, body.top + body.height * 0.42);
    canvas.drawCircle(hole, w * 0.055, fill);
    canvas.drawLine(hole, Offset(w * 0.5, body.top + body.height * 0.70), line);

    // Shackle: a U whose legs go into the body. Opening lifts it and swings
    // the right leg clear of its hole.
    final double lift = h * 0.14 * open;
    final double legX1 = w * 0.30;
    final double legX2 = w * 0.70;
    final double top = h * 0.08 - lift;
    final double r = (legX2 - legX1) / 2;
    final Path shackle = Path()
      ..moveTo(legX1, body.top - lift * 0.2)
      ..lineTo(legX1, top + r)
      ..arcToPoint(Offset(legX2, top + r), radius: Radius.circular(r))
      ..lineTo(legX2, body.top - h * 0.16 * open - lift * 0.2);
    canvas.drawPath(shackle, line);
  }

  @override
  bool shouldRepaint(_LockPainter old) =>
      old.open != open || old.color != color || old.stroke != stroke;
}
