#!/usr/bin/env python3
"""Start the next listing version from the current one.

    python3 tool/new_release.py v3

Copies the newest `listing/v*` folder to the new name so the old one stops
being edited — `listing/v1` is what 1.0.1 shipped with, `v2` what 1.1.1 shipped
with, and so on. The per-locale release notes are cleared, because they describe
the PREVIOUS release and silently shipping them again is worse than shipping
none; everything else (descriptions, keywords, subtitles) carries forward,
because most releases do not change the listing at all.

After this: edit `listing/<new>/en/release_notes.txt` and
`listing/<new>/en/play_changelog.txt`, transcreate them into every
locale, and follow RELEASING.md.
"""
import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LISTING = os.path.join(ROOT, "listing")

# Files that describe one specific release and must not be inherited.
PER_RELEASE = ("release_notes.txt", "changelog.txt")


def versions():
    found = []
    for name in os.listdir(LISTING):
        m = re.fullmatch(r"v(\d+)", name)
        if m and os.path.isdir(os.path.join(LISTING, name)):
            found.append((int(m.group(1)), name))
    return sorted(found)


def main():
    if len(sys.argv) != 2 or not re.fullmatch(r"v\d+", sys.argv[1]):
        sys.exit("usage: python3 tool/new_release.py v3")
    new = sys.argv[1]
    dst = os.path.join(LISTING, new)
    if os.path.exists(dst):
        sys.exit(f"{dst} already exists — nothing done")

    found = versions()
    if not found:
        sys.exit(f"no listing/v* folder to copy from in {LISTING}")
    src = os.path.join(LISTING, found[-1][1])

    shutil.copytree(src, dst)

    cleared = 0
    for root, _, files in os.walk(dst):
        for name in files:
            if name in PER_RELEASE:
                os.remove(os.path.join(root, name))
                cleared += 1

    print(f"{found[-1][1]} -> {new}")
    print(f"cleared {cleared} release-note file(s) — they described {found[-1][1]}")
    print()
    print("next:")
    print(f"  1. write listing/{new}/en/release_notes.txt   (App Store, 4000)")
    print(f"     and  listing/{new}/en/play_changelog.txt   (Play, 500 hard)")
    print("  2. transcreate them into every locale's changelog.txt / release_notes.txt")
    print(f"  3. python3 tool/check_listing.py listing/{new} && "
          f"python3 tool/assemble_listing.py listing/{new}")
    print("  4. see RELEASING.md")


if __name__ == "__main__":
    main()
