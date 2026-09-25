# Cultural Context

**Status: foundational reference.** This document explains the real-world interaction Kombien is modeled on, so design and copy decisions can be checked against it rather than against a generic "mobility app" template.

## The interaction

In Cameroon, taking a shared or private taxi typically starts with a short, public negotiation between passenger and driver:

- The passenger stands by the roadside and calls out a destination and a proposed fare, or waits for the driver to name one.
- "Poste Centrale, 250." "Mvan, 500." "Bonamoussadi, 500."
- The driver accepts, rejects, or counters. The passenger may counter back, walk away, or wait for another taxi.
- This can take seconds, or the passenger may stand there for a long time if fares being called out don't match what they're willing to pay, or no taxi is going their way.

This is a normal, everyday, often quick transaction — not a hostile one — but it does put the burden of price knowledge on the passenger, especially newcomers to a city, tourists, or people traveling an unfamiliar route.

## Why this matters for the product

Passengers currently rely on word of mouth, personal experience, or guesswork for what a fare "should" be. Kombien's core value is replacing guesswork with community-reported reference points — without pretending those reference points are fixed prices.

## Why this matters for the brand

- The negotiation itself — question and response, destination and price — is a richer source of visual and verbal identity than literal taxi imagery (a car, a steering wheel, a road). See [../logo/README.md](../logo/README.md) for how this translates to logo exploration territory.
- Humor and tone should come from the familiarity of the exchange, not from mocking either side of it.
- Franglish (mixing French and English, as is common in everyday Cameroonian speech) is a legitimate voice register here, not a novelty — see [../voice/franglais-guidance.md](../voice/franglais-guidance.md).

## Things to avoid

- Treating this as a generic "African mobility" story — it's specific to a lived, local interaction, not a continent-wide stereotype.
- Portraying drivers as adversaries to be "beaten" through better data — the goal is better-informed negotiation, not one-sided leverage.
- Using the negotiation as comic relief at either party's expense.

## Franglish in the default experience

Decided: Franglish appears in the default voice for cultural and community-facing copy (tagline, marketing, empty states, community prompts) — see [../voice/franglais-guidance.md](../voice/franglais-guidance.md) for exactly where. Core functional strings (buttons, errors, critical instructions) stay in clear French or English per the user's locale, so accessibility isn't traded away for flavor.
