-- Places that riders find through Google when they are not in Kombien yet.
--
-- What Google's rules allow us to keep: the place ID (indefinitely). Not its
-- name, not its address, and coordinates for 30 days at most. So a place found
-- this way is stored as a landmark whose NAME is the rider's own words, tied to
-- the Google place ID. Same Google place + same city = the same landmark, so
-- every rider who picks that place reports against one row and their prices
-- add up, whatever words they each typed.
--
-- Fares keep working unchanged: reports and ranges are keyed by landmark id.

-- ------------------------------------------------------------ landmarks

-- A place found through Google has no coordinates of ours (Google's may only
-- be cached 30 days), so a location is no longer required.
alter table public.landmarks
  alter column location drop not null,
  add column google_place_id text
    check (google_place_id ~ '^[A-Za-z0-9_-]{10,300}$');

alter table public.landmarks
  drop constraint landmarks_source_check,
  add constraint landmarks_source_check
    check (source in ('manual', 'osm', 'google')),
  add constraint landmarks_google_source_check
    check (google_place_id is null or source = 'google');

create unique index landmarks_google_place_key
  on public.landmarks (city_id, google_place_id)
  where google_place_id is not null;

comment on column public.landmarks.google_place_id is
  'Google place ID (storable indefinitely under Google''s policy); null for places that did not come from a Google pick. The name is the rider''s own words, never Google''s.';

-- City packs are searched on the phone by distance, so they only carry places
-- that have a location.
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
           round(extensions.st_x(l.location::extensions.geometry)::numeric, 6),
           l.kind)
         order by l.name), '[]'::jsonb)
  from public.landmarks l
  join public.cities c on c.id = l.city_id
  where c.name = city_name
    and l.location is not null
$$;

grant execute on function public.city_landmarks(text) to anon, authenticated;

-- ------------------------------------------------------------ who added what

-- One row per rider who picked a place: kept for abuse limits and for a later
-- "two riders agree" check. Not readable through the API.
create table public.place_claims (
  id          uuid primary key default gen_random_uuid(),
  landmark_id uuid not null references public.landmarks (id) on delete cascade,
  claimed_by  uuid not null references auth.users (id) on delete cascade,
  label       text not null,
  created_at  timestamptz not null default now(),
  unique (landmark_id, claimed_by)
);

create index place_claims_rider_day_idx on public.place_claims (claimed_by, created_at desc);

alter table public.place_claims enable row level security;
revoke all on public.place_claims from anon, authenticated;

-- ------------------------------------------------------------ add or reuse

-- Turns a Google pick into a landmark the rider can report against: reuses the
-- landmark already linked to that Google place in that city, or creates one
-- named with the rider's own words. Needs a (possibly anonymous) signed-in
-- rider, and refuses junk, personal-looking text, and floods.
create or replace function public.add_google_place(
  p_city     text,
  p_label    text,
  p_place_id text
) returns table (landmark_id uuid, landmark_name text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid       uuid := auth.uid();
  cid       smallint;
  lbl       text := btrim(regexp_replace(coalesce(p_label, ''), '\s+', ' ', 'g'));
  pid       text := btrim(coalesce(p_place_id, ''));
  lm        uuid;
  lname     text;
  candidate text;
  n         integer := 1;
begin
  if uid is null then
    raise exception 'sign in required' using errcode = '28000';
  end if;

  select c.id into cid from public.cities c where c.name = p_city;
  if cid is null then
    raise exception 'unknown city';
  end if;

  if length(lbl) < 2 or length(lbl) > 100 then
    raise exception 'bad name';
  end if;
  -- Not a place name: an email address, a link, or a phone number.
  if lbl ~ '@' or lbl ~* 'https?:|www\.'
     or regexp_replace(lbl, '[\s.\-]', '', 'g') ~ '\d{6,}' then
    raise exception 'bad name';
  end if;
  if pid !~ '^[A-Za-z0-9_-]{10,300}$' then
    raise exception 'bad place';
  end if;

  -- At most 20 additions per rider per day.
  if (select count(*) from public.place_claims pc
        where pc.claimed_by = uid
          and pc.created_at > now() - interval '1 day') >= 20 then
    raise exception 'too many additions today';
  end if;

  select l.id, l.name into lm, lname
    from public.landmarks l
   where l.city_id = cid and l.google_place_id = pid;

  if lm is null then
    candidate := lbl;
    loop
      begin
        insert into public.landmarks (city_id, name, location, source, kind, google_place_id)
        values (cid, candidate, null, 'google', 'google', pid)
        returning id, name into lm, lname;
        exit;
      exception when unique_violation then
        -- Another rider added this very place a moment ago, or the name is taken.
        select l.id, l.name into lm, lname
          from public.landmarks l
         where l.city_id = cid and l.google_place_id = pid;
        if lm is not null then
          exit;
        end if;
        n := n + 1;
        candidate := lbl || ' (' || n || ')';
        if n > 6 then
          raise exception 'name taken';
        end if;
      end;
    end loop;
  end if;

  insert into public.place_claims (landmark_id, claimed_by, label)
  values (lm, uid, lbl)
  on conflict (landmark_id, claimed_by) do nothing;

  return query select lm, lname;
end;
$$;

revoke all on function public.add_google_place(text, text, text) from public;
-- "authenticated" includes anonymous sign-ins (how every rider is signed in).
grant execute on function public.add_google_place(text, text, text) to authenticated;

-- ------------------------------------------------------------ find them again

-- Places riders added through Google, matching what was typed: how the next
-- rider finds "Cinemat" without asking Google at all. (Everything else is
-- searched as before.)
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
  where l.source = 'google'
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
