-- Places around Messassi, Olembe and Mendong, named as Google Maps names them
-- (looked up by the project owner; positions are the centres of the Plus Codes).
--
-- 1. Olembé Pharmacy -> Olembe Pharmacy: it already exists (from OpenStreetMap);
--    only the name changes, to Google's. The old spelling stays as an alias so
--    searching either way finds it, and the id stays so anything attached to it
--    does. Dovv Mendong already carries Google's name at the same spot.
-- 2. Four places that were not in Kombien yet.
--
-- Safe to run again.

update public.landmarks l
   set name = 'Olembe Pharmacy',
       aliases = (select array_agg(distinct a)
                    from unnest(l.aliases || array['Olembé Pharmacy', 'Olembé Pharmacie']) as a)
 where l.name = 'Olembé Pharmacy'
   and l.city_id = (select id from public.cities where name = 'Yaoundé')
   and not exists (select 1 from public.landmarks x
                    where x.city_id = l.city_id and x.name = 'Olembe Pharmacy');

insert into public.landmarks (city_id, name, aliases, location, kind, source, location_accuracy_m)
select c.id, v.name, v.aliases,
       extensions.st_setsrid(extensions.st_makepoint(v.lng, v.lat), 4326)::extensions.geography,
       v.kind, 'manual', v.accuracy
from public.cities c, (values
  ('Dispensaire de Messasi',
   array['Dispensaire de Messassi', 'Dispensaire Messassi']::text[],
   3.946187, 11.522063, 'amenity=clinic', null::int),
  -- Google gave a short code for the market (about 275 m wide): approximate.
  ('Marché Messasi',
   array['Marché Messassi', 'Marche Messassi', 'Marche Messasi']::text[],
   3.941812, 11.518187, 'amenity=marketplace', 200),
  ('Dovv Messassi',
   array['Dovv Messasi', 'Dôvv Messassi']::text[],
   3.944187, 11.516313, 'shop=supermarket', null::int),
  ('Santa Lucia at Entree Simbock',
   array['Santa Lucia Simbock', 'Santa Lucia Entrée Simbock']::text[],
   3.831812, 11.471187, 'shop=supermarket', null::int)
) as v(name, aliases, lat, lng, kind, accuracy)
where c.name = 'Yaoundé'
on conflict (city_id, name) do nothing;
