# Color System

**Status: approved.** See [palette.md](palette.md) for the full palette and role definitions, and [contrast-checks.md](contrast-checks.md) for accessibility status.

## Where the machine-readable tokens live

The authoritative, consumable token files are in [`../tokens/`](../tokens/README.md):

- `../tokens/colors.json`
- `../tokens/colors.css`

This directory (`brand/colors/`) is documentation and rationale; `../tokens/` is what code should actually import.

## Quick reference

| Token | Hex | Role |
|---|---|---|
| Charcoal | `#202020` | Primary text / dark backgrounds |
| Dust Grey | `#A7A18E` | Secondary text/border on dark backgrounds |
| Mango | `#F4A340` | Accent — CTAs, highlights, data emphasis |
| Warm White | `#F4F1E8` | Primary light background |
| Deep Neutral | `#121212` | Dark-mode surface |
| Muted Neutral | `#6F6A60` | Secondary text on light backgrounds |
| Success | `#0E6B34` | Confirmations |
| Warning | `#D97706` | Filled badges only — see [contrast-checks.md](contrast-checks.md) |
| Error | `#C81E1E` | Errors, destructive actions |

Mango is not meant to carry every function — see [palette.md](palette.md#why-mango-doesnt-do-everything).

## Accessibility

Base-palette contrast has been checked against WCAG thresholds — see [contrast-checks.md](contrast-checks.md) for the full table and what it does and doesn't cover. Real UI compositions should still be checked individually once they exist.
