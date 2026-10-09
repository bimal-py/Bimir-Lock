import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final String raw = utf8.decode(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
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

/// A quote and when it was last on the opening screen.
class SeenQuote {
  const SeenQuote(this.quote, this.at);

  final Quote quote;
  final DateTime at;
}

/// The quotes the opening screen has shown, newest first, so one that went by
/// too fast can be read again (Settings › Quotes). Kept on this phone in the
/// app's preferences; a quote seen again moves back to the top.
class QuoteHistory {
  QuoteHistory._();

  static const String _key = 'quote_history';

  /// The newest this many are kept.
  static const int keep = 50;

  static Future<void> add(Quote q, {DateTime? at}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> raw = prefs.getStringList(_key) ?? <String>[];
      final List<String> kept = <String>[
        jsonEncode(<String, Object?>{
          'text': q.text,
          'author': q.author,
          'source': q.source,
          'at': (at ?? DateTime.now()).millisecondsSinceEpoch,
        }),
        for (final String r in raw)
          if (_text(r) != q.text) r,
      ];
      await prefs.setStringList(_key, kept.take(keep).toList());
    } catch (_) {
      // A quote that is not remembered must never get in the way of opening.
    }
  }

  static Future<List<SeenQuote>> all() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<SeenQuote> out = <SeenQuote>[];
    for (final String r in prefs.getStringList(_key) ?? <String>[]) {
      try {
        final Map<String, dynamic> m = jsonDecode(r) as Map<String, dynamic>;
        out.add(
          SeenQuote(
            Quote.fromJson(m),
            DateTime.fromMillisecondsSinceEpoch(m['at'] as int),
          ),
        );
      } catch (_) {
        // A damaged entry is skipped, not fatal.
      }
    }
    return out;
  }

  static Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static String? _text(String raw) {
    try {
      return (jsonDecode(raw) as Map<String, dynamic>)['text'] as String?;
    } catch (_) {
      return null;
    }
  }
}
