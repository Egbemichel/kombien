-- Fare reports: steps of 50, and one voice per person per route per day.
--
-- 1. Fares are paid in steps of 50 FCFA, so a report must be too. Added NOT
--    VALID: new reports are checked, older ones are left alone.
--
-- 2. A rider who opens Kombien in three browsers is three anonymous sign-ins.
--    Reports now also carry a "device hint": a hash of coarse, non-identifying
--    traits the browsers on one phone share (screen size, pixel ratio, cores,
--    time zone). It cannot say who anyone is, and it is only ever compared
--    with other hints. A route's range then counts each person once per day:
--    one report per sign-in per route per day, and one per device hint per
--    route per day. (Two riders with the same phone model who report the same
--    route on the same day count once: the safe direction, since it can only
--    delay a range, never invent one.)

alter table public.fare_reports
  add column if not exists device_hint text
    check (device_hint is null or device_hint ~ '^[0-9a-f]{32}$');

alter table public.fare_reports
  add constraint fare_reports_amount_step check (amount_xaf % 50 = 0) not valid;

-- The reports that count towards a range. Not readable through the API.
create or replace view public.counted_fare_reports as
select c.*
from (
  select distinct on (u.from_landmark_id, u.to_landmark_id,
                      coalesce(u.device_hint, u.reported_by::text), u.day) u.*
  from (
    select distinct on (f.from_landmark_id, f.to_landmark_id, f.reported_by,
                        (f.created_at at time zone 'Africa/Douala')::date)
           f.*, (f.created_at at time zone 'Africa/Douala')::date as day
    from public.fare_reports f
    order by f.from_landmark_id, f.to_landmark_id, f.reported_by,
             (f.created_at at time zone 'Africa/Douala')::date, f.created_at
  ) u
  order by u.from_landmark_id, u.to_landmark_id,
           coalesce(u.device_hint, u.reported_by::text), u.day, u.created_at
) c;

revoke all on public.counted_fare_reports from public, anon, authenticated;

-- The range riders recently paid on a route: the quarter points and the
-- middle, rounded to the nearest 50. Nothing until three people have reported.
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
    (round(percentile_cont(0.25) within group (order by amount_xaf) / 50) * 50)::integer,
    (round(percentile_cont(0.75) within group (order by amount_xaf) / 50) * 50)::integer,
    (round(percentile_cont(0.5) within group (order by amount_xaf) / 50) * 50)::integer,
    count(*)
  from public.counted_fare_reports
  where from_landmark_id = from_id
    and to_landmark_id = to_id
    and created_at > now() - make_interval(days => least(greatest(days, 1), 365))
  having count(*) >= greatest(min_reports, 3)
$$;

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
           (round(percentile_cont(0.25) within group (order by f.amount_xaf) / 50) * 50)::integer as low,
           (round(percentile_cont(0.75) within group (order by f.amount_xaf) / 50) * 50)::integer as high,
           count(*) as n
    from public.counted_fare_reports f
    join public.landmarks l on l.id = f.from_landmark_id
    join public.cities c on c.id = l.city_id
    where c.name = city_name
      and f.created_at > now() - make_interval(days => least(greatest(days, 1), 365))
    group by f.from_landmark_id, f.to_landmark_id
    having count(*) >= 3
  ) r
$$;
