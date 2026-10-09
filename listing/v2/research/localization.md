# Localization: which languages and markets, and the terms people actually search

Collected 2026-10-10.

**How each language was scored.** Opportunity combines four factors:
- **Market size:** smartphone and store reach.
- **Native search demand:** SE Ranking Google web volume for the native term.
- **Competition in the native-language store results:** rating counts of the top App Store results from the iTunes Search API, and the Play titles in that locale.
- **Whether people search in their own language or in English:** compared via SE Ranking volume, App Store hints, Google autocomplete and Play search in each locale.

**Sources used throughout**
- SE Ranking `DATA_getKeywordsMetrics` (Google web volume, Oct 2026).
- App Store search hints (`MZSearchHints`) with the storefront header for each country, e.g. `X-Apple-Store-Front: 143503,29` for Brazil.
- Google autocomplete: `suggestqueries.google.com/complete/search?client=firefox&hl=<lang>&gl=<cc>&q=…`.
- iTunes Search: `itunes.apple.com/search?term=<native term>&country=<cc>&entity=software`.
- Play search: `play.google.com/store/search?q=<term>&c=apps&hl=<lang>&gl=<CC>`.

## 0. Structural facts that change the plan

1. **App Store: English (U.K.) is the primary language of most of our target storefronts.** Source: https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations

   | Storefront | Primary language | Additional indexed languages |
   |---|---|---|
   | Nepal | English (U.K.) | none |
   | India | English (U.K.) | Bangla, Gujarati, **Hindi**, Kannada, Malayalam, Marathi, Odia, Punjabi, Tamil, Telugu, Urdu |
   | Indonesia | English (U.K.) | Indonesian |
   | Pakistan | English (U.K.) | Urdu |
   | Saudi Arabia | English (U.K.) | Arabic |
   | Türkiye | English (U.K.) | Turkish |
   | Thailand | English (U.K.) | Thai |
   | Vietnam | English (U.K.) | Vietnamese |
   | Malaysia | English (U.K.) | Malay |
   | Philippines | English (U.K.) | none |
   | Poland | English (U.K.) | Polish |
   | Egypt | English (U.K.) | Arabic, French |
   | **United States** | English (US) | Arabic, Chinese (Simplified), Chinese (Traditional), French, Korean, Portuguese (Brazil), Russian, Spanish (Mexico), Vietnamese |
   | Brazil | Portuguese (Brazil) | English (U.K.) |
   | Mexico | Spanish (Mexico) | English (U.K.) |
   | Germany | German | English (U.K.) |
   | Japan | Japanese | English (US) |

   **Consequences:**
   - **en-GB is the single most valuable App Store localization after en-US.** It is indexed in Nepal, India and about 100 other storefronts, and as a secondary language in Brazil, Mexico, Germany and others.
   - In Türkiye, Thailand, Vietnam, Indonesia, Saudi Arabia, Pakistan and Poland, a native localization adds a **second** keyword field on top of en-GB, so English and native terms both count.
2. **The App Store has no Nepali localization.** Apple's 50 localizations include Hindi, Bangla, Urdu, Tamil, Telugu, Marathi, Gujarati, Kannada, Malayalam, Odia and Punjabi (11 were added in 2026), but not Nepali. **Play does support Nepali (`ne-NP`)**, as well as `hi-IN`, `bn-BD`, `ur` and `fil`. Source: https://support.google.com/googleplay/android-developer/answer/9844778
3. **Play machine-translates missing listings automatically** and shows a notice: "automated translations of your app's store listing will be available to Google Play users". Auto-translation does not produce good *keywords*, and it never fixes the title, so hand-localize the title and short description for the top markets.
4. **Apple's keyword field is 100 *bytes*, while name and subtitle are 30 *characters*.** CJK, Devanagari, Thai and Arabic use 3 bytes per character in UTF-8, so a Japanese or Hindi keyword field holds only about 33 characters. Spend those markets' bytes on the 3–5 strongest terms.
5. **Play says to localize screenshots that have text:** "For screenshots that contain text, provide separate screenshots and promotional videos for each language that you support." Source: https://support.google.com/googleplay/android-developer/answer/13393723

## 1. Ranked list of languages to localize

The top 15 languages are marked ★. "Native term" volumes are SE Ranking Google web volumes for the listed country.

| Rank | Locale (Play / Apple) | Main markets | Native head term (volume) | English "password manager" in the same country | Native store competition (App Store top results for the native term) | Why it ranks here |
|---|---|---|---|---|---|---|
| ★1 | **English UK** (`en-GB` Apple; Play `en-GB` + `en-IN`) | Nepal, India, Pakistan, Bangladesh, Philippines, Malaysia, Singapore, Nigeria, Kenya; secondary in Gulf, ID, TR, VN, TH | — | IN 550K, NP 33.1K, SA 27.8K, ID 14.8K, TH 5.4K | NP: Apple Passwords 2,404 ratings, then Password Manager - Safe Lock 281, then Bitwarden 27 | English is how South Asia searches. On Apple, en-GB is the primary indexed language for NP and IN, so it is mandatory. |
| ★2 | **Portuguese (Brazil)** (`pt-BR`) | Brazil (also covers some Portugal traffic) | gerenciador de senhas **450K**; gerenciador de senha 49.5K; gerador de senhas 22.4K | 3.2K | Apple BR: iSenhas 1,503 ratings, Proton 267, Safe 1,042, NordPass 407 | Huge native demand, people search in Portuguese, top native-named apps are weak. US Apple also indexes pt-BR. |
| ★3 | **Spanish** (`es-419` + `es-ES` Play; `es-MX` + `es-ES` Apple) | Mexico, Spain, LatAm, US Hispanics | MX: gestor de contraseñas **135K**, administrador de contraseñas 33.1K. ES: gestor de contraseñas **90.5K** | MX 10.8K, ES 6.6K | Apple MX for "administrador de contraseñas": #2 has 0 ratings; Apple ES: Gestor de Contraseñas (Utilities) has 17 | Two storefronts with huge native demand and weak native-named apps. The US App Store also indexes es-MX, so es-MX keywords count in the US too. |
| ★4 | **Indonesian** (`id`) | Indonesia (huge Android base) | "kata sandi" 49.5K; "pengelola kata sandi" no measurable volume | **14.8K** (English dominates) | Apple ID "pengelola kata sandi": the top 9 results all have **0–37 ratings** | Near-zero native competition. On Apple the English en-GB fields are already indexed in ID, so the Indonesian field is pure upside. |
| ★5 | **Turkish** (`tr`) | Türkiye | şifre yöneticisi **49.5K**; şifre oluşturucu 8.1K | 3.6K | Apple TR "şifre yöneticisi": Bitwarden 622 ratings, Safe 183, others 0–40 | Strong native demand with low competition. |
| ★6 | **Vietnamese** (`vi`) | Vietnam | quản lý mật khẩu **18.1K**; trình quản lý mật khẩu 8.1K | 4.4K | Apple VN: top native results have 0–546 ratings | Native demand exceeds English, competition is low, and the US App Store also indexes Vietnamese. |
| ★7 | **German** (`de-DE`) | Germany, Austria, Switzerland | passwortmanager **201K**; passwort manager 47.5K; passwort generator 33.1K | 96.2K | Apple DE: Bitwarden 9,097 ratings, SecureSafe 21,708, Dashlane 14,032, Passwort Safe 3,145 | High competition, but the most privacy-minded market. Offline is a real query in Germany (passwortmanager offline 110; offline passwort manager 70; "ohne cloud / abo / anmeldung / internet" in autocomplete). |
| ★8 | **French** (`fr-FR`; Apple `fr` + `fr-CA`) | France, Canada, Belgium, Switzerland, francophone Africa | gestionnaire de mot de passe **60.5K**; générateur mot de passe 40.5K | 10.8K | Apple FR: Sésame 1,943 ratings, Coffre-fort pour mot de passe 90, Gestionnaire des mots de passe 3 | Big demand with mid competition. French is also indexed in the US, Egypt and many African storefronts. |
| ★9 | **Hindi** (`hi-IN`) | India | "पासवर्ड मैनेजर" appears in Google autocomplete for "पासवर्ड" (IN and NP), but SE Ranking has no measurable volume | 550K | Play IN: Proton uses "Proton Pass: पासवर्ड मैनेजर" and My Passwords "पासवर्ड मैनेजर: My Passwords" | Most Indians search in English, but an Apple Hindi localization is an **extra indexed keyword field in India**, and a Play Hindi listing converts Hindi-UI phones. Moderate effort. |
| ★10 | **Japanese** (`ja-JP`) | Japan (high iOS share) | パスワードマネージャー **301K**; パスワード管理 40.5K; パスワード管理アプリ 8K; パスワード生成 246K | 14.8K | Apple JP: local apps with **39K–45K ratings** (パスワード管理 - 面倒なパスワードを一括管理, パスマネ) | Large, but entrenched local apps and 3-byte keywords. Autocomplete has "パスワード管理アプリ オフライン" and "…無料 android オフライン", and a JP App Store app is named "…オフライン、ローカル対応", so the offline angle is real. |
| ★11 | **Italian** (`it-IT`) | Italy | gestore password **90.5K**; gestione password 74K; app per salvare password 170 | 20.1K | Apple IT: Keeper 6,603 ratings, mSecure 3,559, Dashlane 2,748 | Italians use the English loanword "password", so localization is cheap. "gestore password offline" is in autocomplete. |
| ★12 | **Arabic** (`ar`) | Saudi Arabia, UAE, Egypt, Gulf | مدير كلمات المرور 12.1K; كلمات المرور 8.1K | **27.8K** (English > Arabic) | Apple SA "مدير كلمات المرور": top results have **0–25 ratings** | Native competition is nearly empty, and Arabic is indexed in the US, SA and Egypt App Stores. RTL screenshots are extra work. |
| ★13 | **Polish** (`pl-PL`) | Poland | menedżer haseł **60.5K**; generator haseł 27.1K | 6.6K | Apple PL: Bitwarden 1,282 ratings, Safe 202, others 0–2 | Good demand, weak native competition, and Polish is a second indexed field on top of en-GB in Poland. |
| ★14 | **Korean** (`ko-KR`) | South Korea | 비밀번호 관리자 **18.1K**; 비밀번호 관리 앱 70 | 1.1K | Apple KR: local 비밀번호 뭐였지? 5,772 ratings, others ≤328 | Native-only market. Korean is also indexed in the US App Store. |
| ★15 | **Russian** (`ru-RU`) | Russia, Kazakhstan, Belarus, Central Asia | менеджер паролей 3.6K on Google (understated: Yandex dominates); хранение паролей 210; приложение для хранения паролей 140 | n/a | Apple RU: Kaspersky 2,809 ratings, Safe 1,491, Citadel 202 | Large Russian-speaking base, mid competition. Russian is indexed in the US App Store. Payments don't matter for a free app. |
| 16 | Thai (`th`) | Thailand | จัดการรหัสผ่าน 1.5K; รหัสผ่าน 22.2K | **5.4K** (English > native for the app term) | Apple TH: top native results have 0–63 ratings | Low competition, but English already covers most demand. |
| 17 | **Nepali** (`ne-NP`, Play only) | Nepal (home market) | no measurable volume; NP autocomplete for "पासवर्ड" returns "पासवर्ड मैनेजर" (Hindi spelling). Google's own Nepali Play title is "Google पासवर्ड म्यानेजर". | **33.1K** | n/a (no Nepali App Store localization) | Search happens in English, so do this for **home-market trust and conversion**, not ranking. Cheap for a Nepali developer. |
| 18 | Dutch (`nl-NL`) | Netherlands, Belgium | wachtwoordmanager 74K (one-month spike; baseline about 6.6K); wachtwoord manager 8K; wachtwoordkluis 260 | 22.4K | Apple NL: Bitwarden 2,524 ratings, Keeper 2,959, Dashlane 4,600 | Small and English-friendly, with entrenched brands. |
| 19 | Chinese Traditional / Simplified (`zh-TW` / `zh-Hans`) | Taiwan, Hong Kong, Singapore, Malaysia; mainland China App Store only | 密碼管理 / 密码管理器; 密码本 ("password book") is a popular CN app-name pattern | n/a | Apple CN: 密码管家 3,512 ratings, 密码本 1,202 | Both are indexed in the US App Store. **The mainland China App Store requires an ICP filing number for new apps (MIIT rule), so plan zh-Hans for TW, SG, MY and US indexing, not mainland launch.** Play is unavailable in mainland China. |
| 20 | Bangla (`bn-BD` Play; Apple `bn` for India) | Bangladesh, West Bengal | English searches dominate (My Passwords uses "পাসওয়ার্ড: My Passwords") | n/a | — | Large Android base, low priority until the top 15 are done. A Bangla title must be shortened: "Bimir Lock: পাসওয়ার্ড ম্যানেজার" is 32 characters. |

**Where users search in English (keep English terms, even inside localized keyword fields):**
- Nepal, India, Pakistan, Bangladesh, Philippines, Malaysia and Singapore.
- Indonesia: "password manager" 14.8K vs no measurable volume for "pengelola kata sandi". Indonesian autocomplete still shows "aplikasi password manager", "penyimpan password" and "aplikasi penyimpan password gratis", all mixing English "password" into Indonesian.
- Saudi Arabia and the Gulf: English 27.8K vs Arabic 12.1K.
- Thailand: English 5.4K vs native 1.5K.
- Italy: native phrases use the loanword "password".

**Where the native term clearly wins:** Brazil, Mexico, Spain, Germany, France, Türkiye, Vietnam, Japan, Korea and Poland.

## 2. Native search terms by language

**How each term was verified:**
- **V** = volume measured by SE Ranking (number shown).
- **AC** = appears in Google autocomplete in that country.
- **H** = App Store search hint in that storefront.
- **P** = used in Play titles of top apps in that locale.

Unmarked terms are standard translations with no store or search evidence. Have a native speaker confirm them before use.

| Lang | "password manager" | "password keeper / saver / save passwords" | "password vault" | "offline" / "no account" | Suggested title (≤30 chars), to validate with a native speaker |
|---|---|---|---|---|---|
| pt-BR | **gerenciador de senhas** (V 450K, H, P "Gerenciador de senhas: Safe", "Keeper Gerenciador de senhas"); gerenciador de senha (V 49.5K) | app para guardar senhas (AC); aplicativo para guardar senhas (V 140, AC); guardar senhas (V 140); salvar senhas (V 1.9K) | **cofre de senhas** (V 410, H "cofre de senhas app", AC "cofre de senhas gratuito") | offline (AC "gerenciador de senhas offline"); sem internet; sem conta | `Bimir Lock: Gerenciador Senhas` (30); subtitle `Cofre offline, sem conta` (24) |
| es-MX / es-419 | **gestor de contraseñas** (V 135K, H, P); **administrador de contraseñas** (V 33.1K, H, AC) | app para guardar contraseñas (V 70, AC); guardar contraseñas (V 130) | bóveda de contraseñas; baúl de contraseñas (no volume) | **offline** (AC "gestor de contraseñas offline", "mejor gestor de contraseñas offline"; Play titles "Gestor de Contraseñas Offline", "Gestor Claves Sin Conexión"); sin conexión; sin cuenta | `Bimir Lock: Gestor Contraseñas` (30); put `administrador` in es-MX keywords |
| es-ES | **gestor de contraseñas** (V 90.5K); gestor contraseñas (V 6.6K, H) | guardar contraseñas (V 290, H); app para guardar contraseñas (V 90, AC) | — | gestor de contraseñas offline (V 10) | same as es-MX |
| de-DE | **passwortmanager** (V 201K, H); passwort manager (V 47.5K, H, P "Keeper Passwort Manager"); Passwort-Manager (P "1Password: Passwort-Manager", "Passwort-Manager: Safe") | **passwörter speichern** (V 250); passwort app (V 1.1K, H) | **passwort tresor** (V 390, H, AC "passwort tresor app kostenlos"); passwort safe (V 50, H) | **offline** (V "passwortmanager offline" 110, "offline passwort manager" 70; AC "passwort manager offline kostenlos"); **ohne Cloud / ohne Anmeldung / ohne Abo / ohne Internet** (AC, all four) | `Bimir Lock: Passwortmanager` (27); subtitle `Offline Passwort-Tresor` (23); keywords: `manager,passwort,ohne,cloud,konto,abo,…` |
| fr-FR | **gestionnaire de mot(s) de passe** (V 60.5K / 6.6K; AC; H "gestionnaire mots de passe") | enregistrer mot de passe (V 320); application mot de passe (V 590) | **coffre-fort mots de passe** (H; AC "coffre fort mot de passe gratuit") | **hors ligne** (AC "gestionnaire de mot de passe hors ligne"); **sans abonnement** (AC); sans compte | `Bimir Lock: Mots de passe` (25); subtitle `Gestionnaire hors ligne` (23) |
| id | **password manager** (V 14.8K, English); pengelola kata sandi (AC, H; P "Pengelola kata sandi: Safe", "Bitwarden - Pengelola Sandi") | **penyimpan password** / aplikasi penyimpan password (AC); aplikasi untuk menyimpan password (AC); Kata Sandi (P "Kata Sandi: My Passwords") | brankas kata sandi | offline (AC "password manager offline" in ID); tanpa akun; tanpa internet | `Bimir Lock: Pengelola Sandi` (27); subtitle `Kata sandi offline, tanpa akun` (30) |
| tr | **şifre yöneticisi** (V 49.5K, H, AC; P "Şifre Yöneticisi: My Passwords") | **şifre saklama uygulaması** (AC); şifre uygulaması (H) | şifre kasası (no hint) | internetsiz (AC "internetsiz şifre"); çevrimdışı | `Bimir Lock: Şifre Yöneticisi` (28) |
| vi | **quản lý mật khẩu** (V 18.1K, AC); trình quản lý mật khẩu (V 8.1K, H) | **lưu mật khẩu** (H); app lưu mật khẩu (AC); ứng dụng lưu mật khẩu (AC) | kho mật khẩu | offline (Vietnamese users commonly use the loanword); ngoại tuyến | `Bimir Lock: Quản lý mật khẩu` (28) |
| hi | पासवर्ड मैनेजर (AC in IN and NP; P "Proton Pass: पासवर्ड मैनेजर") + Latin "password manager" (V 550K) | पासवर्ड सेव (AC "पासवर्ड सेव कैसे करें", "सेव्ड पासवर्ड मैनेजर"); Latin "password saver" (H in IN) | पासवर्ड वॉल्ट | ऑफलाइन; Latin "offline" | `Bimir Lock: पासवर्ड मैनेजर` (26 chars / 52 bytes) |
| ja | **パスワード管理** (V 40.5K, H, AC); パスワードマネージャー (V 301K, H); パスワード管理アプリ (V 8K, H, AC) | パスワード管理帳 (H; app "パスワード管理帳（パスメモ）"); パスワード 保存 | パスワード金庫 | **オフライン** (AC "パスワード管理アプリ オフライン"); 買い切り / 無料 (AC) | `Bimir Lock: パスワード管理` (19); subtitle e.g. `オフラインのパスワード金庫` |
| ko | **비밀번호 관리자** (V 18.1K, H, AC); 비밀번호 관리 (V 60, H); 비밀번호 관리 앱 (V 70, AC "…추천") | **비밀번호 저장 앱** (AC); 비밀번호 저장 (AC) | 비밀번호 금고 (Keeper KR uses "보안 금고") | 오프라인 (no AC hit) | `Bimir Lock: 비밀번호 관리자` (20) |
| it | **gestore password** (V 90.5K, H, AC); gestione password (V 74K, H); password manager (V 20.1K) | **app per salvare password** (V 170, AC); salvare password (V 110) | cassaforte password (V 20) | **offline** (V "password manager offline" 50; AC "gestore password offline") | `Bimir Lock: Gestore Password` (28) |
| ar | **مدير كلمات المرور** (V 12.1K, AC; P "Proton Pass: مدير كلمات المرور"); English "password manager" (V 27.8K) | **برنامج حفظ كلمات المرور / السر** (AC); حفظ كلمات المرور | خزنة كلمات المرور (H "password safe خزنة كلمات السر") | بدون إنترنت; بدون حساب | `Bimir Lock: مدير كلمات المرور` (29); RTL screenshots |
| pl | **menedżer haseł** (V 60.5K, AC; P "Menedżer haseł: Safe") | aplikacja do przechowywania haseł (V 70, AC); aplikacja do haseł (AC) | sejf na hasła (no volume) | **offline** (AC "menedżer haseł offline"); bez konta | `Bimir Lock: Menedżer haseł` (26) |
| ru | **менеджер паролей** (V 3.6K, H, AC); хранитель паролей (V 70, H, AC) | **приложение для хранения паролей** (V 140, AC); хранение паролей (V 210, H) | сейф для паролей (H "сейф - хранитель паролей") | **оффлайн / офлайн** (AC "менеджер паролей оффлайн"); без интернета | `Bimir Lock: Менеджер паролей` (28) |
| th | จัดการรหัสผ่าน (V 1.5K, AC; P "NordPass: แอพจัดการรหัสผ่าน"); ตัวจัดการรหัสผ่าน (Apple result names) | เก็บรหัสผ่าน (no hint) | — | ออฟไลน์ | `Bimir Lock: จัดการรหัสผ่าน` (26) |
| ne (Play) | पासवर्ड म्यानेजर (Google's own NP Play title "Google पासवर्ड म्यानेजर"); Latin "password manager" (V 33.1K) | पासवर्ड सेभ; Latin "password saver" (V 90) | पासवर्ड भल्ट | अफलाइन | `Bimir Lock: पासवर्ड म्यानेजर` (28) |
| nl | **wachtwoordmanager** (H, AC); wachtwoord manager (V 8K) | wachtwoorden opslaan (V 320) | **wachtwoordkluis** (V 260) | offline | `Bimir Lock: Wachtwoordmanager` (29) |
| zh-Hans / zh-Hant | 密码管理器 / 密碼管理 (H, AC); 密碼管理員 (TW AC) | **密码本** (H: many CN app names) | 密码箱 / 密码保险箱 (H) | 离线 / 離線 | `Bimir Lock: 密码管理器` (17) / `Bimir Lock: 密碼管理` (16) |

## 3. Recommended rollout order

1. **Wave 1, launch.** Write by hand.
   - `en-US` (Apple, Play default) and `en-GB` (Apple; Play `en-GB` + `en-IN`).
   - `pt-BR`, `es-MX`/`es-419` + `es-ES`, `id`, `tr`, `vi`, `ne-NP` (Play only; home market).
2. **Wave 2, about a month later.** Use App Store Connect and Play Console search-term reports from wave 1 to tune these.
   - `de-DE`, `fr-FR`, `hi-IN`, `it-IT`, `ar`, `pl-PL`.
3. **Wave 3.** `ja-JP`, `ko-KR`, `ru-RU`, `th`, `nl-NL`, `zh-Hant`/`zh-Hans`, `bn-BD`.

**For every localized listing**
- Translate the title and short description or subtitle by hand, ideally with native review. Let Play auto-translate the long description only as a stop-gap.
- Keep the English head term ("password manager") in the keyword field wherever section 1 shows English demand: ID, TH, SA, IT, IN.
- Localize screenshot captions. Keep captions short, under 20% of the image (Play rule).
- Never translate a claim the app cannot keep:
  - No "app lock": the app does not lock on open.
  - No "secure notes" or "encrypted notes": Notes are not encrypted.
  - No "no internet access": Android declares the INTERNET permission.
