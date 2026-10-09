import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What kind of account a site is. Shown beside a suggestion, and decides
/// what the username field asks for.
enum SiteKind {
  email('Email', 'Email address'),
  account('Account', 'Email or phone'),
  social('Social', 'Username, email or phone'),
  bank('Bank', 'Username or customer ID'),
  payments('Payments', 'Mobile number or ID'),
  shopping('Shopping', 'Email or phone'),
  streaming('Streaming', 'Email or phone'),
  work('Work', 'Username or email'),
  gaming('Gaming', 'Username or email'),
  internet('Internet', 'Username or customer ID'),
  network('Wi-Fi', 'Network name'),
  device('Device', 'Account name'),
  investing('Investing', 'Username or client ID'),
  government('Government', 'Username or ID'),
  yours('Saved by you', 'Username or email');

  const SiteKind(this.label, this.userLabel);

  final String label;

  /// Label for the username field when this kind of site is chosen.
  final String userLabel;
}

@immutable
class Site {
  const Site(this.name, this.kind, [this.aliases = const <String>[]]);

  final String name;
  final SiteKind kind;

  /// Other words people type for it: "twitter" finds X, "wifi" finds Wi-Fi.
  final List<String> aliases;
}

/// Suggestions for the "Site or app" field: common sites and apps, plus every
/// name the user has saved that is not among them. Kept on this phone only.
class SiteBook {
  SiteBook._();

  static const String _learnedKey = 'site_names';
  static const int _keepLearned = 200;

  static const List<Site> common = <Site>[
    // Everyday categories, for things that are not one website.
    Site('Bank', SiteKind.bank, <String>['banking', 'mobile banking']),
    Site('Wi-Fi', SiteKind.network, <String>['wifi', 'wlan', 'hotspot', 'internet']),
    Site('Router', SiteKind.network, <String>['router admin', 'modem', 'admin']),
    Site('Email', SiteKind.email, <String>['mail', 'work email']),
    Site('Laptop', SiteKind.device, <String>['computer', 'pc', 'mac']),
    Site('Phone', SiteKind.device, <String>['mobile']),
    Site('Work', SiteKind.work, <String>['office']),
    Site('School', SiteKind.work, <String>['college', 'university', 'campus']),

    // Email and the big accounts.
    Site('Gmail', SiteKind.email, <String>['google', 'mail']),
    Site('Google', SiteKind.account),
    Site('Outlook', SiteKind.email, <String>['hotmail', 'live', 'mail']),
    Site('Microsoft', SiteKind.account, <String>['office 365', 'xbox']),
    Site('Yahoo Mail', SiteKind.email, <String>['mail']),
    Site('iCloud', SiteKind.email, <String>['apple', 'mail']),
    Site('Apple ID', SiteKind.account, <String>['apple', 'icloud', 'app store']),
    Site('Proton Mail', SiteKind.email, <String>['protonmail', 'mail']),

    // Social and chat.
    Site('Facebook', SiteKind.social, <String>['fb', 'meta', 'messenger']),
    Site('Instagram', SiteKind.social, <String>['ig', 'insta']),
    Site('WhatsApp', SiteKind.social),
    Site('Messenger', SiteKind.social, <String>['facebook']),
    Site('X', SiteKind.social, <String>['twitter']),
    Site('TikTok', SiteKind.social),
    Site('Snapchat', SiteKind.social, <String>['snap']),
    Site('Threads', SiteKind.social),
    Site('LinkedIn', SiteKind.social),
    Site('Reddit', SiteKind.social),
    Site('Pinterest', SiteKind.social),
    Site('Telegram', SiteKind.social),
    Site('Discord', SiteKind.social),
    Site('Viber', SiteKind.social),

    // Streaming and music.
    Site('YouTube', SiteKind.streaming, <String>['google']),
    Site('Netflix', SiteKind.streaming),
    Site('Spotify', SiteKind.streaming),
    Site('Prime Video', SiteKind.streaming, <String>['amazon']),
    Site('Disney+', SiteKind.streaming, <String>['disney plus', 'hotstar']),

    // Shopping and rides.
    Site('Amazon', SiteKind.shopping),
    Site('Daraz', SiteKind.shopping),
    Site('eBay', SiteKind.shopping),
    Site('AliExpress', SiteKind.shopping, <String>['alibaba']),
    Site('Pathao', SiteKind.shopping, <String>['ride']),
    Site('inDrive', SiteKind.shopping, <String>['indriver', 'ride']),
    Site('Foodmandu', SiteKind.shopping, <String>['food']),

    // Wallets and payments.
    Site('eSewa', SiteKind.payments, <String>['esewa wallet']),
    Site('Khalti', SiteKind.payments),
    Site('IME Pay', SiteKind.payments, <String>['imepay']),
    Site('Fonepay', SiteKind.payments),
    Site('PayPal', SiteKind.payments),
    Site('Wise', SiteKind.payments, <String>['transferwise']),

    // Banks in Nepal.
    Site('Nabil Bank', SiteKind.bank),
    Site('NIC Asia Bank', SiteKind.bank),
    Site('Global IME Bank', SiteKind.bank),
    Site('Nepal Investment Mega Bank', SiteKind.bank, <String>['nimb', 'nibl']),
    Site('Himalayan Bank', SiteKind.bank),
    Site('Everest Bank', SiteKind.bank),
    Site('NMB Bank', SiteKind.bank),
    Site('Siddhartha Bank', SiteKind.bank),
    Site('Kumari Bank', SiteKind.bank),
    Site('Prabhu Bank', SiteKind.bank),
    Site('Sanima Bank', SiteKind.bank),
    Site('Laxmi Sunrise Bank', SiteKind.bank),
    Site('Machhapuchchhre Bank', SiteKind.bank, <String>['mbl']),
    Site('Citizens Bank', SiteKind.bank),
    Site('Prime Commercial Bank', SiteKind.bank),
    Site('Standard Chartered', SiteKind.bank, <String>['scb']),
    Site('Rastriya Banijya Bank', SiteKind.bank, <String>['rbb']),
    Site('Nepal Bank', SiteKind.bank),
    Site('Agricultural Development Bank', SiteKind.bank, <String>['adbl']),

    // Shares and government services.
    Site('MeroShare', SiteKind.investing, <String>['cdsc', 'mero share']),
    Site('TMS', SiteKind.investing, <String>['nepse', 'broker']),
    Site('Nagarik App', SiteKind.government, <String>['nagarik']),

    // Phone and internet providers.
    Site('Nepal Telecom', SiteKind.internet, <String>['ntc', 'namaste']),
    Site('Ncell', SiteKind.internet),
    Site('WorldLink', SiteKind.internet, <String>['wlink']),
    Site('Vianet', SiteKind.internet),
    Site('DishHome', SiteKind.internet),

    // Work tools.
    Site('GitHub', SiteKind.work, <String>['git']),
    Site('GitLab', SiteKind.work, <String>['git']),
    Site('Slack', SiteKind.work),
    Site('Zoom', SiteKind.work),
    Site('Microsoft Teams', SiteKind.work, <String>['teams']),
    Site('Notion', SiteKind.work),
    Site('Figma', SiteKind.work),
    Site('Canva', SiteKind.work),
    Site('Dropbox', SiteKind.work),
    Site('ChatGPT', SiteKind.work, <String>['openai']),
    Site('Claude', SiteKind.work, <String>['anthropic']),

    // Games.
    Site('Steam', SiteKind.gaming),
    Site('PlayStation', SiteKind.gaming, <String>['psn', 'sony']),
    Site('Xbox', SiteKind.gaming, <String>['microsoft']),
    Site('Epic Games', SiteKind.gaming, <String>['fortnite']),
    Site('PUBG Mobile', SiteKind.gaming, <String>['pubg']),
    Site('Free Fire', SiteKind.gaming, <String>['garena']),
    Site('Roblox', SiteKind.gaming),
  ];

  static String _key(String s) => s.trim().toLowerCase();

  /// The catalogue entry called exactly [name], if any.
  static Site? find(String name) {
    final String k = _key(name);
    if (k.isEmpty) return null;
    for (final Site s in common) {
      if (_key(s.name) == k) return s;
    }
    return null;
  }

  /// Names the user saved that are not in [common], newest first.
  static Future<List<String>> learned() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_learnedKey) ?? <String>[];
  }

  /// Remembers [name] for next time, unless the catalogue has it already.
  static Future<void> learn(String name) async {
    final String n = name.trim();
    if (n.isEmpty || find(n) != null) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(_learnedKey) ?? <String>[];
    list.removeWhere((String s) => _key(s) == _key(n));
    list.insert(0, n);
    if (list.length > _keepLearned) list.removeRange(_keepLearned, list.length);
    await prefs.setStringList(_learnedKey, list);
  }

  /// Everything to suggest from: the user's own names first (saved ones,
  /// then names already in the vault), then the catalogue. No duplicates.
  static List<Site> all({
    List<String> learned = const <String>[],
    Iterable<String> inVault = const <String>[],
  }) {
    final Set<String> seen = <String>{};
    final List<Site> out = <Site>[];
    for (final String n in <String>[...learned, ...inVault]) {
      final String k = _key(n);
      if (k.isEmpty || !seen.add(k)) continue;
      out.add(find(n) ?? Site(n.trim(), SiteKind.yours));
    }
    for (final Site s in common) {
      if (seen.add(_key(s.name))) out.add(s);
    }
    return out;
  }

  /// What to offer for [typed]: names starting with it, then names with a
  /// word starting with it ("kath" → "Bank of Kathmandu"), then aliases
  /// ("twitter" → X). Never the exact name already typed.
  static List<Site> suggestions(String typed, List<Site> from, {int max = 8}) {
    final String q = _key(typed);
    if (q.isEmpty) return const <Site>[];
    final List<Site> starts = <Site>[];
    final List<Site> words = <Site>[];
    final List<Site> aliases = <Site>[];
    for (final Site s in from) {
      final String name = _key(s.name);
      if (name == q) continue;
      if (name.startsWith(q)) {
        starts.add(s);
      } else if (name.split(RegExp(r'[\s\-_.]+')).any((String w) => w.startsWith(q))) {
        words.add(s);
      } else if (q.length >= 2 && s.aliases.any((String a) => a.startsWith(q))) {
        aliases.add(s);
      }
    }
    return <Site>[...starts, ...words, ...aliases].take(max).toList();
  }
}
