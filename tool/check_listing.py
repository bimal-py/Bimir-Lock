#!/usr/bin/env python3
"""Check every store-listing file against the limits the two stores enforce.

Run before any upload. `supply` and `deliver` both print success for values the
store silently truncated or refused per-locale, so measuring here first is the
only cheap way to know a listing is sound.

    python3 tool/check_listing.py                 # listing/v2
    python3 tool/check_listing.py listing/v3      # any listing set

Ported from ../callbreaktracker/tool/check_listing.py. The differences are what a
password manager can get wrong: claiming features Bimir Lock does not have (cloud
sync, breach alerts, 2FA codes), security superlatives Play treats as unverifiable,
and competitor names in Apple's keyword field.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRAND = "Bimir Lock"

PLAY_LOCALES = set("""af am ar az-AZ be bg bn-BD ca cs-CZ da-DK de-DE el-GR en-AU en-CA
en-GB en-IN en-SG en-US en-ZA es-419 es-ES es-US et eu-ES fa fi-FI fil fr-CA fr-FR gl-ES
hi-IN hr hu-HU hy-AM id is-IS it-IT iw-IL ja-JP ka-GE km-KH kn-IN ko-KR ky-KG lo-LA lt lv
mk-MK ml-IN mn-MN mr-IN ms ms-MY my-MM ne-NP nl-NL no-NO pl-PL pt-BR pt-PT rm ro ru-RU
si-LK sk sl sr sv-SE sw ta-IN te-IN th tr-TR uk vi zh-CN zh-HK zh-TW zu""".split())

APPLE_LOCALES = set("""ar-SA bn-BD ca cs da de-DE el en-AU en-CA en-GB en-US es-ES es-MX
fi fr-CA fr-FR gu-IN he hi hr hu id it ja kn-IN ko ml-IN mr-IN ms nl-NL no or-IN pa-IN pl
pt-BR pt-PT ro ru sk sl-SI sv ta-IN te-IN th tr uk ur-PK vi zh-Hans zh-Hant""".split())

PLAY_LIMITS = {"title": 30, "short_description": 80, "full_description": 4000,
               "changelog": 500}
APPLE_LIMITS = {"name": 30, "subtitle": 30, "keywords": 100,
                "promotional_text": 170, "description": 4000, "release_notes": 4000}

# Things Bimir Lock does not do. A listing that claims one is a one-star review
# waiting to happen, and Play's metadata policy rejects unverifiable superlatives.
# A disclaimer ("no cloud sync", "without an account") says the opposite of a
# claim, so a match negated in its own clause is left alone.
FORBIDDEN = re.compile(
    r"\b(cloud sync|syncs?|synchroni[sz]e[sd]?|across (all )?(your )?devices|"
    r"dark web|breach (alerts?|monitoring|scan)|data breach alerts?|"
    r"two[- ]factor codes?|2fa codes?|authenticator|totp|passkeys?|"
    r"browser extension|desktop app|"
    r"military[- ]grade|unhackable|uncrackable|100% secure|bank[- ]level|"
    r"most secure|best password|#1|number one|"
    r"zero[- ]knowledge|end[- ]to[- ]end)\b", re.I)

NEGATION_BEFORE = re.compile(
    r"\b(no|not|without|never|nor|none|isn't|doesn't|don't|won't)\b[^.;:!?\n]*$", re.I)

# Apple rejects other companies' names in the keyword field (guideline 2.3.7).
COMPETITORS = re.compile(
    r"\b(bitwarden|1password|lastpass|dashlane|keeper|nordpass|proton|enpass|keepass\w*|"
    r"roboform|norton|mcafee|avast|kaspersky|google|apple|icloud|samsung|chrome|"
    r"keychain|authy|microsoft)\b", re.I)

# Play title rules: no emoji, no ALL-CAPS words, no promotional words.
EMOJI = re.compile(r"[\U0001F000-\U0001FAFF☀-➿]")
PROMO_IN_TITLE = re.compile(r"\b(free|best|top|#1|new|sale|discount|no ads)\b", re.I)


def length(text):
    """Both stores count UTF-16 code units: an emoji outside the BMP costs two."""
    return sum(2 if ord(c) > 0xFFFF else 1 for c in text)


def claims(text):
    for hit in FORBIDDEN.finditer(text):
        before = text[max(0, hit.start() - 80):hit.start()]
        if not NEGATION_BEFORE.search(before):
            return hit
    return None


problems = []
notes = []


def check(store, root, locales, limits, required):
    if not os.path.isdir(root):
        problems.append(f"{store}: {root} does not exist")
        return
    seen = sorted(d for d in os.listdir(root)
                  if os.path.isdir(os.path.join(root, d)) and not d.startswith("_"))
    for locale in seen:
        if locale not in locales:
            problems.append(f"{store}/{locale}: not a valid {store} locale")
            continue
        for field, limit in limits.items():
            path = os.path.join(root, locale, f"{field}.txt")
            if not os.path.isfile(path):
                if field in required:
                    problems.append(f"{store}/{locale}: missing {field}.txt")
                continue
            text = open(path, encoding="utf-8").read().strip()
            if not text:
                problems.append(f"{store}/{locale}/{field}: empty")
            # Apple's keyword field is 100 BYTES of UTF-8, not characters: a Japanese,
            # Hindi or Arabic keyword costs three bytes a letter.
            n = len(text.encode("utf-8")) if field == "keywords" else length(text)
            if n > limit:
                unit = "bytes" if field == "keywords" else "chars"
                problems.append(f"{store}/{locale}/{field}: {n} {unit}, limit {limit}")
            if field in ("title", "name"):
                if not text.startswith(BRAND):
                    problems.append(f"{store}/{locale}/{field}: {text!r} — must start "
                                    f"with the brand {BRAND!r}, untranslated")
                if EMOJI.search(text):
                    problems.append(f"{store}/{locale}/{field}: emoji in the name")
                if PROMO_IN_TITLE.search(text):
                    problems.append(f"{store}/{locale}/{field}: promotional word "
                                    f"{PROMO_IN_TITLE.search(text).group(0)!r} in the name")
                if any(w.isupper() and len(w) > 3 for w in re.findall(r"[A-Za-z]+", text)):
                    problems.append(f"{store}/{locale}/{field}: ALL-CAPS word in the name")
            if field == "short_description" and EMOJI.search(text):
                notes.append(f"{store}/{locale}/short_description: emoji — Play allows it "
                             "but it reads as spam in search results")
            hit = claims(text)
            if hit:
                problems.append(
                    f"{store}/{locale}/{field}: claims {hit.group(0)!r} — Bimir Lock has "
                    "no sync, no breach monitoring, no 2FA codes, and makes no superlatives")
            if field == "keywords":
                if ", " in text:
                    notes.append(f"{store}/{locale}/keywords: space after a comma — "
                                 "Apple ignores it but it costs a character")
                comp = COMPETITORS.search(text)
                if comp:
                    problems.append(f"{store}/{locale}/keywords: names {comp.group(0)!r} — "
                                    "Apple rejects other brands in keywords")
        # Apple indexes the name and the subtitle already, so a keyword repeated
        # from either is a wasted slot in a 100-character field.
        if store == "apple":
            name = os.path.join(root, locale, "name.txt")
            sub = os.path.join(root, locale, "subtitle.txt")
            kw = os.path.join(root, locale, "keywords.txt")
            if all(os.path.isfile(p) for p in (name, sub, kw)):
                covered = set(re.findall(r"\w+", (open(name, encoding="utf-8").read() + " " +
                                                  open(sub, encoding="utf-8").read()).lower()))
                dupes = sorted({w for k in open(kw, encoding="utf-8").read().split(",")
                                for w in re.findall(r"\w+", k.lower()) if w in covered})
                if dupes:
                    notes.append(f"apple/{locale}/keywords: repeats "
                                 f"{', '.join(dupes)} from the name or subtitle")
    print(f"{store}: {len(seen)} locale(s)")


LISTING = os.path.join(ROOT, sys.argv[1] if len(sys.argv) > 1 else "listing/v2")
check("play", os.path.join(LISTING, "play"), PLAY_LOCALES, PLAY_LIMITS,
      required={"title", "short_description", "full_description"})
check("apple", os.path.join(LISTING, "apple"), APPLE_LOCALES, APPLE_LIMITS,
      required={"name", "subtitle", "keywords", "description"})

for n in notes:
    print(f"  note  {n}")
for p in problems:
    print(f"  FAIL  {p}")
print(f"\n{len(problems)} problem(s), {len(notes)} note(s)")
sys.exit(1 if problems else 0)
