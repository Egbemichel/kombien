-- Kombien: landmarks, fare reports, and the fare range riders see.
--
-- Privacy by construction: a single fare report is never readable through
-- the API. Riders write reports (as anonymous users) and read only the
-- aggregated range for a route, and only once enough riders reported it.

create extension if not exists postgis with schema extensions;
create extension if not exists pg_trgm with schema extensions;
create extension if not exists unaccent with schema extensions;

-- ------------------------------------------------------------ cities

create table public.cities (
  id         smallint generated always as identity primary key,
  name       text not null unique,
  country    char(2) not null default 'CM',
  created_at timestamptz not null default now()
);

comment on table public.cities is 'Cities Kombien covers.';

-- ------------------------------------------------------------ landmarks

create table public.landmarks (
  id         uuid primary key default gen_random_uuid(),
  city_id    smallint not null references public.cities (id),
  name       text not null check (length(trim(name)) between 2 and 120),
  -- Other names riders use ("Poste", "Carrefour Poste").
  aliases    text[] not null default '{}',
  location   extensions.geography(point, 4326) not null,
  created_at timestamptz not null default now(),
  unique (city_id, name)
);

comment on table public.landmarks is
  'Places riders name as a start or destination: junctions, markets, schools.';

-- Accent- and case-insensitive search text (name + aliases).
create or replace function public.landmark_search_text(name text, aliases text[])
returns text
language sql
immutable
set search_path = ''
as $$
  select lower(extensions.unaccent('extensions.unaccent'::regdictionary,
    name || ' ' || array_to_string(aliases, ' ')))
$$;

create index landmarks_search_idx on public.landmarks
  using gin (public.landmark_search_text(name, aliases) extensions.gin_trgm_ops);
create index landmarks_location_idx on public.landmarks using gist (location);

-- ------------------------------------------------------------ fare reports

create type public.vehicle as enum ('taxi', 'moto');
create type public.day_part as enum ('morning', 'afternoon', 'evening', 'night');

create table public.fare_reports (
  id               uuid primary key default gen_random_uuid(),
  from_landmark_id uuid not null references public.landmarks (id),
  to_landmark_id   uuid not null references public.landmarks (id),
  -- What the rider paid, in FCFA (XAF). Bounds catch typos, not real fares.
  amount_xaf       integer not null check (amount_xaf between 50 and 50000),
  vehicle          public.vehicle not null default 'taxi',
  day_part         public.day_part not null,
  raining          boolean not null default false,
  reported_by      uuid not null default auth.uid() references auth.users (id)
                     on delete cascade,
  created_at       timestamptz not null default now(),
  check (from_landmark_id <> to_landmark_id)
);

comment on table public.fare_reports is
  'What riders paid. Write-only for riders; read only as aggregates.';

create index fare_reports_route_idx
  on public.fare_reports (from_landmark_id, to_landmark_id, created_at desc);

-- ------------------------------------------------------------ security

alter table public.cities enable row level security;
alter table public.landmarks enable row level security;
alter table public.fare_reports enable row level security;

create policy "Cities are public"
  on public.cities for select to anon, authenticated using (true);

create policy "Landmarks are public"
  on public.landmarks for select to anon, authenticated using (true);

-- Any signed-in rider (anonymous users included) may add a report as
-- themselves. No select, update or delete policy: reports are write-only.
create policy "Riders add their own reports"
  on public.fare_reports for insert to authenticated
  with check (reported_by = (select auth.uid()));

-- ------------------------------------------------------------ API: search

-- Landmarks matching [query] (accents and case ignored), best match first;
-- near a point when one is given, nearest first among equally good names.
create or replace function public.search_landmarks(
  query text,
  near_lat double precision default null,
  near_lng double precision default null,
  city smallint default null,
  max_results integer default 8
)
returns table (id uuid, name text, distance_m double precision)
language sql
stable
security invoker
set search_path = ''
as $$
  with q as (
    select lower(extensions.unaccent('extensions.unaccent'::regdictionary,
      trim(query))) as text,
      case when near_lat is not null and near_lng is not null then
        extensions.st_setsrid(extensions.st_makepoint(near_lng, near_lat), 4326)::extensions.geography
      end as here
  )
  select l.id, l.name,
         case when q.here is not null
              then extensions.st_distance(l.location, q.here) end as distance_m
  from public.landmarks l, q
  where length(q.text) >= 2
    and (city is null or l.city_id = city)
    and public.landmark_search_text(l.name, l.aliases) like '%' || q.text || '%'
  order by
    -- Names that start with the query first, then nearest, then A–Z.
    (public.landmark_search_text(l.name, l.aliases) like q.text || '%') desc,
    distance_m asc nulls last,
    l.name
  limit least(greatest(max_results, 1), 20)
$$;

-- ------------------------------------------------------------ API: fare range

-- The range riders recently paid on a route, or nothing when fewer than
-- [min_reports] riders reported it in the last [days] days (too few to be
-- a fair range, and too few to stay anonymous).
create or replace function public.fare_range(
  from_id uuid,
  to_id uuid,
  days integer default 90,
  min_reports integer default 3
)
returns table (low_xaf integer, high_xaf integer, median_xaf integer, reports bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select
    (percentile_cont(0.25) within group (order by amount_xaf))::integer,
    (percentile_cont(0.75) within group (order by amount_xaf))::integer,
    (percentile_cont(0.5) within group (order by amount_xaf))::integer,
    count(*)
  from public.fare_reports
  where from_landmark_id = from_id
    and to_landmark_id = to_id
    and created_at > now() - make_interval(days => least(greatest(days, 1), 365))
  having count(*) >= greatest(min_reports, 3)
$$;

comment on function public.fare_range is
  'Aggregated fares for a route; the only way reports are read.';

revoke all on function public.fare_range(uuid, uuid, integer, integer) from public;
grant execute on function public.fare_range(uuid, uuid, integer, integer)
  to anon, authenticated;
grant execute on function public.search_landmarks(text, double precision, double precision, smallint, integer)
  to anon, authenticated;
