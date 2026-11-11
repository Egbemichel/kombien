-- Offline-first support: city packs the phone keeps, the landmark nearest
-- to the rider (so "My location" can be looked up and reported), and the
-- 👍/👎 riders give a fare range.

-- ------------------------------------------------------------ nearest landmark

-- The landmark closest to a point, within [max_m] metres; nothing when the
-- rider is nowhere near a known place.
create or replace function public.nearest_landmark(
  lat double precision,
  lng double precision,
  max_m double precision default 600
)
returns table (id uuid, name text, distance_m double precision)
language sql
stable
security invoker
set search_path = ''
as $$
  with here as (
    select extensions.st_setsrid(extensions.st_makepoint(lng, lat), 4326)::extensions.geography as p
  )
  select l.id, l.name, extensions.st_distance(l.location, here.p)
  from public.landmarks l, here
  where extensions.st_dwithin(l.location, here.p, least(greatest(max_m, 50), 2000))
  -- Neighbourhoods and junctions are what riders say; prefer them when
  -- about as close as a shop or school.
  order by extensions.st_distance(l.location, here.p)
           + case when l.kind like 'place=%' or l.kind like 'highway=%'
                    or l.kind = 'amenity=marketplace' then 0 else 120 end
  limit 1
$$;

-- ------------------------------------------------------------ city pack

-- Every landmark of a city in one compact JSON value (one request, no row
-- limit): [[id, name, [aliases], lat, lng], ...]. The phone searches it
-- offline.
create or replace function public.city_landmarks(city_name text)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_array(
           l.id, l.name, l.aliases,
           round(extensions.st_y(l.location::extensions.geometry)::numeric, 6),
           round(extensions.st_x(l.location::extensions.geometry)::numeric, 6))
         order by l.name), '[]'::jsonb)
  from public.landmarks l
  join public.cities c on c.id = l.city_id
  where c.name = city_name
$$;

-- Fare ranges for every route of a city with enough recent reports, as
-- [[from_id, to_id, low, high, reports], ...]. Same rules as fare_range:
-- aggregates only, at least 3 riders per route.
create or replace function public.city_fares(
  city_name text,
  days integer default 90
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_array(
           r.from_landmark_id, r.to_landmark_id, r.low, r.high, r.n)), '[]'::jsonb)
  from (
    select f.from_landmark_id, f.to_landmark_id,
           (percentile_cont(0.25) within group (order by f.amount_xaf))::integer as low,
           (percentile_cont(0.75) within group (order by f.amount_xaf))::integer as high,
           count(*) as n
    from public.fare_reports f
    join public.landmarks l on l.id = f.from_landmark_id
    join public.cities c on c.id = l.city_id
    where c.name = city_name
      and f.created_at > now() - make_interval(days => least(greatest(days, 1), 365))
    group by f.from_landmark_id, f.to_landmark_id
    having count(*) >= 3
  ) r
$$;

comment on function public.city_fares is
  'Aggregated fares for all well-reported routes of a city (offline packs).';

revoke all on function public.city_fares(text, integer) from public;
grant execute on function public.city_fares(text, integer) to anon, authenticated;
grant execute on function public.city_landmarks(text) to anon, authenticated;
grant execute on function public.nearest_landmark(double precision, double precision, double precision)
  to anon, authenticated;

-- ------------------------------------------------------------ feedback

-- "Was this information helpful?" on a fare range. Write-only, like
-- reports: it tells us which ranges riders trust.
create table public.fare_feedback (
  id               uuid primary key default gen_random_uuid(),
  from_landmark_id uuid not null references public.landmarks (id),
  to_landmark_id   uuid not null references public.landmarks (id),
  helpful          boolean not null,
  low_xaf          integer check (low_xaf between 0 and 50000),
  high_xaf         integer check (high_xaf between 0 and 50000),
  reported_by      uuid not null default auth.uid() references auth.users (id)
                     on delete cascade,
  created_at       timestamptz not null default now()
);

alter table public.fare_feedback enable row level security;

create policy "Riders rate ranges as themselves"
  on public.fare_feedback for insert to authenticated
  with check (reported_by = (select auth.uid()));
