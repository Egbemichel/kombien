-- Fare reports: steps of 50, and one voice per person per route per day.
--
-- 1. Fares are paid in steps of 50 FCFA, so a report must be too. Added NOT
--    VALID: new reports are checked, older ones are left alone.
--
-- 2. A rider who opens Kombien in three browsers is three anonymous sign-ins.
--    Two layers now tell them apart from three real people, and a range
--    counts each person once per route per day:
--      * device_hint: sent by the app. A hash of coarse traits the browsers
--        on one phone share (screen size, pixel ratio, time zone, system,
--        language). It cannot say who anyone is.
--      * net_key: stamped here, by the database, from the network the report
--        came from. The address itself is NEVER stored: it is cut to its
--        neighbourhood (/24, or /64 for IPv6), mixed with the day and a
--        server-side secret, and hashed. The result cannot be turned back
--        into an address, and cannot be matched across days.
--    Two sign-ins count as one person only when BOTH layers agree (same
--    device hint, same network, same day); one sign-in is one person. Needing
--    both keeps two riders who merely own the same phone model, or share a
--    mobile network, from being merged.

alter table public.fare_reports
  add column if not exists device_hint text
    check (device_hint is null or device_hint ~ '^[0-9a-f]{32}$'),
  add column if not exists net_key text;

alter table public.fare_reports
  add constraint fare_reports_amount_step check (amount_xaf % 50 = 0) not valid;

-- The server-side secret for net_key. Nothing in the API can read it.
create table if not exists public.integrity_secret (
  id     boolean primary key default true check (id),
  secret bytea not null
);
alter table public.integrity_secret enable row level security;
revoke all on public.integrity_secret from public, anon, authenticated;
insert into public.integrity_secret (secret)
  values (extensions.gen_random_bytes(32)) on conflict do nothing;

create or replace function public.stamp_report_network()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  h      json;
  ip     text;
  hood   text;
  key    bytea;
begin
  -- Whatever the app sent for net_key is ignored: only the database sets it.
  new.net_key := null;
  begin
    h := current_setting('request.headers', true)::json;
    ip := trim(split_part(coalesce(nullif(h->>'cf-connecting-ip', ''),
                                   nullif(h->>'x-real-ip', ''),
                                   h->>'x-forwarded-for', ''), ',', 1));
    if ip <> '' then
      hood := host(network(set_masklen(ip::inet,
                case family(ip::inet) when 4 then 24 else 64 end)));
    end if;
  exception when others then
    hood := null;
  end;
  if hood is not null then
    select secret into key from public.integrity_secret;
    new.net_key := substr(encode(extensions.hmac(convert_to(
      hood || '|' || to_char(now() at time zone 'Africa/Douala', 'YYYY-MM-DD'),
      'utf8'), key, 'sha256'), 'hex'), 1, 32);
  end if;
  return new;
end;
$$;

revoke all on function public.stamp_report_network() from public, anon, authenticated;

drop trigger if exists fare_reports_stamp_network on public.fare_reports;
create trigger fare_reports_stamp_network
  before insert on public.fare_reports
  for each row execute function public.stamp_report_network();

-- The reports that count towards a range. Not readable through the API.
-- One per sign-in per route per day, then one per (device hint, network) per
-- route per day.
create or replace view public.counted_fare_reports as
select c.*
from (
  select distinct on (u.from_landmark_id, u.to_landmark_id, u.person, u.day) u.*
  from (
    select s.*,
           (s.created_at at time zone 'Africa/Douala')::date as day,
           case when s.device_hint is not null and s.net_key is not null
                then s.device_hint || ':' || s.net_key
                else s.reported_by::text end as person
    from (
      select distinct on (f.from_landmark_id, f.to_landmark_id, f.reported_by,
                          (f.created_at at time zone 'Africa/Douala')::date) f.*
      from public.fare_reports f
      order by f.from_landmark_id, f.to_landmark_id, f.reported_by,
               (f.created_at at time zone 'Africa/Douala')::date, f.created_at
    ) s
  ) u
  order by u.from_landmark_id, u.to_landmark_id, u.person, u.day, u.created_at
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
