# Privacy Policy

**Status: approved policy for how Kombien handles data, ahead of any application code existing.** This is written now so the product is built around these commitments from the start, rather than retrofitting privacy after the fact.

## What Kombien collects

Kombien's core function is collecting **reported fares**: a route (origin/destination) and a price, plus enough metadata to judge recency (a timestamp) and reliability (report volume).

- **No account or sign-in is required to contribute a fare report.**
- Fare reports are treated as **anonymous by default** — no name, phone number, or other personal identifier is attached to a report.
- A minimal technical identifier (e.g. a device- or session-scoped id) may be used strictly for abuse prevention (rate-limiting spam/fraudulent reports), never for building a profile of a person's travel history or identity. Each report also carries a **device hint**: a hash of coarse traits (screen size, pixel ratio, processor cores, time zone) that cannot identify a person, used only so that one person using several browsers on one phone counts once towards a route's fare range.
- **Places riders add themselves:** the name the rider gives and where it is (their phone's position at that moment if they choose "I'm here now", else a known place it is near). The place is public, so other riders can find it and see fares for it. An anonymous identifier is kept with each addition to limit abuse and is never shown. See [docs/setup/places-added-by-riders.md](docs/setup/places-added-by-riders.md).
- **Places found through Google:** when a rider picks a Google suggestion, Kombien stores Google's place ID (which Google allows) and the name the rider gave it — never Google's own name, address or coordinates. See [docs/setup/google-places.md](docs/setup/google-places.md).
- **Searches that find nothing** are counted so the place list can be completed: the typed words, the city and the language, added into one count per place name. No identifier of any kind is sent with them, and anything that looks like a phone number, email address or link is dropped before it is sent (and checked again by the database). The count lives in `search_misses`, which riders can neither read nor write directly (see `supabase/migrations/20261111000600_search_misses.sql`).

## What Kombien does not do

- Does not require real-name identity to use the core product.
- Does not sell or share user data with third parties. The one exception is by design and limited: when a place isn't in Kombien, the typed place name is sent to Google Places to get suggestions (Google also sees the request's IP address), and only when a Google key is configured. No Kombien identifier is sent.
- Does not attempt to re-identify anonymous fare reports.
- Does not use fare-report data for anything beyond showing aggregated, community fare information back to users.

## What's public

Aggregated fare data (ranges, recency, report volume per route) is the product — it's meant to be public and shared. Individual raw reports are not displayed with any identifying information attached.

## Data retention and deletion

- Fare reports are retained to keep route data useful over time (recency matters more than permanence — see [brand/strategy/brand-strategy.md](brand/strategy/brand-strategy.md)).
- If you believe a report of yours should be removed, contact a maintainer (see [GOVERNANCE.md](GOVERNANCE.md)) or open an issue using the [data quality report template](.github/ISSUE_TEMPLATE/data-quality-report.md) — that template already has a privacy-considerations field for exactly this.

## When application infrastructure exists

This document should be revisited and expanded to cover:

- Exact technical identifiers collected and their retention period.
- Any analytics or crash-reporting tooling introduced, and what it collects.
- Legal basis and regional compliance (e.g. GDPR-style requirements) once the app has real users and real infrastructure.
- A contact method dedicated to privacy requests, if volume warrants one beyond the maintainer contact above.

## Relationship to security reporting

This document covers how user data is *handled by design*. If you find a way user data could be exposed or compromised, that's a security issue — see [SECURITY.md](SECURITY.md) instead.
