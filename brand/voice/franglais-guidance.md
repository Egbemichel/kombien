# Franglish Guidance

**Status: decided.** Franglish is part of Kombien's default voice — scoped to where it fits, not blanket-applied everywhere.

## What "Franglish" means here

The everyday mixing of French and English (and sometimes local languages) common in urban Cameroonian speech — e.g. "Kombien-là?", "Je paie combien?", "on est où", mixing numerals and currency casually across languages. It's not slang for novelty's sake; it's how the target audience actually talks about fares.

## Where it's the default

- **The project name and tagline** — "Kombien" and "Je paie combien?" (see [../strategy/naming.md](../strategy/naming.md)).
- **Cultural and community-facing copy** — empty states, contribution prompts, marketing copy, social presence, this brand documentation.
- **Anywhere the copy is explicitly voicing the negotiation moment itself** — quoting or echoing the roadside exchange (see [../strategy/cultural-context.md](../strategy/cultural-context.md)).

## Where it stays out (by default)

- **Core functional UI strings** — buttons, form labels, error messages, and any instruction the user needs to act on correctly. These default to clear French or English per the user's locale. Getting an error message wrong because it was optimized for flavor over clarity would work against the accessibility goal, not for the brand.
- **App-store metadata and formal legal copy** — plain language per market/locale conventions.

## Practical rule of thumb

If getting the phrasing "wrong" mainly costs some personality, Franglish is fair game. If getting it wrong costs the user comprehension of what to do next, default to plain, locale-appropriate French or English.

## For translators and contributors

When adding new copy, tag it mentally as "voice" (cultural/community-facing) or "functional" (instructional) and apply the rule above. If it's ambiguous which bucket a string falls into, default to the functional (plain-language) treatment.
