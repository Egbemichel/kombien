# Contrast Checks

**Status: approved base-palette check.** WCAG 2.x relative-luminance contrast ratios, calculated against the approved hex values in [palette.md](palette.md). This covers the palette itself, not real UI compositions (text over images, translucent surfaces) — check those individually once actual screens exist.

## Method

Standard WCAG contrast ratio: `(L1 + 0.05) / (L2 + 0.05)`, where `L1` is the relative luminance of the lighter color and `L2` of the darker one. Thresholds referenced: **AA normal text 4.5:1, AAA normal text 7:1, AA large text/UI components 3:1.**

## Results

| Pair | Ratio | AA normal (4.5) | AAA normal (7) | Large text/UI (3) |
|---|---|---|---|---|
| Charcoal text on Warm White | 14.43:1 | ✅ | ✅ | ✅ |
| Charcoal text on Mango | 7.88:1 | ✅ | ✅ | ✅ |
| Mango text/icons on Warm White | 1.83:1 | ❌ | ❌ | ❌ |
| Dust Grey text on Warm White | 2.29:1 | ❌ | ❌ | ❌ |
| Dust Grey text on Charcoal | 6.31:1 | ✅ | ❌ | ✅ |
| Muted Neutral text on Warm White | 4.75:1 | ✅ (narrow margin) | ❌ | ✅ |
| Muted Neutral text on Charcoal | 3.04:1 | ❌ | ❌ | ✅ |
| Success (`#0E6B34`) text on Warm White | 5.86:1 | ✅ | ❌ | ✅ |
| Error (`#C81E1E`) text on Warm White | 5.08:1 | ✅ | ❌ | ✅ |
| Warning (`#D97706`) text/icons on Warm White | 2.82:1 | ❌ | ❌ | ❌ |
| Charcoal text on Warning fill | 5.12:1 | ✅ | ❌ | ✅ |

## What this means in practice

- **Charcoal on Warm White** and **Charcoal on Mango** are strong pairings — safe for body text and text on accent surfaces.
- **Mango is not safe as text or icon color on Warm White.** Use it for large filled surfaces (buttons, badges) with Charcoal text on top.
- **Dust Grey fails on Warm White** — use Muted Neutral for secondary text on light backgrounds instead; Dust Grey is fine as secondary text on Charcoal.
- **Success and Error both work directly as text on Warm White** at normal sizes (AA, not AAA).
- **Warning does not work as foreground text/icon on Warm White** — use it as a filled badge with Charcoal text on top instead (5.12:1, passes AA), the same pattern as Mango.

## Not yet checked

- Deep Neutral (`#121212`) as a background paired with each text color — likely close to Charcoal's numbers but not calculated directly.
- `background-secondary` (`#ECE7D8` / `#262626`) — these are layering tints, not intended as text-contrast backgrounds, so no ratio is tracked for them; if text ever sits directly on them, check before shipping.
- Real components (buttons, form fields, focus rings) once they exist.
- Any translucent/opacity-adjusted use of these colors.

## Do not claim

Do not describe the Kombien brand as "WCAG AA/AAA compliant" based on this document alone — it covers the base palette pairings above, not the product.
