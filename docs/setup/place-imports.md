# Importing places from open datasets

Kombien's own places come from OpenStreetMap. Two more free datasets can fill
gaps. Nothing here runs by itself and nothing touches the database until you
review a migration and push it.

## What each dataset gives

| Dataset | Licence | What we found |
|---|---|---|
| **Overture Maps Places** | Per source: Meta/Microsoft CDLA Permissive 2.0, Foursquare Apache 2.0, AllThePlaces CC0 | Many businesses OSM lacks: hotels, banks, fuel stations, schools, restaurants. Tried on a Yaoundé sample, it added about 190 places OSM did not have. It does **not** have every place riders ask for: Sino Mart and Cinemat were not in it. |
| **GeoNames** | CC BY 4.0 | About 100 places in the two cities, mostly outlying villages. Little value, but cheap and safe. |
| **Foursquare OS Places** | Apache 2.0 | The raw dataset is gated behind a sign-in, and Overture already carries Foursquare data, so it is not built. |

So these imports widen coverage; they do not replace the "Not there? Add it
yourself" flow. Places like Sino Mart still reach Kombien through riders
(see [places-added-by-riders.md](places-added-by-riders.md)).

## Running them

On GitHub: **Actions → Place imports → Run workflow**. It fetches Overture on
GitHub's network (a few minutes), runs both importers and uploads a
`place-imports` artifact holding, for each dataset, a report (`*_report.md`,
also shown on the run's summary page) and a migration (`*_places.sql`).

Locally (needs `pip install duckdb`, and a fast connection for Overture):

```bash
python supabase/tools/geonames_places.py
python supabase/tools/overture_places.py          # --release 2026-10-21.0 to pin
```

## What the importers do

1. Keep only kinds riders name to a driver (hotels, banks, fuel, schools,
   worship, markets, malls, hospitals, stadiums, and restaurants/bars only at
   high confidence). Closed and low-confidence places are dropped.
2. Drop places Kombien already has: the same name, one name inside the other
   close by, or a very similar name close by. Existing places are read from
   `supabase/migrations/*_osm_landmarks.sql`.
3. Keep one place per name per city. A name used far apart (a chain) is
   dropped, since a rider could not say which one.
4. Write the report and a migration that upserts by the dataset's own id
   (`source`, `external_id`), so re-running refreshes a place without
   changing its landmark id and the fares attached to it.

## Review, then apply

1. Read the report: counts, drops with reasons, and a sample to check by eye.
2. Copy the migration(s) you want into `supabase/migrations/` (the dates in
   the file names put them after the schema migration below).
3. `supabase db push --linked --dry-run`, then without `--dry-run`.

**Apply order:** PR #9 (Google Places fallback, once the API key exists) →
PR #10 (add-a-place by riders) → this PR's `20261112000300_place_sources.sql`
→ the generated import migrations. The generated SQL has been checked to parse
as PostgreSQL but has not been run against a database, so use the dry run.

## Credits

The app credits Overture Maps Foundation and GeoNames in Settings → About and
in the terms of use. Merge this PR before loading either dataset.
