-- Three places riders ask for near Elig-Edzoa (Yaoundé I) that no imported
-- dataset had. Added by hand (source 'manual'), from places the project owner
-- looked up on Google Maps; positions are the centres of the Plus Codes
-- (precise to about 14 m):
--   Sino Mart          6FMHVGQH+XV  (Nouvelle Route Omnisport)
--   Marché Elig-Edzoa  6FMHVGRJ+34
--   Elig-Edzoa         the neighbourhood, at the point OpenStreetMap has for it
--
-- Safe to run again: a place already there under the same name is left alone.

insert into public.landmarks (city_id, name, aliases, location, kind, source)
select c.id, v.name, v.aliases,
       extensions.st_setsrid(extensions.st_makepoint(v.lng, v.lat), 4326)::extensions.geography,
       v.kind, 'manual'
from public.cities c, (values
  ('Sino Mart',
   array['Sinomart', 'Sino Mart Omnisport']::text[],
   3.889937, 11.529687, 'shop=supermarket'),
  ('Marché Elig-Edzoa',
   array['Marche Elig-Edzoa', 'Marché Elig Edzoa', 'Marché d''Elig-Edzoa', 'Marché Elig-Dzoa']::text[],
   3.890188, 11.530312, 'amenity=marketplace'),
  ('Elig-Edzoa',
   array['Elig Edzoa', 'Elig-Dzoa', 'Elig Dzoa']::text[],
   3.886840, 11.530400, 'place=neighbourhood')
) as v(name, aliases, lat, lng, kind)
where c.name = 'Yaoundé'
on conflict (city_id, name) do nothing;
