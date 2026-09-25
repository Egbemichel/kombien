# Kombien Logo System

**Status: first approved exports in place.** The wordmark, logomark, combined logo, monochrome version, app icon, and favicon have been designed in Figma and exported — see [Current exports](#current-exports) below and [usage-guidelines.md](usage-guidelines.md#source-references) for the Figma source.

## Approved direction

**A typographic identity built from the word "Kombien" itself and the negotiation moment — not a pictorial mark.**

Concretely:

- The wordmark ("Kombien," set in [Space Grotesk](../typography/README.md)) is the primary identity, not a symbol standing in for it.
- The logomark (the compact mark) draws from **question-and-response** and **price notation** — e.g. a treatment of "?" or a number/price shape — rather than a pictorial icon.
- Explicitly rejected as direction: taxi silhouettes, map pins, steering wheels, standard road graphics, or any literal transportation iconography (see [../strategy/brand-strategy.md](../strategy/brand-strategy.md#what-the-brand-should-avoid)).
- The mark works in one color and holds up at small sizes (favicon/app-icon scale).

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

**"-light" / "-dark" convention:** the suffix names the **background it's designed to sit on** — `-light` = for light backgrounds (dark-colored mark), `-dark` = for dark backgrounds (light-colored mark).

Two naming quirks worth knowing about so nobody "fixes" them by accident:

- The app icon repeats its format in the filename (`kombien-app-icon-svg.svg`, `kombien-app-icon-png.png`) rather than relying on the extension alone. Redundant, but harmless — keep it consistent if you add more app-icon variants.
- Favicon files skip the `kombien-` prefix that everything else uses. If you add more favicon sizes later, match the existing `favicon<size>.<ext>` pattern rather than introducing a third convention.

New assets don't need to match these exactly, but should follow the same spirit: `kombien-<type>-<light|dark>.svg` for anything with a light/dark pair, a plain descriptive name otherwise.

## Adding or changing exports

1. Export into the matching folder — SVGs into [`exports/svg/`](exports/svg/), any PNGs into [`exports/png/`](exports/png/).
2. Update [usage-guidelines.md](usage-guidelines.md#source-references) if the Figma source, export date, or approval status changed.
3. Open a PR with the files and doc update together, using the design-PR checklist in the [PR template](../../.github/PULL_REQUEST_TEMPLATE.md) (clear-space/min-size review, contrast review, confirm no unlicensed assets).

## Still outstanding

[usage-guidelines.md](usage-guidelines.md) still needs its clear-space, minimum-size, background-usage, and incorrect-usage sections filled in against the real artwork above — that has to be written by looking at the actual shapes, not guessed at in advance.
