# Typography System

**Status: approved.**

## Typefaces

| Role | Typeface |
|---|---|
| Display and interface | [Space Grotesk](https://fonts.google.com/specimen/Space+Grotesk) |
| Data, prices, metadata, technical details | [JetBrains Mono](https://www.jetbrains.com/lp/mono/) |

Machine-readable tokens live in [`../tokens/typography.json`](../tokens/typography.json) and [`../tokens/typography.css`](../tokens/typography.css).

## Font roles

- **Space Grotesk** — headings, UI labels, body copy, navigation, marketing surfaces. It's the "voice" typeface: direct, a little technical-feeling without being cold.
- **JetBrains Mono** — anything numeric or data-like: fare values, timestamps, route codes, currency, and all code/technical documentation. Using a monospace face for prices reinforces that these are *data points*, not polished marketing numbers — consistent with the brand's "report what's observed" stance (see [../strategy/brand-strategy.md](../strategy/brand-strategy.md)).

## Weight usage

| Weight | Typeface | Use |
|---|---|---|
| Regular (400) | Space Grotesk | Body text, captions, default UI labels |
| Medium (500) | Space Grotesk | Emphasized labels, navigation, secondary headings |
| Bold (700) | Space Grotesk | H1–H2 headings, primary emphasis |
| Regular (400) | JetBrains Mono | Default data display (fares, timestamps, route codes) |
| Medium (500) | JetBrains Mono | An emphasized data value that needs to stand out (e.g. the fare figure in a result card) |

## Hierarchy

| Level | Typeface | Weight |
|---|---|---|
| H1 | Space Grotesk | Bold |
| H2 | Space Grotesk | Bold |
| H3 | Space Grotesk | Medium |
| Body | Space Grotesk | Regular |
| Caption / label | Space Grotesk | Medium (for legibility at small size) |
| Data values (fares, prices) | JetBrains Mono | Regular, Medium for emphasis |
| Route labels | JetBrains Mono | Regular — routes read as data (an origin–destination pair), consistent with fares and timestamps |
| Timestamps | JetBrains Mono | Regular |
| Code / technical docs | JetBrains Mono | Regular |

Exact point sizes and line-heights are implementation details for whatever design system consumes these tokens (web, mobile) — this table fixes typeface and weight, not pixel values.

## Fallback stack

```css
:root {
  --font-display: "Space Grotesk", Inter, ui-sans-serif, system-ui, sans-serif;
  --font-mono: "JetBrains Mono", ui-monospace, SFMono-Regular, monospace;
}
```

Inter is used as an intermediate fallback because it's widely available and metrically compatible-ish with Space Grotesk's grotesque sans character, before falling back to system fonts.

## Licensing

Both typefaces are open source (SIL Open Font License). See [font-licensing.md](font-licensing.md) for links and details — **font files are not redistributed in this repository**; they're referenced by official source.

## Accessibility considerations

- Both typefaces have reasonably open counters and x-heights, which helps legibility at small sizes.
- JetBrains Mono was designed for code legibility (distinguishing `0`/`O`, `1`/`l`/`I`), which is a genuine asset for displaying currency and numeric fare data where misreading a digit matters.
- Specific minimum sizes and line-heights are left to the design system implementation, not fixed here.
