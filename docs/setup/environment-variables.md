# Environment Variables

**Status: placeholder.** The app ([`../../app/`](../../app/)) is frontend-only right now — no backend, no API base URL, no keys — so there's nothing to configure yet.

## When this becomes relevant

Once a backend or data pipeline is added, this document should list:

- Each required and optional environment variable.
- What it configures (API keys, database connection strings, feature flags).
- Where to get a value for local development (e.g. a `.env.example` file).
- Which variables are safe to commit versus which must stay secret.

Until then, note that `.env*` files are already excluded via [`.gitignore`](../../.gitignore) so secrets aren't committed by accident once they exist.
