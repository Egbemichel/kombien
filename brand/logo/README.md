# Kombien Logo System

**Status: first approved exports in place.** The wordmark, logomark, combined logo, monochrome version, app icon, and favicon have been designed in Figma and exported — see [Current exports](#current-exports) below and [usage-guidelines.md](usage-guidelines.md#source-references) for the Figma source.

## Approved direction

**A hand gesture and a lettering system, not a taxi or a road.**

This corrects an earlier version of this document, which described a direction (an abstract "?"/price-notation symbol) that was never actually built. What follows describes the real, exported artwork.

- **The logomark** is a raised two-finger hand gesture with a small curved swoosh beneath it — read at once as *counting* ("how many/how much") and as the physical act of hailing a taxi. It's gestural and specific to the cultural moment the whole project is named after, without being a literal vehicle, road, or map icon (see [../strategy/brand-strategy.md](../strategy/brand-strategy.md#what-the-brand-should-avoid) — that "avoid" list is about generic mobility-app iconography, not about gesture generally, and a hand doesn't fall into it).
- **The wordmark** is custom lowercase lettering for "kombien" with two small orange (Mango) faceless humanoid figures built directly into the letterforms, standing in for what would otherwise be plain dots/connectors. Two figures, specifically — a natural, if unconfirmed, read as the two sides of every fare negotiation (rider and driver).
- Both the logomark and the wordmark's embedded figures work in flat, single-color silhouette and hold up at small sizes (favicon/app-icon scale).
- The wordmark's figure is also the seed for Kombien's mascot — see [../illustration/README.md](../illustration/README.md) for that character system. The logomark (the hand gesture) and the mascot (the figure) are deliberately two separate things: one is the static identity mark, the other is the animated in-product companion.

## Directory structure

| Directory | Purpose |
|---|---|
| `source/` | Not files — just a pointer to the Figma file (see [usage-guidelines.md](usage-guidelines.md#source-references)) |
| `exports/svg/` | Every exported SVG — wordmark, logomark, logo, monochrome, app icon, favicon, all types together |
| `exports/png/` | Raster fallbacks, where needed |
| `exports/pdf/` | Print-ready exports — empty until a print use case actually exists |

There's a single canonical home per file: **`exports/<format>/`**, organized by format, not by logo type — the filename already encodes the type.

## Current exports

Naming in use, in `exports/svg/` unless noted:

| File | What it is |
|---|---|
| `kombien-wordmark-light.svg` | Wordmark, for light backgrounds |
| `kombien-wordmark-dark.svg` | Wordmark, for dark backgrounds |
| `kombien-logomark-light.svg` | Logomark (compact mark), for light backgrounds |
| `kombien-logomark-dark.svg` | Logomark, for dark backgrounds |
| `kombien-logo-light.svg` | Combined lockup (logomark + wordmark), for light backgrounds |
| `kombien-logo-dark.svg` | Combined lockup, for dark backgrounds |
| `kombien-logo-monochrome.svg` | Single flat-color version, one-ink use |
| `kombien-app-icon-svg.svg` | App icon, vector master |
| `kombien-app-icon-png.png` *(in `exports/png/`)* | App icon, raster master |
| `favicon16x16.svg`, `favicon32x32.svg` | Favicon, pre-sized SVG variants |
| `favicon512x512-png.png` *(in `exports/png/`)* | Favicon, raster master |
| `mascot-mango.svg` | Mascot — default, solid Mango fill |
| `mascot-charcoal.svg` | Mascot — Charcoal fill (higher-contrast context, e.g. on a light surface where Mango would be too close to the background) |
| `mascot-dust-grey.svg` | Mascot — Dust Grey fill (muted/inactive context) |

**"-light" / "-dark" convention:** the suffix names the **background it's designed to sit on** — `-light` = for light backgrounds (dark-colored mark), `-dark` = for dark backgrounds (light-colored mark). The mascot files use a **different convention** — the suffix names the fill color itself, not a background — since the mascot is a single silhouette recolored per context rather than a mark with distinct light/dark art.

Naming quirks worth knowing about so nobody "fixes" them by accident:

- The app icon repeats its format in the filename (`kombien-app-icon-svg.svg`, `kombien-app-icon-png.png`) rather than relying on the extension alone. Redundant, but harmless — keep it consistent if you add more app-icon variants.
- Favicon files skip the `kombien-` prefix that everything else uses. If you add more favicon sizes later, match the existing `favicon<size>.<ext>` pattern rather than introducing a third convention.
- Mascot files skip the `kombien-` prefix too, and use a color name instead of `light`/`dark`. If more mascot color variants or pose states are added later, match `mascot-<color>.svg` (or `mascot-<pose>.svg` for a distinct pose, if that becomes a thing) rather than retrofitting the light/dark convention onto it.

New assets don't need to match these exactly, but should follow the spirit of whichever convention actually fits: `kombien-<type>-<light|dark>.svg` for anything with a true light/dark pair, `<type>-<color>.svg` for a single silhouette recolored per context, a plain descriptive name otherwise.

## Adding or changing exports

1. Export into the matching folder — SVGs into [`exports/svg/`](exports/svg/), any PNGs into [`exports/png/`](exports/png/).
2. Update [usage-guidelines.md](usage-guidelines.md#source-references) if the Figma source, export date, or approval status changed.
3. Open a PR with the files and doc update together, using the design-PR checklist in the [PR template](../../.github/PULL_REQUEST_TEMPLATE.md) (clear-space/min-size review, contrast review, confirm no unlicensed assets).

## Still outstanding

[usage-guidelines.md](usage-guidelines.md) still needs its clear-space, minimum-size, background-usage, and incorrect-usage sections filled in against the real artwork above — that has to be written by looking at the actual shapes, not guessed at in advance.
