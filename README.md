# Kombien

> **Je paie combien?**

Kombien is an open-source, community-powered taxi fare intelligence project. It turns the everyday experience of Cameroonian roadside taxi fare negotiation — a shouted destination, a proposed price, a counteroffer — into shared, public, searchable knowledge.

> **Status: early setup.** The name, tagline, colors, typography, and the first logo exports are decided and in place (see [BRAND.md](BRAND.md) and [brand/logo/README.md](brand/logo/README.md)). A Flutter app scaffold exists at [`app/`](app/README.md) with placeholder screens, wired up to the brand theme — no backend yet, and no real screens yet either (those come in one at a time to replace the placeholders).

## What Kombien is

Passengers standing by the road negotiating a taxi fare are often working blind — they don't know what other people recently paid for the same route. Kombien lets riders:

- Look up community-reported fares for a route.
- See a range, not a single "correct" price — fares vary by time, negotiation, and context.
- Contribute the fare they paid after a trip, so the next passenger has better information.

Kombien does **not** claim to publish one universally correct fare. It reports what the community has observed, with recency and context, and it says so plainly when data is thin.

## Why this exists

This is a passion project, not a startup pitch. It's rooted in a specific, everyday Cameroonian interaction:

> "Poste Centrale, 250." "Mvan, 500." "Bonamoussadi, 500."

Kombien exists so a passenger doesn't have to enter that negotiation completely blind. See [brand/strategy/cultural-context.md](brand/strategy/cultural-context.md) for the full cultural framing.

## Repository structure

- [`app/`](app/README.md) — the Flutter mobile app (frontend only for now).
- [`brand/`](brand/README.md) — brand strategy, voice, logo system, color and typography tokens, and product/social assets.
- [`docs/`](docs/setup/github-setup.md) — setup guides, architecture notes, and decision records.
- [`scripts/`](scripts/validate-brand-assets.mjs) — tooling that validates brand asset structure.
- [`.github/`](.github/PULL_REQUEST_TEMPLATE.md) — issue templates, PR template, and CI workflows.

A monorepo — application code lives alongside the brand system. See [docs/setup/local-development.md](docs/setup/local-development.md) for how to run everything locally.

## Contributing

Contributions are welcome — code, design, data quality reports, and documentation alike. Start with [CONTRIBUTING.md](CONTRIBUTING.md).

## Brand, privacy, and license

- This project's **software license** ([LICENSE](LICENSE): MIT) and its **brand/trademark policy** ([BRAND.md](BRAND.md)) are separate — using the code under MIT doesn't by itself grant permission to use the Kombien name or logo.
- How user-contributed fare data is handled is covered in [PRIVACY.md](PRIVACY.md).

## Project status

- [x] Software license selected (MIT)
- [x] Brand strategy, voice, colors, and typography approved
- [x] First logo exports produced and approved (usage guidelines still to be written — see [brand/logo/usage-guidelines.md](brand/logo/usage-guidelines.md))
- [x] Repository protections configured (branch protection, tag protection, secret scanning — see [docs/setup/github-setup.md](docs/setup/github-setup.md))
- [x] Application scaffolding added (Flutter, placeholder screens — see [app/README.md](app/README.md))
- [ ] Real screens in place of placeholders
- [ ] Backend/API
- [ ] Public launch

This list will be kept current as the project moves past initial setup.
