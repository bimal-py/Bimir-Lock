#!/usr/bin/env python3
"""Build the Google Play feature graphic (1024x500) from the real logo and a capture.

    ../marketing/.venv/bin/python tool/make_feature_graphic.py
    ../marketing/.venv/bin/python tool/make_feature_graphic.py --install
    ../marketing/.venv/bin/python tool/make_feature_graphic.py --screen path/to/vault.png

Same visual system as the screenshot panels (tool/make_screenshots.py): the soft
crimson wash, the faint padlock, Google Sans Flex. Logo and wordmark on the left,
the vault on a phone on the right, bleeding off the bottom edge. Nothing important
sits in the outer 10% — Play crops the graphic differently on phones, tablets and TV.

The image-model alternative (for a more illustrated cover) is in
listing/v2/FEATURE_GRAPHIC_PROMPT.md.
"""
import os
import shutil
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_screenshots as ms  # noqa: E402

ROOT = ms.ROOT
W, H = 1024, 500
OUT = os.path.join(ms.OUT, "featureGraphic.png")
PLAY = os.path.join(ROOT, "android/fastlane/metadata/android/en-US/images/featureGraphic.png")
LOGO = os.path.join(ROOT, "assets/brand/mark.png")

TAGLINE = "Your passwords, locked on your phone"
CHIPS = ["Offline", "No account", "Encrypted"]


def main():
    args = sys.argv[1:]
    screen_path = None
    if "--screen" in args:
        screen_path = args[args.index("--screen") + 1]
    # Play is Android: prefer the Android capture so the status bar is Android's
    screen_path = screen_path or ms.raw_path("android_phone", "vault") or ms.raw_path("iphone", "vault")
    if not screen_path:
        sys.exit("no listing/shots/raw/android_phone/vault.png (or iphone/vault.png) yet — "
                 "capture it, or pass --screen <png>")

    spec = ms.Spec("feature", (W, H), 0, 0, 0, 0, 0, 0, 0, False)
    img = ms.background(spec)
    d = ImageDraw.Draw(img)

    # left block: logo, wordmark, tagline, chips — vertically centred
    logo = Image.open(LOGO).convert("RGBA").resize((96, 96), Image.LANCZOS)
    x0 = 72
    f_name = ImageFont.truetype(ms.F_BOLD, 62)
    f_tag = ImageFont.truetype(ms.F_MED, 25)
    f_chip = ImageFont.truetype(ms.F_MED, 19)
    block_h = 96 + 18 + 62 + 16 + 25 + 30 + 40
    y = (H - block_h) // 2
    img.paste(logo, (x0, y), logo)
    y += 96 + 18
    d.text((x0, y), "Bimir Lock", font=f_name, fill=ms.INK)
    y += 62 + 16
    d.text((x0, y), TAGLINE, font=f_tag, fill=ms.SUB)
    y += 25 + 30
    cx = x0
    for chip in CHIPS:
        tw = d.textlength(chip, font=f_chip)
        d.rounded_rectangle([cx, y, cx + tw + 32, y + 40], radius=20, outline=ms.RULE, width=2)
        d.text((cx + 16 + tw / 2, y + 20), chip, font=f_chip, fill=ms.RULE, anchor="mm")
        cx += tw + 32 + 12

    # right: the phone, top-anchored, running off the bottom edge
    screen = Image.open(screen_path).convert("RGB")
    folder = "iphone" if "/iphone/" in screen_path else "android_phone"
    screen = ms.status_bar(screen, folder, "replace" if "/raw/" in screen_path else "add")
    sw = 300
    sh = round(sw * screen.height / screen.width)
    bezel, radius = 8, 34
    frame = Image.new("RGBA", (sw + 2 * bezel, sh + 2 * bezel), (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle(
        [0, 0, frame.width - 1, frame.height - 1], radius=radius + bezel, fill=ms.BEZEL)
    inner = screen.resize((sw, sh), Image.LANCZOS).convert("RGBA")
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw - 1, sh - 1], radius=radius, fill=255)
    frame.paste(inner, (bezel, bezel), mask)
    img.paste(frame, (W - 64 - frame.width, 52), frame)

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.convert("RGB").save(OUT, optimize=True)
    print(f"wrote {os.path.relpath(OUT, ROOT)} ({W}x{H})")
    if "--install" in args:
        os.makedirs(os.path.dirname(PLAY), exist_ok=True)
        shutil.copyfile(OUT, PLAY)
        print(f"installed -> {os.path.relpath(PLAY, ROOT)}")


if __name__ == "__main__":
    main()
