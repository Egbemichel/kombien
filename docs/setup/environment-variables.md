# Environment Variables

The app talks to [Supabase](https://supabase.com) (see
[decision 0001](../decisions/0001-app-stack.md)). It takes two build-time
values; without them it runs on built-in sample data, so it works with no
backend at all.

| Variable | What it is | Secret? |
| --- | --- | --- |
| `SUPABASE_URL` | The project's API URL. Local: `http://127.0.0.1:54321`. | No |
| `SUPABASE_PUBLISHABLE_KEY` | The project's publishable (anon) key. | No: it ships inside the app. Row-level security in the database decides what it can do. |

Never put the **secret** / `service_role` key in the app or in this repo.

## Running the app against Supabase

1. Copy [`app/supabase.example.json`](../../app/supabase.example.json) to
   `app/supabase.local.json` (git-ignored) and fill in the two values.
2. Run:

   ```bash
   flutter run -d chrome --dart-define-from-file=supabase.local.json
   ```

## Local Supabase

Needs Docker Desktop running and the Supabase CLI.

```bash
supabase start          # from the repo root; applies supabase/migrations and supabase/seed.sql
supabase status         # prints the local URL and publishable key
supabase db reset       # rebuild the local database from migrations + seed
supabase stop
```

## Hosted project

Create the project in the Supabase dashboard (region close to Cameroon, e.g.
Europe), then link and push the schema:

```bash
supabase link --project-ref <project-ref>
supabase db push
```

In the dashboard, under Authentication → Sign In / Providers, turn on
**Anonymous sign-ins**: riders report fares without an account.
