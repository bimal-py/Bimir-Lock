# Competitors: password managers on Google Play and the App Store

Collected 2026-10-10, US storefront unless noted.

**How the data was collected**
- **App Store titles, categories and ratings:** iTunes Search API (`https://itunes.apple.com/search?term=password+manager&entity=software&country=us&limit=50`, plus the same call for `password+keeper`, `password+vault`, `password+saver`, `offline+password+manager`, `offline+passwords`, `offline+password+safe`, `keepassium`, `enpass`, `keepass`). The API returns `primaryGenreName` and `genres`; the second genre is the secondary category.
- **App Store subtitles:** read from each public product page, e.g. `https://apps.apple.com/us/app/id1137397744`, header element `p.subtitle`. The API does not return subtitles.
- **Chart positions:** the badge on each product page, plus the legacy RSS top-free feeds `https://itunes.apple.com/{cc}/rss/topfreeapplications/limit=100/genre={6002|6007}/json`.
- **Play titles, short descriptions, categories, installs and ratings:** parsed from `https://play.google.com/store/apps/details?id=<pkg>&hl=en_US&gl=US`, in the page's embedded `ds:5` data. That is the same source the web page renders.
- **Play search order:** `https://play.google.com/store/search?q=<query>&c=apps&hl=en_US&gl=US`.
- **Rating counts:** App Store counts are for the US storefront only. Play counts are global.

---

## 1. Major brands: the head of the market

| App | App Store name | Apple subtitle | Apple category (primary + secondary) | Apple US ratings | Play title | Play short description | Play category | Play installs / rating | Model |
|---|---|---|---|---|---|---|---|---|---|
| Apple Passwords (built into iOS 18+) | Passwords | none | Utilities | 804,260 / 4.72 | not on Play | n/a | n/a | n/a | iCloud Keychain sync; the iPhone default |
| Google Password Manager | not on iOS (it lives inside Chrome) | n/a | n/a | n/a | Google Password Manager (`com.google.android.apps.credentialmanager`) | "A quicker way to access Google Password Manager on your phone." | **Tools** | shortcut app (install count shows "1+"); 4.16 from 16,112 ratings | Google account sync; the Android default. Ranks #1 on Play for "password manager", "password keeper", "save passwords" and "password manager app" |
| Bitwarden | Bitwarden Password Manager | Secure your digital life | Productivity + Utilities | 33,818 / 4.76 (#176 Productivity on its page badge) | Bitwarden Password Manager | "Bitwarden is a login and password manager that helps keep you safe while online." | Productivity | 5M+ / 4.73 (181,644) | Cloud, open source, free tier |
| 1Password | 1Password: Password Manager | Save & share passwords safely | Productivity + Utilities | 42,288 / 4.67 (#91 Productivity on its badge; #90 in the US Productivity RSS chart) | 1Password: Password Manager | "Store your passwords, credit cards, notes and more securely with 1Password" | Productivity | 1M+ / 4.60 (25,916) | Cloud, subscription |
| Proton Pass | Proton Pass - Password Manager | Passkeys, 2FA & secure vault | Productivity + Utilities | 8,491 / 4.84 | Password Manager - Proton Pass | "Encrypted password manager, safe passkeys, autofill login credentials, and 2FA." | Productivity | 1M+ / 4.79 (60,188) | Cloud, end-to-end encrypted, freemium |
| LastPass | LastPass Password Manager | Store & Autofill Passwords | Productivity + Utilities | 57,295 / 4.38 | LastPass Password Manager | "The Last Password you will ever need." | Productivity | 10M+ / 3.77 (235,901) | Cloud, freemium |
| Dashlane | Dashlane Password Manager | Autofill, VPN, Authenticator | Productivity + Utilities | 107,173 / 4.79 | Dashlane Password Manager | "Securely store and sync passwords, passkeys, and personal info on every device." | Productivity | 5M+ / 4.51 (242,681) | Cloud, subscription |
| NordPass | NordPass: Password Manager | Passkey keeper & secure vault | Productivity + Utilities | 13,009 / 4.65 | NordPass Password Manager | "Store passwords and passkeys securely in your vault. Log in easier everywhere." | Productivity | 1M+ / 4.43 (34,349) | Cloud, freemium |
| Keeper | Keeper Password Manager | Password Generator & Vault | Productivity + Business | 231,166 / 4.90 | Keeper Password Manager | "Password Manager & Vault for Unlimited Storage, Autofill & Dark Web Monitoring" | Productivity | 10M+ / 4.67 (111,496) | Cloud, subscription |
| RoboForm | RoboForm Password Manager | Keep Secure & Auto Fill Forms | Productivity + Utilities | 48,821 / 4.73 | RoboForm Password Manager | "Password Manager and Form Filler that remembers passwords so you don't have to." | Productivity | 1M+ / 4.73 (37,027) | Cloud, subscription |
| Enpass | Enpass Password Manager | Generate & Autofill Passwords | Productivity + Utilities | 1,310 / 4.24 | Enpass Password Manager | "Password and passkey manager – your vault in your cloud, safe from hackers." | Productivity | 1M+ / 3.86 (21,702) | Local vault plus your own cloud (no Enpass server); Indian company |
| Norton | Norton Password Manager | Secure Password Manager | **Utilities** + Productivity | 41,378 / 4.50 | Norton Password Manager | "Experience password freedom with Norton Password Manager." | **Tools** | 1M+ / 4.40 (92,694) | Cloud, bundled with Norton security |
| KeePassDX | not on iOS | n/a | n/a | n/a | **KeePassDX Passkey Vault** (renamed; it used to be "KeePassDX") | "Manage Passkey / Password in a local and open-source vault" | Productivity | 500K+ / 4.21 (5,045) | Offline, open source, KeePass .kdbx files |
| Keepass2Android | not on iOS | n/a | n/a | n/a | Keepass2Android Password Safe | "Keepass2Android is a password manager compatible with KeePass" | **Tools** | 1M+ / 4.35 (36,545) | Offline or BYO sync, KeePass files |
| Keepass2Android Offline | not on iOS | n/a | n/a | n/a | Keepass2Android Offline (`keepass2android.keepass2android_nonet`) | "Keepass2Android Offline is a variant of Keepass2Android for local files only" | **Tools** | 500K+ / 4.5 (5,465) | Offline-only build with no INTERNET permission |
| Strongbox | Strongbox - Password Manager | KeePass & Password Safe Vault | Productivity + Utilities | 4,069 / 4.73 | not on Play | n/a | n/a | n/a | KeePass and Password Safe files, local or BYO sync |
| KeePassium | KeePassium (KeePass passwords) | Respects your privacy | Productivity + Utilities | 1,416 / 4.70 | not on Play | n/a | n/a | n/a | Offline-first KeePass client |

**What this tells us**
- **Naming:** every big brand uses "Brand + Password Manager" (or "Brand: Password Manager") on both stores. No major brand uses "offline" anywhere in its title or subtitle. Proton leads its Play title with the keyword ("Password Manager - Proton Pass"), and Play allows that.
- **Subtitles:** big-brand subtitles sell sync, passkeys, 2FA, VPN or autofill (cloud features). Only KeePassium ("Respects your privacy") leans on privacy, so the "offline / no account" angle is unclaimed at the top of the market.
- **Passkeys:** passkey wording is spreading. NordPass, Proton and Bitwarden mention it, and KeePassDX renamed itself to "KeePassDX Passkey Vault". Bimir Lock does not support passkeys, so it must not use that word anywhere in its metadata.

---

## 2. Small offline vault apps: the real competition

These apps rank on the same long-tail queries Bimir Lock can win: offline, no account, password keeper, password saver and password safe.

### 2a. Google Play (US, global installs)

| Play title | Package | Short description (verbatim) | Category | Installs / rating | Where it ranks (Play US search, 2026-10-10) |
|---|---|---|---|---|---|
| Password Manager: My Passwords | com.er.mo.apps.mypasswords | "Secure offline password manager with passkeys, autofill, 2FA & unlimited entries" | Productivity | 1M+ / 4.76 (49,510) | #9 "password manager", #3 "password keeper", #11 "password saver", #13 "password vault" |
| Password Safe and Manager | com.reneph.passwordsafe | "Password manager with 2FA codes, passkeys & autofill. Offline AES-256 vault." | Productivity | 1M+ / 4.62 (58,841) | #13 "password manager", #6 "password keeper", #11 "password vault" |
| PassKeep: Password Manager | com.redeyes.sspasswords | "Offline password manager with autofill. No cloud, no account required." | **Tools** | 1M+ / 4.51 (16,727) | #12 "password keeper". **This is the closest positioning to Bimir Lock.** |
| Password Manager: Safe (SafeInCloud) | com.safeincloud.free | "Password manager with passkeys, built-in authenticator & Google Drive backup" | Productivity | 5M+ / 4.42 (52,154) | #15 "password manager" |
| Password Saver | com.gsonly.passbook | "This app stores your passwords. Simple and secure." | **Tools** (has ads) | 500K+ / 4.88 (20,908) | **#1 "password saver"** (exact-match title) |
| aWallet Password Manager | org.awallet.free | "Android Wallet Password Manager" | Productivity (has ads) | 1M+ / 4.71 (40,846) | top 20 for "save passwords" and "password saver" |
| One Key: password manager | com.gaurav.onekey | "Completely offline, Ad free, Fingerprint and Backup capable password manager" | Productivity | 100K+ / 4.44 (2,387) | mid-pack on "password manager app" and "save passwords" |
| DroidPass: Password Manager | com.passwordmanager.droidpass | "Autofill logins, passkeys & 2FA codes in one offline, encrypted vault" | Productivity | 100K+ / 4.52 (1,335) | #14 "password saver" |
| Offline Password Manager | app.desmundyeng.passwordmanager | "Simple & lightweight offline Password Manager with Biometric login" | Productivity | 100K+ / 3.71 (2,776) | #7 "offline password manager" |
| Offline Password Manager | com.bhanu.passwordmanager | "Offers secure password storage, No internet require for app to function." | **Tools** | 10K+ / 3.68 (299) | **#1 "offline password manager"** |
| Offline password manager: Zero | tech.bluespace.android.id_guard | "The safest offline password manager to generate, store and autofill passwords." | Tools | 10K+ / 4.21 (136) | #9 "offline password manager" |
| Owl Offline Password Manager | com.niven.passwordmanager | "True offline password manager. No internet access. Your data's locally encrypted" | Tools | 1K+ / no rating | #4 "offline password manager" |
| Offline Password Manager | com.jackappsdev.password_manager | "Minimalistic, Secure, Offline - Password Manager" | Tools | 1K+ / 4.2 (38) | #3 "offline password manager" |
| Offline Password Manager | com.androidsc.pass | "Keep passwords safe offline, encrypted & private. No internet needed." | Tools | **50+** / no rating | #6 "offline password manager" |
| PasswordBee Offline Manager | com.appbooster.passwordbee | "Offline password vault/locker with AES-256 encrypt. No cloud,no account,no ads." | Tools | **5+** / no rating | #10 "offline password manager"; also surfaces in Germany for "passwort manager offline" |
| Password Keeper | com.keenapps.passwordkeeper | "Keep track of all your passwords, securely and entirely offline" | Productivity | **500+** / no rating | **#7 "password keeper"** on exact-match title alone |
| **Bimir Lock (today)** | com.cklamib.bimirLock | "Bimir-Lock: Your Ultimate Data Guardian." | Tools | 10+ / no rating | Title "Bimir lock", developer name "Bimal kc". No category keyword in the title or short description, so it cannot rank for anything except its own name. |

**Play takeaways**
1. **Exact-match words in the title and short description win the long tail on Play, even with almost no installs.** Apps with 5–1,000 installs sit in the top 10 for "offline password manager" and "password keeper" because those words are in their titles. Play also indexes the short description and the full description.
2. **The "offline" niche on Play is crowded with near-identical "Offline Password Manager" titles, but they are weak:** low ratings, few installs, and several no longer updated. A polished app with "offline password manager" in the short description and a localized listing can overtake them.
3. **The biggest offline-positioned vaults (My Passwords, Password Safe, PassKeep) all hit 1M+ installs.** Each put "offline" or "no cloud, no account" in the short description, and none use the word in the title.
4. **Localized titles drive the big offline vaults' international reach.** The generic keyword goes before the colon and the brand after it:
   - My Passwords: "Palavras-passe: My Passwords" (BR), "Contraseñas: My Passwords" (ES/MX), "Kata Sandi: My Passwords" (ID), "पासवर्ड मैनेजर: My Passwords" (IN-hi), "Şifre Yöneticisi: My Passwords" (TR), "Менеджер паролей: My Passwords" (RU), "Gestore Password: My Passwords" (IT), "Menedżer haseł: My Passwords" (PL), "パスワード管理: My Passwords" (JP), "비밀번호 관리자: My Passwords" (KR), "পাসওয়ার্ড: My Passwords" (BD), "مدير كلمات السر: My Passwords" (SA).
   - SafeInCloud: "Gerenciador de senhas: Safe", "Pengelola kata sandi: Safe", "パスワード管理・Safe", "비밀번호 관리자・Safe", "Менеджер паролей: Safe", "Mots de passe et clés: Safe", "Wachtwoordmanager: Safe".
   - Password Safe: "Password Safe Senhas", "Password Safe y Gestor", "Password Safe und Manager", "Password Safe จัดการรหัสผ่าน", "Password Safe ম্যানেজার".

   Source: Play search in each locale, e.g. `https://play.google.com/store/search?q=gerenciador%20de%20senhas&c=apps&hl=pt-BR&gl=BR`. The full lists are in `localization.md`.

### 2b. App Store (US)

| App Store name | Seller | Subtitle (verbatim) | Category (primary + secondary) | US ratings | Where it ranks (iTunes Search API order) |
|---|---|---|---|---|---|
| Password Manager - Safe Lock | AppRover | Autofill Passwords & Passcode | Productivity only | 16,520 / 4.50 | #15 "password manager" (US), **#5 in India and #2 in Nepal** for "password manager" (IN 4,350 ratings, NP 281 ratings). It also appears as an autocomplete suggestion in the NP, ID, TR, VN, TH, SA and PK storefronts. |
| Password Manager' | 广栋 莫 | Lock Apps Keep Vault Safe | Productivity + Utilities | 16,814 / 4.37 | #16 "password manager", #9 "password vault", #5 "offline password manager" |
| iPassworder Password Manager | Dmytro Vynokurov | Easiest way to store passwords | Productivity + Utilities | 4,696 / 4.78 | #5 "password keeper", **#3 "offline password manager"** |
| My Passwords Manager | Nikos Grammatikopoulos | none set | Productivity + Utilities | 4,037 / 4.71 | #20 "password manager", #10 "password keeper" |
| Password Manager: Passible | FITNESS22 LTD | Password safe & vault storage | Productivity + Utilities | 6,272 / 4.74 | #12 "password manager", #11 "password vault" |
| Password Manager (2FAS Pass) | 2FAS | Private, Secure, Local-first. | Productivity + Utilities | 26 / 4.54 | **#4 "offline password manager"** |
| One Key: Password Manager | Gaurav Gaurav | Safe offline password manager | Productivity + Utilities | 169 / 4.80 | #9 "offline password manager" |
| Surepass Password Manager | Refined Insight Ltd | Offline Safe with AutoFill | Productivity + Utilities | 484 / 4.82 | #13 "offline password manager" |
| Pocket Pass Manager | Jorge Carlos Frias Galan | The offline Password Manager | Utilities + Productivity | 24 / 4.46 | #30 "offline password manager" |
| OffVault - Password Manager | Brothapps S.L. | Offline & Encrypted. No Cloud. | Utilities + Productivity | 0 | #27 "offline password manager" |
| Password Manager Pro offline | Nagy Solaiman | All Features you would need! | Utilities + Productivity | 0 | #6 "offline password manager" |
| Offline Password Safe | (2021 app) | n/a | Utilities | 1 | **#1 "offline password safe"**, which is also the top App Store autocomplete suggestion for "offline password" |
| Vault: Offline Password Safe | (May 2026) | n/a | Utilities | 0 | #2 "offline password safe" |
| LocalPass - Offline Passwords | (Oct 2025) | n/a | Utilities | 0 | #1 "offline passwords" |
| 8PWD 2026 – Offline Passwords | (Sep 2026) | n/a | Utilities | 0 | #3 "offline passwords" |
| Password Saver & Vault / LockIt Password Saver / Passaver | various | n/a | Utilities | 0 / 17 / 1 | top 12 for "password saver" on exact-match names |
| PassVault: Password Keeper | 晖明 甘 | n/a | Productivity | 2 | #11 "password keeper" |
| Password Safe Manager & Vault (iOS version of reneph Password Safe) | Robert Ehrhardt | Passkey, 2FA & Authenticator | Productivity + Utilities | 1,596 / 4.71 | **#1 "password safe"**, #13 "password vault" |
| pwSafe 2 - Password Safe | Huvisoft | Password Manager | Utilities + Productivity | 5,108 / 4.75 (paid $2.99) | #2 "password safe" |

**App Store takeaways**
1. **On iOS the "offline" long tail is held by apps with 0–500 ratings,** most launched in 2025–2026 and filed under Utilities. The App Store weights the name and subtitle heavily, and apps with zero ratings rank #1 to #6 because the exact words are in their name or subtitle. Bimir Lock can win "offline password manager", "offline password safe", "password keeper" and "password saver" by putting those words in the name, subtitle and keyword field.
2. **The App Store already autocompletes "offline password ..."** in the US, GB and IN storefronts, so users really type these phrases. The suggestions are "offline password safe", "offline password generator", "opm: offline password manager", "localpass - offline passwords", "vault - offline passwords" and "bastion offline password mgr".
3. **"Password Manager - Safe Lock" shows what a generic exact-match name does in South Asia:** #2 in Nepal and #5 in India for "password manager", ahead of 1Password, Keeper and LastPass. Those storefronts are thin. Nepal's top results have under 300 local ratings.
4. **Apple Passwords is #1 for every generic query in every storefront tested** (US, IN, NP, BR, DE, ES, FR, IT, JP, ID, VN, SA, NL, TW). It is the default every iPhone user already has. Bimir Lock's pitch on iOS has to be what Passwords is not: no Apple account or iCloud, PIN plus Face ID, wrong-PIN alerts, and a portable encrypted backup file.

---

## 3. How small offline apps name themselves (patterns to copy or avoid)

| Pattern | Examples | Use for Bimir Lock? |
|---|---|---|
| "Offline" as the title's lead word | Offline Password Manager (×5 on Play), Offline Password Safe, LocalPass - Offline Passwords | No. The brand must come first, and five apps with identical titles look like clones. Put "offline" in the Play short description and the Apple subtitle instead. |
| "Brand: Password Manager" | One Key: password manager, DroidPass: Password Manager, PassKeep: Password Manager | **Yes.** "Bimir Lock: Password Manager" is 28 characters. |
| Benefit trio in the short description or subtitle: "No cloud, no account, no ads" | PassKeep ("No cloud, no account required"), PasswordBee ("No cloud,no account,no ads"), OffVault ("Offline & Encrypted. No Cloud.") | **Yes for "no cloud, no account".** Keep "no ads" out of the Play title and short description, because Play guidance says "No Ads" promotes deals (see `platform-rules.md`). |
| "No internet access / no internet needed" | Owl, AndroiDSC, bhanu "Offline Password Manager", Keepass2Android Offline | **No.** Bimir Lock's Android manifest declares INTERNET (the `upgrader` version check), so it cannot truthfully claim "no internet access". Say "works offline; your vault never leaves your phone". |
| Synonym titles that catch other queries | Password Saver (#1 "password saver"), Password Keeper (#7 "password keeper"), Password Safe… | Partly. Use "keeper", "saver", "safe" and "vault" in the Apple subtitle and keyword field, and in the Play description. |
| Passkey / 2FA / authenticator claims | My Passwords, Password Safe, DroidPass, Proton, NordPass | **No.** These features are not in Bimir Lock, and claiming them is misleading (Apple 2.3.1, Play metadata policy). |

---

## 4. What this means for Bimir Lock

- **The real competition is the offline-vault tier:** My Passwords, Password Safe, PassKeep, Password Saver, One Key and DroidPass on Play, and iPassworder, Password Manager - Safe Lock, Passible, Surepass, One Key and the 2025–26 "offline" newcomers on iOS. The cloud brands are not the target. Bimir Lock cannot outrank Google, Apple or Bitwarden on "password manager", but it can rank on combinations with "offline", "no account", "keeper", "saver", "safe", "locker" and "vault", and in non-English storefronts.
- **Bimir Lock's real differentiators,** none of which the top results advertise in their metadata:
  - no account or sign-up, and no cloud sync;
  - an encrypted backup file with its own backup password that the user keeps anywhere;
  - wrong-PIN lockout plus an intruder photo;
  - free with no ads.
- **Gaps in today's listing:**
  - The Play title "Bimir lock" contains no keyword.
  - The short description "Your Ultimate Data Guardian" is superlative fluff with no searchable term.
  - The Play category is Tools.
  - The iOS app is not live yet; the iTunes lookup for `com.cklamib.bimirLock` returns 0 results.
