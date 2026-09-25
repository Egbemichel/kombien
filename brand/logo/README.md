# Kombien Logo System

**Status: direction approved, artwork not yet produced.** The creative direction below is decided. No actual logo file exists yet — that's real design execution work that still has to happen in Figma. This directory holds the *structure* the logo system will live in once that work is done.

## Approved direction

**A typographic identity built from the word "Kombien" itself and the negotiation moment — not a pictorial mark.**

Concretely:

- The wordmark ("Kombien," set in [Space Grotesk](../typography/README.md)) is the primary identity, not a symbol standing in for it.
- If a compact symbol is developed alongside the wordmark, it draws from **question-and-response** and **price notation** — e.g. a treatment of "?" or a number/price shape — rather than a pictorial icon.
- Explicitly rejected as direction: taxi silhouettes, map pins, steering wheels, standard road graphics, or any literal transportation iconography (see [../strategy/brand-strategy.md](../strategy/brand-strategy.md#what-the-brand-should-avoid)).
- The mark must work in one color and hold up at small sizes (favicon/app-icon scale) — a design constraint on whatever gets produced, not yet tested since nothing has been drawn.

This resolves the *direction* question so design work isn't starting from a blank brief. It does not resolve the actual construction, proportions, or final artwork — that's produced and reviewed in Figma per the workflow below.

## Directory structure

| Directory | Purpose |
|---|---|
| `source/` | Not files — just a pointer to the Figma file (see [usage-guidelines.md](usage-guidelines.md#source-references)) |
| `exports/svg/` | Every exported SVG — wordmark, symbol, lockup, monochrome, app icon, favicon, all types together |
| `exports/png/` | Raster fallbacks, where needed (see [Export checklist](#export-checklist)) |
| `exports/pdf/` | Print-ready exports — empty until a print use case actually exists |

There is a single canonical home per file: **`exports/<format>/`**, organized by format, not by logo type. The filename (see naming convention below) already encodes whether it's a wordmark, symbol, lockup, or monochrome mark — there's no separate `primary/`/`symbol/`/`monochrome/` folder to keep in sync with it, so there's only ever one copy of each asset.

Every directory above currently contains only a `.gitkeep` — no placeholder shapes, no draft exports standing in as if final.

## What to design

At minimum:

1. **Wordmark** — "Kombien" set in Space Grotesk Bold (see [typography tokens](../typography/README.md)). Two color treatments, transparent background:
   - For light backgrounds: Charcoal (`#202020`) type.
   - For dark backgrounds: Warm White (`#F4F1E8`) type.
2. **Symbol** *(optional, but needed if you want anything to work at favicon/app-icon size)* — the compact mark, per the [approved direction](#approved-direction): question/response or price-notation derived, not pictorial. Same two color treatments as the wordmark.
3. **Lockup** *(only if you built a symbol)* — symbol + wordmark combined. Same two color treatments.
4. **Monochrome** — a single flat-color version (pure black or pure white) for one-ink contexts. One file, no light/dark pair.
5. **App icon** — full-bleed square artwork built from the symbol if you have one, or a simplified monogram if you don't (the full multi-letter wordmark won't read at icon size). A Mango-fill background with a Charcoal mark is a reasonable starting point for shelf/home-screen recognition — your call in Figma.
6. **Favicon** — same logic as the app icon: needs to read at 16–32px, so it has to be the symbol/monogram, never the full wordmark.

**If you skipped the symbol:** you still need *something* compact for #5 and #6 — a simplified "K" or "?" treatment, even if it's not promoted as a general-purpose symbol elsewhere.

Before exporting, sanity-check each one against: legibility at small size, one-color performance, whether it works without the tagline, and that none of the "avoid" list snuck in (see [../strategy/brand-strategy.md](../strategy/brand-strategy.md#what-the-brand-should-avoid)).

## Export checklist

| # | File | Format(s) | Size/notes |
|---|---|---|---|
| 1 | `kombien-wordmark-light.svg` | SVG | Vector master, Charcoal on transparent |
| 2 | `kombien-wordmark-dark.svg` | SVG | Vector master, Warm White on transparent |
| 3 | `kombien-symbol-light.svg` | SVG | Vector master, Charcoal on transparent *(skip if no symbol)* |
| 4 | `kombien-symbol-dark.svg` | SVG | Vector master, Warm White on transparent *(skip if no symbol)* |
| 5 | `kombien-lockup-light.svg` | SVG | Vector master, Charcoal on transparent *(skip if no symbol)* |
| 6 | `kombien-lockup-dark.svg` | SVG | Vector master, Warm White on transparent *(skip if no symbol)* |
| 7 | `kombien-monochrome.svg` | SVG | Single flat color, no variants |
| 8 | `kombien-app-icon.svg` + `.png` | SVG + PNG | PNG master at 1024×1024 (covers iOS; downscale for Android/Play at 512×512 as needed) |
| 9 | `kombien-favicon.svg` + `.png` | SVG + PNG | PNG master at 512×512 — let build tooling generate the actual 16/32/48px favicon set from it |

**"-light" / "-dark" convention:** the suffix names the **background it's designed to sit on** — `-light` = for light backgrounds (dark-colored mark), `-dark` = for dark backgrounds (light-colored mark). This trips people up in both directions, so it's spelled out here rather than left implicit.

Everything ships as SVG (the vector master). Only add a PNG where a raster fallback is actually needed: app icon and favicon (both go through platform/browser pipelines that expect raster), plus anywhere else you hit a spot that can't render SVG (e.g. a GitHub social-preview image, an email signature). Don't bulk-export PNGs of every file "just in case" — export raster only when something concretely needs it. Skip PDF entirely for now; `exports/pdf/` stays empty until an actual print use case shows up.

## Where it goes and how it ships

1. Export the files above into the matching folder — SVGs into [`exports/svg/`](exports/svg/.gitkeep), any PNGs into [`exports/png/`](exports/png/.gitkeep). Nothing else needs to change in this repo's folder structure.
2. Fill in [usage-guidelines.md](usage-guidelines.md#source-references) with the real Figma file link, page name, export date, and your name/handle as designer.
3. Open a PR adding those files and that doc update together, using the design-PR checklist in the [PR template](../../.github/PULL_REQUEST_TEMPLATE.md) (clear-space/min-size review, contrast review, confirm no unlicensed assets).
4. Once merged, this README and [usage-guidelines.md](usage-guidelines.md) get a follow-up pass to fill in the now-real clear-space, minimum-size, and incorrect-usage guidance — that has to be written against the actual artwork, not guessed at ahead of time.
