# Logo Usage Guidelines

**Status: written against the approved exports in [`exports/`](README.md#current-exports).** Every measurement below was taken from the exported SVGs themselves (rendered and measured, not estimated), and every contrast ratio uses the method in [../colors/contrast-checks.md](../colors/contrast-checks.md). Minimum sizes are for screens; print minimums aren't set yet because nothing has been printed (see [Known limitations](#known-limitations)).

## The parts

All three pieces share the same artwork. The lockup is the logomark and wordmark placed together at fixed proportions; don't rebuild it by hand.

| Piece | Files | Native size (SVG units) | What it is |
|---|---|---|---|
| **Primary logo (lockup)** | `kombien-logo-light.svg`, `kombien-logo-dark.svg` | 731 × 265 | Logomark on the left, wordmark sitting on its baseline to the right |
| **Logomark (compact symbol)** | `kombien-logomark-light.svg`, `kombien-logomark-dark.svg` | 189 × 265 | The raised two-finger hand with the curved swoosh, single color |
| **Wordmark** | `kombien-wordmark-light.svg`, `kombien-wordmark-dark.svg` | 520 × 157 | Lowercase "kombien" with three Mango figures: two forming the "m", one forming the "n" |
| **Monochrome lockup** | `kombien-logo-monochrome.svg` | 731 × 265 | The lockup entirely in Warm White, figures included |

Remember the suffix convention from [README.md](README.md#current-exports): `-light` means *for light backgrounds* (Charcoal ink), and `-dark` means *for dark backgrounds* (Warm White ink).

### When to use which

- **Primary logo:** the default anywhere there's room. Use it in the README header, the app's about/splash surfaces, social banners, and slides.
- **Logomark:** where space is square or tiny, or where the name is already on screen next to it: app bar, social avatars, a favicon-scale slot, a watermark. Don't use it as a stand-in for the name in places where nobody has seen the name yet.
- **Wordmark:** where the hand would compete with something else already gestural or illustrated (for example next to the mascot), or in tight horizontal spaces like a nav bar where the lockup's height won't fit.
- **Monochrome:** one-ink situations on a **dark** background: an embossed or stamped look, a single-color overlay on a dark photo, or printing in one light ink on a dark material. There is no dark-ink one-color file yet (see [Known limitations](#known-limitations)).

## Clear space

**None of the exported files include padding.** Rendering them shows the artwork running right up to all four edges of the viewBox (within half a unit). Anything placed next to an SVG's bounding box is therefore touching the logo, so add the clear space yourself.

The unit is **x = the diameter of one figure's head** in the wordmark (28 units at native size).

| Piece | Minimum clear space, every side | As a share of the piece's height |
|---|---|---|
| Primary logo | 1x (28 units) | ≈ 10.5% of lockup height |
| Wordmark | 1x (28 units) | ≈ 18% of wordmark height |
| Logomark | 1 finger-stroke width (24 units); the logomark has no figures, so its own stroke is the unit | ≈ 9% of logomark height |

That's the floor, not the target. In layouts with room, such as a splash screen, a README header, or a social card, use **2x or more**.

Worked example: a lockup shown 58 px tall needs at least 6 px on every side, and 12 px is better.

## Minimum size

These were tested by rasterizing each SVG at exact pixel sizes on Warm White at 1x density, then checking where the parts stop reading distinctly.

| Piece | Minimum (screen) | What breaks below it |
|---|---|---|
| Primary logo | **160 px wide** (≈ 58 px tall) | Around 130 px wide the figures' heads start fusing with the "m" strokes, and by 100 px the wordmark reads as a smudge next to the hand |
| Wordmark | **120 px wide** (≈ 36 px tall) | Below about 100 px wide the three figure heads merge into the letters |
| Logomark | **20 px tall** (24 px preferred) | At 16 px the gesture still reads; at 12 px it doesn't. Below 20 px, use the dedicated favicon files rather than scaling the logomark down |

On high-density screens these are CSS/logical pixels, not device pixels.

## Background usage

The logo is drawn in two inks: Charcoal (or Warm White) for the hand and letters, and Mango for the wordmark's figures. The Mango figures are what limit where the lockup and wordmark can go, because they disappear on any background close to Mango in lightness.

| Background | Lockup / wordmark | Logomark | Why |
|---|---|---|---|
| Warm White `#F4F1E8` | ✅ `-light` | ✅ `-light` | The intended pairing. Charcoal is 14.43:1; the Mango figures are a low 1.83:1, but they read by hue and shape, and this is the approved art |
| Background-secondary `#ECE7D8`, plain white | ✅ `-light` | ✅ `-light` | Charcoal 13.18:1 on `#ECE7D8`; figures stay visible (1.67:1 and 2.07:1) for the same reason as above |
| Charcoal `#202020` | ✅ `-dark` | ✅ `-dark` | Warm White 14.43:1, Mango figures 7.88:1. This is the strongest pairing for the full-color logo |
| Deep Neutral `#121212`, `#262626` | ✅ `-dark` | ✅ `-dark` | Same as Charcoal, a little stronger on `#121212` |
| Mango `#F4A340` | ❌ | ✅ `-light` only | The figures vanish into the background and the wordmark reads "ko bie". The Charcoal logomark is 7.88:1 on Mango and works well |
| Dust Grey `#A7A18E` | ❌ | ✅ `-light` only | Mango on Dust Grey is 1.25:1, so the figures effectively disappear. Charcoal is 6.31:1 |
| Muted Neutral `#6F6A60` | ❌ | ❌ | Neither ink holds up well: Warm White is 4.76:1, Mango 2.60:1, and Charcoal is too dark. Choose a different surface |
| Photos or illustrations | Only on a calm area that's clearly light or clearly dark, using the matching variant | Same | Never over a busy area or one that shifts between light and dark across the mark. If no calm area exists, put the logo on a solid Warm White or Charcoal panel instead |

The monochrome (Warm White) lockup follows the `-dark` row. It is **not** for Mango backgrounds: Warm White on Mango is 1.83:1.

## Color restrictions

- The hand and the letters are always **Charcoal `#202020`** (on light) or **Warm White `#F4F1E8`** (on dark).
- The wordmark's figures are always **Mango `#F4A340`**, except in the monochrome version, where everything is Warm White.
- No other brand color (Dust Grey, Muted Neutral, Success, Warning, Error) appears in the logo. No gradients, tints, or opacity changes.
- The mascot has its own recolor rules (Mango, Charcoal, Dust Grey). Those apply to the standalone mascot files only, not to the figures inside the wordmark. See [../illustration/README.md](../illustration/README.md).

## Incorrect usage

Don't:

1. **Put the lockup or wordmark on Mango or Dust Grey.** The figures disappear (see [Background usage](#background-usage)).
2. **Recolor the figures** to Charcoal, Warm White, or anything else in the two-ink versions. The orange figures are the wordmark's identity; if you need one ink, use the monochrome file.
3. **Swap the light and dark files** (for example `-light` on Charcoal). The ink would match the background.
4. **Stretch, squash, skew, or rotate** any piece. Scale proportionally only.
5. **Re-space or rearrange the lockup.** Don't move the wordmark relative to the hand, stack them vertically, or put the hand on the right. Only the exported lockup is approved; a stacked lockup doesn't exist yet.
6. **Retype "kombien" in a font** in place of the wordmark. The lettering is custom and includes the figures; Space Grotesk "kombien" is body text, not the logo.
7. **Add effects:** drop shadows, outlines or strokes, glows, bevels, textures, or gradients.
8. **Crop the artwork or crowd it.** Respect the clear space, and remember that the files themselves have none.
9. **Use the logo below its minimum size.** Use the logomark, then the favicon files, instead.
10. **Animate the logo.** The logomark is the static identity mark; the mascot is the one that moves. See [../illustration/README.md](../illustration/README.md).
11. **Place it over busy photos** without a calm area or a solid panel behind it.

## Favicon and app icon

- **Favicons** (`favicon16x16.svg`, `favicon32x32.svg`, `favicon512x512-png.png`) are the logomark, redrawn per size, sitting inside a circular clip on a white square. The mark covers about 56% of the canvas height (9 of 16 px at 16 px), which leaves room for browser-tab rounding. Use the file sized for the slot; don't downscale the 512 px PNG to 16 px.
- **App icon** (`kombien-app-icon-svg.svg`, `kombien-app-icon-png.png`, 432 × 432) is the logomark, Charcoal on white, inside a 264 px circular safe zone. The ink spans about 170 × 239 units, centered. That safe zone survives the circular and squircle masks applied by iOS and Android.
- Both use pure white `#FFFFFF` as the background, not Warm White (see [Known limitations](#known-limitations)).
- The wordmark is never used at icon scale; its figures don't survive it.

## Figma source location

See [Source references](#source-references). The file is private to the project owner.

## Export naming conventions

See [README.md → Current exports](README.md#current-exports) for the full file list and the naming quirks to keep.

## Known limitations

These are true of the current exports. They're listed so nobody works around them silently. Fixing any of them is a design change and goes through a PR with the [design checklist](../../.github/PULL_REQUEST_TEMPLATE.md).

- **No padding in any SVG.** Clear space has to be added by whoever places the file.
- **No dark-ink one-color version.** `kombien-logo-monochrome.svg` is Warm White only, so a one-ink Charcoal use (stamping on light paper, a fax-style printout) has no approved file yet.
- **Off-palette near-white in the dark and monochrome files.** The "k" in `kombien-logo-dark.svg`, `kombien-logo-monochrome.svg`, and `kombien-wordmark-dark.svg` is stroked `#F3EBDD` while the rest is Warm White `#F4F1E8`. The difference is invisible in practice (1.05:1), but it isn't a palette color.
- **The favicons and app icon use pure white**, not Warm White, as their background.
- **Print minimum sizes aren't set.** No print use case exists yet, and `exports/pdf/` is empty. Set them by proofing a real print rather than converting the pixel values.
- **No logomark-only or wordmark-only monochrome files.**

## Source references

| Field | Value |
|---|---|
| Figma file link | *Not published. The source file is private to the project owner; ask via an issue if you need access.* |
| Figma page name | *train* |
| Date of export | *Friday 25th, September 2026* |
| Designer / contributor | *By Egbe Michel Tambe* |
| Approval status | *Approved* |
| Export formats | *.svg, .png* |
| Known limitations | See [Known limitations](#known-limitations) |

Don't fill fields here with placeholder-looking values to make this look further along than it is. Leave a field marked "not yet" until it's genuinely true.
