-- City packs carry each place's kind (OpenStreetMap tag), so the phone can
-- rank "the place I am at" the way riders say it: a junction or market
-- before the centre point of a whole neighbourhood.

-- [[id, name, [aliases], lat, lng, kind], ...]
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
$$;

-- Nearest known place: junctions, markets and localities first; the centre
-- of a neighbourhood only counts as much further away (it is the middle of
-- an area, not where someone stands); shops, schools and the like between.
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
  order by extensions.st_distance(l.location, here.p)
           + case
               when l.kind in ('place=quarter', 'place=suburb', 'place=neighbourhood')
                 then 250
               when l.kind like 'place=%' or l.kind like 'highway=%'
                    or l.kind = 'amenity=marketplace' then 0
               else 120
             end
  limit 1
$$;

grant execute on function public.city_landmarks(text) to anon, authenticated;
grant execute on function public.nearest_landmark(double precision, double precision, double precision)
  to anon, authenticated;
