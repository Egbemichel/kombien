-- Riders adding a place themselves, with a position they can stand behind.
--
-- A rider can say where a place is in three ways:
--   gps   "I'm here now": a fresh phone position, accepted only if accurate
--         (100 m or better) and inside the city
--   near  "It's near a place I know": the position of a known landmark, with
--         how far away it is, so it is approximate and says so
--   none  "I'm not sure where": the name alone; found by name, not by distance
--
-- Nothing proves a rider is at the place, so every addition is a claim that is
-- recorded (place_claims), rate limited, checked for duplicates of what Kombien
-- already has, and marked source = 'rider' so a maintainer can review or remove
-- it. Fares keep working unchanged: reports and ranges are keyed by landmark id.

-- ------------------------------------------------------------ city areas

-- The same boxes the OpenStreetMap import and the app use (south, west, north, east).
alter table public.cities
  add column south double precision,
  add column west  double precision,
  add column north double precision,
  add column east  double precision;

update public.cities set south = 3.70, west = 11.40, north = 3.98, east = 11.62 where name = 'Yaoundé';
update public.cities set south = 3.95, west = 9.60,  north = 4.15, east = 9.85  where name = 'Douala';

-- ------------------------------------------------------------ landmarks

-- How sure the position is, in metres: the phone's own accuracy for gps, the
-- distance from the known place for near. Null for places from datasets.
alter table public.landmarks
  add column location_accuracy_m integer
    check (location_accuracy_m is null or location_accuracy_m between 0 and 5000);

-- Where a landmark came from is a short lowercase word. Open-ended on purpose:
-- several data sources each add their own and none should undo another's.
alter table public.landmarks
  drop constraint if exists landmarks_source_check,
  add constraint landmarks_source_check check (source ~ '^[a-z]{3,20}$');

-- ------------------------------------------------------------ find them again

-- Places riders added (through Google or by hand) matching what was typed.
create or replace function public.find_rider_places(
  p_query text,
  p_city  text,
  p_max   integer default 5
) returns table (id uuid, name text)
language sql
stable
security invoker
set search_path = ''
as $$
  select l.id, l.name
  from public.landmarks l
  join public.cities c on c.id = l.city_id
  where l.source in ('google', 'rider')
    and c.name = p_city
    and length(btrim(coalesce(p_query, ''))) >= 2
    and public.landmark_search_text(l.name, l.aliases)
        like '%' || lower(extensions.unaccent('extensions.unaccent'::regdictionary, btrim(p_query))) || '%'
  order by
    (public.landmark_search_text(l.name, l.aliases)
       like lower(extensions.unaccent('extensions.unaccent'::regdictionary, btrim(p_query))) || '%') desc,
    l.name
  limit least(greatest(p_max, 1), 10)
$$;

revoke all on function public.find_rider_places(text, text, integer) from public;
grant execute on function public.find_rider_places(text, text, integer) to anon, authenticated;

-- ------------------------------------------------------------ add a place

-- Adds a place, or returns the one Kombien already has. Never creates a
-- duplicate: the same name (accents and case ignored) is the same place, as in
-- the OpenStreetMap import, and a very similar name within 150 m is too.
create or replace function public.add_rider_place(
  p_city        text,
  p_label       text,
  p_method      text,
  p_lat         double precision default null,
  p_lng         double precision default null,
  p_accuracy_m  integer default null,
  p_anchor_id   uuid default null,
  p_anchor_m    integer default null
) returns table (landmark_id uuid, landmark_name text, already_known boolean)
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid     uuid := auth.uid();
  c       public.cities;
  lbl     text := btrim(regexp_replace(coalesce(p_label, ''), '\s+', ' ', 'g'));
  folded  text;
  pt      extensions.geography;
  acc     integer;
  lm      uuid;
  lname   text;
begin
  if uid is null then
    raise exception 'sign in required' using errcode = '28000';
  end if;

  select * into c from public.cities where name = p_city;
  if c.id is null then
    raise exception 'unknown city';
  end if;

  -- The name: the rider's own words, and not something personal.
  if length(lbl) < 2 or length(lbl) > 100 then
    raise exception 'bad name';
  end if;
  if lbl ~ '@' or lbl ~* 'https?:|www\.'
     or regexp_replace(lbl, '[\s.\-]', '', 'g') ~ '\d{6,}' then
    raise exception 'bad name';
  end if;

  -- Where it is.
  if p_method = 'gps' then
    if p_lat is null or p_lng is null or p_accuracy_m is null then
      raise exception 'bad position';
    end if;
    if p_accuracy_m < 0 or p_accuracy_m > 100 then
      raise exception 'position too weak';
    end if;
    if p_lat not between c.south and c.north or p_lng not between c.west and c.east then
      raise exception 'outside the city';
    end if;
    pt := extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography;
    acc := greatest(p_accuracy_m, 1);
  elsif p_method = 'near' then
    if p_anchor_id is null or p_anchor_m is null or p_anchor_m not between 0 and 1000 then
      raise exception 'bad position';
    end if;
    select a.location into pt
      from public.landmarks a
     where a.id = p_anchor_id and a.city_id = c.id and a.location is not null;
    if pt is null then
      raise exception 'bad position';
    end if;
    acc := greatest(p_anchor_m, 10);
  elsif p_method = 'none' then
    pt := null;
    acc := null;
  else
    raise exception 'bad position';
  end if;

  -- At most 20 additions per rider per day (shared with places added through Google).
  if (select count(*) from public.place_claims pc
        where pc.claimed_by = uid
          and pc.created_at > now() - interval '1 day') >= 20 then
    raise exception 'too many additions today';
  end if;

  folded := public.landmark_search_text(lbl, '{}');

  -- Already known? The same name...
  select l.id, l.name into lm, lname
    from public.landmarks l
   where l.city_id = c.id
     and public.landmark_search_text(l.name, '{}') = folded
   limit 1;

  -- ...or a very similar one right there.
  if lm is null and pt is not null then
    select l.id, l.name into lm, lname
      from public.landmarks l
     where l.city_id = c.id
       and l.location is not null
       and extensions.st_dwithin(l.location, pt, 150)
       and extensions.similarity(public.landmark_search_text(l.name, '{}'), folded) >= 0.6
     order by extensions.similarity(public.landmark_search_text(l.name, '{}'), folded) desc
     limit 1;
  end if;

  if lm is not null then
    insert into public.place_claims (landmark_id, claimed_by, label)
    values (lm, uid, lbl)
    on conflict (landmark_id, claimed_by) do nothing;
    return query select lm, lname, true;
    return;
  end if;

  insert into public.landmarks (city_id, name, location, kind, source, location_accuracy_m)
  values (c.id, lbl, pt, 'rider', 'rider', acc)
  returning id, name into lm, lname;

  insert into public.place_claims (landmark_id, claimed_by, label)
  values (lm, uid, lbl);

  return query select lm, lname, false;
end;
$$;

revoke all on function public.add_rider_place(text, text, text, double precision, double precision, integer, uuid, integer) from public;
-- "authenticated" includes anonymous sign-ins (how every rider is signed in).
grant execute on function public.add_rider_place(text, text, text, double precision, double precision, integer, uuid, integer) to authenticated;
