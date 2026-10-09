import 'package:bimir_lock/utils/helper/faq_search.dart';

/// Every question the FAQ answers. Each fact here is what the app does,
/// checked against the code — change the answer when the code changes.
const List<FaqEntry> faqEntries = <FaqEntry>[
  // PIN & unlock.
  FaqEntry(
    topic: FaqTopic.unlock,
    question: 'How do I open a saved password?',
    answer:
        'Tap it and enter your 6-digit PIN. If you turned on fingerprint or '
        'Face ID unlock in Settings › Security, that works too.',
    tags: <String>['see password', 'reveal', 'show password'],
  ),
  FaqEntry(
    topic: FaqTopic.unlock,
    question: 'Does Bimir Lock ask for the PIN when it opens?',
    answer:
        'No. The list of site names, with usernames partly hidden, opens '
        'straight away. Every password asks for your PIN, fingerprint or face '
        'before it is shown, copied, edited or deleted, and so do backups and '
        'Wrong PIN alerts.',
    tags: <String>['app lock', 'lock on open', 'startup'],
  ),
  FaqEntry(
    topic: FaqTopic.unlock,
    question: 'I forgot my PIN. What can I do?',
    answer:
        'Tap "Forgot PIN?" on the keypad, or go to Settings › Security › '
        'Forgot PIN?. If fingerprint or Face ID unlock is on, confirm it is you '
        'and choose a new PIN; your passwords stay as they are. If it is off, '
        'the PIN cannot be reset: you can erase the app and start again, then '
        'restore from a backup file. There is no master PIN, and the developer '
        'cannot recover it for you.',
    tags: <String>['reset pin', 'recover', 'lost pin'],
  ),
  FaqEntry(
    topic: FaqTopic.unlock,
    question: 'Why was my PIN refused?',
    answer:
        'New PINs have 6 digits, and easy ones are refused: all the same digit '
        '(111111), straight runs (123456), repeating pairs (121212) and the '
        'most common PINs. A PIN like that is the first thing anyone tries.',
    tags: <String>['weak pin', '123456', 'pin not accepted'],
  ),
  FaqEntry(
    topic: FaqTopic.unlock,
    question: 'Can I keep my old 4-digit PIN?',
    answer:
        'Yes, a 4-digit PIN from an earlier version keeps working. A 6-digit '
        'one is far harder to guess: change it in Settings › Security › Change '
        'access PIN.',
    tags: <String>['four digits', 'six digits'],
  ),
  FaqEntry(
    topic: FaqTopic.unlock,
    question: 'What happens after too many wrong PINs?',
    answer:
        'After 7 wrong PINs in a row the keypad locks for 30 seconds, then 1, '
        '5 and 15 minutes. Closing the app does not reset the count; the right '
        'PIN or your fingerprint or face does. Fingerprint and Face ID still '
        'work while the keypad is locked.',
    tags: <String>['locked out', 'wait', 'timer'],
  ),
  FaqEntry(
    topic: FaqTopic.unlock,
    question: 'What are Wrong PIN alerts?',
    answer:
        'Settings › Security › Wrong PIN alerts lists every time the keypad '
        'locked. If you turn on "Take a photo", the front camera also '
        'photographs whoever entered the wrong PINs. Photos stay on this phone, '
        'only you can open the list (it asks for your PIN), and the newest 30 '
        'are kept.',
    tags: <String>['intruder', 'selfie', 'who tried', 'camera'],
  ),
  // Passwords.
  FaqEntry(
    topic: FaqTopic.passwords,
    question: 'How does the password generator work?',
    answer:
        'When you add or edit a password, open "Generate a password". Pick a '
        'length from 8 to 64 (20 to start) and switch numbers and symbols on or '
        'off. Upper and lower case are always in, look-alike characters such '
        'as l, I, O and 0 are left out, and it uses the phone\'s secure random '
        'generator.',
    tags: <String>['random password', 'strong password', 'create'],
  ),
  FaqEntry(
    topic: FaqTopic.passwords,
    question: 'What does Password Checkup look for?',
    answer:
        'Weak passwords, and passwords used on more than one site. Tap the '
        'Password Checkup card on the vault to see them, with a Change button '
        'on each. It is worked out on this phone; nothing is sent anywhere.',
    tags: <String>['weak', 'reused', 'health'],
  ),
  FaqEntry(
    topic: FaqTopic.passwords,
    question: 'Does Bimir Lock tell me if a password was leaked?',
    answer:
        'No. It does not check your passwords against breach lists, because '
        'that would mean sending something about them over the internet. '
        'Password Checkup only finds weak and reused ones.',
    tags: <String>['breach', 'hacked', 'pwned', 'compromised'],
  ),
  FaqEntry(
    topic: FaqTopic.passwords,
    question: 'Are my Notes encrypted?',
    answer:
        'The note you add to a password is encrypted, like the password. The '
        'separate Notes section (the notepad button on the vault) is for '
        'everyday notes: it is not encrypted and does not ask for the PIN. '
        'Keep recovery codes and other secrets in a password\'s note.',
    tags: <String>['secure notes', 'private notes', 'recovery codes'],
  ),
  FaqEntry(
    topic: FaqTopic.passwords,
    question: 'How long does a copied password stay on the clipboard?',
    answer:
        '30 seconds. After that Bimir Lock clears the clipboard if it still '
        'holds that password. A revealed password also hides itself again '
        'after 30 seconds.',
    tags: <String>['copy', 'paste', 'clipboard'],
  ),
  // Autofill.
  FaqEntry(
    topic: FaqTopic.autofill,
    question: 'How do I turn on autofill on Android?',
    answer:
        'Settings › Security › Autofill, then choose Bimir Lock in the list '
        'Android shows. Sign-in forms in other apps then offer your saved '
        'logins, and Bimir Lock can offer to save a new one when you sign in.',
    tags: <String>['autofill service', 'fill passwords android'],
  ),
  FaqEntry(
    topic: FaqTopic.autofill,
    question: 'How do I turn on AutoFill on iPhone or iPad?',
    answer:
        'In the iPhone\'s Settings, go to General › AutoFill & Passwords (on '
        'iOS 17 and earlier: Passwords › Password Options) and turn on Bimir '
        'Lock. In a sign-in field, tap Passwords or the key above the keyboard '
        'and choose Bimir Lock.',
    tags: <String>['ios autofill', 'iphone fill', 'password provider'],
  ),
  FaqEntry(
    topic: FaqTopic.autofill,
    question: 'Why doesn\'t my iPhone offer to save passwords in Bimir Lock?',
    answer:
        'iOS lets other password managers fill passwords but not catch new '
        'ones as you sign in. Add new passwords in Bimir Lock itself; Android '
        'can offer to save them for you.',
    tags: <String>['save prompt iphone', 'ios save'],
  ),
  FaqEntry(
    topic: FaqTopic.autofill,
    question: 'Why doesn\'t autofill appear in some browsers or apps?',
    answer:
        'It works where the app or browser supports Android autofill or iOS '
        'AutoFill. Some browsers only use their own password manager. When '
        'nothing is offered, copy the password from Bimir Lock instead.',
    tags: <String>['browser', 'not showing'],
  ),
  FaqEntry(
    topic: FaqTopic.autofill,
    question: 'What does autofill ask before it fills a password?',
    answer:
        'Your fingerprint, face or the phone\'s screen lock on Android, and '
        'Face ID, Touch ID or the passcode on iPhone. Without a screen lock or '
        'passcode on the phone, Bimir Lock will not fill.',
    tags: <String>['screen lock', 'confirm'],
  ),
  // Backup.
  FaqEntry(
    topic: FaqTopic.backup,
    question: 'How do I back up my passwords?',
    answer:
        'Settings › Backup › Back up to a file. Choose a backup password of at '
        'least 10 characters (separate from your PIN), then save the file '
        'wherever your phone\'s save dialog offers: the phone, a cloud drive '
        'you already use, or a computer. The file is encrypted with Argon2id '
        'and AES-256-GCM.',
    tags: <String>['export', 'save file'],
  ),
  FaqEntry(
    topic: FaqTopic.backup,
    question: 'How do I move my passwords to a new phone?',
    answer:
        'Back up to a file on the old phone and copy it across. On the new '
        'phone, install Bimir Lock and use Settings › Backup › Restore from a '
        'file (or "Restore from a backup" on an empty vault), then enter the '
        'backup password. Restore adds what is missing, skips exact '
        'duplicates and never deletes anything.',
    tags: <String>['transfer', 'import', 'new phone', 'restore'],
  ),
  FaqEntry(
    topic: FaqTopic.backup,
    question: 'I forgot my backup password.',
    answer:
        'Then that file cannot be opened by anyone, including you and the '
        'developer. Make a new backup with a password you will remember, and '
        'keep it somewhere safe.',
    tags: <String>['lost backup password'],
  ),
  FaqEntry(
    topic: FaqTopic.backup,
    question: 'What is inside a backup file?',
    answer:
        'Your site names, usernames, passwords and the notes on them. It does '
        'not include the Notes section, your profile, settings or Wrong PIN '
        'alerts.',
    tags: <String>['backup contents'],
  ),
  FaqEntry(
    topic: FaqTopic.backup,
    question: 'Will I lose my passwords if I uninstall the app?',
    answer:
        'Yes, unless you have a backup file. Your vault lives only on this '
        'phone and is kept out of Google and iCloud device backups, so make a '
        'backup file before uninstalling or changing phones.',
    tags: <String>['uninstall', 'delete app', 'reinstall'],
  ),
  // Privacy.
  FaqEntry(
    topic: FaqTopic.privacy,
    question: 'Is there an account or cloud sync?',
    answer:
        'No. There is no sign-up and no server, so your vault lives on one '
        'phone. To use the same passwords on another phone, restore a backup '
        'file there; the two copies do not sync afterwards.',
    tags: <String>['sync', 'two phones', 'cloud', 'login'],
  ),
  FaqEntry(
    topic: FaqTopic.privacy,
    question: 'Can the developer see my passwords?',
    answer:
        'No. Nothing you save is sent anywhere. Passwords and their notes are '
        'encrypted with AES-256-GCM using a key kept in Android Keystore or the '
        'iOS Keychain, and that key never leaves your phone.',
    tags: <String>['encryption', 'safe', 'secure'],
  ),
  FaqEntry(
    topic: FaqTopic.privacy,
    question: 'Does Bimir Lock need the internet?',
    answer:
        'No, it works offline. It only goes online to check the store for a '
        'newer version, and to open links you tap, such as this app\'s privacy '
        'policy.',
    tags: <String>['offline', 'wifi', 'data'],
  ),
  FaqEntry(
    topic: FaqTopic.privacy,
    question: 'Why does Bimir Lock ask for the camera?',
    answer:
        'To take a profile photo, and, only if you turn on Wrong PIN alerts › '
        'Take a photo, to photograph whoever enters 7 wrong PINs in a row. '
        'Photos stay on your phone.',
    tags: <String>['camera permission'],
  ),
  FaqEntry(
    topic: FaqTopic.privacy,
    question: 'Are there ads or tracking?',
    answer: 'No ads, no analytics and no tracking of any kind.',
    tags: <String>['ads', 'analytics'],
  ),
  // The app.
  FaqEntry(
    topic: FaqTopic.app,
    question: 'Is Bimir Lock free?',
    answer: 'Yes. No subscription and no in-app purchases.',
    tags: <String>['price', 'cost', 'premium'],
  ),
  FaqEntry(
    topic: FaqTopic.app,
    question: 'Which languages is the app in?',
    answer: 'English, for now.',
    tags: <String>['nepali', 'hindi', 'language'],
  ),
  FaqEntry(
    topic: FaqTopic.app,
    question: 'How do I switch to dark mode?',
    answer: 'Settings › Appearance: System, Light or Dark.',
    tags: <String>['theme', 'dark theme'],
  ),
  FaqEntry(
    topic: FaqTopic.app,
    question: 'How do I report a problem or suggest something?',
    answer:
        'Settings › Help › Report a problem opens your email app with a short '
        'report addressed to the developer. Please never include a password, '
        'PIN or backup password.',
    tags: <String>['bug', 'feedback', 'contact', 'support'],
  ),
];
