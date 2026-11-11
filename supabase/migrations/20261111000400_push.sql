-- Push notifications: "Your report unlocked fares for Poste -> Eyang."
--
-- A rider who opts in stores their browser's push subscription. When a
-- route reaches 3 recent reports, the notify-unlocked function (Edge
-- Function, supabase/functions) queues a notification for the riders who
-- reported it, and sends what is due: never 21:00-07:00 Cameroon time,
-- at most one a day per phone. What was held back goes out the next time
-- any phone checks in (the app asks the function to send what is due when
-- it opens, and after each report).

-- ------------------------------------------------------------ subscriptions

create table public.push_subscriptions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users (id)
                 on delete cascade,
  -- What the browser hands out: where to send, and the keys to encrypt
  -- for this phone. Nothing else about the rider.
  endpoint     text not null unique
                 check (endpoint ~ '^https://' and length(endpoint) <= 1000),
  p256dh       text not null check (length(p256dh) <= 200),
  auth         text not null check (length(auth) <= 100),
  locale       text not null default 'en' check (locale in ('en', 'fr')),
  topics       text[] not null default '{unlocked}',
  last_sent_at timestamptz,
  created_at   timestamptz not null default now()
);

comment on table public.push_subscriptions is
  'Phones that asked for notifications, and on which topics.';

create index push_subscriptions_user_idx on public.push_subscriptions (user_id);

alter table public.push_subscriptions enable row level security;

-- Riders see and manage only their own subscription.
create policy "Riders add their own subscription"
  on public.push_subscriptions for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "Riders see their own subscription"
  on public.push_subscriptions for select to authenticated
  using (user_id = (select auth.uid()));
create policy "Riders change their own subscription"
  on public.push_subscriptions for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "Riders remove their own subscription"
  on public.push_subscriptions for delete to authenticated
  using (user_id = (select auth.uid()));

-- ------------------------------------------------------------ server only

-- Routes already announced as unlocked (once per route).
create table public.route_unlocks (
  from_landmark_id uuid not null references public.landmarks (id),
  to_landmark_id   uuid not null references public.landmarks (id),
  unlocked_at      timestamptz not null default now(),
  primary key (from_landmark_id, to_landmark_id)
);

-- Notifications waiting for their time (quiet hours, one a day).
create table public.push_outbox (
  id              bigint generated always as identity primary key,
  subscription_id uuid not null references public.push_subscriptions (id)
                    on delete cascade,
  payload         jsonb not null,
  send_after      timestamptz not null default now(),
  sent_at         timestamptz,
  created_at      timestamptz not null default now()
);

create index push_outbox_due_idx on public.push_outbox (send_after)
  where sent_at is null;

-- No policies: only the server function (service role) reads or writes.
alter table public.route_unlocks enable row level security;
alter table public.push_outbox enable row level security;
