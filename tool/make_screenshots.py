#!/usr/bin/env python3
"""Build the App Store / Play screenshot panels from raw device captures.

    ../marketing/.venv/bin/python tool/make_screenshots.py            # en-US
    ../marketing/.venv/bin/python tool/make_screenshots.py --all      # every captions/<locale>.json
    ../marketing/.venv/bin/python tool/make_screenshots.py --install  # also copy into the fastlane trees

Needs Pillow (`pip install pillow`); the marketing venv already has it.

Same visual system as the Callbreak panels (../callbreaktracker/tool/make_screenshots.py):
a soft vertical wash in the brand colour, a faint watermark, a bold headline over a
short rule and a one-line subtitle, and one device frame holding one screen. Callbreak
is green with card suits; Bimir Lock is the logo crimson with a padlock and a keyhole.

Inputs
  listing/shots/raw/iphone/<slug>.png          iPhone 17 Pro Max (or any 6.9"), portrait
  listing/shots/raw/ipad/<slug>.png            iPad Pro 13", portrait
  listing/shots/raw/android_phone/<slug>.png   Android phone, portrait (optional)
  listing/shots/raw/android_tablet/<slug>.png  Android tablet / large AVD (optional)
  listing/v2/screenshots/panels.json           order + which slug goes in which set
  listing/v2/screenshots/captions/<locale>.json  headline + subtitle per slug

When an Android capture is missing the iPhone (phone) or iPad (tablet) one is used
instead, with a warning — Play accepts it, but a real Android capture looks native.

Output
  listing/shots/out/<locale>/iphone/NN_<slug>.png        1320x2868  App Store 6.9"
  listing/shots/out/<locale>/iphone_63/NN_<slug>.png     1206x2622  App Store 6.3" (same panel)
  listing/shots/out/<locale>/ipad/NN_<slug>.png          2064x2752  App Store 13"
  listing/shots/out/<locale>/phoneScreenshots/...        1080x1920  Play phone
  listing/shots/out/<locale>/sevenInchScreenshots/...    1600x2560  Play 7" tablet
  listing/shots/out/<locale>/tenInchScreenshots/...      1600x2560  Play 10" tablet
  listing/shots/out/_contact_<locale>_<set>.png          one-glance review sheet

--install copies them to ios/fastlane/screenshots/<apple-locale>/ and
android/fastlane/metadata/android/<play-locale>/images/. Both stores REPLACE a
locale's whole set on upload, so review the contact sheets first.
"""
import json
import os
import shutil
import sys

from PIL import Image, ImageDraw, ImageFont, features

# Hindi, Nepali, Bengali, Thai and Arabic captions need complex text shaping (raqm),
# or vowel signs land on the wrong letter and Arabic comes out unjoined and
# backwards. Pillow's wheel carries raqm but loads fribidi at run time, and on this
# Mac fribidi is Homebrew's, off the default search path — so re-run once with it on.
_BREW_LIB = "/opt/homebrew/lib"
if (not features.check("raqm") and not os.environ.get("BIMIR_SHOTS_REEXEC")
        and os.path.isfile(os.path.join(_BREW_LIB, "libfribidi.0.dylib"))):
    os.environ["DYLD_LIBRARY_PATH"] = _BREW_LIB + ":" + os.environ.get("DYLD_LIBRARY_PATH", "")
    os.environ["BIMIR_SHOTS_REEXEC"] = "1"
    os.execv(sys.executable, [sys.executable] + sys.argv)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# SHOTS_RAW / SHOTS_OUT let a preview run from other captures without touching these.
RAW = os.environ.get("SHOTS_RAW", os.path.join(ROOT, "listing/shots/raw"))
OUT = os.environ.get("SHOTS_OUT", os.path.join(ROOT, "listing/shots/out"))
CFG = os.path.join(ROOT, "listing/v2/screenshots")

FONT_DIR = os.path.join(ROOT, "assets/fonts")
F_BOLD = os.path.join(FONT_DIR, "GoogleSansFlex-Bold.ttf")
F_MED = os.path.join(FONT_DIR, "GoogleSansFlex-Medium.ttf")

# Google Sans Flex covers Latin, Greek, Cyrillic and Vietnamese. Other scripts take
# the macOS system face for that script, so a localized caption never renders tofu.
# lang -> (font file candidates, style names for the headline, for the subtitle)
_HIRAGINO = "/System/Library/Fonts/\u30d2\u30e9\u30ae\u30ce\u89d2\u30b4\u30b7\u30c3\u30af {}.ttc"
SYSTEM_FONTS = {
    "hi": (["/System/Library/Fonts/Kohinoor.ttc"], ("Bold",), ("Medium",)),
    "ne": (["/System/Library/Fonts/Kohinoor.ttc"], ("Bold",), ("Medium",)),
    "mr": (["/System/Library/Fonts/Kohinoor.ttc"], ("Bold",), ("Medium",)),
    "bn": (["/System/Library/Fonts/KohinoorBangla.ttc"], ("Bold",), ("Medium",)),
    "ta": (["/System/Library/Fonts/Supplemental/Tamil MN.ttc"], ("Bold",), ("Regular",)),
    "te": (["/System/Library/Fonts/KohinoorTelugu.ttc"], ("Bold",), ("Medium",)),
    "ja": ([_HIRAGINO.format("W7"), _HIRAGINO.format("W4")], ("W7",), ("W4", "W7")),
    "ko": (["/System/Library/Fonts/AppleSDGothicNeo.ttc"], ("Bold",), ("Medium",)),
    "zh": (["/System/Library/Fonts/Hiragino Sans GB.ttc"], ("W6",), ("W3",)),
    "th": (["/System/Library/Fonts/Supplemental/Thonburi.ttc"], ("Bold",), ("Regular",)),
    "ar": (["/System/Library/Fonts/GeezaPro.ttc"], ("Bold",), ("Regular",)),
    "fa": (["/System/Library/Fonts/GeezaPro.ttc"], ("Bold",), ("Regular",)),
    "ur": (["/System/Library/Fonts/GeezaPro.ttc"], ("Bold",), ("Regular",)),
    "he": (["/System/Library/Fonts/ArialHB.ttc"], ("Bold",), ("Regular",)),
    "iw": (["/System/Library/Fonts/ArialHB.ttc"], ("Bold",), ("Regular",)),
}

# Brand: the logo crimson (#901743, the app's light-theme primary) on a near-white
# that warms into the app's soft primary container (#FBE7ED) toward the bottom.
BG_TOP = (252, 248, 249)
BG_BOT = (243, 221, 229)
INK = (72, 14, 37)        # headline: the crimson taken almost to black
SUB = (94, 78, 85)        # subtitle: warm grey
RULE = (144, 23, 67)      # #901743
MARK = (144, 23, 67, 12)  # watermark: the crimson at ~5%
BEZEL = (10, 10, 12)      # near-black, so a dark-theme screen still reads as framed


class Spec:
    """One store canvas. Fractions are of the canvas, so every size shares a layout."""

    def __init__(self, name, canvas, head, sub, screen_w, top, bottom, bezel, radius, island):
        self.name, self.canvas = name, canvas
        self.head, self.sub = head, sub          # font px as a fraction of width
        self.screen_w = screen_w                  # max screen width, fraction of width
        self.top, self.bottom = top, bottom       # screen band, fractions of height
        self.bezel, self.radius = bezel, radius   # fractions of screen width
        self.island = island


IPHONE = Spec("iphone", (1320, 2868), 0.076, 0.036, 0.64, 0.255, 0.915, 0.018, 0.115, False)
IPAD = Spec("ipad", (2064, 2752), 0.058, 0.028, 0.70, 0.245, 0.925, 0.016, 0.035, False)
PLAY_PHONE = Spec("phoneScreenshots", (1080, 1920), 0.076, 0.036, 0.60, 0.265, 0.945, 0.018, 0.08, False)
PLAY_TABLET = Spec("tabletScreenshots", (1600, 2560), 0.060, 0.029, 0.70, 0.245, 0.93, 0.016, 0.035, False)

BAR_MODE = None  # --status-bar=… overrides panels.json for every folder

# Extra exports of a finished panel. Apple's 2026 size table names the 6.3" class
# (iPhone 17 / 16 / 18 Pro) as required next to the 6.9" one; fastlane files 1206x2622
# under APP_IPHONE_61. Same artwork, so no extra captures are needed.
EXTRA_SIZES = {"iphone": [("iphone_63", (1206, 2622))]}

# set name in panels.json -> (spec, raw folder, fallback raw folder, output folders)
SETS = {
    "iphone": (IPHONE, "iphone", None, ["iphone"]),
    "ipad": (IPAD, "ipad", None, ["ipad"]),
    "play_phone": (PLAY_PHONE, "android_phone", "iphone", ["phoneScreenshots"]),
    "play_tablet": (PLAY_TABLET, "android_tablet", "ipad",
                    ["sevenInchScreenshots", "tenInchScreenshots"]),
}

# Store locale codes differ between the two stores; captions are keyed by the Play one.
# Play-only locales (ne-NP, es-US, zh-HK) map to None: no App Store screenshots.
APPLE_LOCALE = {
    "en-US": "en-US", "es-ES": "es-ES", "es-419": "es-MX", "es-US": None, "pt-BR": "pt-BR",
    "pt-PT": "pt-PT", "de-DE": "de-DE", "fr-FR": "fr-FR", "fr-CA": "fr-CA", "it-IT": "it",
    "nl-NL": "nl-NL", "pl-PL": "pl", "tr-TR": "tr", "ru-RU": "ru", "uk": "uk", "id": "id",
    "vi": "vi", "th": "th", "ja-JP": "ja", "ko-KR": "ko", "zh-CN": "zh-Hans",
    "zh-TW": "zh-Hant", "zh-HK": None, "hi-IN": "hi", "bn-BD": "bn-BD", "ar": "ar-SA",
    "ne-NP": None,
}


def gradient(size):
    w, h = size
    strip = Image.new("RGB", (1, h))
    d = ImageDraw.Draw(strip)
    for y in range(h):
        t = (y / max(1, h - 1)) ** 1.4   # stays light behind the headline
        d.point((0, y), tuple(round(a + (b - a) * t) for a, b in zip(BG_TOP, BG_BOT)))
    return strip.resize(size, Image.BILINEAR)


def padlock(d, cx, cy, s):
    """A padlock centred on (cx, cy), body width 2s. The keyhole is cut through."""
    t = s * 0.30
    d.arc([cx - s * 0.72, cy - s * 1.55, cx + s * 0.72, cy - s * 0.05], 180, 360, fill=MARK, width=int(t))
    d.rectangle([cx - s * 0.72, cy - s * 0.80, cx - s * 0.72 + t, cy - s * 0.05], fill=MARK)
    d.rectangle([cx + s * 0.72 - t, cy - s * 0.80, cx + s * 0.72, cy - s * 0.05], fill=MARK)
    d.rounded_rectangle([cx - s, cy - s * 0.15, cx + s, cy + s * 1.45], radius=s * 0.28, fill=MARK)
    keyhole(d, cx, cy + s * 0.55, s * 0.24, (0, 0, 0, 0))


def keyhole(d, cx, cy, r, fill):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill)
    d.polygon([(cx - r * 0.45, cy + r * 0.4), (cx + r * 0.45, cy + r * 0.4),
               (cx + r * 0.75, cy + r * 2.6), (cx - r * 0.75, cy + r * 2.6)], fill=fill)


def background(spec):
    w, h = spec.canvas
    img = gradient(spec.canvas).convert("RGBA")
    mark = Image.new("RGBA", spec.canvas, (0, 0, 0, 0))
    d = ImageDraw.Draw(mark)
    padlock(d, w * 0.91, h * 0.060, w * 0.105)
    # bottom-left: a ring with a keyhole through it, the lock seen face-on
    r = w * 0.15
    cx, cy = w * 0.06, h * 0.965
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=MARK)
    keyhole(d, cx, cy - r * 0.25, r * 0.30, (0, 0, 0, 0))
    return Image.alpha_composite(img, mark).convert("RGB")


# --- Status bar -------------------------------------------------------------
# Every panel gets the same clean bar Apple and Google use in their own marketing:
# 9:41, full signal, full Wi-Fi, full battery, no notification icons. Geometry is in
# points (iOS) or dp (Android) and scaled to the capture, so it lands where the real
# one does on that device class.
#
#   keep     the capture's own bar is already clean (simulator `status_bar override`,
#            Android demo mode) — leave it, only add the Dynamic Island on iPhone
#   replace  paint over the capture's bar and draw a clean one (real-device captures)
#   add      the capture has no bar at all (the flutter-test harness) — make room on top
#
# Per raw folder in panels.json -> "status_bar": "replace", or {"mode": "replace",
# "bar": 40} to paint a taller band (pt/dp) when a phone's own bar peeks out under
# the clean one. `--status-bar=<mode>` overrides every folder.
SF = "/System/Library/Fonts/SFNS.ttf"

# folder -> (kind, logical width of the device class, bar height in those units)
DEVICE = {
    "iphone": ("ios", 440, 62),           # iPhone 16/17 Pro Max, 62 pt safe area
    "ipad": ("ipados", 1032, 24),          # iPad Pro 13", 24 pt bar
    "android_phone": ("android", 411, 32),  # 32 dp covers punch-hole phones
    "android_tablet": ("android", 800, 28),
}


def sf(px, weight="Semibold"):
    try:
        f = ImageFont.truetype(SF, px)
        f.set_variation_by_name(weight)
        return f
    except (OSError, ValueError):
        return ImageFont.truetype(F_BOLD if weight != "Regular" else F_MED, px)


def bar_colour(img, y):
    """The most common colour on row y — the app bar the status bar sits on."""
    row = img.crop((0, y, img.width, y + 1)).getcolors(img.width) or [(1, (255, 255, 255))]
    return max(row)[1]


def ink_for(bg):
    lum = 0.2126 * bg[0] + 0.7152 * bg[1] + 0.0722 * bg[2]
    return (0, 0, 0) if lum > 140 else (255, 255, 255)


def cell_bars(d, x, cy, u, c, ios=True):
    if ios:   # four rising bars, 17 x 11 pt
        bw, gap, h = 3 * u, 1.6 * u, 11 * u
        for i, f in enumerate((0.36, 0.55, 0.78, 1.0)):
            bx = x + i * (bw + gap)
            d.rounded_rectangle([bx, cy + h / 2 - h * f, bx + bw, cy + h / 2], radius=u * 0.8, fill=c)
        return 17 * u
    s = 14 * u   # Android: a filled right triangle
    d.polygon([(x, cy + s / 2), (x + s, cy + s / 2), (x + s, cy - s / 2)], fill=c)
    return s


def wifi(d, x, cy, u, c, ios=True):
    w = 15.5 * u if ios else 16 * u
    cx, base = x + w / 2, cy + 5.5 * u
    if ios:   # three arcs over a dot
        for r in (8.0, 5.4):
            d.arc([cx - r * u * 1.05, base - r * u * 1.05, cx + r * u * 1.05, base + r * u * 1.05],
                  225, 315, fill=c, width=max(1, round(2.0 * u)))
        r = 2.6 * u * 1.05
        d.pieslice([cx - r, base - r, cx + r, base + r], 225, 315, fill=c)
        return w
    r = 9 * u   # Android: one filled fan
    d.pieslice([cx - r, base - r, cx + r, base + r], 225, 315, fill=c)
    return w


def battery(d, x, cy, u, c, ios=True, bg=(255, 255, 255)):
    if ios:   # 27 x 13 pt, outline at 35%, full charge, nub on the right
        w, h = 25 * u, 12 * u
        dim = tuple(round(a * 0.35 + b * 0.65) for a, b in zip(c, bg))
        d.rounded_rectangle([x, cy - h / 2, x + w, cy + h / 2], radius=3.6 * u, outline=dim,
                            width=max(1, round(u)))
        d.rounded_rectangle([x + 2 * u, cy - h / 2 + 2 * u, x + w - 2 * u, cy + h / 2 - 2 * u],
                            radius=2 * u, fill=c)
        d.rounded_rectangle([x + w + 1 * u, cy - 2 * u, x + w + 2.4 * u, cy + 2 * u],
                            radius=u, fill=dim)
        return w + 2.4 * u
    w, h = 8 * u, 14 * u   # Android: upright, filled
    d.rectangle([x + w * 0.3, cy - h / 2 - 1.5 * u, x + w * 0.7, cy - h / 2], fill=c)
    d.rounded_rectangle([x, cy - h / 2, x + w, cy + h / 2], radius=1.2 * u, fill=c)
    return w


def status_bar(img, folder, mode, bar=None):
    kind, logical, default_bar = DEVICE[folder]
    bar = bar or default_bar
    u = img.width / logical
    band = round(bar * u)
    if mode == "add":
        bg = bar_colour(img, 1)
        grown = Image.new("RGB", (img.width, img.height + band), bg)
        grown.paste(img, (0, band))
        img = grown
    elif mode == "replace":
        bg = bar_colour(img, min(img.height - 1, band + 2))
        ImageDraw.Draw(img).rectangle([0, 0, img.width, band - 1], fill=bg)
    else:
        bg = bar_colour(img, min(img.height - 1, band + 2))
    d = ImageDraw.Draw(img)
    c = ink_for(bg)

    if kind == "ios":
        island_w, island_h, island_top = 126 * u, 37 * u, 11 * u
        cy = island_top + island_h / 2
        d.rounded_rectangle([(img.width - island_w) / 2, island_top,
                             (img.width + island_w) / 2, island_top + island_h],
                            radius=island_h / 2, fill=(0, 0, 0))
        if mode == "keep":
            return img
        d.text((82 * u, cy), "9:41", font=sf(round(17 * u)), fill=c, anchor="mm")
        x = 322 * u
        x += cell_bars(d, x, cy, u, c) + 5.5 * u
        x += wifi(d, x, cy, u, c) + 5.5 * u
        battery(d, x, cy, u, c, bg=bg)
    elif kind == "ipados":
        if mode == "keep":
            return img
        cy = band / 2
        f = sf(round(12.5 * u))
        d.text((20 * u, cy), "9:41", font=f, fill=c, anchor="lm")
        tx = 20 * u + d.textlength("9:41", font=f) + 6 * u
        d.text((tx, cy), "Tue Jan 9", font=sf(round(12.5 * u), "Medium"), fill=c, anchor="lm")
        right = img.width - 20 * u
        bw = 27.4 * u
        battery(d, right - bw, cy, u, c, bg=bg)
        pct = "100%"
        pw = d.textlength(pct, font=f)
        d.text((right - bw - 4 * u - pw, cy), pct, font=f, fill=c, anchor="lm")
        wifi(d, right - bw - 4 * u - pw - 5 * u - 15.5 * u, cy, u, c)
    else:
        if mode == "keep":
            return img
        cy = band / 2
        d.text((24 * u, cy), "9:41", font=ImageFont.truetype(F_MED, round(14 * u)), fill=c, anchor="lm")
        x = img.width - 24 * u - 8 * u
        battery(d, x, cy, u, c, ios=False)
        x -= 6 * u + 14 * u
        cell_bars(d, x, cy, u, c, ios=False)
        x -= 6 * u + 16 * u
        wifi(d, x, cy, u, c, ios=False)
    return img


def fit(img, box):
    """Scale to cover `box` and centre-crop."""
    bw, bh = box
    s = max(bw / img.width, bh / img.height)
    r = img.resize((max(1, round(img.width * s)), max(1, round(img.height * s))), Image.LANCZOS)
    return r.crop(((r.width - bw) // 2, (r.height - bh) // 2,
                   (r.width - bw) // 2 + bw, (r.height - bh) // 2 + bh))


def device(canvas, screen, spec):
    """Frame `screen` at the largest size that fits the spec's band, centred."""
    w, h = spec.canvas
    max_w = w * spec.screen_w
    max_h = h * (spec.bottom - spec.top)
    s = min(max_w / screen.width, max_h / screen.height)
    sw, sh = round(screen.width * s), round(screen.height * s)
    x, y = (w - sw) // 2, round(h * spec.top)
    bezel = max(6, round(sw * spec.bezel))
    radius = round(sw * spec.radius)

    frame = Image.new("RGBA", (sw + 2 * bezel, sh + 2 * bezel), (0, 0, 0, 0))
    d = ImageDraw.Draw(frame)
    d.rounded_rectangle([0, 0, sw + 2 * bezel - 1, sh + 2 * bezel - 1],
                        radius=radius + bezel, fill=BEZEL)
    inner = fit(screen, (sw, sh)).convert("RGBA")
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw - 1, sh - 1], radius=radius, fill=255)
    frame.paste(inner, (bezel, bezel), mask)
    canvas.paste(frame, (x - bezel, y - bezel), frame)


def font_for(locale, bold):
    """(file, face index) for this locale's headline (bold) or subtitle face."""
    lang = locale.split("-")[0]
    if lang not in SYSTEM_FONTS:
        return (F_BOLD if bold else F_MED), 0
    files, bold_styles, med_styles = SYSTEM_FONTS[lang]
    # styles in priority order, so a subtitle prefers W4 even when the W7 file comes first
    for want in (bold_styles if bold else med_styles):
        for path in files:
            if not os.path.isfile(path):
                continue
            for i in range(32):
                try:
                    style = ImageFont.truetype(path, 12, index=i).getname()[1]
                except OSError:
                    break
                if style == want:
                    return path, i
    existing = [p for p in files if os.path.isfile(p)]
    return (existing[0], 0) if existing else ((F_BOLD if bold else F_MED), 0)


def truetype(face, px):
    return ImageFont.truetype(face[0], px, index=face[1])


def _greedy(d, units, joiner, font, max_w):
    lines, cur = [], ""
    for u in units:
        trial = (cur + joiner + u) if cur else u
        if d.textlength(trial, font=font) <= max_w or not cur:
            cur = trial
        else:
            lines.append(cur)
            cur = u
    if cur:
        lines.append(cur)
    return lines


def wrap(d, text, font, max_w):
    """Break into as few lines as fit, then even them out: no orphan word or
    character on the last line ("Strong passwords / in one tap", not "… in / one tap")."""
    # CJK and Thai have no spaces between words: break between characters instead.
    if " " not in text.strip():
        units, joiner = list(text), ""
    else:
        units, joiner = text.split(), " "
    lines = _greedy(d, units, joiner, font, max_w)
    if len(lines) < 2:
        return lines
    lo = max(d.textlength(u, font=font) for u in units)
    hi = max_w
    while hi - lo > 2:   # narrowest width that still gives the same number of lines
        mid = (lo + hi) / 2
        if len(_greedy(d, units, joiner, font, mid)) <= len(lines):
            hi = mid
        else:
            lo = mid
    return _greedy(d, units, joiner, font, hi)


def caption(img, spec, head, sub, locale):
    w, h = spec.canvas
    d = ImageDraw.Draw(img)
    margin = int(w * 0.075)
    fb, fm = font_for(locale, True), font_for(locale, False)

    px = int(w * spec.head)
    fh = truetype(fb, px)
    lines = wrap(d, head, fh, w - 2 * margin)
    # shrink rather than run to three lines; two lines is fine
    while (len(lines) > 2 or any(d.textlength(l, font=fh) > w - 2 * margin for l in lines)) \
            and px > w * spec.head * 0.70:
        px = int(px * 0.95)
        fh = truetype(fb, px)
        lines = wrap(d, head, fh, w - 2 * margin)

    line_h = int(px * 1.14)
    y = int(h * 0.075)
    ink_bottom = y
    for ln in lines:
        d.text((w / 2, y), ln, font=fh, fill=INK, anchor="ma")
        ink_bottom = d.textbbox((w / 2, y), ln, font=fh, anchor="ma")[3]
        y += line_h

    # the rule hangs under the lowest descender, not under the line box
    ry = ink_bottom + int(px * 0.30)
    rw, rh = int(w * 0.085), max(6, int(w * 0.0065))
    d.rounded_rectangle([w / 2 - rw / 2, ry, w / 2 + rw / 2, ry + rh], radius=rh // 2, fill=RULE)

    sp = int(w * spec.sub)
    fs = truetype(fm, sp)
    y = ry + rh + int(sp * 0.9)
    sub_lines = wrap(d, sub, fs, w - 2 * margin)
    while len(sub_lines) > 2 and sp > w * spec.sub * 0.75:
        sp = int(sp * 0.95)
        fs = truetype(fm, sp)
        sub_lines = wrap(d, sub, fs, w - 2 * margin)
    for ln in sub_lines:
        d.text((w / 2, y), ln, font=fs, fill=SUB, anchor="ma")
        y += int(sp * 1.28)
    return y


def panel(spec, screen, head, sub, locale):
    img = background(spec)
    bottom_of_text = caption(img, spec, head, sub, locale)
    # never let a long localized caption run under the device
    top = max(spec.top, (bottom_of_text + spec.canvas[0] * 0.05) / spec.canvas[1])
    local = Spec(spec.name, spec.canvas, spec.head, spec.sub, spec.screen_w, top,
                 spec.bottom, spec.bezel, spec.radius, spec.island)
    device(img, screen, local)
    return img


def raw_path(folder, slug):
    for ext in (".png", ".jpg", ".jpeg"):
        p = os.path.join(RAW, folder, slug + ext)
        if os.path.isfile(p):
            return p
    return None


def contact_sheet(paths, dst):
    if not paths:
        return
    ims = [Image.open(p) for p in paths]
    th = 900
    thumbs = [im.resize((round(im.width * th / im.height), th), Image.LANCZOS) for im in ims]
    gap = 24
    sheet = Image.new("RGB", (sum(t.width for t in thumbs) + gap * (len(thumbs) + 1), th + 2 * gap),
                      (235, 235, 238))
    x = gap
    for t in thumbs:
        sheet.paste(t, (x, gap))
        x += t.width + gap
    sheet.save(dst)


def build(locale, captions, panels):
    report = []
    for set_name, slugs in panels["sets"].items():
        spec, folder, fallback, outs = SETS[set_name]
        made, missing, borrowed = [], [], []
        for out_folder in outs:
            os.makedirs(os.path.join(OUT, locale, out_folder), exist_ok=True)
        for i, slug in enumerate(slugs, start=1):
            if slug not in captions:
                missing.append(f"{slug} (no caption in {locale}.json)")
                continue
            src, src_folder = raw_path(folder, slug), folder
            if src is None and fallback:
                src, src_folder = raw_path(fallback, slug), fallback
                if src:
                    borrowed.append(slug)
            if src is None:
                missing.append(f"{folder}/{slug}.png")
                continue
            screen = Image.open(src).convert("RGB")
            cfg = panels.get("status_bar", {}).get(src_folder, "replace")
            if isinstance(cfg, str):
                cfg = {"mode": cfg}
            screen = status_bar(screen, src_folder, BAR_MODE or cfg.get("mode", "replace"),
                                cfg.get("bar"))
            img = panel(spec, screen, captions[slug]["head"], captions[slug]["sub"], locale)
            for out_folder in outs:
                dst = os.path.join(OUT, locale, out_folder, f"{i:02d}_{slug}.png")
                img.save(dst, optimize=True)
            for extra, size in EXTRA_SIZES.get(set_name, []):
                os.makedirs(os.path.join(OUT, locale, extra), exist_ok=True)
                img.resize(size, Image.LANCZOS).save(
                    os.path.join(OUT, locale, extra, f"{i:02d}_{slug}.png"), optimize=True)
            made.append(os.path.join(OUT, locale, outs[0], f"{i:02d}_{slug}.png"))
        contact_sheet(made, os.path.join(OUT, f"_contact_{locale}_{set_name}.png"))
        report.append((set_name, len(made), len(slugs), missing, borrowed))
    return report


def install(locale):
    src = os.path.join(OUT, locale)
    apple = APPLE_LOCALE.get(locale)
    if apple:
        dst = os.path.join(ROOT, "ios/fastlane/screenshots", apple)
        shutil.rmtree(dst, ignore_errors=True)
        os.makedirs(dst)
        # deliver reads one flat folder per locale and sorts by name, so prefix the set
        for sub, tag in (("iphone", "a"), ("iphone_63", "c"), ("ipad", "b")):
            d = os.path.join(src, sub)
            for f in sorted(os.listdir(d)) if os.path.isdir(d) else []:
                shutil.copyfile(os.path.join(d, f), os.path.join(dst, f"{tag}{f}"))
        print(f"  installed -> ios/fastlane/screenshots/{apple}/")
    images = os.path.join(ROOT, "android/fastlane/metadata/android", locale, "images")
    for sub in ("phoneScreenshots", "sevenInchScreenshots", "tenInchScreenshots"):
        d = os.path.join(src, sub)
        if not os.path.isdir(d) or not os.listdir(d):
            continue
        dst = os.path.join(images, sub)
        shutil.rmtree(dst, ignore_errors=True)
        shutil.copytree(d, dst)
    print(f"  installed -> android/fastlane/metadata/android/{locale}/images/")


def main():
    global BAR_MODE
    args = sys.argv[1:]
    for a in args:
        if a.startswith("--status-bar="):
            BAR_MODE = a.split("=", 1)[1]
            if BAR_MODE not in ("keep", "replace", "add"):
                sys.exit("--status-bar must be keep, replace or add")
    if not features.check("raqm"):
        print("warning: no raqm text shaping — Devanagari, Bengali, Thai and Arabic "
              "captions will render wrongly (brew install libraqm)")
    with open(os.path.join(CFG, "panels.json"), encoding="utf-8") as f:
        panels = json.load(f)
    cap_dir = os.path.join(CFG, "captions")
    if "--all" in args:
        locales = sorted(n[:-5] for n in os.listdir(cap_dir) if n.endswith(".json"))
    else:
        locales = [a for a in args if not a.startswith("--")] or ["en-US"]

    for locale in locales:
        with open(os.path.join(cap_dir, f"{locale}.json"), encoding="utf-8") as f:
            captions = json.load(f)
        print(f"{locale}")
        for set_name, made, total, missing, borrowed in build(locale, captions, panels):
            print(f"  {set_name:12} {made}/{total}")
            if borrowed:
                print(f"               borrowed from iOS captures: {', '.join(borrowed)}")
            if missing:
                print(f"               waiting on: {', '.join(missing)}")
        if "--install" in args:
            install(locale)
    print("\nreview listing/shots/out/_contact_*.png before --install")


if __name__ == "__main__":
    main()
