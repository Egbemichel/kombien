# Governance

Kombien is currently maintained by its founding contributor as a sole maintainer/project owner (a BDFL-style model, common for early-stage open-source passion projects). This document explains how decisions get made now and how that structure grows.

## Roles

- **Project owner** — has final say on the project's direction, name, and brand identity. Currently the repository owner ([@Egbemichel](https://github.com/Egbemichel)).
- **Maintainers** — can review and merge pull requests, triage issues, and moderate discussions. Today, the project owner is the only maintainer. Additional maintainers will be added by the project owner's invitation as the project and its trusted contributor base grow, and will be listed here when that happens.
- **Contributors** — anyone who opens an issue, discussion, or pull request.

A [`CODEOWNERS`](.github/CODEOWNERS) file exists, currently routing everything to the project owner. Split it into per-directory ownership once specific areas of the codebase (e.g. mobile app, backend, brand assets) have distinct, trusted owners.

## Decision-making

- **Routine changes** (bug fixes, small features, documentation, minor design corrections) can be reviewed and merged by any maintainer.
- **Major changes** — to the project name, tagline, logo direction, primary color palette, typography system, or software license — require explicit sign-off from the project owner, regardless of who proposes them and regardless of how many maintainers exist. See [brand/README.md](brand/README.md#brand-change-policy).
- Disagreements that can't be resolved in a PR or issue thread should move to a Discussion for broader input before the project owner makes a final call.

## Moderation

Maintainers enforce the [Code of Conduct](CODE_OF_CONDUCT.md). In practice:

1. A first violation gets a direct, private warning explaining what needs to change.
2. Repeated or more serious violations result in content moderation (hiding comments, locking threads) and, if needed, blocking the person from the repository.
3. Severe violations (harassment, doxxing, etc.) can skip straight to a block.
4. Anyone blocked can appeal by contacting the project owner directly — moderation decisions aren't meant to be permanent by default, but repeat offenses after an appeal will not get another one.

## Forks and derivative projects

Kombien's code is MIT-licensed (see [LICENSE](LICENSE)). If you fork or build on this project:

- You don't need permission to fork, modify, or redistribute the code under the MIT license.
- You **do** need to avoid implying your fork is the official Kombien project, and you should not reuse the Kombien name, logo, or visual identity in a way that suggests endorsement — see [BRAND.md](BRAND.md).
- If you'd like your fork or derivative listed here, open a discussion.

## Changing this document

Changes to governance itself should go through a pull request so the change is visible and discussable, even though the project owner has final approval.
