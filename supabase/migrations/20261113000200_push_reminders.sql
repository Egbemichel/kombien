-- Two more reasons to send a notification to riders who turned them on:
--   'updates'   "Kombien has been updated" (when a release is announced)
--   'reminders' a morning nudge, every 3 days, at 08:30 Cameroon time
--
-- Nothing new is collected: the same anonymous subscription (a browser
-- address and keys) as before. Riders who turned notifications on get both;
-- turning them off removes the subscription, so there is nothing to keep.

alter table public.push_subscriptions
  alter column topics set default '{unlocked,updates,reminders}';

update public.push_subscriptions
   set topics = (select array_agg(distinct t)
                   from unnest(topics || '{updates,reminders}') as t);

-- When the last morning nudge went to this phone. New subscribers get their
-- first one 3 days after they turned notifications on.
alter table public.push_subscriptions
  add column if not exists last_reminder_at timestamptz not null default now();

-- Releases already announced (once each), so a re-run never notifies twice.
create table if not exists public.push_announcements (
  kind       text not null,
  key        text not null,
  created_at timestamptz not null default now(),
  primary key (kind, key)
);
alter table public.push_announcements enable row level security;
-- No policies: only the server function (service role) reads or writes.
