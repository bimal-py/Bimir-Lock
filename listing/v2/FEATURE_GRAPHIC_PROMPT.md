# Google Play feature graphic ("cover") — Bimir Lock

**Spec:** 1024 × 500 px, PNG (24-bit, no transparency) or JPEG, under 15 MB.
Play shows it at the top of the listing, in some search/editorial slots, and
crops it differently per device. Keep the logo, name and phone inside the middle
~80%; nothing important within 50 px of any edge.

**In use for 1.1.1:** the graphic you made, `listing/v2/graphics/feature_graphic_source.png`
(1794 × 876), scaled to `listing/v2/graphics/featureGraphic.png` (1024 × 500) and
installed at `android/fastlane/metadata/android/en-US/images/featureGraphic.png`.
Upload it with `cd android && bundle exec fastlane upload_images`.

The two ways it can be regenerated:

## A. Built from the real app

```sh
../marketing/.venv/bin/python tool/make_feature_graphic.py            # writes listing/shots/out/
../marketing/.venv/bin/python tool/make_feature_graphic.py --install  # REPLACES the graphic above
```

Uses the real logo (`assets/brand/mark.png`), the real vault capture
(`listing/shots/raw/android_phone/vault.png`) and the same crimson system as the
screenshots. A preview made from the test harness is in
`listing/shots/preview/feature_graphic_preview.png`. No invented UI, no garbled
logo — and it matches the screenshots exactly.

## B. Image-model prompt (for a more illustrated cover)

Image models redraw logos and app text badly. Generate the **scene without the logo
or any words**, then place the real logo + "Bimir Lock" + tagline on top in
Figma/Canva (Google Sans Flex Bold, colour `#480E25`; tagline `#5E4E55`).

### Prompt (ChatGPT image / Gemini / Ideogram / Midjourney)

```
Wide banner, exact aspect ratio 1024:500, for a mobile password-manager app called
Bimir Lock. Calm, premium, editorial product photography style — NOT a 3D render,
NOT sci-fi.

Background: flat warm off-white (#FBF7F8) fading very slightly to a soft blush pink
(#F3DDE5) at the bottom. A single very large, very faint padlock outline in deep
crimson at about 5% opacity bleeds off the top-right corner.

Right half: one modern smartphone with thin black bezels, front-facing, tilted about
8 degrees, standing on the lower edge so its bottom third is cropped by the frame.
On its screen, a clean light-theme list app: a rounded search bar, one summary card
with a small amber shield icon, and a list of rows, each with a pastel circle
holding a single capital letter and two lines of short grey text. Accent colour
deep crimson #901743 used only on one small round "+" button. Crisp, legible,
minimal UI. Soft natural shadow under the phone.

Left half: empty negative space (text will be added later), with nothing in it
except the background.

Style rules: flat, clean, restrained, lots of whitespace. No glowing effects, no
neon, no holograms, no circuit-board patterns, no binary code, no floating shields,
no padlock icons on the screen, no gradients beyond the subtle background, no
people, no hands, no text, no letters, no logos, no watermark.
```

### If the model must also render the text (Ideogram or GPT-image are best at it)

Append:

```
On the left half, vertically centred and left-aligned with generous margin: the
words "Bimir Lock" in a heavy geometric sans-serif, colour #480E25, very large;
under it, smaller, in warm grey #5E4E55: "Your passwords, locked on your phone";
under that, three small outlined pill labels in crimson #901743 reading "Offline",
"No account", "Encrypted". Spell every word exactly as written.
```

Then still replace the generated monogram/logo (if any) with the real one.

### Checklist before uploading

- [ ] Exactly 1024 × 500, no alpha channel (`sips -g hasAlpha file.png`)
- [ ] Real logo, not a model's imitation of it
- [ ] Every visible word spelled right; no fake UI words like "Pasword"
- [ ] Nothing claims what the app doesn't do (no "sync", "cloud", "#1", "most secure")
- [ ] Readable at 50% size (that is how it shows in many slots)
- [ ] Save to `android/fastlane/metadata/android/en-US/images/featureGraphic.png`,
      then `cd android && bundle exec fastlane upload_images`
