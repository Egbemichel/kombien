-- "Report a problem" from Settings: up to three answers, write-only for
-- riders (read by maintainers in the dashboard).

create type public.problem_kind as enum ('wrong_fare', 'place_missing', 'bug', 'other');
create type public.problem_area as enum ('fares', 'report', 'settings', 'other');

create table public.problem_reports (
  id          uuid primary key default gen_random_uuid(),
  kind        public.problem_kind not null,
  area        public.problem_area,
  details     text check (details is null or length(details) <= 280),
  app_version text check (app_version is null or length(app_version) <= 20),
  locale      text check (locale is null or length(locale) <= 10),
  platform    text check (platform is null or length(platform) <= 20),
  reported_by uuid not null default auth.uid() references auth.users (id)
                on delete cascade,
  created_at  timestamptz not null default now()
);

comment on table public.problem_reports is
  'Problems riders report from Settings. Insert-only through the API.';

alter table public.problem_reports enable row level security;

create policy "Riders report problems as themselves"
  on public.problem_reports for insert to authenticated
  with check (reported_by = (select auth.uid()));
