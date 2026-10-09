import 'dart:math' as math;
import 'dart:ui';

import 'dart:io';

import 'package:flutter/material.dart';

/// Opens [file] large over a blurred screen, the way a profile picture
/// opens in Instagram: a big round photo with a soft shadow, the [name] (a
/// caption) under it. Ported from the Callbreak Tracker app's avatar preview.
///
/// Out again by tapping anywhere off the photo, or by dragging it away — a
/// short drag springs back. Pinch grows the whole photo about the point
/// between the fingers, a double tap zooms to where it lands, and a zoomed
/// photo pans under one finger.
///
/// [from] is where the small avatar sits on screen: the photo grows out of
/// it on the way in and shrinks back into it on the way out. Without it the
/// photo fades in where it ends up.
Future<void> showPhotoPreview(
  BuildContext context, {
  required File file,
  String? name,
  Rect? from,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, _) => _AvatarPreview(
        file: file,
        name: name,
        from: from,
        entrance: animation,
      ),
    ),
  );
}

/// Where [context]'s widget is drawn on screen, as the square a round
/// avatar fills — the place the preview grows out of.
Rect? photoRect(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  final rect = box.localToGlobal(Offset.zero) & box.size;
  final side = math.min(rect.width, rect.height);
  return Rect.fromCenter(center: rect.center, width: side, height: side);
}

enum _Gesture { drag, zoom, pan }

class _AvatarPreview extends StatefulWidget {
  const _AvatarPreview({
    required this.file,
    required this.name,
    required this.from,
    required this.entrance,
  });

  final File file;
  final String? name;
  final Rect? from;

  /// The route's own animation: the photo's flight out of the avatar and
  /// back, and the blur coming up behind it.
  final Animation<double> entrance;

  @override
  State<_AvatarPreview> createState() => _AvatarPreviewState();
}

class _AvatarPreviewState extends State<_AvatarPreview>
    with SingleTickerProviderStateMixin {
  static const double _maxZoom = 4;
  static const double _doubleTapZoom = 2.5;

  /// How far the photo has been dragged towards the way out.
  Offset _drag = Offset.zero;

  /// Zoom inside the circle, and where the zoomed photo has been moved to.
  double _scale = 1;
  Offset _pan = Offset.zero;

  _Gesture? _gesture;
  double _scaleAtStart = 1;
  Offset _lastFocal = Offset.zero;
  bool _closing = false;

  /// Springs the photo back — from a short drag, an undone zoom, a double tap.
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late Offset _dragFrom, _dragTo, _panFrom, _panTo;
  late double _scaleFrom, _scaleTo;

  /// The flight: quick off the avatar and settling into place, and on the
  /// way back gathering speed into the avatar.
  late final CurvedAnimation _flight = CurvedAnimation(
    parent: widget.entrance,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void initState() {
    super.initState();
    _settle.addListener(() {
      final t = Curves.easeOutCubic.transform(_settle.value);
      setState(() {
        _drag = Offset.lerp(_dragFrom, _dragTo, t)!;
        _pan = Offset.lerp(_panFrom, _panTo, t)!;
        _scale = lerpDouble(_scaleFrom, _scaleTo, t)!;
      });
    });
  }

  @override
  void dispose() {
    _flight.dispose();
    _settle.dispose();
    super.dispose();
  }

  void _animateTo({Offset? drag, Offset? pan, double? scale}) {
    _dragFrom = _drag;
    _panFrom = _pan;
    _scaleFrom = _scale;
    _dragTo = drag ?? _drag;
    _panTo = pan ?? _pan;
    _scaleTo = scale ?? _scale;
    _settle.forward(from: 0);
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  /// A zoomed photo still covers the whole circle: it can be moved only as
  /// far as its overhang.
  Offset _clampPan(Offset pan, double diameter, double scale) {
    final limit = diameter * (scale - 1) / 2;
    return Offset(
      pan.dx.clamp(-limit, limit).toDouble(),
      pan.dy.clamp(-limit, limit).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flight,
      builder: (context, _) => _view(context, _flight.value),
    );
  }

  /// The view [progress] of the way through the flight in (0 = still the
  /// small avatar, 1 = settled large).
  Widget _view(BuildContext context, double progress) {
    final screen = MediaQuery.sizeOf(context);
    final diameter = math.min(
      math.min(screen.width, screen.height) * 0.78,
      380.0,
    );
    // How far through being dragged out the photo is: it shrinks a little
    // as it goes, and the blur thins, like the photo in Instagram.
    final away = (_drag.distance / (screen.height * 0.35)).clamp(0.0, 1.0);
    final presence = 1 - away;

    // Where the photo rests: the photo and the name under it centred
    // together, then wherever a drag has taken it.
    final nameRoom = widget.name == null ? 0.0 : 44.0;
    // Zoom grows the whole photo, past the edges of the screen if need be,
    // about wherever it has been moved to.
    final base =
        Offset(screen.width / 2, (screen.height - nameRoom) / 2) + _drag;
    final size = diameter * (1 - 0.18 * away) * _scale;
    final rest = Rect.fromCenter(
      center: base + _pan,
      width: size,
      height: size,
    );
    final from = widget.from;
    final photo = from == null
        ? Rect.fromCenter(
            center: rest.center,
            width: rest.width * lerpDouble(0.86, 1, progress)!,
            height: rest.height * lerpDouble(0.86, 1, progress)!,
          )
        : Rect.lerp(from, rest, progress)!;
    final shown = progress * presence;
    // The name steps aside while the photo is zoomed in.
    final nameShown = shown * (2 - _scale).clamp(0.0, 1.0);

    bool onPhoto(Offset point) =>
        (point - rest.center).distance <= rest.width / 2;

    return Semantics(
      // Tapping off the photo cannot be found by a screen reader, so the
      // way out is said out loud.
      label: widget.name == null
          ? 'Picture. Double tap to close.'
          : 'Picture of ${widget.name}. Double tap to close.',
      button: true,
      onTap: _close,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          if (!onPhoto(details.globalPosition)) _close();
        },
        onScaleStart: (details) {
          _settle.stop();
          _gesture = null;
          _scaleAtStart = _scale;
          _lastFocal = details.focalPoint;
        },
        onScaleUpdate: (details) {
          if (details.pointerCount >= 2) _gesture = _Gesture.zoom;
          _gesture ??= _scale > 1.01 ? _Gesture.pan : _Gesture.drag;
          final delta = details.focalPoint - _lastFocal;
          _lastFocal = details.focalPoint;
          setState(() {
            switch (_gesture!) {
              case _Gesture.zoom:
                // Grown about the point between the fingers, so what is
                // under them stays under them.
                final scale = (_scaleAtStart * details.scale).clamp(
                  1.0,
                  _maxZoom,
                );
                final centre = base + _pan;
                final grown =
                    details.focalPoint +
                    (centre - details.focalPoint) * (scale / _scale);
                _scale = scale;
                _pan = _clampPan(grown - base + delta, diameter, _scale);
              case _Gesture.pan:
                _pan = _clampPan(_pan + delta, diameter, _scale);
              case _Gesture.drag:
                _drag += delta;
            }
          });
        },
        onScaleEnd: (details) {
          switch (_gesture) {
            case _Gesture.drag:
              final flung = details.velocity.pixelsPerSecond.distance > 900;
              if (_drag.distance > 110 || flung) {
                // Back into the avatar from wherever it was let go.
                _close();
              } else {
                _animateTo(drag: Offset.zero);
              }
            case _Gesture.zoom:
            case _Gesture.pan:
              if (_scale < 1.05) _animateTo(scale: 1, pan: Offset.zero);
            case null:
              break;
          }
          _gesture = null;
        },
        child: Stack(
          children: [
            // Drawn stronger as the photo arrives rather than faded as a
            // layer: a blur under a fading layer does not fade with it.
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: (24 * presence + 4) * progress,
                  sigmaY: (24 * presence + 4) * progress,
                ),
                child: ColoredBox(
                  color: Colors.black.withValues(
                    alpha: (0.18 + 0.32 * presence) * progress,
                  ),
                ),
              ),
            ),
            // Laid out at its full size and scaled to the flight's, so the
            // picture is decoded once rather than at every size it passes.
            // Laid out once at full size and fitted to the flight's rectangle,
            // so the picture is decoded once rather than at every size it
            // passes — and so it is touchable over all of what is drawn.
            Positioned.fromRect(
              rect: photo,
              child: Opacity(
                opacity: from == null ? progress : 1,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox.square(
                    dimension: diameter,
                    child: GestureDetector(
                      onDoubleTapDown: (details) {
                        final zoomedIn = _scale > 1.01;
                        final towards =
                            details.localPosition -
                            Offset(diameter / 2, diameter / 2);
                        _animateTo(
                          scale: zoomedIn ? 1 : _doubleTapZoom,
                          pan: zoomedIn
                              ? Offset.zero
                              : _clampPan(
                                  -towards * (_doubleTapZoom - 1),
                                  diameter,
                                  _doubleTapZoom,
                                ),
                        );
                      },
                      onDoubleTap: () {},
                      child: _Photo(
                        file: widget.file,
                        diameter: diameter,
                        shadow: shown,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.name != null)
              Positioned(
                left: 0,
                right: 0,
                top: photo.bottom + 16,
                child: Opacity(
                  opacity: nameShown,
                  child: Text(
                    widget.name!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 12),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The round photo: a soft blurred shadow under it and a hairline ring round
/// it. Zoom and flight scale the whole of it from outside.
class _Photo extends StatelessWidget {
  const _Photo({
    required this.file,
    required this.diameter,
    required this.shadow,
  });

  final File file;
  final double diameter;

  /// 1 at rest, fading towards 0 as the photo is dragged away.
  final double shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1.5,
        ),
        boxShadow: [
          // Wide and soft, below — the photo floats off the blurred screen.
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6 * shadow),
            blurRadius: 56,
            spreadRadius: 2,
            offset: const Offset(0, 22),
          ),
          // Close and faint all round, so the edge never melts into a dark
          // background.
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25 * shadow),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.file(
          file,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => ColoredBox(
            color: Colors.black26,
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white70,
              size: diameter * 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
