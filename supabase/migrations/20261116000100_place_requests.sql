-- What riders want added, and telling them when it is.
--
-- Two kinds of request, both tied to the rider's anonymous id (never to a
-- name, number or account) and never readable through the API:
--
--   'suggestion'  "Tell us about it": a place the rider named and could not
--                 find, saved for the maintainers to look up and add, with an
--                 optional note about where it is.
--   'search'      a place the rider searched for and did not find, kept ONLY
--                 for riders who turned notifications on, so they can be told
--                 when it arrives. (The anonymous count in search_misses is
--                 unchanged and still has no rider identity.)
--
-- When a place that answers a request is added, the notify-unlocked function
-- sends that rider "<place> is now on Kombien" (see answered_place_requests).
-- Turning notifications off forgets the rider's searches (forget_place_watches).

-- ------------------------------------------------------------ requests

create table public.place_requests (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users (id)
                on delete cascade,
  kind        text not null check (kind in ('search', 'suggestion')),
  name        text not null check (length(name) between 3 and 80),
  -- "Where is it?" in the rider's words (suggestions only).
  note        text check (note is null or length(note) <= 120),
  city        text not null default '' check (length(city) <= 40),
  locale      text not null default '' check (length(locale) <= 10),
  status      text not null default 'open'
                check (status in ('open', 'added', 'dismissed')),
  -- The place that answered it (set when the maintainers add it by hand, or
  -- found by name when it was added another way).
  landmark_id uuid references public.landmarks (id) on delete set null,
  created_at  timestamptz not null default now(),
  notified_at timestamptz
);

create unique index place_requests_once_idx
  on public.place_requests (user_id, kind, lower(name));
create index place_requests_waiting_idx
  on public.place_requests (status, created_at) where notified_at is null;

comment on table public.place_requests is
  'Places riders asked for (suggestions, and searches of riders with notifications on). Private: written only through suggest_place() and watch_place(); read by the maintainers and the notify function.';

alter table public.place_requests enable row level security;
-- No policies, and no table privileges for the API roles either.
revoke all on public.place_requests from anon, authenticated;

-- ------------------------------------------------------------ notifications topic

-- Riders with notifications on get "place added" too, like the other topics.
alter table public.push_subscriptions
  alter column topics set default '{unlocked,updates,reminders,places}';

update public.push_subscriptions
   set topics = (select array_agg(distinct t) from unnest(topics || '{places}') as t);

-- ------------------------------------------------------------ writing a request

-- The text of a name that is safe to keep: not an email address, a link or a
-- phone number. (Same rules as log_search_miss.)
create function public.place_text_ok(t text)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select t is not null
     and t !~ '@'
     and t !~* 'https?:|www\.'
     and regexp_replace(t, '[\s.\-]', '', 'g') !~ '\d{6,}'
$$;

-- "Tell us about it": a place the rider could not find. At most 10 a day.
create function public.suggest_place(
  p_name   text,
  p_note   text default null,
  p_city   text default '',
  p_locale text default ''
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid  uuid := auth.uid();
  n    text := regexp_replace(btrim(coalesce(p_name, '')), '\s+', ' ', 'g');
  note text := nullif(left(regexp_replace(btrim(coalesce(p_note, '')), '\s+', ' ', 'g'), 120), '');
begin
  if uid is null then
    return;
  end if;
  if length(n) < 3 or length(n) > 80 or not public.place_text_ok(n) then
    return;
  end if;
  if note is not null and not public.place_text_ok(note) then
    note := null;
  end if;
  if (select count(*) from public.place_requests r
        where r.user_id = uid and r.kind = 'suggestion'
          and r.created_at > now() - interval '1 day') >= 10 then
    return;
  end if;

  insert into public.place_requests (user_id, kind, name, note, city, locale)
  values (uid, 'suggestion', n, note, left(btrim(coalesce(p_city, '')), 40),
          left(btrim(coalesce(p_locale, '')), 10))
  on conflict (user_id, kind, lower(name)) do update
    set note = coalesce(excluded.note, public.place_requests.note);
end;
$$;

-- A search that found nothing, kept for a rider with notifications on so they
-- can be told when the place arrives. Anyone else: nothing is kept (their
-- search still counts, anonymously, in search_misses). At most 30 a day.
create function public.watch_place(
  p_query  text,
  p_city   text default '',
  p_locale text default ''
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  q   text := lower(regexp_replace(btrim(coalesce(p_query, '')), '\s+', ' ', 'g'));
begin
  if uid is null then
    return;
  end if;
  if length(q) < 3 or length(q) > 60 or not public.place_text_ok(q) then
    return;
  end if;
  if not exists (select 1 from public.push_subscriptions s
                  where s.user_id = uid and 'places' = any (s.topics)) then
    return;
  end if;
  if (select count(*) from public.place_requests r
        where r.user_id = uid and r.kind = 'search'
          and r.created_at > now() - interval '1 day') >= 30 then
    return;
  end if;

  insert into public.place_requests (user_id, kind, name, city, locale)
  values (uid, 'search', q, left(btrim(coalesce(p_city, '')), 40),
          left(btrim(coalesce(p_locale, '')), 10))
  on conflict (user_id, kind, lower(name)) do nothing;
end;
$$;

-- Notifications turned off: forget what this rider searched for.
create function public.forget_place_watches()
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.place_requests
   where user_id = auth.uid() and kind = 'search';
$$;

revoke all on function public.place_text_ok(text) from public;
revoke all on function public.suggest_place(text, text, text, text) from public, anon;
revoke all on function public.watch_place(text, text, text) from public, anon;
revoke all on function public.forget_place_watches() from public, anon;
grant execute on function public.suggest_place(text, text, text, text) to authenticated;
grant execute on function public.watch_place(text, text, text) to authenticated;
grant execute on function public.forget_place_watches() to authenticated;

-- ------------------------------------------------------------ answered requests

-- Requests that a place now answers, not yet told: the request, the rider, and
-- the place. A place answers a request when
--   - the maintainers linked it (landmark_id set by the Plus Code loader), or
--   - it was added AFTER the request, in the same city, and its name contains
--     what was asked (or every word of it, in any order, ignoring accents).
-- One place per request. Server only: the notify function calls it with the
-- service role.
create function public.answered_place_requests()
returns table (
  request_id   uuid,
  user_id      uuid,
  kind         text,
  asked        text,
  landmark_id  uuid,
  place_name   text,
  locale       text
)
language sql
stable
security definer
set search_path = ''
as $$
  select distinct on (r.id)
         r.id, r.user_id, r.kind, r.name, l.id, l.name, r.locale
  from public.place_requests r
  join public.landmarks l on
       l.id = r.landmark_id
    or (r.landmark_id is null
        and l.created_at > r.created_at
        and length(r.name) >= 4
        and (r.city = '' or exists (select 1 from public.cities c
                                     where c.id = l.city_id
                                       and lower(c.name) = lower(r.city)))
        and (
          public.landmark_search_text(l.name, l.aliases)
            like '%' || lower(extensions.unaccent('extensions.unaccent'::regdictionary, r.name)) || '%'
          or (
            exists (select 1
                      from unnest(string_to_array(lower(extensions.unaccent('extensions.unaccent'::regdictionary, r.name)), ' ')) w
                     where length(w) > 2)
            and not exists (select 1
                      from unnest(string_to_array(lower(extensions.unaccent('extensions.unaccent'::regdictionary, r.name)), ' ')) w
                     where length(w) > 2
                       and public.landmark_search_text(l.name, l.aliases) not like '%' || w || '%')
          )
        ))
  where r.status in ('open', 'added')
    and r.notified_at is null
  order by r.id, (l.id = r.landmark_id) desc, l.created_at
$$;

revoke all on function public.answered_place_requests() from public, anon, authenticated;
grant execute on function public.answered_place_requests() to service_role;
