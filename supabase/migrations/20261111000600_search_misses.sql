-- Searches that found nothing, so the people who maintain the place list can
-- see which places riders are actually looking for.
--
-- Privacy by construction: this keeps only the typed words, the city and the
-- language, with a count. No user id, no device id, no location, no time of
-- day per search. The same words from many riders add up to one row. Riders
-- never read it; maintainers read it in the dashboard (or the CLI):
--
--   select query, city, times, last_seen
--   from public.search_misses order by times desc limit 50;
--
-- After adding a place, delete its rows so the list shows what is still missing.

create table public.search_misses (
  query      text        not null,
  city       text        not null default '',
  locale     text        not null default '',
  times      integer     not null default 1,
  first_seen timestamptz not null default now(),
  last_seen  timestamptz not null default now(),
  primary key (query, city)
);

create index search_misses_last_seen_idx on public.search_misses (last_seen desc);

comment on table public.search_misses is
  'Place searches that found nothing: typed words, city, language, count. No rider identity. Written only through log_search_miss().';

-- No policies: the API cannot read or write this table directly.
alter table public.search_misses enable row level security;

-- The only way in. Riders do not need to be signed in (searching does not
-- sign them in), so the anonymous role may call it. It cleans what it gets,
-- drops anything that looks personal, and stops if it is being flooded.
create function public.log_search_miss(
  p_query  text,
  p_city   text default '',
  p_locale text default ''
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  q text := lower(regexp_replace(btrim(coalesce(p_query, '')), '\s+', ' ', 'g'));
  c text := left(btrim(coalesce(p_city, '')), 40);
  l text := left(btrim(coalesce(p_locale, '')), 10);
begin
  if length(q) < 3 or length(q) > 60 then
    return;
  end if;

  -- Not a place name: an email address, a link, or a phone number.
  if q ~ '@' or q ~ 'https?:|www\.' then
    return;
  end if;
  if regexp_replace(q, '[\s.\-]', '', 'g') ~ '\d{6,}' then
    return;
  end if;

  -- Flood guard: this is a free write path, so refuse bursts and runaway size.
  if (select count(*) from public.search_misses
        where last_seen > now() - interval '1 minute') > 300 then
    return;
  end if;
  if (select coalesce(reltuples, 0) from pg_class
        where oid = 'public.search_misses'::regclass) > 100000 then
    return;
  end if;

  insert into public.search_misses (query, city, locale)
  values (q, c, l)
  on conflict (query, city) do update
    set times = public.search_misses.times + 1,
        last_seen = now(),
        locale = excluded.locale;
end;
$$;

revoke all on function public.log_search_miss(text, text, text) from public;
grant execute on function public.log_search_miss(text, text, text) to anon, authenticated;
