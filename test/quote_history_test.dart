import 'package:bimir_lock/utils/helper/quote_book.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  const Quote a = Quote(text: 'A', author: 'Ann');
  const Quote b = Quote(text: 'B', author: 'Ben', source: 'Book');

  test('newest first, and a quote seen again moves back to the top', () async {
    await QuoteHistory.add(a, at: DateTime(2026, 10, 1));
    await QuoteHistory.add(b, at: DateTime(2026, 10, 2));
    expect(
      (await QuoteHistory.all()).map((SeenQuote s) => s.quote.text),
      <String>['B', 'A'],
    );

    await QuoteHistory.add(a, at: DateTime(2026, 10, 3));
    final List<SeenQuote> seen = await QuoteHistory.all();
    expect(seen.map((SeenQuote s) => s.quote.text), <String>['A', 'B']);
    expect(seen.first.at, DateTime(2026, 10, 3));
    expect(seen.last.quote.source, 'Book');
  });

  test('keeps only the newest ${QuoteHistory.keep}, and clears', () async {
    for (int i = 0; i < QuoteHistory.keep + 5; i++) {
      await QuoteHistory.add(
        Quote(text: 'q$i', author: 'x'),
        at: DateTime(2026, 1, 1).add(Duration(minutes: i)),
      );
    }
    final List<SeenQuote> seen = await QuoteHistory.all();
    expect(seen.length, QuoteHistory.keep);
    expect(seen.first.quote.text, 'q${QuoteHistory.keep + 4}');
    await QuoteHistory.clear();
    expect(await QuoteHistory.all(), isEmpty);
  });
}
