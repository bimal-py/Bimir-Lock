# Screenshots — what to capture

> **Today (2026-10-10) `raw/iphone` and `raw/ipad` hold test renders, not device
> captures:** the app's own widgets drawn at App Store pixel sizes by
> `STORE_SHOT_DIR=listing/shots/raw FONT_DIR=$FLUTTER_ROOT/bin/cache/artifacts/material_fonts flutter test test/screens_test.dart --plain-name "store "`.
> They have no status bar, so `panels.json` says `"add"` for those folders, and the
> AutoFill panel shows the in-app guide rather than the system sheet. Replace any
> file with a real capture (same name) and set that folder to `"replace"`.
> The framed panels themselves are generated and gitignored.

Raw captures go here with **exact file names**. No frames, no captions, no
resizing: `tool/make_screenshots.py` adds the crimson panel, the device frame,
the headline and a clean 9:41 status bar.

```
listing/shots/raw/iphone/<slug>.png          iPhone 17 Pro Max simulator   1320 x 2868
listing/shots/raw/ipad/<slug>.png            iPad Pro 13-inch (M5) sim     2064 x 2752
listing/shots/raw/android_phone/<slug>.png   Android phone (Pixel 9 Pro AVD or your phone)
listing/shots/raw/android_tablet/<slug>.png  Pixel Tablet AVD, PORTRAIT    1600 x 2560
```

All portrait. 8 slugs per device = 32 captures. The App Store's 6.3" iPhone size
(1206 x 2622, which Apple's 2026 table lists as required) is exported from the
same iPhone captures — no extra screenshots needed. If you skip the Android ones, the
iPhone/iPad captures are reused for Play (it works, but a real Android capture
looks native: Android status bar, Android autofill dropdown).

## The 8 screens (store order)

Light theme for all except `dark`. Use the demo vault below so every screen tells
the same story, and set a **6-digit PIN** (the old 4-digit ones show 4 cells and a
"Yours has 4 digits" nudge in Settings).

| # | slug | Screen | State to set up | Headline on the panel |
|---|---|---|---|---|
| 1 | `vault` | Home (vault list) | 12 entries, Password Checkup card showing "2 reused · 3 weak", search bar empty, no tour, no update dialog | Your passwords, locked on your phone |
| 2 | `autofill` | **Another app's sign-in form** | **Android:** a login screen (e.g. any app or Chrome sign-in) with the Bimir Lock autofill suggestion dropped down under the email field. **iOS:** a login field → key icon / "Passwords" → Bimir Lock list after Face ID (Simulator: Features → Face ID → Enrolled, then Matching Face) | Fill passwords into other apps |
| 3 | `generator` | Add password | Site "Spotify", email filled, generator **expanded**, length 20, Numbers + Symbols on, strength bar "Very strong", password revealed | Strong passwords in one tap |
| 4 | `checkup` | **Password Checkup page** (tap the card) | The list with weak + reused entries visible | Find weak and reused passwords |
| 5 | `unlock` | Unlock sheet over the vault | Tap an entry → "Open Amazon" sheet, **2 of 6 dots** filled (set a **6-digit** PIN first — a 4-digit PIN shows 4 cells) | Every password opens only for you |
| 6 | `alerts` | Settings → Wrong PIN alerts | "Take a photo" **ON**, 2–3 recent entries **with photos** (enter 10 wrong PINs, then 7 more, on a REAL phone — the simulator has no camera; use your own face or a soft toy) | See who tried to get in |
| 7 | `backup` | Settings → Back up to a file | Backup-password dialog open, password typed (dots), strength bar filled | A backup only you can open |
| 8 | `dark` | Home (vault list) | Same as #1, **dark theme** | Easy on the eyes at night |

Captions live in `listing/v2/screenshots/captions/<locale>.json`; order and sets
in `listing/v2/screenshots/panels.json`.

### Demo vault (type these in once, use on every device)

| Site | Username | Password | Note |
|---|---|---|---|
| Amazon | sita.sharma@gmail.com | strong, generated | |
| Bank of Kathmandu | SITA4421 | strong | |
| Gmail | sita.sharma@gmail.com | strong | |
| Netflix | sita.sharma@gmail.com | `Summer2024` (weak) | Family plan, renews on the 3rd. |
| Instagram | sita.sharma | same as Netflix (reused) | |
| Spotify | sita.sharma@gmail.com | strong | |
| GitHub | sitasharma | strong | |
| Home Wi-Fi | router | weak | |
| PayPal | sita.sharma@gmail.com | strong | |
| Daraz | 9841xxxxxx | same as Instagram (reused) | |
| Figma | sita@studio.np | strong | |
| eSewa | 9841xxxxxx | weak | |

Names only — no logos are shown (the app draws letter monograms), which keeps the
screenshots clear of anyone's trademark artwork.

## The status bar

Every panel ends up with the same clean bar: **9:41, full signal, full Wi-Fi,
full battery, no notification icons**. The generator paints it (`"replace"` in
`panels.json`), so a capture from your own phone at 23:58 with 12% battery and
three notification icons still comes out clean. Capturing with a clean bar to
begin with is still better — nothing to paint over:

**iOS Simulator** (run once per booted simulator, before capturing):

```sh
xcrun simctl status_bar booted override --time "9:41" \
  --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --operatorName "" \
  --batteryState charged --batteryLevel 100

xcrun simctl io booted screenshot listing/shots/raw/iphone/vault.png
xcrun simctl status_bar booted clear      # when done
```

**Android emulator / phone** (demo mode):

```sh
adb shell settings put global sysui_demo_allowed 1
adb shell am broadcast -a com.android.systemui.demo -e command enter
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4
adb shell am broadcast -a com.android.systemui.demo -e command network -e mobile show -e datatype none -e level 4
adb shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false

adb exec-out screencap -p > listing/shots/raw/android_phone/vault.png
adb shell am broadcast -a com.android.systemui.demo -e command exit   # when done
```

If you captured with a clean bar and want it kept exactly as the OS drew it, set
that folder to `"keep"` in `panels.json` (the iPhone Dynamic Island is still drawn,
because simulator screenshots leave it out). If a phone's own bar peeks out under
the painted one, give that folder a taller band: `{"mode": "replace", "bar": 40}`.

## Then

```sh
../marketing/.venv/bin/python tool/make_screenshots.py            # en-US
../marketing/.venv/bin/python tool/make_screenshots.py --all      # every captions/<locale>.json
open listing/shots/out/_contact_en-US_iphone.png                  # review
../marketing/.venv/bin/python tool/make_screenshots.py --all --install
```

`--install` copies the panels into `ios/fastlane/screenshots/<locale>/` and
`android/fastlane/metadata/android/<locale>/images/`. Both stores REPLACE a
locale's whole set on upload — review the contact sheets first.

A preview built from the flutter-test harness (no device needed, lower
resolution, no autofill screen) shows the look before you capture:

```sh
SCREENSHOT_DIR=/tmp/bimir_shots FONT_DIR=$FLUTTER_ROOT/bin/cache/artifacts/material_fonts \
  flutter test test/screens_test.dart
# copy phone-06-vault.png -> /tmp/bimir_raw/iphone/vault.png etc., then:
SHOTS_RAW=/tmp/bimir_raw SHOTS_OUT=/tmp/bimir_out \
  ../marketing/.venv/bin/python tool/make_screenshots.py --status-bar=add
```
