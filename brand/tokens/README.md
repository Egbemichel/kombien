# Brand Tokens

Machine-readable, framework-agnostic tokens for color and typography. These are what code should import — the docs in [`../colors/`](../colors/README.md) and [`../typography/`](../typography/README.md) explain the *why*; these files are the *what*.

**Status: approved.** Values match the current, decided palette and typefaces.

## Files

| File | Use |
|---|---|
| `colors.json` | Base + semantic color values, framework-agnostic |
| `colors.css` | CSS custom properties, with a `prefers-color-scheme: dark` override |
| `typography.json` | Font family, source, license, and role mapping |
| `typography.css` | CSS custom properties for font stacks |

## Consuming these tokens

**Web (CSS):**

```css
@import url("path/to/brand/tokens/colors.css");
@import url("path/to/brand/tokens/typography.css");

.fare-value {
  color: var(--color-text-primary);
  font-family: var(--font-mono);
}
```

**Any platform (JSON):**

```js
import colors from "./brand/tokens/colors.json";
import typography from "./brand/tokens/typography.json";

const accent = colors.semantic.light.accentPrimary; // "#F4A340"
```

Mobile projects (iOS/Android/Flutter/React Native) should read the JSON files and map them into their own design-token or theming system rather than depending on the CSS files directly.

## Keeping these in sync

`colors.json`/`colors.css` and `typography.json`/`typography.css` are maintained by hand in parallel — there's no build step generating one from the other yet. If you change a value, update both the JSON and CSS versions in the same PR. The validation script (`scripts/validate-brand-assets.mjs`) checks that these files exist and parse correctly, but does not currently check that JSON and CSS values match — that's a manual review item until tooling exists for it.

## Related

- [../colors/README.md](../colors/README.md) — palette rationale and roles
- [../colors/contrast-checks.md](../colors/contrast-checks.md) — accessibility status
- [../typography/README.md](../typography/README.md) — typeface roles and hierarchy
- [../typography/font-licensing.md](../typography/font-licensing.md) — licensing and sources
