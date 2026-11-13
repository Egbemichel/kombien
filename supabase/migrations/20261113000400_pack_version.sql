-- A phone keeps a saved copy of a city's places (the offline pack). This lets
-- the phone ask, cheaply, whether the database has places its copy lacks, so a
-- place added today is on the phone the next time the app opens, not a week
-- later. The answer is only "how many places, and when was the newest added":
-- nothing about any rider.

create or replace function public.pack_version(city_name text)
returns text
language sql
stable
security invoker
set search_path = ''
as $$
  select count(*)::text || ':' || coalesce(extract(epoch from max(l.created_at))::bigint::text, '0')
  from public.landmarks l
  join public.cities c on c.id = l.city_id
  where c.name = city_name
$$;

grant execute on function public.pack_version(text) to anon, authenticated;
