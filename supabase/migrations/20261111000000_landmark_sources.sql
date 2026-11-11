-- Where each landmark comes from, so OpenStreetMap places can be refreshed
-- in place (same id, fares stay attached) and hand-added ones left alone.

alter table public.landmarks
  add column kind   text,
  add column source text not null default 'manual'
    check (source in ('manual', 'osm')),
  add column osm_id text unique
    check (osm_id ~ '^(node|way|relation)/[0-9]+$');

comment on column public.landmarks.kind is
  'OpenStreetMap tag that made it a landmark, e.g. place=suburb, amenity=marketplace.';
comment on column public.landmarks.osm_id is
  'OpenStreetMap element (node/123); null for hand-added places.';
