/// A question and its answer, as the FAQ lists them.
class FaqEntry {
  const FaqEntry({
    required this.topic,
    required this.question,
    required this.answer,
    this.tags = const <String>[],
  });

  final FaqTopic topic;
  final String question;
  final String answer;

  /// Other words people use for what this answers — searched as well as the
  /// question, but never shown.
  final List<String> tags;
}

enum FaqTopic {
  unlock('PIN & unlock'),
  passwords('Passwords'),
  autofill('Autofill'),
  backup('Backup'),
  privacy('Privacy'),
  app('The app');

  const FaqTopic(this.label);

  final String label;
}

/// What a search found.
class FaqResults {
  const FaqResults({this.best, this.related = const <FaqEntry>[]});

  /// The question that is plainly the one asked, when there is one.
  final FaqEntry? best;

  /// Everything else that is about the same thing, closest first.
  final List<FaqEntry> related;

  bool get isEmpty => best == null && related.isEmpty;
}

/// Finds answers the way a person asks for them, with no package and no
/// network — the Callbreak Tracker app's FAQ search, with a password
/// manager's vocabulary.
///
/// A query and every entry are reduced to *concepts*: words lower-cased,
/// their endings trimmed (backups, backing → backup), filler words dropped,
/// and the many names for one thing folded into one — passcode and code are
/// pin, Face ID and fingerprint are biometric, export is backup, leak and
/// breach are one. A word not known at all is matched to the nearest known
/// word when it is one typo away (two for a long word), so "pasword" and
/// "biometrik" still land.
///
/// Each entry is scored by the concepts it shares with the query, worth most
/// in its question, then in its hidden tags, least in its answer. One that
/// carries the query as a phrase, or holds nearly all of it in its question,
/// is the best match; the rest come back as related, closest first.
class FaqSearch {
  FaqSearch(this.entries) {
    for (final FaqEntry entry in entries) {
      final Set<String> question = _concepts(entry.question);
      final Set<String> tags = _concepts(entry.tags.join(' '));
      final Set<String> answer = _concepts(entry.answer);
      _index.add((entry, question, tags, answer));
      // Typos are corrected only towards words in questions and tags — the
      // answers are long enough to hold a near-spelling of almost anything.
      _vocabulary
        ..addAll(question)
        ..addAll(tags);
    }
  }

  final List<FaqEntry> entries;
  final List<(FaqEntry, Set<String>, Set<String>, Set<String>)> _index =
      <(FaqEntry, Set<String>, Set<String>, Set<String>)>[];
  final Set<String> _vocabulary = <String>{};

  static const int _maxRelated = 6;

  /// How far ahead of the runner-up an answer must score to be the best
  /// match without carrying the query outright.
  static const double _clearLead = 2;

  FaqResults search(String query) {
    final String phrase = _normalise(query);
    if (phrase.isEmpty) return const FaqResults();
    final Set<String> wanted = <String>{
      for (final String concept in _concepts(query)) _closestKnown(concept),
    }..removeWhere((String concept) => concept.isEmpty);
    if (wanted.isEmpty) return const FaqResults();

    final List<(FaqEntry, double, bool, double)> scored =
        <(FaqEntry, double, bool, double)>[];
    for (final (
          FaqEntry entry,
          Set<String> question,
          Set<String> tags,
          Set<String> answer,
        )
        in _index) {
      double score = 0;
      int inQuestion = 0;
      for (final String concept in wanted) {
        if (question.contains(concept)) {
          score += 3;
          inQuestion++;
        } else if (tags.contains(concept)) {
          score += 2;
        } else if (answer.contains(concept)) {
          score += 1;
        }
      }
      if (score == 0) continue;
      // Favour the entries that answer more of what was asked over those
      // that mention one word of it many ways — and among those, the
      // question closest to the query as a whole.
      final double coverage = inQuestion / wanted.length;
      final double overlap = inQuestion / question.union(wanted).length;
      score += coverage * 2 + overlap * 2;
      final bool exact =
          _normalise(entry.question).contains(phrase) ||
          (wanted.length >= 2 && coverage >= 0.75) ||
          overlap >= 0.6;
      scored.add((entry, score, exact, coverage));
    }
    if (scored.isEmpty) return const FaqResults();

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final (FaqEntry, double, bool, double) top = scored.first;
    // Plainly the one asked: it carries the query, or it covers most of it
    // and stands well clear of the next answer.
    final bool clearLead =
        scored.length == 1 || top.$2 - scored[1].$2 >= _clearLead;
    final FaqEntry? best = top.$3 || (top.$4 >= 0.6 && clearLead)
        ? top.$1
        : null;
    // Only the answers worth reading: within reach of the best score.
    final double floor = top.$2 * 0.34;
    return FaqResults(
      best: best,
      related: <FaqEntry>[
        for (final (FaqEntry entry, double score, _, _) in scored)
          if (entry != best && score >= floor) entry,
      ].take(_maxRelated).toList(),
    );
  }

  /// The known word a stray one was meant to be, if any is a typo away.
  String _closestKnown(String concept) {
    if (_vocabulary.contains(concept) || concept.length < 4) return concept;
    final int allowed = concept.length >= 8 ? 2 : 1;
    String? nearest;
    int nearestDistance = allowed + 1;
    for (final String known in _vocabulary) {
      if ((known.length - concept.length).abs() > allowed) continue;
      final int distance = _editDistance(concept, known, allowed);
      if (distance < nearestDistance) {
        nearest = known;
        nearestDistance = distance;
      }
    }
    return nearest ?? concept;
  }

  static String _normalise(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static Set<String> _concepts(String text) {
    final List<String> words = _normalise(text).split(' ');
    final Set<String> concepts = <String>{};
    for (int i = 0; i < words.length; i++) {
      // Two-word names first — "face id", "back up", "wrong pin".
      if (i + 1 < words.length) {
        final String? pair = _phrases['${words[i]} ${words[i + 1]}'];
        if (pair != null) {
          concepts.add(pair);
          i++;
          continue;
        }
      }
      final String word = words[i];
      if (word.isEmpty || _stopWords.contains(word)) continue;
      final String stem = _stem(word);
      concepts.add(
        _synonyms[word] ?? _synonyms[stem] ?? _synonyms['${stem}e'] ?? stem,
      );
    }
    return concepts;
  }

  /// Trims the endings that only change a word's grammar.
  static String _stem(String word) {
    if (word.length <= 3 || RegExp(r'^[0-9]+$').hasMatch(word)) return word;
    for (final String ending in const <String>[
      'ings',
      'ing',
      'ies',
      'ed',
      'es',
      's',
    ]) {
      if (word.endsWith(ending) && word.length - ending.length >= 3) {
        final String stem = word.substring(0, word.length - ending.length);
        return ending == 'ies' ? '${stem}y' : stem;
      }
    }
    return word;
  }

  /// Edit distance between [a] and [b], giving up past [limit].
  static int _editDistance(String a, String b, int limit) {
    List<int> previous = List<int>.generate(b.length + 1, (int i) => i);
    for (int i = 1; i <= a.length; i++) {
      final List<int> current = List<int>.filled(b.length + 1, 0)..[0] = i;
      int rowBest = current[0];
      for (int j = 1; j <= b.length; j++) {
        final int cost = a[i - 1] == b[j - 1] ? 0 : 1;
        current[j] = <int>[
          previous[j] + 1,
          current[j - 1] + 1,
          previous[j - 1] + cost,
        ].reduce((int x, int y) => x < y ? x : y);
        if (current[j] < rowBest) rowBest = current[j];
      }
      if (rowBest > limit) return limit + 1;
      previous = current;
    }
    return previous[b.length];
  }

  static const Set<String> _stopWords = <String>{
    'a',
    'an',
    'the',
    'is',
    'are',
    'am',
    'was',
    'were',
    'be',
    'been',
    'do',
    'does',
    'did',
    'i',
    'me',
    'my',
    'we',
    'our',
    'you',
    'your',
    'it',
    'its',
    'what',
    'how',
    'why',
    'when',
    'where',
    'which',
    'who',
    'whom',
    'can',
    'could',
    'should',
    'would',
    'will',
    'shall',
    'if',
    'of',
    'to',
    'in',
    'on',
    'at',
    'for',
    'with',
    'and',
    'or',
    'but',
    'so',
    'that',
    'this',
    'there',
    'they',
    'them',
    'he',
    'she',
    'his',
    'her',
    'about',
    'any',
    'some',
    'get',
    'got',
    'have',
    'has',
    'had',
    'not',
    'no',
    'yes',
    'than',
    'then',
    'into',
    'from',
    'by',
    'as',
    'up',
    'out',
    'happen',
    'happens',
    'mean',
    'means',
    'work',
    'works',
    'tell',
    'please',
    'app',
    'bimir',
    'still',
    'use',
    'using',
    'need',
    'want',
    'way',
    'all',
    'one',
    'only',
  };

  /// Two-word names, folded into one concept before anything else.
  static const Map<String, String> _phrases = <String, String>{
    'face id': 'biometric',
    'touch id': 'biometric',
    'face unlock': 'biometric',
    'back up': 'backup',
    'auto fill': 'autofill',
    'wrong pin': 'lockout',
    'wrong pins': 'lockout',
    'too many': 'lockout',
    'locked out': 'lockout',
    'new phone': 'restore',
    'another phone': 'restore',
    'change phone': 'restore',
    'switch phone': 'restore',
    'two phones': 'sync',
    'other device': 'sync',
    'password manager': 'manager',
    'access pin': 'pin',
    'screen lock': 'screenlock',
    'dark mode': 'theme',
    'light mode': 'theme',
  };

  /// The many names for one thing, folded into one concept. Looked up before
  /// and after trimming endings.
  static const Map<String, String> _synonyms = <String, String>{
    // Unlocking.
    'pin': 'pin', 'passcode': 'pin', 'code': 'pin', 'pincode': 'pin',
    'digit': 'digit', 'digits': 'digit', 'number': 'digit',
    'fingerprint': 'biometric', 'finger': 'biometric', 'face': 'biometric',
    'faceid': 'biometric', 'touchid': 'biometric', 'biometric': 'biometric',
    'biometrics': 'biometric',
    'forgot': 'forgot', 'forget': 'forgot', 'forgotten': 'forgot',
    'lost': 'forgot', 'recover': 'forgot', 'reset': 'forgot',
    'lock': 'lockout', 'lockout': 'lockout', 'locked': 'lockout',
    'blocked': 'lockout', 'wait': 'lockout', 'timer': 'lockout',
    'intruder': 'intruder', 'photo': 'intruder', 'picture': 'intruder',
    'selfie': 'intruder', 'camera': 'camera', 'thief': 'intruder',
    'alert': 'intruder', 'alerts': 'intruder', 'snoop': 'intruder',
    'open': 'open', 'unlock': 'open', 'see': 'open', 'view': 'open',
    'show': 'open', 'reveal': 'open',
    // Passwords.
    'password': 'password', 'passwords': 'password', 'login': 'password',
    'credential': 'password', 'account': 'password',
    'generate': 'generator', 'generator': 'generator', 'random': 'generator',
    'create': 'generator', 'strong': 'strong', 'strength': 'strong',
    'weak': 'weak', 'reuse': 'reuse', 'reused': 'reuse', 'same': 'reuse',
    'duplicate': 'reuse', 'checkup': 'checkup', 'check': 'checkup',
    'health': 'checkup', 'leak': 'leak', 'leaked': 'leak', 'breach': 'leak',
    'hacked': 'leak', 'pwned': 'leak', 'compromised': 'leak',
    'note': 'note', 'notes': 'note', 'copy': 'copy', 'clipboard': 'copy',
    'paste': 'copy',
    // Autofill.
    'autofill': 'autofill', 'fill': 'autofill', 'autocomplete': 'autofill',
    'browser': 'browser', 'chrome': 'browser', 'safari': 'browser',
    'iphone': 'ios', 'ipad': 'ios', 'ios': 'ios', 'apple': 'ios',
    'android': 'android', 'samsung': 'android',
    // Backup.
    'backup': 'backup', 'export': 'backup', 'save': 'backup', 'file': 'backup',
    'restore': 'restore', 'import': 'restore', 'transfer': 'restore',
    'move': 'restore', 'migrate': 'restore', 'uninstall': 'uninstall',
    'delete': 'uninstall', 'remove': 'uninstall', 'reinstall': 'uninstall',
    'drive': 'backup',
    // Privacy.
    'cloud': 'sync', 'sync': 'sync', 'icloud': 'sync', 'server': 'sync',
    'online': 'internet', 'internet': 'internet', 'offline': 'internet',
    'wifi': 'internet', 'data': 'internet', 'privacy': 'privacy',
    'private': 'privacy', 'safe': 'privacy', 'secure': 'privacy',
    'encrypt': 'encrypt', 'encrypted': 'encrypt', 'encryption': 'encrypt',
    'developer': 'developer', 'ad': 'ad', 'ads': 'ad', 'tracking': 'ad',
    'analytics': 'ad',
    // The app.
    'free': 'free', 'price': 'free', 'cost': 'free', 'pay': 'free',
    'subscription': 'free', 'language': 'language', 'english': 'language',
    'nepali': 'language', 'hindi': 'language', 'bug': 'report',
    'problem': 'report', 'report': 'report', 'feedback': 'report',
    'contact': 'report', 'email': 'report', 'support': 'report',
    'theme': 'theme', 'dark': 'theme',
  };
}
