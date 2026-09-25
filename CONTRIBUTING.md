# Contributing to Kombien

Thanks for your interest in Kombien. This is a community passion project — contributions of code, design, data, and documentation are all welcome. This guide explains how to work with the repository day to day.

## Ways to contribute

- **Code** — application features, fixes, tooling.
- **Design** — logo exploration, illustration, UI, brand applications (see [brand/README.md](brand/README.md)).
- **Data quality** — flagging fares that look wrong, stale, or misleading (use the [data quality report template](.github/ISSUE_TEMPLATE/data-quality-report.md)).
- **Documentation** — improving setup guides, fixing unclear docs, translating.

You don't need permission to open an issue or start a discussion. For larger changes, opening an issue first helps avoid wasted work.

## Branch strategy

| Prefix | Use |
|---|---|
| `main` | Stable, reviewed work only |
| `feature/<short-description>` | New features |
| `fix/<short-description>` | Bug fixes |
| `docs/<short-description>` | Documentation changes |
| `design/<short-description>` | Design and brand work |
| `hotfix/<short-description>` | Urgent fixes |

Delete your branch after it's merged when practical — keeps the branch list readable for everyone.

## Commit conventions

Use short, descriptive, prefixed commit messages:

```text
feat: add route fare report form
fix: correct fare range formatting
docs: update brand contribution guide
design: add approved Kombien wordmark
chore: validate brand token files
```

## Pull requests

Open PRs against `main` and fill out the [PR template](.github/PULL_REQUEST_TEMPLATE.md). In general, a good PR includes:

- A clear summary and motivation.
- The type of change (fix, feature, docs, design, chore).
- Screenshots or recordings for anything visual.
- Notes on what you tested.
- Accessibility considerations, where relevant.
- A brand-consistency check for anything user-facing.

**Design-related PRs** additionally need:

- A link to the Figma source file or frame.
- Exported assets (light/dark versions where relevant).
- Confirmation that clear-space and minimum-size were reviewed.
- A color-contrast check.
- Mobile and GitHub-preview examples if the asset appears in either context.
- Confirmation that no unlicensed fonts or assets were introduced.

## Issues

Use the template that matches what you're reporting:

- [Bug report](.github/ISSUE_TEMPLATE/bug_report.md)
- [Feature request](.github/ISSUE_TEMPLATE/feature_request.md)
- [Design proposal](.github/ISSUE_TEMPLATE/design_proposal.md)
- [Data quality report](.github/ISSUE_TEMPLATE/data-quality-report.md)
- [Brand feedback](.github/ISSUE_TEMPLATE/brand-feedback.md)

## Discussions

GitHub Discussions is the right place for open-ended ideas, design reviews that aren't tied to a specific PR yet, and general questions. Use [Issues](https://github.com/Egbemichel/kombien/issues) for concrete, actionable work.

## Adding or changing brand assets

Brand assets originate in Figma, not in the repository. See [brand/logo/README.md](brand/logo/README.md) for the current export workflow. Small corrections (typos, obvious fixes) can be reviewed by any maintainer. Changes to the name, logo direction, primary colors, or typography require sign-off from the project owner or designated brand maintainer — see [GOVERNANCE.md](GOVERNANCE.md).

## First-time contributor checklist

- [ ] Read this file and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
- [ ] Check open issues and discussions to avoid duplicate work.
- [ ] Fork or branch, following the naming convention above.
- [ ] Make your change on its own branch.
- [ ] Run `node scripts/validate-brand-assets.mjs` if you touched anything under `brand/`.
- [ ] Open a PR using the template.
- [ ] Be responsive to review feedback — most PRs need at least one round.

## Maintainer responsibilities

See [GOVERNANCE.md](GOVERNANCE.md) for how maintainers are chosen, how brand-change approval works, and how forks and derivative projects should identify themselves.
