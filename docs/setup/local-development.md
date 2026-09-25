# Local Development

**Status: placeholder.** This repository currently contains brand and project infrastructure only — no application code has been added yet, so there's nothing to run locally beyond viewing documentation and, optionally, the brand tokens.

## What you can do today

- Browse the brand system starting at [`brand/README.md`](../../brand/README.md).
- Preview the color tokens by opening [`brand/tokens/colors.css`](../../brand/tokens/colors.css) in any HTML page that imports it.
- Run the brand asset validation script:

```bash
node scripts/validate-brand-assets.mjs
```

This requires a maintained Node.js version (see the [GitHub Actions workflow](../../.github/workflows/validate-brand-assets.yml) for the version currently used in CI) but no dependency installation — the script is dependency-free.

## When application code is added

This document should be rewritten to cover:

- Prerequisites (runtime versions, package managers).
- Install steps.
- How to run the app locally (dev server, mobile emulator, etc.).
- How to run tests.
- Common troubleshooting.

See [environment-variables.md](environment-variables.md) for the parallel placeholder on configuration.
