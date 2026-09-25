# GitHub Setup

A practical guide to how this repository is organized and how to work with it — not a bureaucratic checklist, just what a contributor or maintainer actually needs to know.

## 1. Repository naming

Working repository name: **`kombien`** (matches the current `origin` remote, `github.com/Egbemichel/kombien`). The project name is final, reviewed with legal counsel — see [`../../brand/strategy/naming.md`](../../brand/strategy/naming.md). If the name ever changes, the repository can be renamed later; GitHub preserves redirects from the old name automatically.

## 2. Repository description

> Open-source community-powered taxi fare intelligence for Cameroon and beyond.

Update this in the repo's GitHub settings (About panel) and keep it in sync with [`../../brand/strategy/positioning.md`](../../brand/strategy/positioning.md) if it changes.

## 3. Suggested topics

Review before adding — only add topics that accurately describe the actual repository at its current stage:

```text
open-source
cameroon
mobility
transportation
taxi
fare-intelligence
community-data
civic-tech
franglish
flutter
mobile-app
```

Some of these (e.g. `flutter`, `mobile-app`) assume a tech stack that hasn't been chosen yet — add them once true, not in anticipation.

## 4. Branch strategy

See [`../../CONTRIBUTING.md`](../../CONTRIBUTING.md#branch-strategy) for the full table. Summary: `main` is stable; `feature/`, `fix/`, `docs/`, `design/`, `hotfix/` prefixes for everything else. Delete branches after merge when practical.

## 5. Commit conventions

Short, prefixed commits — `feat:`, `fix:`, `docs:`, `design:`, `chore:`. See [`../../CONTRIBUTING.md`](../../CONTRIBUTING.md#commit-conventions) for examples. No automatic co-author attribution is added to commit messages by convention here.

## 6. Pull request rules

- PRs target `main`.
- Use the [PR template](../../.github/PULL_REQUEST_TEMPLATE.md) — it covers summary, motivation, type of change, testing, accessibility, brand consistency, and a design-specific checklist for visual changes.
- At least one review before merge (see branch protection below).

## 7. Issue templates

Five templates exist under [`.github/ISSUE_TEMPLATE/`](../../.github/ISSUE_TEMPLATE/): bug report, feature request, design proposal, data quality report, and brand feedback. Pick the one that matches what you're reporting; if none fit, open a blank issue and say so.

## 8. Discussions guidance

Enable GitHub Discussions once there's enough contributor activity to justify it. Use Discussions for open-ended ideas and design reviews that aren't tied to a specific piece of work yet (templates in [`.github/DISCUSSION_TEMPLATE/`](../../.github/DISCUSSION_TEMPLATE/)); use Issues for concrete, actionable items.

## 9. CODEOWNERS guidance

Not yet needed — there's only one contributor area (this initial setup). Add a `CODEOWNERS` file once distinct areas exist (e.g. `/brand/` owned by a design maintainer, `/mobile/` by a mobile lead) so reviews route automatically. Until then, all PRs should go to the project owner or listed maintainers in [`../../GOVERNANCE.md`](../../GOVERNANCE.md).

## 10. Security reporting

See [`../../SECURITY.md`](../../SECURITY.md). Short version: use GitHub's private vulnerability reporting, don't open a public issue for a live vulnerability.

## 11. License and brand policy distinction

The software license ([`../../LICENSE`](../../LICENSE): MIT) and the brand/trademark policy ([`../../BRAND.md`](../../BRAND.md)) are separate documents governing separate things. Don't conflate "the code is open source" with "you can use the Kombien name and logo freely" — see `BRAND.md` for why.

## 12. Release and tagging guidance

No releases exist yet. Once the project ships something installable or versioned:

- Use [Semantic Versioning](https://semver.org/) (`vMAJOR.MINOR.PATCH`) for tags.
- Tag from `main` only, after a merge, not from a feature branch.
- Write release notes summarizing user-facing changes; link back to merged PRs.

## 13. GitHub Actions guidance

One workflow exists today: [`.github/workflows/validate-brand-assets.yml`](../../.github/workflows/validate-brand-assets.yml), which runs `scripts/validate-brand-assets.mjs` on PRs and pushes to `main` that touch brand files, docs, or the script itself. It checks file structure and machine-readable token validity — **not** visual quality. Add further workflows (lint, test, build) once application code exists, and keep each workflow scoped to what it actually changed-path-triggers on, to avoid unnecessary CI runs.

## 14. Figma asset contribution workflow

1. Work happens in Figma first, in a file with the page structure documented in [`../../brand/logo/README.md`](../../brand/logo/README.md).
2. Explore at least three logo directions (typographic price negotiation, conversational/question-based symbol, shared community observations) before converging — don't start with a taxi.
3. Get approval on wordmark spelling, symbol construction, clear space, minimum size, light/dark/monochrome versions, and color usage before exporting.
4. Export only approved assets, using the naming convention in [`../../brand/logo/README.md`](../../brand/logo/README.md#export-naming-convention).
5. Add source references (Figma link, page, export date, contributor, approval status) to [`../../brand/logo/usage-guidelines.md`](../../brand/logo/usage-guidelines.md).
6. Open a PR that adds the exported files to the matching `brand/logo/exports/<format>/` directory and updates the usage guidelines — use the design-PR checklist in the [PR template](../../.github/PULL_REQUEST_TEMPLATE.md).

## 15. How to add or update brand assets

- Non-logo assets (colors, typography, tokens): edit the relevant file under [`brand/`](../../brand/README.md) directly, run `node scripts/validate-brand-assets.mjs`, and open a PR.
- Logo/visual assets: follow the Figma workflow above — don't hand-author SVGs directly into this repo without a Figma source to point back to.
- Always check the [brand change policy](../../brand/README.md#brand-change-policy) for whether your change is "small" (any maintainer can review) or "major" (needs project-owner sign-off).

## 16. How to handle brand changes

Open a [design proposal issue](../../.github/ISSUE_TEMPLATE/design_proposal.md) or start a Discussion describing what's changing, why, what's affected, and whether it's breaking. See [`../../brand/README.md#brand-change-policy`](../../brand/README.md#brand-change-policy) and [`../../GOVERNANCE.md`](../../GOVERNANCE.md) for the approval path.

## 17. Maintainer responsibilities

Covered in [`../../GOVERNANCE.md`](../../GOVERNANCE.md) — review and merge routine PRs, triage issues, moderate discussions, and escalate major brand/name/license decisions to the project owner rather than deciding unilaterally.

## 18. Fork and derivative-project guidance

Forking is fine once a software license is published (see [`../../LICENSE`](../../LICENSE)). Forks and derivative projects should not present themselves as the official Kombien project or reuse its name/logo in a way implying endorsement — see [`../../BRAND.md`](../../BRAND.md) and [`../../GOVERNANCE.md`](../../GOVERNANCE.md#forks-and-derivative-projects).

## 19. Community conduct

Everyone participating in issues, PRs, discussions, or any other project space is expected to follow [`../../CODE_OF_CONDUCT.md`](../../CODE_OF_CONDUCT.md).

## 20. First-time contributor checklist

See [`../../CONTRIBUTING.md#first-time-contributor-checklist`](../../CONTRIBUTING.md#first-time-contributor-checklist) — read the contributing guide and code of conduct, check for duplicate work, branch correctly, run validation if you touched `brand/`, and open a PR with the template filled out.

---

## 21. Repository protections (configured)

So an open-source repo with outside contributors can't lose work to a bad push, a bad merge, or a compromised CI run. All of this is live on `main`:

**Branch protection (`main`):**
- No direct pushes — every change goes through a PR.
- Required status check: the `validate` (brand-assets) job must pass, and the branch must be up to date with `main`.
- Force-pushes blocked, branch deletion blocked.
- Conversation resolution required before merge.
- Applies to admins too (`enforce_admins`), not just outside contributors.
- Required approving reviews: **0** for now, since there's a single maintainer and GitHub won't let you approve your own PR. **Raise this to 1+ once a second trusted maintainer is added** — otherwise the PR gate and CI check still apply, just without a second pair of eyes.

**Tag protection:** a ruleset blocks deletion, retagging, and non-fast-forward updates on any `v*` tag, so a published release can't be silently rewritten.

**Repository security features enabled:**
- Secret scanning + push protection (blocks commits containing obvious secrets before they land).
- Dependabot security updates and vulnerability alerts.
- Private vulnerability reporting (see [`../../SECURITY.md`](../../SECURITY.md)).

**Access:** only the project owner has write/admin access. Outside contributors work through fork + PR only — that's the safe default and needs no further setup as the contributor base grows.

**CODEOWNERS:** [`.github/CODEOWNERS`](../../.github/CODEOWNERS) routes all PRs to the project owner. Enable "require review from Code Owners" in branch protection once the owner isn't the sole approver bottleneck.

### Not settable via API — configure manually

**Actions → General → "Fork pull request workflows from outside collaborators."** GitHub only exposes this tri-state setting through the web UI, not the REST API. Recommendation for this project: **"Require approval for all external contributors"** — the strictest of the three options.

Why the strict option specifically: Kombien is early-stage with a single maintainer, so the approval overhead is low (one person, reviewing occasionally), while the risk profile will only grow — once real application code, deploy workflows, or secrets exist, a workflow run from an untrusted PR is a real way to exfiltrate secrets or push a malicious change through CI. The two looser options ("new to GitHub" / "first-time contributor") stop requiring approval after someone's first merged contribution, which means a contributor who earns trust with one small, legitimate PR could submit a malicious workflow change afterward with no further gate. That trade-off isn't worth the saved clicks at this stage. Revisit this once there's a stable set of trusted, repeat contributors and the manual-approval overhead genuinely gets in the way.
