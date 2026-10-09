import 'package:bimir_lock/utils/helper/faq_search.dart';
import 'package:bimir_lock/views/faq/faq_entries.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FaqSearch search = FaqSearch(faqEntries);

  String? best(String query) => search.search(query).best?.question;

  List<String> all(String query) {
    final FaqResults r = search.search(query);
    return <String>[
      if (r.best != null) r.best!.question,
      ...r.related.map((FaqEntry e) => e.question),
    ];
  }

  test('every topic has questions, and no question is asked twice', () {
    for (final FaqTopic topic in FaqTopic.values) {
      expect(
        faqEntries.where((FaqEntry e) => e.topic == topic),
        isNotEmpty,
        reason: topic.label,
      );
    }
    final Set<String> questions = faqEntries
        .map((FaqEntry e) => e.question)
        .toSet();
    expect(questions.length, faqEntries.length);
  });

  test('a question asked in its own words is the best match', () {
    expect(best('I forgot my PIN'), 'I forgot my PIN. What can I do?');
    expect(best('is there cloud sync'), 'Is there an account or cloud sync?');
    expect(best('are my notes encrypted'), 'Are my Notes encrypted?');
  });

  test('other words for the same thing land on the same answer', () {
    expect(
      all('lost my passcode'),
      contains('I forgot my PIN. What can I do?'),
    );
    expect(all('export passwords'), contains('How do I back up my passwords?'));
    expect(
      all('transfer to new phone'),
      contains('How do I move my passwords to a new phone?'),
    );
    expect(
      all('was my password hacked'),
      contains('Does Bimir Lock tell me if a password was leaked?'),
    );
    expect(all('face id'), isNotEmpty);
  });

  test('small typos still find the answer', () {
    expect(
      all('pasword generater'),
      contains('How does the password generator work?'),
    );
    expect(
      all('autofil iphone'),
      contains('How do I turn on AutoFill on iPhone or iPad?'),
    );
  });

  test('nothing for nonsense, and nothing for an empty query', () {
    expect(search.search('zebra helicopter').isEmpty, isTrue);
    expect(search.search('   ').isEmpty, isTrue);
  });

  test('answers never promise what the app does not do', () {
    final RegExp claims = RegExp(
      r'\b(syncs across|military|unhackable|zero[- ]knowledge|dark web)\b',
      caseSensitive: false,
    );
    for (final FaqEntry e in faqEntries) {
      expect(claims.hasMatch(e.answer), isFalse, reason: e.question);
    }
  });
}
