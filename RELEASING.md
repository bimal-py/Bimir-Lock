# Shipping a release

Every release is the same steps. Nothing here submits anything for review —
both stores are left holding a draft for you to press the button on.

## 0. Once, if the keys are missing

```sh
cat android/fastlane/.env                # SUPPLY_JSON_KEY -> the Play service-account json
cat ios/fastlane/appstore_api_key.json   # key id, issuer id, path to the .p8
```

Both point at `/Users/groot/personal_projects/app_keys/` — the same keys Callbreak
uses. Neither file is in git.

## 1. Bump the version

`pubspec.yaml`, e.g. `1.1.1+5` → `1.1.2+6`. The number after `+` is the Play
version code and must always go up. `assemble_listing.py` names the Play
changelog file after it.

## 2. Start the next listing folder

```sh
python3 tool/new_release.py v3      # copies listing/v2 -> listing/v3
```

`listing/v2` then stops being touched — it is the record of what 1.1.1 shipped
with, the way `listing/v1` is the record of 1.0.1.

## 3. Write the English "What's New"

```
listing/v3/en/release_notes.txt    App Store   (4000 limit)
listing/v3/en/play_changelog.txt   Play        (500 limit, hard)
```

Only touch the description, name, subtitle or keywords if the app has actually
changed shape. A keyword edit sends the app NAME back through Apple review; a
What's New edit does not.

Both stores count UTF-16 code units — an emoji outside the BMP costs two.
`check_listing.py` counts the same way.

## 4. Transcreate into every locale

Write `listing/v3/play/<locale>/changelog.txt` and
`listing/v3/apple/<locale>/release_notes.txt` for every locale, reading that
locale's own description first so the note matches its voice. Never claim cloud
sync, breach alerts, 2FA codes or "most secure" — `check_listing.py` fails them.

## 5. Check, then assemble

```sh
python3 tool/check_listing.py listing/v3       # limits, locales, forbidden claims
python3 tool/assemble_listing.py listing/v3    # -> the two fastlane trees
```

`check_listing.py` must print `0 problem(s)`.

## 6. Build the binaries (you, not a script)

```sh
flutter clean && flutter pub get
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
flutter build ipa       --release --obfuscate --split-debug-info=build/symbols
```

Upload the .ipa with Xcode Organizer or Transporter.

## 7. Upload

Read the stores back first:

```sh
cd android && bundle exec fastlane probe
cd ../ios  && bundle exec fastlane probe
```

**App Store**

```sh
cd ios
bundle exec fastlane ensure_edit_version version:1.1.1   # if there is no draft
bundle exec fastlane locales                             # every locale accepted?
bundle exec fastlane upload_release_notes validate:true  # dry run
bundle exec fastlane upload_release_notes                # What's New only
```

Then attach the build to the version in App Store Connect and press Submit.

**Google Play**

```sh
cd android
bundle exec fastlane deploy validate:true    # dry run: the AAB + changelogs
bundle exec fastlane deploy                  # draft release on production
```

Then open the Console, review the draft release, and roll it out.

## The traps worth re-reading

See `FASTLANE.md`: Play has no draft for listing text (use managed publishing),
`upload_images` replaces the whole screenshot set, and neither store's "success"
means the value applied — always `probe` afterwards.
