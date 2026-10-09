# Keyword demand and placement for Bimir Lock

Collected 2026-10-10. Recommendations first, evidence after.

## 0. Constraints from the code audit (they override keyword demand)

- **The app does not lock on open.** PIN or biometrics are asked per password or action. Do not use "app lock", "applock", "lock apps" or "lock screen" keywords, and do not describe the app as locking itself. Those queries are app-locker intent anyway (Apple hints for "lock" and "password lock" are AppLocker-type apps).
- **Notes are not encrypted.** Do not use "secure notes", "encrypted notes", "private notes" or "secret notes" anywhere (keywords, subtitle or description). Encrypted is the wrong word for that feature.
- **No passkeys, TOTP/2FA or authenticator:** never use `passkey`, `2fa`, `authenticator` or `otp` (Apple 2.3.7 "irrelevant phrases", Play metadata policy).
- **No competitor or brand names** in any keyword field or description: Google, Apple, iCloud, Keychain, KeePass, Bitwarden, 1Password, LastPass, Keeper, Dashlane, NordPass, Proton, Norton, Enpass, RoboForm and the rest. Apple: "Names of other apps or companies aren't allowed" (ASC keywords field); "Don't include … Competing app names" (Apple product-page guide). Play: "don't compare your app or game to other apps" (Play store-listing best practices). Sources are in `platform-rules.md`.
- **No "no internet" claims.** Android declares INTERNET for the `upgrader` version check (`android/app/src/main/AndroidManifest.xml` line 7). Say "works offline" or "vault stays on your phone", not "no internet access" or "no internet permission".
- **Avoid "free" in Play title and short description, and in Apple name, subtitle and keywords.** Play says "Free" and "No Ads" promote deals; Apple 2.3.7 bans pricing info in metadata. Use them in the full description only.

## 1. Recommended placement (ready to use)

| Field | Recommendation | Length |
|---|---|---|
| **Play title** (30) | `Bimir Lock: Password Manager` | 28 |
| **Play short description** (80) | `Offline password manager & vault: no account, no cloud. Fingerprint & autofill.` | 79 |
| Alt short description | `Offline password keeper & vault. No account, no cloud. Autofill + fingerprint.` | 78 |
| **Apple name** (30) | `Bimir Lock: Password Manager` | 28 |
| **Apple subtitle** (30) | `Offline Vault, Keeper & Saver` (ranking-first: adds offline, vault, keeper, saver) | 29 |
| Alt subtitle (conversion-first) | `Offline vault, no account` | 25 |
| **Apple keywords** en-US and en-GB (100 bytes, no spaces) | `safe,locker,generator,autofill,private,local,login,pin,strong,book,storage,save,account,backup,cloud` | 100 |
| Apple promotional text (170, not indexed) | Conversion copy only; it can change without a new version. | — |
| Play full description (4,000, **indexed**) | Use "password manager" 4–6 times. Use "offline" 4–5 times. Use each of these once or twice, naturally: password keeper, password saver, password vault, password safe, password locker, save passwords, password generator, password strength / checkup, autofill, no account, no cloud, works offline, local, encrypted backup file, fingerprint / Face ID, PIN. No keyword lists, no competitor names, no emoji bullets. | — |

**How Apple combines the fields.** The name, subtitle and keyword field are matched word by word across all three. "Bimir Lock: Password Manager" plus the subtitle above plus the keyword field above makes the app eligible for these queries:
- offline password manager, password vault, password keeper, password saver, password safe, password locker;
- password generator, strong password generator, password book, password storage, save password(s);
- local password manager, password manager no account / no cloud, password autofill, private vault, password backup, pin vault.

**Words deliberately left out of the Apple keyword field:**
- In the name or subtitle already: password, manager, offline, vault, keeper, saver. Repeats waste bytes.
- Plurals: passwords. Apple treats plurals as duplicates.
- "app". Apple says avoid it.
- "free" (pricing), "secure" (low value; "secure" hints are VPNs and folders), and "notes" or "lock" (code audit).

**en-GB matters as much as en-US.** On the App Store, **English (U.K.) is the primary language of the Nepal, India, Indonesia, Pakistan, Saudi Arabia, Türkiye, Thailand, Vietnam, Malaysia and Philippines storefronts.** The US storefront uses English (US). Source: Apple "App Store localizations", https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations.
- Add an en-GB localization with the same name, subtitle and keyword set (en-GB spelling is identical here). Otherwise India and Nepal fall back to the app's primary language.
- The US storefront also indexes Spanish (Mexico), Portuguese (Brazil), French, Korean, Russian, Vietnamese, Arabic and Chinese (Simplified and Traditional) localizations. Each is an extra 100-byte keyword field that counts in the US.

## 2. Ranked keyword table (English)

**Columns**
- **Volume** is SE Ranking monthly *Google web* search volume, Oct 2026, for `us`, `in`, `uk` and `np` (MCP `DATA_getKeywordsMetrics`). It is a demand proxy, not App Store or Play search volume.
- **KD** is SE Ranking keyword difficulty (0–100) for US web search. It is a proxy for how saturated the term is.
- **Store signal** comes from:
  - App Store search hints: `https://search.itunes.apple.com/WebObjects/MZSearchHints.woa/wa/hints?clientApplication=Software&term=…`, called with header `X-Apple-Store-Front: 143441,29`. Without that header the endpoint returns an empty list.
  - Google autocomplete: `http://suggestqueries.google.com/complete/search?client=firefox&q=…`.
  - Play and App Store search result composition.
- **Fit** means fit with the offline / no-account angle.

| # | Query | Volume US / IN / GB / NP | KD (US) | Store signal | Intent | Fit | Placement |
|---|---|---|---|---|---|---|---|
| 1 | password manager | 1.5M\* / 550K / 246K / 33.1K | 98 | Apple hint #2 for "password"; Play #1 is Google Password Manager | Category head term, partly navigational (\*the US figure jumped from ~301K to 1.5M in mid-2026; most of that is "Google Password Manager" navigation) | Must have, but not winnable head-on | **Title (both stores)**, Play short description, description |
| 2 | password generator | 246K / 47.5K / 47.5K / 320 | 96 | Apple hints "password generator", "random password generator", "strong" variants | Mostly web-tool intent (people want a website) | Feature, secondary | Apple keyword `generator` (+`strong`); Play description |
| 3 | password app | 1.6K / **165K** / 540 / – | 77 | Apple hint "password app"; Google AC "password app for android/iphone" | Generic "app for passwords"; India is huge | Good | Play description (natural sentence); Apple ignores "app" |
| 4 | save password(s) | 5.4K / **27.1K** / 500 / – | 75 | Apple hints only apps ("save passwords - encrypted"); Google AC "app to save passwords android/iphone/free" | Store-my-passwords intent, plus navigational "saved passwords in Chrome" | High | Apple keyword `save`; Play short description or description ("save passwords") |
| 5 | password vault | 2.4K / 40 / 20 / 10 | 68 | Apple hints: 10 "password vault …" apps | Commercial | High | **Apple subtitle `Vault`**; Play short description |
| 6 | password safe | 2.4K / 390 / 190 / – | 72 | Apple hint #6 for "password"; Apple #1 = Password Safe Manager & Vault (1.6K ratings) | Commercial or navigational | High | Apple keyword `safe`; Play description |
| 7 | password keeper | 920 / 140 / 390 / 10 | 54 | Apple hint #3 for "password"; "password keeper free" is the top completion; Play #7 is a 500-install exact-title app | Commercial; older and less technical users | High | **Apple subtitle `Keeper`**; Play description, alt short description |
| 8 | password locker | 480 / 390 / 90 / – | 34 | Apple hints "password locker", "my password locker free", "private password locker app" | Password storage. "password lock" alone is app-lock intent, so avoid it | Medium-high (fits the brand) | Apple keyword `locker`; Play description, once |
| 9 | **offline password manager** / password manager offline | 390 + 390 / – / 90 + 90 / – | **6** / 21 | Google AC: "offline password manager android / free / ios / reddit", "best offline password manager". Apple hints: "offline password safe", "offline password generator", "opm: offline password manager" (US, GB, IN). Play #1 is a 10K-install exact-title app. | Transactional, high purchase intent, privacy-minded | **Perfect: our USP** | **Apple subtitle `Offline`** + name; **Play short description first words**; description 4–5× |
| 10 | best offline password manager | 110 / – / – / – | 21 | Google AC: "… android", "… iphone", "… free" | Comparison | Perfect, but "best" is banned in metadata | Description context only ("offline password manager for Android") |
| 11 | password saver / password saver app | 80 + 260 / 10 + 170 / 10 / **90** | 57 / **7** | Apple hint "password saver" (US, IN, NP, PK); Play #1 for "password saver" is the exact-title "Password Saver" (500K+) | Commercial, non-technical users (strong in South Asia) | High | **Apple subtitle `Saver`**; Play description |
| 12 | local password manager | 20 / – / 40 / – | 50 | Google AC: "local password manager android / app / free", "password manager local only / local storage" | Transactional | Perfect | Apple keyword `local`; Play description |
| 13 | password manager no cloud / without cloud / not cloud based | 10 + 10 / – / – / – | 35 | Google AC: "password manager that doesn't use cloud", "password manager not cloud based", "best password manager not cloud based" | Transactional | Perfect | Play short description ("no cloud"); Apple keyword `cloud` |
| 14 | password manager no account / without account / without login | no data | – | Google AC: "password manager no account", "password manager without login", "password manager without account" | Transactional | Perfect | Play short description ("no account"); Apple keyword `account`; alt Apple subtitle |
| 15 | password manager without subscription | 10 | 44 | Google AC: "password manager without subscription", "best password manager without subscription" | Price-sensitive | Perfect (free, no IAP) | Description only ("no subscription"); not in title or short description (deal wording) |
| 16 | password manager without internet | no data | – | Google AC exists | Transactional | Fits, but the claim is risky (see section 0) | Description: "works without internet" is OK as a usage statement; never "no internet permission" |
| 17 | password vault offline / password keeper offline | (in #9) | – | Google AC: "password vault offline", "password keeper offline", "offline password vault device" | Transactional | Perfect | Covered by subtitle + name on Apple; Play description |
| 18 | password storage (app) | 10 / – / – / – | 8 | Apple hints "password storage", "easy password storage" | Commercial | Good | Apple keyword `storage` |
| 19 | password book (app) | 10 / – / – / – | 28 | Apple hints "password book-password manager", "my password book"; Google AC is mostly paper notebooks | Older users replacing a paper book | Medium | Apple keyword `book`; Play description, once |
| 20 | password checker / password strength checker | 5.4K / – / – / – ; 80 | 72 / 59 | Apple hints "password strength checker / test" | Mostly web tool | Medium (Password Checkup feature) | Apple keyword `strong`; Play description ("check weak and reused passwords") |
| 21 | autofill password (app) | 10 | 35 | Several competitor subtitles use "Autofill" | Feature | Good, with caveats: Android saves + fills, iOS fills only | Apple keyword `autofill`; Play description |
| 22 | password manager android / for android | 5.4K / 590 / – / – ; 210 | 69 / 17 | Google AC | Platform qualifier | Good on Play only | Play description ("…for Android"); **never on Apple** (Apple 2.3.10) |
| 23 | password manager iphone / for iphone | 880 ; 20 | 7 | Google AC | Platform qualifier | Apple only | Not needed: the App Store is iPhone by definition |
| 24 | free password manager / password manager free | 10.8K / 20 / 50 / 20 ; 540 | 94 / 52 | Apple hint "password manager free" (top 3 in US) | Price | True, but restricted wording | Play full description only; Apple description only |
| 25 | private vault / pin | – | – | Apple hints for "private vault" are photo vaults; "pin" hints are Pinterest | Mixed | Low on its own | Apple keywords `private`, `pin` only as combiners (cheap bytes) |

**Excluded on purpose:**
- **Feature not built:** `secure notes`, `secure notes app` (US 320 / 140, KD 18 / 27, attractive but Notes are not encrypted), `private notes`, `password protected notes`.
- **Wrong positioning (the app does not lock on open):** `app lock`, `applock`, `password lock`.
- **Competitor or other platform names:** `keychain` (Apple's iCloud Keychain), `keepass`, `google password manager`, `vaultwarden`.
- **Unsupported features:** `passkey`, `2fa`, `authenticator`.

## 3. Winnable long tail (priority order)

1. **offline password manager / password manager offline / offline password safe.** KD 6–21. The App Store results are filled with 0–500-rating apps, and Play's top 10 includes apps with 5–1,000 installs. *Put "Offline" in the Apple subtitle and lead the Play short description with it.*
2. **password keeper** (US 920, GB 390, KD 54). Apple autocompletes it as the #3 "password" suggestion, and Play rewards exact words. *Apple subtitle `Keeper`; Play description.*
3. **password saver / password saver app** (US 260 app variant at KD 7, NP 90, IN 170). Strong in South Asia. *Apple subtitle `Saver`.*
4. **password vault / password safe / password locker** (2.4K / 2.4K / 480 US). *Subtitle `Vault`, keywords `safe`, `locker`.*
5. **password manager no account / no cloud / local password manager / without subscription.** Low measured volume but very clear Google autocomplete demand and exactly our story. Converts well. *Play short description + description; Apple keywords `account`, `cloud`, `local`.*
6. **save password(s)** (IN 27.1K, US 5.4K). *Apple keyword `save`; Play description.*
7. **password book / password storage.** Tiny, cheap bytes.
8. **Non-English head terms** (see `localization.md`). Brazil, Mexico, Spain, Türkiye, Indonesia, Vietnam and Saudi Arabia have native-language App Store results whose top apps have 0–1,000 ratings. That is the easiest "big" volume available.

## 4. Per-country English evidence (SE Ranking, Google web, Oct 2026)

| Query | US | IN | GB | NP |
|---|---|---|---|---|
| password manager | 1,500,000\* | 550,000 | 246,000 | 33,100 |
| password app | 1,600 | 165,000 | 540 | – |
| save password(s) | 5,400 ("save passwords") | 27,100 ("save password") | 500 | – |
| password generator | 246,000 | 47,500 | 47,500 | 320 |
| password lock *(app-lock intent; excluded)* | – | 2,400 | – | – |
| password safe | 2,400 | 390 | 190 | – |
| password locker | 480 | 390 | 90 | – |
| password keeper | 920 | 140 | 390 | 10 |
| password saver (app) | 80 (260) | 10 (170) | 10 | 90 |
| password vault | 2,400 | 40 | 20 | 10 |
| offline password manager | 390 | n/a | 90 | n/a |
| password manager offline | 390 | n/a | 90 | n/a |
| best offline password manager | 110 | – | – | – |
| local password manager | 20 | – | 40 | – |
| secure notes *(excluded)* | 320 | 170 | 90 | – |
| password manager android | 5,400 | 590 | – | – |

\*The US "password manager" volume is inflated by "Google Password Manager" navigation from mid-2026. The trend line was about 301K before July 2026.

## 5. App Store search-hint evidence (US storefront 143441 unless noted)

- **password** → password manager | password keeper | password generator | password game | password safe | password manager free | …
- **password ke** → password keeper | password keeper free | password keep | password keep - manager | …
- **password sa** → password safe | password saver | password safe manager & vault | password saver & vault | …
- **password v** → password vault | password vault pro | password vault - manager | …
- **password l** → app password lock | password locker | … (app-lock intent dominates)
- **offline password** → offline password safe | offline password generator | 8pwd 2026 – offline passwords | bastion offline password mgr | localpass - offline passwords | pwnote – offline password | vaultx offline password vault
  - Same in GB (143444) and IN (143467), plus "opm: offline password manager".
- **password saver** → password saver | password saver & vault | lockit password saver. Same in IN, NP and PK.
- **password book** → password book-password manager | account manager-password book | my password book
- **password storage** → password storage | easy password storage | passpeak - password storage
- **IN (143467) "password"** → password | password manager | **password saver** | password reset | password safe | password generator | … | password vault
- **NP (143484) "password manager"** → hvault - password manager | vaultly: password manager 2fa | 2fa codes & password manager | bitwarden password manager | **password manager - safe lock** | …
  - The Nepal storefront has thin demand, so app names appear as suggestions. Ranking there comes from the exact phrase "password manager" in the name.
- **"password manager offline", "password manager no …", "password organizer", "password checkup", "login manager"** → no suggestions in the US. These phrases are typed but too rare for autocomplete. Cover them through word combinations, not exact phrases.

## 6. Google autocomplete evidence (gl=us, hl=en)

- **offline password manager** → … device | android | free | windows | github | linux | reddit | hardware | ios
- **password manager without** → subscription | login | account | cloud | internet | browser extension
- **password manager no cloud** → … | not cloud based | non cloud | best password manager not cloud based
- **local password manager** → windows | open source | linux | mac | android | reddit | free | github | app
- **app to save passwords** → android | iphone | free | app to store passwords | app to keep passwords safe | app to remember passwords
- **password vault offline** → password manager offline | … offline open source | … offline free | password keeper offline | … offline app

## 7. Brand-name and wording policy (summary; details in `platform-rules.md`)

- **Apple**, keyword field: "Names of other apps or companies aren't allowed." Product-page guide: don't include "Unauthorized use of trademarked terms … Terms that are not relevant to the app. Competing app names." Guideline 2.3.7: don't pack metadata with "trademarked terms, popular app names, pricing information, or other irrelevant phrases".
- **Play:** no "Free" or "No Ads" in the title. No "#1", "Best", "Top" or "New". No keyword lists. No comparisons with other apps. These rules apply to every translation.
