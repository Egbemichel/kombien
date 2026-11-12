# Update and morning-reminder notifications

Riders who turned notifications on (an anonymous browser subscription, nothing
else) can get three kinds of notification:

| Topic | When | Sent by |
|---|---|---|
| `unlocked` | their report helped unlock a route's fares | the app, after a report |
| `updates` | "Kombien has been updated" | the deploy, when the change asks for it |
| `reminders` | a morning nudge, **every 3 days, about 08:30 Cameroon time** | the daily **Push reminders** workflow |

Rules that always apply (in the `notify-unlocked` function): never between
21:00 and 07:00 Cameroon time, and at most one notification a day to a phone.
Nothing about location is involved: a notification is "it is morning, and it
has been 3 days", not "you are somewhere".

## Why every 3 days

Every day is too much, and every 2 days still feels like nagging. Every 3 days
is about ten a month. Change `REMINDER_EVERY_HOURS` in
`supabase/functions/notify-unlocked/index.ts` (66 = every 3 days with room for
a late run; 42 = every 2 days) and the texts in `reminders`.

## One-time setup

1. Apply the migration `20261113000200_push_reminders.sql` (adds the topics,
   `last_reminder_at` and the announcements table; existing subscribers get
   both new topics).
2. Pick a long random value for `NOTIFY_SECRET` and set it in **both** places:
   - `supabase secrets set NOTIFY_SECRET=...` (function secret)
   - GitHub repository secret `NOTIFY_SECRET`
3. Deploy the function: `supabase functions deploy notify-unlocked`.
4. The `Push reminders` workflow runs daily at 07:30 UTC (08:30 Cameroon). Run
   it once from the Actions tab to check; a phone that subscribed less than 3
   days ago is simply not due yet.

## Announcing an update

Put **`[announce]`** in the pull request title. When that change deploys, the
deploy asks the function to send "Kombien has been updated" once (never twice
for the same release, never twice within 12 hours, held until morning at
night). Without `[announce]`, a deploy is silent, so small fixes do not ping
everyone.

## If something looks wrong

- No reminders arrive: check the workflow run's log (a 403 means the two
  `NOTIFY_SECRET` values differ), and that `VAPID_*` secrets exist.
- Riders say it is too much: raise `REMINDER_EVERY_HOURS`.
