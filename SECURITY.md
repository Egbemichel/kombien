# Security Policy

## Current status

Kombien has no deployed infrastructure yet. This repository contains the brand system, project docs, and a frontend-only Flutter app ([`app/`](app/README.md)) with no backend, no API, and no collected user data. This policy is in place so a reporting path exists from day one and stays current as the project grows.

## Reporting a vulnerability

If you believe you've found a security vulnerability in this repository or in a future Kombien deployment:

1. **Do not open a public issue.** Public issues are visible to everyone, including before a fix is available.
2. Use GitHub's private vulnerability reporting for this repository (Security tab → "Report a vulnerability"), if enabled, or contact a maintainer directly (see [GOVERNANCE.md](GOVERNANCE.md)).
3. Include what you found, steps to reproduce, and potential impact if known.

## What to expect

- Acknowledgement of your report as soon as a maintainer is available to respond.
- An honest assessment — this is a volunteer-run project, so response time will vary.
- Credit, if you'd like it, once a fix ships.

## Scope

Once a backend and data infrastructure exist, this document should be updated to specify:

- Which components are in scope (API, mobile app, data pipeline, etc.).
- How user-reported fare data should be handled from a privacy standpoint.
- Any bug bounty or recognition program, if one is introduced.

Until then, treat this policy as covering the repository itself and the Flutter app's source (supply-chain concerns in dependencies such as Dart/pub packages, leaked secrets, malicious contributions, etc.).
