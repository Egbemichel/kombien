-- Fix: adding a place Kombien already has failed with 'column reference
-- "landmark_id" is ambiguous' (the ON CONFLICT target clashed with the function's
-- output column of the same name). Without a target, ON CONFLICT DO NOTHING covers
-- the same unique key. Same function, same grants.

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
    on conflict do nothing;
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
