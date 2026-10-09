import 'dart:async';
import 'dart:math';

import 'package:bimir_lock/ui/tokens.dart';
import 'package:flutter/material.dart';

/// What a hidden password looks like. Always the same length, so the mask does
/// not give away how long the real one is.
const String secretMask = '••••••••••';

enum _Kind { letter, digit, symbol }

_Kind _kindOf(String ch) {
  final int c = ch.codeUnitAt(0);
  if (c >= 48 && c <= 57) return _Kind.digit;
  if ((c >= 65 && c <= 90) || (c >= 97 && c <= 122)) return _Kind.letter;
  return _Kind.symbol;
}

/// A password as spans: letters in the text colour, digits in [BimirPalette.digit]
/// and symbols in the brand colour, so look-alikes (O/0, l/1) and the "shape" of
/// a password can be read at a glance.
TextSpan colouredSecret(String value, TextStyle base, BimirPalette p) {
  final List<TextSpan> spans = <TextSpan>[];
  final StringBuffer run = StringBuffer();
  _Kind? kind;
  void flush() {
    if (run.isEmpty) return;
    final Color colour = switch (kind!) {
      _Kind.letter => base.color ?? p.foreground,
      _Kind.digit => p.digit,
      _Kind.symbol => p.primary,
    };
    spans.add(
      TextSpan(
        text: run.toString(),
        style: TextStyle(color: colour),
      ),
    );
    run.clear();
  }

  for (final String ch in value.characters) {
    final _Kind k = ch.length == 1 ? _kindOf(ch) : _Kind.symbol;
    if (k != kind) {
      flush();
      kind = k;
    }
    run.write(ch);
  }
  flush();
  return TextSpan(style: base, children: spans);
}

/// A password that can be shown or hidden. Showing it plays a short "decode":
/// each character settles out of noise, left to right, in about a third of a
/// second. Skipped entirely when the OS asks for reduced motion.
class SecretText extends StatefulWidget {
  const SecretText({
    super.key,
    required this.value,
    required this.revealed,
    this.size = 20,
    this.maxLines,
  });

  final String value;
  final bool revealed;
  final double size;
  final int? maxLines;

  @override
  State<SecretText> createState() => _SecretTextState();
}

class _SecretTextState extends State<SecretText> {
  static const String _noise =
      'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789#%&*+=?@';
  final Random _random = Random();
  Timer? _timer;
  int _settled = 0; // characters already showing their real value
  bool _decoding = false;

  @override
  void didUpdateWidget(SecretText old) {
    super.didUpdateWidget(old);
    if (widget.revealed && (!old.revealed || old.value != widget.value)) {
      _start();
    } else if (!widget.revealed) {
      _stop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    if (Motion.reduced(context) || widget.value.isEmpty) {
      _decoding = false;
      return;
    }
    final int length = widget.value.characters.length;
    // ~320 ms whatever the length, never faster than one character a frame.
    final int steps = min(length, 20);
    _settled = 0;
    _decoding = true;
    int tick = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 16), (Timer t) {
      tick++;
      if (!mounted) return t.cancel();
      setState(() {
        _settled = (tick / steps * length).floor().clamp(0, length);
        if (_settled >= length) {
          _decoding = false;
          t.cancel();
        }
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    _decoding = false;
  }

  @override
  Widget build(BuildContext context) {
    final BimirPalette p = BimirPalette.of(context);
    final TextStyle base = BimirPalette.secret(context, size: widget.size);
    if (!widget.revealed) {
      return Text(
        secretMask,
        style: base.copyWith(color: p.muted, letterSpacing: 2),
        semanticsLabel: 'Password hidden',
        maxLines: 1,
      );
    }
    String shown = widget.value;
    if (_decoding) {
      final List<String> chars = widget.value.characters.toList();
      for (int i = _settled; i < chars.length; i++) {
        chars[i] = _noise[_random.nextInt(_noise.length)];
      }
      shown = chars.join();
    }
    return Semantics(
      label: 'Password',
      value: widget.value,
      child: ExcludeSemantics(
        child: Text.rich(
          colouredSecret(shown, base, p),
          maxLines: widget.maxLines,
          softWrap: true,
        ),
      ),
    );
  }
}

/// A controller for password fields that colours digits and symbols the same
/// way as [SecretText] while the value is visible. Obscured fields ignore it.
class SecretEditingController extends TextEditingController {
  SecretEditingController({super.text});

  BimirPalette? palette;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final BimirPalette p = palette ?? BimirPalette.of(context);
    if (value.composing.isValid && withComposing) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    return colouredSecret(text, style ?? const TextStyle(), p);
  }
}
