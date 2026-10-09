# Store setup — every field fastlane cannot set

fastlane uploads the listing text, screenshots, feature graphic, URLs, categories
(Apple), copyright and App Review contact. Everything below is a form in the Play
Console or App Store Connect that you fill in by hand, once. Each answer is checked
against the code (see the feature inventory summary at the bottom).

Order of work for 1.1.1:

1. Fix the website (privacy policy + app page) — **before** submitting either store
2. Play Console: App content forms → Store settings → (upload listing with fastlane)
3. App Store Connect: App Information → Pricing → App Privacy → (fastlane) → build → submit

---

## 0. The website (blocking)

| Page | Today | Do |
|---|---|---|
| https://bimalkhatri.com.np/bimir-lock/privacy-policy | Generic template: claims email, device IDs, usage analytics, IP, an account | Replace the body with `listing/v2/PRIVACY_POLICY.md` |
| https://bimalkhatri.com.np/bimir-lock | "activity monitoring … in real time", "Android" only, no App Store link | Replace the copy with the "Website app page" block below; add the App Store link once live: `https://apps.apple.com/app/id6821090857` |
| https://bimalkhatri.com.np/bimir-lock/terms-and-conditions | not reviewed here | Check it does not mention accounts, subscriptions or data collection |

Both live in the website's Supabase content (`supabase/seeds/0011_personal_apps.sql`
seeded the app page), not in this repo.

**Website app page (replacement copy)**

- Tagline: *An offline password manager. No account, no cloud, no ads.*
- About: *Bimir Lock keeps your passwords encrypted on your own phone. Every saved
  password opens only with your 6-digit PIN, fingerprint or Face ID. It creates
  strong passwords, flags weak and reused ones, fills them into other apps, and backs
  up to one encrypted file you keep wherever you like.*
- Highlights: **Encrypted on your phone** — AES-256-GCM with a key in Android
  Keystore / iOS Keychain. **Password Checkup** — finds weak and reused passwords on
  the device. **Autofill** — fill passwords into other apps; Android can save new
  logins too. **Wrong PIN alerts** — the keypad locks after 7 wrong PINs and can
  photograph whoever is guessing.
- Platforms: Android, iOS · Category: Security

---

## 1. Google Play Console — `com.cklamib.bimirLock`

### App content (Policy → App content)

| Form | Answer | Why |
|---|---|---|
| **Privacy policy** | `https://bimalkhatri.com.np/bimir-lock/privacy-policy` | After the page is fixed |
| **Ads** | **No, my app does not contain ads** | No ad SDK |
| **App access** | **All functionality is available without special access** | No login; the reviewer sets their own PIN |
| **Content rating** (IARC) | Category: **"All other app types"** (utility). Violence, sexuality, language, controlled substances, gambling: **No** to all. "Do users interact or exchange content?" **No**. "Shares user's current physical location?" **No**. "Allows purchase of digital goods?" **No**. "Unrestricted internet/web browser?" **No** (only fixed links open). | Expect **Everyone / PEGI 3 / USK 0** |
| **Target audience and content** | **18 and over** (optionally also 16–17). Not appealing to children: **No** | Keeps it out of the Families programme |
| **News app** | No | |
| **COVID-19 tracing** | No | |
| **Data safety** | see below | |
| **Government app** | No | |
| **Financial features** | **My app doesn't provide any financial features** | Storing a bank password is not a financial feature |
| **Health** | No health features | |
| **Advertising ID** (Android 13+) | **No**, the app does not use an advertising ID | No ads/analytics SDKs |
| **Photo and video permissions** | Not declared — the app uses the camera and the system photo picker, not `READ_MEDIA_IMAGES` | Check the **release** merged manifest; only a debug merge was inspected |

### Data safety

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | (not asked once "No") |
| Do you provide a way for users to request that their data is deleted? | (not asked once "No") |

Why "No" is correct under Google's definitions:
- **Collected** means sent off the device by the app. Bimir Lock sends nothing; the
  vault, notes, photos and settings never leave the phone.
- **Backup files** are created by an explicit user action and go where the user
  picks in the system save dialog — Google treats user-initiated transfers to a
  destination the user chooses as not collected.
- **Autofill** fills fields on the device; it is the user's own data moving between
  apps on their phone.
- The **store version check** (upgrader) only asks Google Play/App Store for the
  latest version number — not user data.

Optional badges you can still show: "No data shared with third parties", "No data collected".

### Store settings (Grow → Store presence → Store settings)

| Field | Value |
|---|---|
| App category | **Productivity** (move from Tools) — 34 of 49 password managers on Play sit there, including the big offline vaults; see `research/categories.md` |
| Tags (up to 5) | **Password manager**, **Privacy & security** (add others only if they truly apply) |
| Contact email | khattribimal90@gmail.com (already set) |
| Phone | Already set. It is shown publicly on the listing — remove it if you'd rather not |
| Website | change to `https://bimalkhatri.com.np/bimir-lock` (today: the home page) |
| External marketing | On |

### Main store listing

Uploaded by fastlane from `listing/v2/play/<locale>/`:

```sh
python3 tool/check_listing.py && python3 tool/assemble_listing.py
cd android && bundle exec fastlane upload_listing validate:true
bundle exec fastlane upload_listing
bundle exec fastlane upload_images    # icon, feature graphic, screenshots
```

Turn on **Managed publishing** (Publishing overview) first if you want the new
listing and the 1.1.1 build to go live together.

**App icon:** 512 × 512 PNG, the live one is fine (`listing/v1/android/en-US/images/icon.png`).
**Feature graphic:** `tool/make_feature_graphic.py --install`, or see `FEATURE_GRAPHIC_PROMPT.md`.
**Video:** none (optional; a 30-second screen recording of add → generate → autofill would help).

### Release 1.1.1 (versionCode 5)

You build the AAB; then `cd android && bundle exec fastlane deploy` puts it on
production as a **draft** with the changelogs from `listing/v2/play/<locale>/changelog.txt`.

Release notes are under 500 characters in every locale (`check_listing.py` enforces it).

### Play Console declarations specific to this app

- **AutofillService:** no declaration form exists for it; nothing to do. (Play
  restricts the **Accessibility** API for password managers — Bimir Lock does not
  use it.)
- **Camera:** an ordinary runtime permission, asked only when the user turns on the
  photo. No declaration.
- **Package visibility:** the manifest uses a launcher `<queries>` intent, not
  `QUERY_ALL_PACKAGES` — no declaration.

---

## 2. App Store Connect — app id 6821090857, bundle `com.cklamib.bimirLock`

### App Information

| Field | Value |
|---|---|
| Name / Subtitle | uploaded by fastlane (`apple/<locale>/name.txt`, `subtitle.txt`) |
| Primary language | English (U.S.) |
| Category | **Primary: Utilities**, **Secondary: Productivity** — see `research/categories.md` (fastlane uploads these from `apple/_app/`) |
| Content rights | **No**, it does not contain, show or access third-party content |
| Age rating | Fill the questionnaire: every content question **None**; Unrestricted Web Access **No**; User-generated content **No**; Messaging/chat **No**; Advertising **No**; Gambling/contests **No**; Medical/treatment info **No**; Parental controls/age assurance **No** → **4+** |
| License agreement | Apple's standard EULA (the app's own terms are linked in-app) |

### Pricing and Availability

- Price: **Free** (Tier 0). No in-app purchases.
- Availability: **All countries/regions**. If you keep France, see export compliance below.
- Pre-orders: no.

### App Privacy

- Privacy Policy URL: `https://bimalkhatri.com.np/bimir-lock/privacy-policy`
- **Data collection: "No, we do not collect data from this app."**
  Result on the product page: **Data Not Collected**.
- Same reasoning as Play's Data safety. Apple's definition of "collect" is
  transmitting data off the device in a way that lets you or a third party access it
  beyond what's needed to serve a request in real time — nothing in Bimir Lock does.

### Version 1.1.1 (iOS App Store)

| Field | Value |
|---|---|
| Version string | Run `cd ios && bundle exec fastlane ensure_edit_version version:1.1.1` — App Store Connect created "1.0"; the build is 1.1.1 |
| Screenshots | iPhone 6.9" (1320×2868) + iPad 13" (2064×2752) — fastlane uploads them. Both are required: the app runs on iPad (`TARGETED_DEVICE_FAMILY = 1,2`) |
| Promotional text, description, keywords, support/marketing URL | fastlane (`upload_listing`) |
| What's New | not shown for a first release; fastlane uploads `release_notes.txt` anyway, harmless |
| Build | upload from Xcode Organizer / Transporter, then pick it here |
| Sign-in required | **No** |
| App Review contact + notes | fastlane (`apple/_app/review_information/`; phone from `ios/fastlane/.env`) |
| Version release | **Manually release this version** |
| Phased release | Optional; not needed for a first release |

### Export compliance (asked when you attach the build)

Bimir Lock uses standard encryption it implements itself (AES-256-GCM, Argon2id via
CryptoKit and the `encrypt`/`pointycastle` packages) for its primary purpose —
protecting passwords. So:

- "Does your app use encryption?" → **Yes**
- "Does your app qualify for any of the exemptions…?" → it is **not** exempt as
  "encryption is not the primary function" — protecting secrets *is* its function.
- Algorithm type → **Standard encryption algorithms instead of, or in addition to,
  using or accessing the encryption within Apple's operating system**
- Apple then treats it as mass-market encryption (US EAR 5D992.c / §740.17(b)(1)):
  you need to file the **annual self-classification report** with BIS (a one-line
  CSV, due each February, by email), and for **France** Apple may ask for the
  ANSSI declaration — or exclude France from availability.

`ios/Runner/Info.plist` declares `ITSAppUsesNonExemptEncryption` = `YES` (from build 1.1.1
onward; Callbreak says NO because it only uses the OS's HTTPS). With YES, each new build
shows "Missing Compliance" in App Store Connect until you answer the questions above —
it takes a minute. Once Apple has approved compliance documentation you can add the
`ITSEncryptionExportComplianceCode` it gives you and the prompt stops. *(This is the
common reading for offline password managers — confirm with Apple's export compliance
documentation if unsure; it is not legal advice.)*

### App Store-specific checks before submitting

- **Guideline 2.1 (completeness):** the reviewer can use everything without an
  account — covered by the review notes.
- **Guideline 4.2 / 5.1.1:** camera use is explained in `NSCameraUsageDescription`
  and is opt-in; photo library string is present; Face ID string is present for the
  app and the extension.
- **Guideline 2.3.7 (keywords):** no competitor names — `check_listing.py` fails them.
- **AutoFill extension:** the AutoFill Credential Provider entitlement and the App
  Group are on both App IDs (done in Sept 2026).

---

## Feature truth that shaped the copy (from the code, 2026-10-10)

The listing says only what the app does. Things it deliberately does **not** claim:

- **No PIN on opening the app** — the PIN/biometric is asked per action (open a
  password, copy it, edit, delete, back up, view alerts). So the copy says "every
  password opens only with your PIN", never "the app locks".
- **Notes** are not encrypted and not behind the PIN → never "secure notes".
- **Site names and usernames** are stored in plain text; only passwords and their
  notes are encrypted → "passwords and their notes are encrypted".
- No auto-lock, no screenshot blocking, no breach monitoring, no sync, no 2FA/TOTP,
  no passkeys, no import from other managers, English-only UI.
- **Autofill** unlocks with biometrics *or* the phone's screen lock; iOS fills only
  and has no QuickType suggestions.

Product follow-ups worth considering (they would make the listing stronger, and some
reviewers will look for them): lock on open / after N minutes in the background,
`FLAG_SECURE` + app-switcher privacy cover, encrypting notes and putting them behind
the PIN, excluding intruder photos and notes from iCloud device backups, CSV import
from other managers, QuickType suggestions (`ASCredentialIdentityStore`).
