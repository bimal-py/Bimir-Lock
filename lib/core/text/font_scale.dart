/// Per-language font-size multipliers.
///
/// Some scripts (e.g. Devanagari, Bengali, Arabic) render visually smaller
/// than Latin at the same `fontSize` because of x-height / cap-height
/// differences. Use this map to apply a per-language scale so all languages
/// look balanced.
///
/// Read by [AppText] — every text widget in the app should go through it
/// (or apply [AppTextScale.of] manually) so the scale is consistent.
///
/// `flutter_scale_kit` ships a `scale` field on `LanguageFontConfig`, but the
/// package never multiplies `baseTextStyle.fontSize` by it — so the field is
/// effectively dead. We do it ourselves here.
class AppTextScale {
  AppTextScale._();

  static const Map<String, double> _scales = {
    // 'ne': 1.10,  // Nepali / Devanagari
    // 'bn': 1.10,  // Bengali
    // 'ar': 1.05,  // Arabic
    // Default for any language not listed here is 1.0.
  };

  static double of(String? languageCode) {
    if (languageCode == null) return 1.0;
    return _scales[languageCode] ?? 1.0;
  }
}
