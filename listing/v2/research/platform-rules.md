# Store rules that affect Bimir Lock's listing

Collected 2026-10-10. Quotes were fetched from the URLs shown on that date.

## 1. Field limits

| Field | Limit | Indexed for search? | Source |
|---|---|---|---|
| Apple app name | 2–30 characters | Yes (strongest) | https://developer.apple.com/help/app-store-connect/reference/app-information/app-information |
| Apple subtitle | 30 characters | Yes | same page |
| Apple keywords | **100 bytes**, comma-separated, each term over 2 characters | Yes (hidden) | https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information |
| Apple promotional text | 170 characters, editable any time without review | No | same |
| Apple description | 4,000 characters, plain text | **No** for App Store search (used for web search) | same |
| Apple "What's New" | 4,000 characters | No | same |
| Play title | 30 characters | Yes (strongest) | https://support.google.com/googleplay/android-developer/answer/13393723 |
| Play short description | 80 characters | Yes | https://support.google.com/googleplay/android-developer/answer/9866151 |
| Play full description | 4,000 characters | **Yes** | https://support.google.com/googleplay/android-developer/answer/13393723 |
| Play tags | up to 5 | browse/classification | https://support.google.com/googleplay/android-developer/answer/9859673 |

**Keywords and promotional text update on different schedules.** The Apple keyword field can only be changed with a new app version. Promotional text can change at any time.

## 2. Apple: metadata rules that matter for a password manager

### Guideline 2.3.7

Source: https://developer.apple.com/app-store/review/guidelines/#accurate-metadata

> "Choose a unique app name, assign keywords that accurately describe your app, and don't try to pack any of your metadata with trademarked terms, popular app names, pricing information, or other irrelevant phrases just to game the system. App names must be limited to 30 characters. Metadata such as app names, subtitles, screenshots, and previews should not include prices, terms, or descriptions that are not specific to the metadata type. App subtitles are a great way to provide additional context for your app; they must follow our standard metadata rules and should not include inappropriate content, reference other apps, or make unverifiable product claims. Apple may modify inappropriate keywords at any time or take other appropriate steps to prevent abuse."

### Keywords field (App Store Connect help)

> "Your app is searchable by app name and company name, so you shouldn't duplicate these values in the keyword list. Names of other apps or companies aren't allowed."

### Product-page guide

Source: https://developer.apple.com/app-store/product-page/

- **Format:** "Keywords are limited to 100 characters total, with terms separated by commas and no spaces … Don't repeat any words … included in your app name, subtitle, or category."
- **Avoid:** "Plurals of words you've already included", "Generic terms … such as 'app' or 'game'", "Filler words like 'the' and 'to'", "Special characters, such as # or @".
- **Rejection risks:** "Improper use of keywords is a common reason for App Store rejections. Don't include: Unauthorized use of trademarked terms, celebrity names, or other protected words and phrases. Terms that are not relevant to the app. Competing app names."
- **Subtitle:** "Avoid generic descriptions such as 'world's best app.' Instead, highlight features or typical uses of your app."

### Other guidelines

- **2.3.1(a)**, from https://developer.apple.com/app-store/review/guidelines/:
  - Undocumented features: "Don't include any hidden, dormant, or undocumented features … All new features, functionality, and product changes must be described with specificity in the Notes for Review section."
  - Misleading marketing: "marketing your app in a misleading way, such as by promoting content or services that it does not actually offer … is grounds for removal."
- **2.3.3:** "Screenshots should show the app in use, and not merely the title art, login page, or splash screen."
- **2.3.8:** metadata must suit a 4+ audience.
- **2.3.10:** "don't include names, icons, or imagery of other mobile platforms or alternative app marketplaces in your app or metadata."
- **4.1(c):** "You cannot use another developer's icon, brand, or product name in your app's icon or name, without approval from the developer."

### What this means for Bimir Lock on iOS

- **No competitor or company names** in the name, subtitle, keyword field or screenshots: Bitwarden, 1Password, LastPass, Keeper, Dashlane, NordPass, Proton, Norton, KeePass, Google, iCloud, Keychain, Apple Passwords. That includes comparison copy such as "unlike iCloud Keychain…".
- **No "free"** in the name, subtitle or keywords. That is pricing information under 2.3.7. Say it in the description only.
- **No "best", "#1", "most secure", "unhackable" or "military-grade" in the subtitle.** These are unverifiable product claims. "AES-256 encryption" is a verifiable fact: vault key `KEY_BITS = 256` in `android/app/src/main/kotlin/com/cklamib/bimirLock/crypto/VaultCrypto.kt`, and backups use `aes-256-gcm` + Argon2id in `lib/utils/helper/backup_crypto.dart`. "Military-grade" is marketing fluff.
- **No words for features the app does not have.** These count as irrelevant terms under 2.3.7 or misleading under 2.3.1:
  - passkey, 2FA, authenticator, OTP;
  - VPN, photo vault;
  - **app lock** (the app does not lock on open);
  - **secure notes / encrypted notes** (Notes are not encrypted).
- **No "Android" or "Google Play"** in iOS metadata (2.3.10). Describing backups as saved "to Files, iCloud Drive or any cloud drive app" is fine. Naming "Google Drive" is low-risk, since it is a storage service rather than a mobile platform, but "any cloud drive app" avoids the question.
- **Describe AutoFill accurately.** On iOS Bimir Lock **fills** passwords via the AutoFill Credential Provider extension. It cannot offer to **save** passwords, because iOS gives third-party managers no save prompt. Don't promise "save passwords automatically as you log in" on iOS.
- **App Review notes (2.3.1(a))** must cover:
  - how to create the 6-digit PIN;
  - that the app does not lock on open, and PIN or Face ID is asked per password or action;
  - how to enable AutoFill: Settings › General › AutoFill & Passwords › allow filling from Bimir Lock (the label reads "AutoFill & Passkeys" on newer iOS; check on a test device);
  - the opt-in wrong-PIN photo feature and that its photos stay on the device;
  - how backup and restore work, including the separate backup password.
- **Export compliance.** The app uses standard encryption (AES-GCM via CryptoKit / Keystore, Argon2id), so App Store Connect will ask the encryption questions. Read https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance and answer them for standard algorithms. If the answers qualify, set `ITSAppUsesNonExemptEncryption` in Info.plist so the questions aren't asked on every build. Apple's page notes that France separately controls encryption apps. This is a submission item, not a listing item, but it blocks release if skipped.

## 3. Google Play: metadata policy and listing guidance

### Metadata policy

Source: https://support.google.com/googleplay/android-developer/answer/9898842

- **Title, icon and developer name:** no "emojis, emoticons, or repeated special characters"; no ALL CAPS "unless it is part of your brand name"; no symbols or text implying store performance or ranking, price or promotion, or a Google Play program.
- **Descriptions:** no "misleading, improperly formatted, non-descriptive, irrelevant, excessive, or inappropriate metadata"; no "unattributed or anonymous user testimonials"; no "repetitive or unrelated keywords".

### Store listing best practices

Source: https://support.google.com/googleplay/android-developer/answer/13393723, verbatim.

- **Title:** "Your app title must be 30 characters or less." / "Make sure your title is unique, accessible, and avoid common terms."
- **Free / No Ads:** "Don't use text elements to promote deals. Words like 'Free' and 'No Ads' promote deals and don't belong in app titles or developer names."
- **Rankings and price:** "Your store listing shouldn't include text that indicate store performance or ranking, such as 'App of the year,' '#1,' 'Best of Play 20XX,' 'Popular,' award icons … your images and text should not indicate the price and promotional information, such as '10% off,' '$50 cash back,' 'free for a limited time only'."
- **Caps and emoji:** "Don't use CAPS unless your brand is capitalized. Avoid using emojis, emoticons, and special character sequences that are irrelevant to your app." The page's own bad example is "Crane: travel PLANNER!! 🌞".
- **Short description:** "No pricing or ranking: Don't include promotional offers (like 'free' or 'discount') or claims about store performance (like '#1' or 'Best')." / "Accurate and honest: Make sure the description is truthful and doesn't mislead users." / "Don't repeat your short description in your full description."
- **Full description:**
  - Keyword lists: "a block of words in a list isn't helpful to users … Give an overview of your app or game using everyday language, not a list of keywords."
  - Comparisons: "Don't include misleading or irrelevant references to other apps, products, or people. Also, don't compare your app or game to other apps or games."
  - Testimonials and superlatives: "we don't allow unattributed or anonymous user testimonials … Saying that something is the 'best' or '#1 rated' or comparing it to another app isn't permitted."
- **Translations:** "the Metadata policy and our other policies apply to all translations of your Google Play store listing."

### Screenshot text

Source: https://support.google.com/googleplay/android-developer/answer/9866151

- "Add taglines only if necessary … Taglines should not take up more than **20% of the image**."
- "Do not include any content that reflects or suggests Google Play performance, ranking, accolades or awards, user testimonials, or price and promotional information. For example, do not use words like 'Best,' '#1,' 'Top,' 'New,' 'Discount,' 'Sale,' or 'Million Downloads.'"
- "Avoid adding any form of call-to-action, for example, 'Download now,' 'Install now,' 'Play now,' or 'Try now'."
- "prioritize UI in the first three screenshots."
- Large screens: "Exclude additional text that is not part of your core app experience, as this can get cut off."
- Localized text (from answer/13393723): "For screenshots that contain text, provide separate screenshots … for each language that you support."

### What this means for Bimir Lock on Play

- **Title:** `Bimir Lock: Password Manager`. Do not add "Free", "No Ads", "Best" or "#1", and keep it in mixed case. The v1 title "Bimir lock" has a lowercase "l" in the brand; fix the casing.
- **Short description:** put "no cloud" and "no account" here, but not "free" or "no ads". Replace v1's "Your Ultimate Data Guardian": it is superlative fluff with no keyword.
- **Full description:**
  - Drop the emoji bullets from v1 (🔒 🔐 …); plain bullets are safer under "improperly formatted".
  - No "unlike LastPass…" comparisons.
  - No "trusted by thousands" without attribution.
  - Mention "free" and "no ads" here, factually.
- **Developer name:** the v1 listing shows "Bimal kc". The Play developer name follows the same rules: no "Free" or "No Ads", and no emojis. Keep it consistent with the Apple seller name (the legal name) to build trust.

## 4. Autofill and credential-provider specifics

### Android (AutofillService)

- Bimir Lock uses `android.service.autofill.AutofillService` with `BIND_AUTOFILL_SERVICE`. That is a system-bound permission, and **no Play Console declaration form exists for it.**
- **Do not add an AccessibilityService for autofill.** Play's Accessibility API policy says password managers are not accessibility tools, so they cannot declare `isAccessibilityTool`. They would need a prominent in-app disclosure and a Play declaration. Source: https://support.google.com/googleplay/android-developer/answer/10964491
- **Package visibility.** The manifest uses a narrow `<queries>` MAIN/LAUNCHER intent filter rather than `QUERY_ALL_PACKAGES`. That avoids the QUERY_ALL_PACKAGES declaration. Play's permitted uses for the broad permission are "device search, antivirus apps, file managers, and browsers"; password managers and autofill are not listed. Keep it that way. Source: https://support.google.com/googleplay/android-developer/answer/10158779
- **Listing copy:** "Autofill saves new logins and fills them in apps and browsers that support Android Autofill" is accurate. Avoid "works everywhere"; some apps and browsers block autofill.

### iOS (AutoFill Credential Provider extension)

- Requires the AutoFill Credential Provider entitlement on the extension, which `com.cklamib.bimirLock.AutofillExtension` already has per the project notes. There is no separate listing requirement, but the feature must appear in the App Review notes (2.3.1(a)).
- **Fill only.** Bimir Lock cannot capture new logins on iOS. Users add them in the app, and the listing must not imply automatic saving.

## 5. Privacy labels: Play Data safety and Apple App Privacy

### Definitions (verbatim)

- **Apple**, https://developer.apple.com/app-store/app-privacy-details/:
  - "'Collect' refers to transmitting data off the device in a way that allows you and/or your third-party partners to access it for a period longer than what is necessary to service the transmitted request in real time."
  - "Data that is processed only on device is not 'collected' and does not need to be disclosed in your answers."
- **Play**, https://support.google.com/googleplay/android-developer/answer/10787469:
  - Collection means "transmitting data from your app off a user's device".
  - Data "only processed locally on the user's device and not sent off device does not need to be disclosed."
  - Developers who collect nothing "must still complete the form", and "a privacy policy … is required to complete the Data safety form."

### Applied to Bimir Lock

- **Vault, notes, the PIN hash and the encrypted keys** live on the device in Keystore/Keychain and local storage, and are never sent anywhere. Not collected.
- **Intruder photos** are taken by the front camera, opt-in, and stored locally. Not collected; Apple: photos never transmitted off device "would not meet the definition of 'collected'". The camera *permission* still needs a clear purpose string:
  - iOS `NSCameraUsageDescription`;
  - Android runtime permission requested only when the user turns the feature on.
- **Backup file.** The user exports it through the system file picker to a location they choose. The developer never receives it, so it is not collection.
- **Version check (`upgrader`).** The app contacts the store (iTunes lookup / Play page) to compare versions. No user data is sent and the developer receives nothing, so it is not developer collection. **This is why "no internet access" claims are false** for this build.
- **No analytics, crash-reporting or ad SDKs** appear in `pubspec.yaml` (dependencies checked 2026-10-10).
- **Expected answers:**
  - Apple: **"Data Not Collected"**.
  - Play: **"No data collected"** and **"No data shared"**. The "encrypted in transit" and "data deletion" sections become N/A.
  - Both stores still need a **privacy-policy URL**. Apple 5.1.1(i): "All apps must include a link to their privacy policy in the App Store Connect metadata field and within the app".
- **Optional:** Play offers an "Independent security review" badge via third-party validation (MASA). It is not needed at launch, but it is a credible trust signal for a password manager later.
- **Keep the claims in sync.** Re-check both labels and the listing copy if any SDK, online quotes or crash reporting is added, or if the update check is removed. Removing the INTERNET permission would allow a true "no internet permission" claim on Android, which Keepass2Android Offline and Owl use as a selling point.

## 6. Screenshot and graphic sizes (2026)

### App Store

Source: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications, fetched 2026-10-10.

| Slot | Accepted sizes (portrait) | Required? |
|---|---|---|
| iPhone 6.9" / 6.7" "Dynamic Island (large display)" (iPhone Air, 18/17/16 Pro Max, 16/15 Plus …) | **1320 × 2868**, 1290 × 2796, 1260 × 2736 | Used for the large class; 6.5" falls back to it |
| iPhone 6.5" "Face ID (large display)" | 1284 × 2778, 1242 × 2688 | "Required if app runs on iPhone and screenshots for iPhone with Dynamic Island (large display) aren't provided" |
| iPhone 6.3" "Dynamic Island (medium display)" (iPhone 18 Pro, 17, 16 …) | **1206 × 2622**, 1179 × 2556 | Apple's "Required device sizes" box now says: "iPhone: At least one screenshot for iPhone with Dynamic Island (medium display)." |
| iPhone 5.5" / 4.7" | 1242 × 2208 / 750 × 1334 | Scaled automatically |
| iPhone Duo (foldable) | 1398 × 2034 outer, 2007 × 2853 inner | "Starting in April 2027, screenshots will be required for any app using the iOS 27.1 SDK or later." Not needed now. |
| **iPad 13"** | **2064 × 2752**, 2048 × 2732 | "Required if app runs on iPad". **Bimir Lock targets iPad** (`TARGETED_DEVICE_FAMILY = "1,2"`), so this is required. |
| iPad 12.9" / 11" | scaled from 13" | optional |

- **Rules:** 1–10 screenshots per size; `.jpeg`, `.jpg` or `.png`; "Images can't include alpha channels or transparencies."
- **Practical plan:** export **1320 × 2868** and **1206 × 2622** for iPhone, plus **2064 × 2752** for iPad. The required-size wording on the 2026 page names the medium (6.3") class, while older guidance named 6.9", so uploading both iPhone sizes removes the ambiguity. Alternatively, drop iPad support (`TARGETED_DEVICE_FAMILY = 1`) if iPad screenshots aren't worth making.

### Google Play

Source: https://support.google.com/googleplay/android-developer/answer/9866151

| Asset | Requirement |
|---|---|
| App icon | 512 × 512, 32-bit PNG with alpha, max 1024 KB; "Do not include badges or text that suggest ranking, price, Google Play categories" |
| **Feature graphic** | **1024 × 500**, JPEG or 24-bit PNG (no alpha). Required to publish. "Do not use prominent branding that is similar to your app icon." |
| Phone screenshots | Minimum 2 to publish, up to 8 per device type. JPEG or 24-bit PNG (no alpha); min 320 px, max 3840 px; the long side can't be more than twice the short side. **To be eligible for recommendation surfaces: "at least four screenshots with minimum 1080px resolution … 9:16 for portrait screenshots (minimum 1080x1920px)".** |
| 7" and 10" tablet screenshots ("Large screens") | Minimum 4; "between 1,080 and 7,680px"; 16:9 landscape or 9:16 portrait. Avoid extra text that "can get cut off on Play homepages". |
| Text on screenshots | Taglines ≤ 20% of the image; no "Best / #1 / Top / New / Discount / Sale / Million Downloads"; no call-to-action |

**Practical plan for Play**
- Phone: **1080 × 1920** (9:16). That meets both the hard limits and the recommendation-eligibility rule; 20:9 1080 × 2400 is valid but not 9:16.
- 7" tablet: **1200 × 1920** or 1080 × 1920 (9:16).
- 10" tablet: **1600 × 2560** or 2160 × 3840 (9:16).
- Feature graphic: **1024 × 500**.

## 7. Policy traps checklist

1. Competitor names in the Apple keyword field, or comparisons in any description. Apple rejects them, and Play forbids comparisons.
2. "Free", "No Ads", "#1", "Best" or "Top" in the Play title or short description, the Apple name or subtitle, or screenshot captions.
3. **"No internet access / no internet permission / 100% offline"** while Android declares INTERNET for the update check. Say "works offline; your passwords never leave your phone".
4. **"App lock" or "locks the app"** wording: the app does not lock on open.
5. **"Secure notes" or "encrypted notes"**: Notes are not encrypted.
6. Passkey, 2FA or authenticator wording: not supported.
7. iOS copy promising automatic saving of new logins. iOS is fill-only.
8. "Android" or Play imagery in iOS metadata (2.3.10).
9. iPad screenshots missing while the app targets iPad. Upload is blocked until they exist.
10. Privacy labels saying "no data" while an analytics or crash SDK is present. Fine today, so re-check on every dependency change.
11. Emojis, ALL CAPS or emoji bullets in the Play title and description, as in the v1 description.
12. Unverifiable superlatives such as "Ultimate", "most secure" or "unhackable". v1's short description "Your Ultimate Data Guardian" should go.
