# Environment Variables

**Status: placeholder.** No application code exists yet, so there are no environment variables to configure.

## When this becomes relevant

Once a backend, data pipeline, or mobile app is added, this document should list:

- Each required and optional environment variable.
- What it configures (API keys, database connection strings, feature flags).
- Where to get a value for local development (e.g. a `.env.example` file).
- Which variables are safe to commit versus which must stay secret.

Until then, note that `.env*` files are already excluded via [`.gitignore`](../../.gitignore) so secrets aren't committed by accident once they exist.
