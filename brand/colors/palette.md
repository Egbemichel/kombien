# Color Palette

**Status: approved.** These are the values in use — not a Figma-refinement placeholder. Machine-readable versions live in [`../tokens/colors.json`](../tokens/colors.json) and [`../tokens/colors.css`](../tokens/colors.css).

## Base colors

| Name | Hex | Notes |
|---|---|---|
| Charcoal | `#202020` | Primary dark neutral |
| Dust Grey | `#A7A18E` | Warm mid neutral |
| Mango | `#F4A340` | The primary accent color |
| Warm White | `#F4F1E8` | Primary light neutral |
| Deep Neutral | `#121212` | Darker alternative to Charcoal (dark-mode surfaces) |
| Muted Neutral | `#6F6A60` | Darker alternative to Dust Grey (dark-mode secondary text/border) |

## Extended colors (status)

| Name | Hex | Notes |
|---|---|---|
| Success | `#0E6B34` | Confirmations, positive states |
| Warning | `#D97706` | Use as a filled badge (Charcoal text on top) — see [contrast-checks.md](contrast-checks.md) |
| Error | `#C81E1E` | Errors, destructive actions |

These are deliberately distinct from Mango — Mango is the brand accent (CTAs, highlights, data emphasis), not a stand-in for "warning."

## Semantic roles

| Role | Light mode | Dark mode | Notes |
|---|---|---|---|
| `background-primary` | Warm White | Charcoal | |
| `background-secondary` | `#ECE7D8` | `#262626` | A step below the primary background, for layering (cards on a page, etc.) |
| `surface` | Warm White | Deep Neutral | |
| `text-primary` | Charcoal | Warm White | |
| `text-secondary` | Muted Neutral | Dust Grey | Dust Grey fails contrast on Warm White — see [contrast-checks.md](contrast-checks.md) — so light mode uses Muted Neutral instead |
| `accent-primary` | Mango | Mango | Reserve for CTAs, highlights, and data emphasis — not body text |
| `accent-on-accent` | Charcoal | Charcoal | Text/icons placed on top of a Mango surface |
| `border` | Dust Grey | Muted Neutral | Solid, not opacity-based — kept simple |
| `focus` | Mango, 2px solid, 2px offset | Mango, 2px solid, 2px offset | Applies to any focusable interactive element |
| `success` | `#0E6B34` | `#0E6B34` | |
| `warning` | `#D97706` | `#D97706` | Filled-badge usage — see note above |
| `error` | `#C81E1E` | `#C81E1E` | |

## Why Mango doesn't do everything

Mango is a strong, warm accent — good for calls to action, highlights, and emphasizing a data point (e.g. a fare number). It performs poorly as body text or foreground content on light backgrounds (see [contrast-checks.md](contrast-checks.md)), so it's not used for body copy, secondary text, or status colors — those have their own values now (see Extended colors, above).
