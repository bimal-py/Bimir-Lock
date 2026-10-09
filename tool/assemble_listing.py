#!/usr/bin/env python3
"""Copy listing/v2/** into the two fastlane metadata trees.

`listing/v2/` is the source of truth a human edits. `android/fastlane/metadata/`
and `ios/fastlane/metadata/` are what supply and deliver actually upload, and
they have different folder shapes — so this is the one place that knows how to
translate between them.

    python3 tool/assemble_listing.py               # listing/v2
    python3 tool/assemble_listing.py listing/v3

Never edit the fastlane metadata folders by hand: this overwrites their text.
Images and screenshots are not touched (tool/make_screenshots.py --install does those).

  listing/v2/play/<locale>/title|short_description|full_description.txt
      -> android/fastlane/metadata/android/<locale>/
  listing/v2/play/<locale>/changelog.txt
      -> android/fastlane/metadata/android/<locale>/changelogs/<versionCode>.txt
  listing/v2/apple/<locale>/*.txt              -> ios/fastlane/metadata/<locale>/
  listing/v2/apple/_shared/*.txt (the URLs)    -> into every Apple locale
  listing/v2/apple/_app/** (categories, copyright, review contact)
      -> ios/fastlane/metadata/ (app-level, not per locale)
"""
import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, sys.argv[1] if len(sys.argv) > 1 else "listing/v2")

PLAY_TEXT = ("title.txt", "short_description.txt", "full_description.txt")


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text.rstrip("\n") + "\n")


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read().strip()


def version_code():
    """The Play changelog file is named after the build it ships with."""
    m = re.search(r"^version:\s*[\d.]+\+(\d+)", read(os.path.join(ROOT, "pubspec.yaml")), re.M)
    if not m:
        sys.exit("pubspec.yaml has no version with a +build number")
    return m.group(1)


def review_phone():
    env = os.path.join(ROOT, "ios", "fastlane", ".env")
    if not os.path.isfile(env):
        return None
    for line in open(env, encoding="utf-8"):
        if line.strip().startswith("ASC_REVIEW_PHONE="):
            return line.split("=", 1)[1].strip().strip('"') or None
    return None


def assemble_play():
    src = os.path.join(SRC, "play")
    dst = os.path.join(ROOT, "android", "fastlane", "metadata", "android")
    if not os.path.isdir(src):
        return 0
    code = version_code()
    # Screenshots live under the destination and are NOT regenerated from
    # listing/, so keep them: wipe only the per-locale text.
    for locale in sorted(os.listdir(dst)) if os.path.isdir(dst) else []:
        for name in PLAY_TEXT:
            p = os.path.join(dst, locale, name)
            if os.path.isfile(p):
                os.remove(p)

    n = 0
    for locale in sorted(os.listdir(src)):
        d = os.path.join(src, locale)
        if not os.path.isdir(d) or locale.startswith("_"):
            continue
        for name in PLAY_TEXT:
            p = os.path.join(d, name)
            if os.path.isfile(p):
                write(os.path.join(dst, locale, name), read(p))
        p = os.path.join(d, "changelog.txt")
        if os.path.isfile(p):
            write(os.path.join(dst, locale, "changelogs", f"{code}.txt"), read(p))
        n += 1
    return n


def assemble_apple():
    src = os.path.join(SRC, "apple")
    dst = os.path.join(ROOT, "ios", "fastlane", "metadata")
    if not os.path.isdir(src):
        return 0

    shared = {}
    shared_dir = os.path.join(src, "_shared")
    for name in sorted(os.listdir(shared_dir)) if os.path.isdir(shared_dir) else []:
        if name.endswith(".txt"):
            shared[name] = read(os.path.join(shared_dir, name))

    app_dir = os.path.join(src, "_app")
    if os.path.isdir(app_dir):
        for base, _, files in os.walk(app_dir):
            for name in files:
                if name.endswith(".txt"):
                    rel = os.path.relpath(os.path.join(base, name), app_dir)
                    target = os.path.join(dst, rel)
                    os.makedirs(os.path.dirname(target), exist_ok=True)
                    shutil.copyfile(os.path.join(base, name), target)

    # The repo is public, so the App Review phone number is never committed: it comes
    # from the gitignored ios/fastlane/.env (ASC_REVIEW_PHONE), the way Callbreak keeps it.
    phone = review_phone()
    if phone:
        write(os.path.join(dst, "review_information", "phone_number.txt"), phone)
    else:
        print("note: ASC_REVIEW_PHONE not set in ios/fastlane/.env — App Review phone left as is")

    n = 0
    for locale in sorted(os.listdir(src)):
        d = os.path.join(src, locale)
        if not os.path.isdir(d) or locale.startswith("_"):
            continue
        for name in sorted(os.listdir(d)):
            if name.endswith(".txt"):
                write(os.path.join(dst, locale, name), read(os.path.join(d, name)))
        for name, text in shared.items():
            write(os.path.join(dst, locale, name), text)
        n += 1
    return n


play = assemble_play()
apple = assemble_apple()
print(f"play  -> android/fastlane/metadata/android/  {play} locale(s)")
print(f"apple -> ios/fastlane/metadata/               {apple} locale(s)")
if play == 0 and apple == 0:
    print(f"nothing to assemble — is {os.path.relpath(SRC, ROOT)}/ populated?")
    sys.exit(1)
