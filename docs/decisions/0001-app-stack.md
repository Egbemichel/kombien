# 0001 — App stack

**Status:** accepted.
**Date:** 2026-11-09

## Context

Kombien is moving from design to working features (language switching,
location permission, saved places). Until now the only stated choice was
Flutter for the app; nothing else was written down.

## Decision: the app

| Concern | Choice | Why |
| --- | --- | --- |
| App framework | Flutter (Dart), Material 3 | One codebase for Android first, iOS and web later. |
| Type | DM Sans through `google_fonts`, files bundled in `assets/google_fonts/` | Brand font; bundled so text never waits on the network. |
| Icons | `hugeicons` (stroke rounded) | Brand icon set. |
| Vector art | `flutter_svg` | Wordmark and skyline. |
| Languages | Flutter's built-in `gen-l10n` (`flutter_localizations`, `intl`), strings in `app/lib/l10n/*.arb` | Official, compile-time checked; English and French now, more by adding an ARB file. |
| Local storage | `shared_preferences` | Small settings: language, saved places, first-run flags. |
| Location | `geolocator` behind `app/lib/services/location_service.dart` | Permission and position on Android, iOS and web; wrapped so tests use a fake. |
| State | Plain `ValueNotifier`s in `app/lib/app/app_state.dart`, handed down by `KAppScope` | Enough for today; revisit (e.g. Riverpod) when screens share server data. |
| Motion | One spring, `app/lib/design/k_motion.dart` | Every animation runs on the same physics. |

## Decision: the backend — Supabase

Chosen 2026-11-09.

| Concern | Choice | Why |
| --- | --- | --- |
| Database | Supabase Postgres with PostGIS, `pg_trgm`, `unaccent` | Landmarks are places: "nearest first" and fuzzy, accent-blind names ("Ngoa-Ekellé" = "ngoa ekelle"). |
| Schema | Migrations in `supabase/migrations/`, dev seed in `supabase/seed.sql` | Reviewable, reproducible, same locally and hosted. |
| Riders | Anonymous sign-in, once per phone, on first write | No accounts to report a fare; abuse can still be traced to a device. |
| Privacy | Row-level security: reports are insert-only; reads go through `fare_range()`, which returns only the aggregate, and only for routes with at least 3 reports | A single trip is never readable; small routes don't reveal one rider. |
| App access | `supabase_flutter`; URL and publishable key at build time (`--dart-define`) | No secrets in the app; runs on sample data when unset. |

Open source and self-hostable, which fits a community civic-tech project.
