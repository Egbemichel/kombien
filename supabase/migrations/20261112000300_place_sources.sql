-- Places from open datasets (Overture Maps, GeoNames), beside OpenStreetMap's.
--
-- Each imported place keeps the id it has in its dataset, so a later import can
-- refresh it in place (same landmark id, so fares stay attached) and a place
-- added by hand or by a rider is left alone.

alter table public.landmarks
  add column if not exists external_id text;

comment on column public.landmarks.external_id is
  'The place''s id in the dataset named by source (an Overture id, a GeoNames id); null for places added by hand or by riders. OpenStreetMap places keep theirs in osm_id.';

-- Where a place came from is a short lowercase word ('osm', 'overture',
-- 'geonames', 'google', 'rider', 'manual'). Open-ended on purpose, so several
-- sources can coexist and none undoes another's constraint.
alter table public.landmarks
  drop constraint if exists landmarks_source_check,
  add constraint landmarks_source_check check (source ~ '^[a-z]{3,20}$');

create unique index if not exists landmarks_source_external_key
  on public.landmarks (source, external_id)
  where external_id is not null;
