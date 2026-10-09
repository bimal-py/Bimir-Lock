# Bimir Lock — Privacy Policy (replacement text for the website)

> **Why this file exists.** The page live at
> https://bimalkhatri.com.np/bimir-lock/privacy-policy (effective June 15, 2026) is a
> generic template. It says the app collects your **email address, device identifiers,
> usage analytics and IP address**, mentions creating an account, and talks about
> analytics retention of 14–26 months. Bimir Lock does none of that. Google checks the
> Data safety form against the privacy policy, and Apple checks the App Privacy label
> against it — a policy that claims collection while the forms say "no data collected"
> is a rejection risk on both stores.
>
> Replace the page's body with the text below (it lives in the website's Supabase
> content, not in this repo), then keep the URL the same. Everything in it is checked
> against the code on branch `chore/upgrade-toolchain-and-autofill` (version 1.1.1).

---

**Bimir Lock Privacy Policy**

Effective: October 10, 2026 · Applies to Bimir Lock for Android and iOS, version 1.1.1 and later
Developer: Bimal Khatri, Pokhara, Nepal · khattribimal90@gmail.com

## The short version

Bimir Lock is an offline password manager. It has no account, no servers, no
analytics, no advertising and no tracking. What you save stays on your phone.
The developer never receives your passwords, notes, name, photos or anything else
you put in the app, and could not read them if you sent them.

## What the app stores, and where

Everything below is stored only on your device, inside the app's private storage:

- **Passwords and the note attached to each password** — encrypted with
  AES-256-GCM using a key held in the Android Keystore or the iOS Keychain. The key
  never leaves your device.
- **Site or app names and usernames** for each saved password, used to list and
  search them.
- **Your profile name and optional profile photo**, used only to greet you.
- **Notes** you write in the Notes section.
- **Wrong PIN alerts**: the time of each keypad lock, and — only if you turn on
  "Take a photo" — a photo from the front camera of whoever entered the wrong PINs.
  The newest 30 are kept; older ones are deleted automatically.
- **Your settings**, such as theme, biometric unlock on/off and tips you have seen.

On Android, the password database is excluded from Google's cloud backup and
device-to-device transfer. On iOS, the password database is excluded from iCloud
backup.

## What leaves your device

Only what you choose to send:

- **Backup files.** When you tap "Back up to a file", the app creates a file
  encrypted with a backup password you choose (Argon2id + AES-256-GCM) and hands it
  to your phone's save dialog. You decide where it goes — your phone, Files, iCloud
  Drive, Google Drive or anywhere else your phone offers. If you choose a cloud
  service, that service's privacy policy applies to the file it stores. Without your
  backup password, the file cannot be opened by anyone, including the developer.
- **Autofill.** If you turn on autofill, the app fills the username and password you
  pick into the app or website in front of you, after your fingerprint, face or
  screen lock. On Android it can also offer to save a login you just typed. This
  happens on your device; nothing is sent to the developer.
- **Copy and share.** Text you copy or share goes where you send it. Copied
  passwords are cleared from the clipboard after 30 seconds if it still holds them.
- **Notes export.** "Export notes" creates a plain (unencrypted) file and opens your
  phone's share sheet.

## Network use

Bimir Lock does not send any of your data over the internet. It connects only to:

- **Google Play or the App Store**, to check whether a newer version of the app is
  available. This request contains the app's identifier and your device's country
  setting; Google and Apple handle it under their own privacy policies.
- **Web pages you open yourself** from the app, such as this policy, the terms and
  the developer's links.

## Permissions

- **Camera** — to take a profile photo, and, only if you turn on Wrong PIN alerts →
  Take a photo, to photograph whoever enters 7 wrong PINs in a row. Photos stay on
  your device.
- **Photos / photo library** — to choose a profile photo.
- **Face ID / fingerprint** — handled entirely by your phone's operating system. The
  app is only told whether the check passed; it never receives biometric data.
- **Autofill service (Android) / AutoFill password provider (iOS)** — so you can fill
  saved passwords into other apps and websites. You turn this on in your phone's
  settings and can turn it off at any time.
- **Internet** — for the version check and the links described above.

## What the developer does not do

No account or sign-up. No analytics or crash reporting. No advertising or
advertising identifiers. No tracking across apps or websites. No selling or sharing
of personal information. No cloud servers holding your vault.

## Deleting your data

Because the developer holds no copy of your data, there is nothing to request.
Uninstalling Bimir Lock deletes everything it stored on that device. You can also
erase the vault from inside the app ("Forgot PIN?" → "Erase and start again" when
fingerprint/face unlock is off). Backup files you saved elsewhere are yours to
delete.

## Children

Bimir Lock is not directed at children under 13 and does not knowingly collect
information from anyone, of any age.

## Changes

If this policy changes, the new version will be posted at this address with a new
effective date. Material changes will also be noted in the app's release notes.

## Contact

Questions about this policy: khattribimal90@gmail.com (subject "Bimir Lock privacy").
