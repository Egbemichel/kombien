# Kombien Brand System

This directory is the working home for Kombien's brand identity: strategy, voice, logo, color, typography, and the tokens that let any codebase (web, mobile, docs) consume the brand consistently.

**Status: strategy, voice, color, and typography are approved and in use.** The logo's creative *direction* is approved; the actual artwork hasn't been produced yet — see [logo/README.md](logo/README.md). Icon and illustration systems haven't started.

## Structure

| Directory | Contents |
|---|---|
| [`strategy/`](strategy/brand-strategy.md) | Purpose, audience, positioning, cultural context, naming |
| [`voice/`](voice/voice-and-tone.md) | Voice and tone, microcopy patterns, Franglish guidance, do/don't |
| [`logo/`](logo/README.md) | Logo direction and export directories (empty until Figma artwork lands) |
| [`colors/`](colors/README.md) | Color palette documentation and contrast checks |
| [`typography/`](typography/README.md) | Typeface roles, hierarchy, and licensing |
| [`icons/`](icons/README.md) | Icon system (not yet started) |
| [`illustration/`](illustration/README.md) | Illustration system (not yet started) |
| [`social/`](social/README.md) | Social preview images, templates, launch assets |
| [`product/`](product/app-icon/.gitkeep) | App icon, favicon, empty states, screenshots |
| [`tokens/`](tokens/README.md) | Machine-readable color and typography tokens (JSON + CSS) |

## Brand change policy

A brand change — to the name, tagline, logo direction, primary colors, or typography — should be proposed through a [design proposal issue](../.github/ISSUE_TEMPLATE/design_proposal.md) or a Discussion, and should explain:

- What is changing and why.
- What problem it solves.
- What assets are affected.
- Whether the change is breaking for existing integrations (app icons, published docs, etc.).
- Whether documentation needs to change alongside it.
- Whether it requires maintainer approval.

**Small corrections** (a typo in a doc, an obviously wrong contrast value) can be reviewed by any maintainer. **Major changes** to the name, logo, primary colors, or typography require explicit approval from the project owner or designated brand maintainer — see [../GOVERNANCE.md](../GOVERNANCE.md).

## Validating brand assets

Run the validation script before opening a PR that touches this directory:

```bash
node scripts/validate-brand-assets.mjs
```

It checks that expected token files, READMEs, and guideline files exist and are well-formed. It does **not** validate visual quality — that's a human review step.

## What's still outstanding

- The actual logo artwork (SVG/PNG/PDF exports) — the direction is decided, production happens in Figma. See [logo/README.md](logo/README.md).
- An icon or illustration system — neither has started.

See [../BRAND.md](../BRAND.md) for how this relates to the software license.
