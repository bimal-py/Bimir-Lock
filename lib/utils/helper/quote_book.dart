import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class Quote {
  const Quote({required this.text, required this.author, this.source});

  final String text;
  final String author;
  final String? source;

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
    text: json['text'] as String,
    author: json['author'] as String,
    source: json['source'] as String?,
  );
}

/// The launch-screen quotes: a fixed, checked list shipped with the app
/// (assets/quotes/quotes.json). No network, no API key, no account.
class QuoteBook {
  static const String asset = 'assets/quotes/quotes.json';

  /// Shown if the list cannot be read for any reason.
  static const Quote fallback = Quote(
    text: 'Three may keep a secret, if two of them are dead.',
    author: 'Benjamin Franklin',
    source: "Poor Richard's Almanack, 1735",
  );

  static List<Quote>? _all;

  static Future<List<Quote>> all({AssetBundle? bundle}) async {
    if (_all != null) return _all!;
    try {
      // Decoded here rather than with loadString, which hands files over 50 KB
      // to a background isolate; for one small file that only adds latency.
      final ByteData data = await (bundle ?? rootBundle).load(asset);
      final String raw = utf8.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      _all = list
          .map((dynamic e) => Quote.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      _all = const <Quote>[fallback];
    }
    return _all!;
  }

  static Future<Quote> random({Random? rng}) async {
    final List<Quote> quotes = await all();
    if (quotes.isEmpty) return fallback;
    return quotes[(rng ?? Random()).nextInt(quotes.length)];
  }
}
