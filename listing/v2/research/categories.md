# Category choice for Bimir Lock

Collected 2026-10-10.

## Recommendation

| Store | Recommendation | Today |
|---|---|---|
| **App Store** | **Primary: Utilities. Secondary: Productivity.** | Not live yet; the v1 metadata category files are empty. |
| **Google Play** | **Productivity** (move from Tools), with tags **Password manager** and **Privacy & security**. Add up to 3 more relevant tags only if they truly apply. | Tools |

Both choices are reversible. On Apple, categories change with any new version submission. On Play, the category can be changed at any time in Store settings. Revisit after 60–90 days, using the acquisition-source reports in App Store Connect and Play Console (search vs. browse share).

---

## Evidence: App Store

### Apple's own definitions list password management under both categories

Source: https://developer.apple.com/app-store/categories/
- **Utilities:** "Apps that enable the user to solve a problem or complete a specific task. For example: calculators … screen locks, barcode scanners, unit conversion tools, **password management**, remote controls."
- **Productivity:** "Apps that make a specific process or task more organized or efficient. For example: task management, calendar management, translation, note taking, printing, **password management**, cloud storage …"
- **On the primary category:** "The primary category you select is important for your app's discoverability on the App Store. This will be the category in which the app appears when people browse the App Store or filter search results, and it determines placement on the Apps tab …" Apple advises choosing by purpose, where users look, and "Which categories contain the same type of apps as yours."

### Where password managers sit today

Source: iTunes Search API, 5 US queries, 106 unique password-manager-like apps.

| Primary category | Apps | Who |
|---|---|---|
| Productivity | 66 | Every big cloud brand: 1Password, Bitwarden, Dashlane, LastPass, Keeper, NordPass, Proton Pass, RoboForm, Enpass, mSecure, SafeInCloud, Strongbox, KeePassium; plus Password Manager - Safe Lock, iPassworder, Passible |
| Utilities | 34 | **Apple Passwords** (the iOS default; 804K ratings), **Norton Password Manager**, pwSafe 2, My Eyes Only, iRemember, and **almost every 2025–26 offline newcomer**: Offline Password Safe, Vault: Offline Password Safe, LocalPass - Offline Passwords, 8PWD – Offline Passwords, OffVault, Password Manager Pro offline, Pocket Pass Manager, Keepery, Passito |
| Business / Photo & Video / other | 6 | — |

- **Category pairs:** "Productivity + Utilities" 53 apps; "Utilities + Productivity" 20.
- **Top 20 by US ratings:** 14 Productivity, 5 Utilities, 1 Photo & Video.

### How crowded each chart is

Source: legacy RSS top-free feeds `https://itunes.apple.com/{cc}/rss/topfreeapplications/limit=100/genre={6002 Utilities | 6007 Productivity}/json`, with rating counts from iTunes Lookup. The bottom of the chart (ranks 71–100) shows what it takes to enter.

| Storefront | Utilities ranks 1–25 (median ratings) | Utilities ranks 71–100 (median) | Productivity ranks 1–25 (median) | Productivity ranks 71–100 (median) |
|---|---|---|---|---|
| US | 500,489 | **17,634** | 1,491,468 | **57,034** |
| DE | 7,455 | **4,662** | 105,765 | **8,911** |
| GB | 153,827 | 6,396 | 154,339 | 4,618 |
| IN | 24,154 | 1,535 | 158,368 | 1,056 |
| BR | 169,708 | 3,245 | 150,456 | 2,137 |
| NP (home) | 822 | **41** | 4,171 | **23** |

- **US Productivity top 25:** dominated by AI assistants and office suites. Examples: Muse from Meta, ChatGPT, Google Gemini, Claude, Gmail, Microsoft Authenticator, Grok, Copilot, Google Docs and Drive, Outlook, Word, Excel. The **only password manager in the US Productivity top 100 is 1Password at #90.** Bitwarden is #82 in Germany, and #176 US Productivity per its product-page badge.
- **US Utilities top 25:** browsers, carrier apps, VPNs, Google Authenticator and TV remotes. **No password manager** appears in the Utilities top 100 of any storefront checked: US, IN, GB, DE, BR, NP. Apple Passwords is a system app and is not charted.
- **Chart depth:** Utilities is about 3× shallower than Productivity at the chart bottom in the US and about 2× in Germany. In IN, GB, BR and NP the two are within about 1.5× of each other, and both are reachable in Nepal: about 25–40 ratings gets an app into the bottom of either chart there.

### Why Utilities primary on iOS

1. **It is where the iPhone default lives.** Apple Passwords is Utilities-only, and Norton is Utilities too. Users who browse or filter for a password tool alongside the system one find Utilities.
2. **It is the offline micro-niche's category.** Nearly every 2025–26 "offline password" app on iOS chose Utilities, so the Utilities filter gives a cluster where Bimir Lock is the most complete app.
3. **The chart is shallower in the biggest storefront** (US 17.6K vs 57K median ratings at ranks 71–100; DE 4.7K vs 8.9K). The Productivity chart is now an AI-assistant chart.
4. **Productivity as secondary keeps the second listing.** A secondary category lets the app appear in Productivity browsing and filters too, so nothing is lost relative to the big brands.
5. **The name fits.** "Bimir Lock" reads as a device-security utility, and Apple's Utilities definition names both "screen locks" and "password management". The app does not lock on open, so do not lean on "lock" beyond the brand.

**Trade-off.** In India and Nepal, the Productivity chart bottom is slightly shallower (IN 1,056 vs 1,535; NP 23 vs 41). If after launch most installs come from Nepal or India browse traffic rather than search, swapping primary and secondary is a cheap test with the next version.

---

## Evidence: Google Play

### Play's own descriptions

Source: https://support.google.com/googleplay/android-developer/answer/9859673
- **Tools:** "Tools for Android devices"
- **Productivity:** "Notepad, to-do list, keyboard, printing, calendar, backup, calculator, conversion"
- Apps can add up to **five tags**. Available tags include **"Password manager"** and **"Privacy & security"** (list: https://www.apptweak.com/en/aso-blog/complete-list-of-available-google-play-store-tags). Play says to pick the tags "most obviously relevant".

### Where password managers sit today

Source: 49 listings parsed from `play.google.com/store/apps/details` pages, US.

| Category | Count | Who |
|---|---|---|
| **Productivity** | **34** | Bitwarden, 1Password, Proton Pass, LastPass, Dashlane, NordPass, Keeper, RoboForm, Enpass, KeePassDX, Avira, Zoho Vault, Sticky, mSecure, pCloud Pass, SecureSafe; **and the biggest offline-positioned vaults: Password Manager: My Passwords (1M+), Password Safe and Manager (1M+), Password Manager: Safe (5M+), aWallet (1M+), One Key (100K+), DroidPass (100K+)** |
| Tools | 15 | Google Password Manager (system shortcut), Norton, Bitdefender SecurePass, 2FAS Pass, Keepass2Android (+Offline), **PassKeep (1M+, "No cloud, no account")**, Password Saver (500K+), and most small "Offline Password Manager" clones (10K+ and below). **Bimir Lock is here today.** |

### How crowded each chart is

Source: AppBrain US top-free charts, 2026-10-10:
- Tools: https://www.appbrain.com/stats/google-play-rankings/top_free/tools/us
- Productivity: https://www.appbrain.com/stats/google-play-rankings/top_free/productivity/us

| | Tools | Productivity |
|---|---|---|
| Top 10 | Phone cleaners, Google Authenticator, Proton VPN, Google Translate, find-my-phone | Meta Muse, ChatGPT, Claude, Word, Gemini, Grok, Adobe Reader |
| Ranks 90–100 | Cleaners, PDF tools, cast apps, 27K–130M installs | Notes, Notion, Google Drive, PDF readers, 160K–15B installs |
| Password managers in top 100 | **None** | **None** |

Play's category landing pages show the same mix:
- `/store/apps/category/TOOLS`: VPNs, Authenticator, Lens, Gboard, Smart Switch.
- `/store/apps/category/PRODUCTIVITY`: ChatGPT, Docs, Word, Keep, Gemini, Claude.

### Why Productivity on Play

1. **Neither chart is reachable,** so the category matters for classification and browse adjacency, not for charts.
2. **Productivity is where Play users and Play itself find password managers.** That covers 34 of 49 listings, including all big brands except Norton, and the three largest offline vaults whose positioning is closest to ours (My Passwords, Password Safe, SafeInCloud).
3. **Play's own Productivity examples include "backup" and "notepad".** That is closer to an encrypted vault with backup and notes than "Tools for Android devices", which describes device utilities: cleaners, VPNs, launchers.
4. **The "Password manager" tag works in either category,** so the move loses nothing for tag-based browse.
5. **Counter-argument, and why it does not win.** Tools holds Google Password Manager, PassKeep and Keepass2Android. But Google Password Manager is a system shortcut, not a competitor you can sit next to in browse. The Tools set is otherwise small clones plus VPNs and cleaners.
6. **Category has little direct effect on keyword ranking.** Play ranks on title, short description, full description and engagement. The listing text matters far more than the category, so don't expect the switch to move rankings by itself.

## Sources

- Apple categories: https://developer.apple.com/app-store/categories/
- iTunes Search API: `https://itunes.apple.com/search?term=password+manager&entity=software&country=us&limit=50` (and keeper / vault / saver / offline variants)
- App Store RSS charts: `https://itunes.apple.com/us/rss/topfreeapplications/limit=100/genre=6002/json` (Utilities) and `…/genre=6007/json` (Productivity); also `in`, `gb`, `de`, `br`, `np`
- Play categories and tags: https://support.google.com/googleplay/android-developer/answer/9859673
- Play tag list: https://www.apptweak.com/en/aso-blog/complete-list-of-available-google-play-store-tags
- AppBrain charts: https://www.appbrain.com/stats/google-play-rankings/top_free/tools/us and https://www.appbrain.com/stats/google-play-rankings/top_free/productivity/us
