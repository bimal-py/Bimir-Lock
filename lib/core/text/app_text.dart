import 'package:flutter/material.dart';
import 'package:bimir_lock/core/text/font_scale.dart';

/// Drop-in [Text] replacement that applies a per-language font scale so text
/// renders at consistent visual size across scripts.
///
/// Use this everywhere you'd write `Text(...)` in the app. The scale is
/// configured in [AppTextScale].
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.textDirection,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textScaler,
    this.semanticsLabel,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextScaler? textScaler;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.maybeLocaleOf(context)?.languageCode;
    final scale = AppTextScale.of(lang);

    final base = style ?? DefaultTextStyle.of(context).style;
    final scaledStyle = (scale != 1.0 && base.fontSize != null)
        ? base.copyWith(fontSize: base.fontSize! * scale)
        : style;

    return Text(
      data,
      style: scaledStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textScaler: textScaler,
      semanticsLabel: semanticsLabel,
    );
  }
}
