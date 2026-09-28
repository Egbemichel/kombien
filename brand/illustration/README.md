# Illustration System

**Status: first mascot exports in place.** No broader illustration system beyond it.

## The mascot

Derived from the small orange (Mango) humanoid figure already built into the wordmark's letterforms (see [../logo/README.md](../logo/README.md#approved-direction)) — not a new, separately invented character. Two of these figures appear in the wordmark itself, plausibly representing the two sides of every fare negotiation (rider and driver); one of them, refined, becomes the standalone mascot used throughout the app.

**Still unnamed.** Naming it is a small, low-stakes creative decision worth keeping for the project owner rather than settling here.

### Current exports

In [`../logo/exports/svg/`](../logo/exports/svg/) — the mascot ships from the same export pipeline as the rest of the logo system, since it's sourced from the same Figma file:

| File | What it is |
|---|---|
| `mascot-mango.svg` | Default — solid Mango fill |
| `mascot-charcoal.svg` | Solid Charcoal fill, for contexts where Mango wouldn't have enough contrast |
| `mascot-dust-grey.svg` | Solid Dust Grey fill, for a muted/inactive context |

Three color variants exist; no pose/state variants yet (idle, thinking, landed, celebrating, concerned — see [Motion states](#motion-states) below) — those are expected to be built as code-driven animations of a single silhouette, not as separate exported artwork per pose. If that assumption turns out wrong once real animation work starts, this doc and the export set both need to change together.

### Design rules

- **Faceless silhouette.** Solid fill in a single brand color per the variants above, no eyes, no mouth, ever. Nothing else in the identity has a "face" register — adding one to the mascot alone would read as a second, bolted-on art style rather than part of the same system.
- **Expression comes from pose and motion only**, driven by the spring presets already in [`../tokens/motion.json`](../tokens/motion.json) / `KombienSprings` — not from added features. See [../motion/README.md](../motion/README.md) for the underlying motion principles this depends on.
- **The logomark (the hand gesture) and the mascot (the figure) are separate things.** The gesture is the static identity mark — app icon, favicon, wordmark companion. The mascot is the animated in-product companion. They shouldn't be merged into one element.

### Motion states

| State | Behavior | Spring |
|---|---|---|
| Idle | Slow, barely-perceptible breathing scale (1.0 → 1.02 → 1.0, ~3s cycle) | `gentle` |
| Thinking | Gentle lean/wobble, only while a real request is in flight | `gentle` |
| Landed | One squash-and-stretch bounce when a route resolves | `snappy` |
| Celebration | A bigger bounce, optionally a small raised-arm pose (a quiet callback to the logomark's own raised-hand gesture) | `snappy` |
| Concerned | A tilt/slump — no exaggerated features needed | `standard` |

Any state not listed here defaults to no motion at all — the mascot doesn't animate just to fill time. See [../motion/README.md](../motion/README.md#where-not-to-use-it) for the general restraint rule this follows.

### Where it appears (and doesn't)

Appears: splash, onboarding, search-in-progress, the destination end of the Fare Results map once the route line finishes drawing, the report-success/celebration moment, empty states (History with no searches yet).

Deliberately absent: Settings/About, and anywhere inside a data-dense list or form (Fare Results' report list, the Report Fare form fields) — the mascot marks emotional/branding moments, not working screens.

## Beyond the mascot

No other illustration exists, and none should be added speculatively. If a genuine need comes up (a dedicated empty-state graphic, a launch asset), propose it via a [design proposal issue](../../.github/ISSUE_TEMPLATE/design_proposal.md) — it should draw from the same territory as the logo and mascot (the negotiation, language, the two-figure motif) rather than introducing a new visual language, and should avoid generic African visual clichés and literal taxi/road imagery either way (see [../strategy/brand-strategy.md](../strategy/brand-strategy.md#what-the-brand-should-avoid)).
