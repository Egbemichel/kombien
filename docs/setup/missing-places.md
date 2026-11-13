# Finding and adding the places riders look for

Riders search for a place, find nothing, and Kombien notes the searched words
(anonymously: words, city, how many times, no rider identity). This is the
routine that turns that list into places in the app.

## 1. What is missing

```bash
python supabase/tools/missing_places.py            # the 40 most searched
python supabase/tools/missing_places.py --top 100 --out wanted.csv
```

It prints the list (most searched first, without anything the database now
has) and writes `missing_places.csv`. Needs `supabase` logged in and linked,
like `supabase db push`.

## 2. Look each place up

For each row, search the place on Google Maps yourself and copy its **Plus
Code** (it shows under the name, like `VGQH+XQ5`; the full form
`6FMHVGQH+XV` also works). Put it in the `plus_code` column. Fix `name` if the
search was a misspelling, and set `kind` (market, supermarket, neighbourhood,
junction, school, hospital, hotel, bank, church, mosque, fuel, restaurant,
other) and `aliases` (other names, separated by `;`) if you know them. Rows
without a code are skipped, so fill in as many as you like and leave the rest.

Google's terms don't allow copying its data in bulk: look places up one by
one as you would normally. A place's position is a plain fact; this is not a
scraper.

## 3. Turn the file into a migration

```bash
python supabase/tools/places_from_plus_codes.py missing_places.csv
```

It decodes each Plus Code, checks the point is inside the city, compares with
everything already in the **live** database (same name, one name inside the
other close by, a very similar name close by), and writes
`supabase/migrations/<date>_manual_places.sql` plus a list of what it skipped
and why. The migration saves places as `source = 'manual'`, is safe to run
twice, and clears the answered searches from the missing list.

## 4. Review and apply

Read the printed list, open the migration, then:

```bash
supabase db push --linked --dry-run
supabase db push --linked
```

Commit the migration file so the repository matches the database. Phones pick
up the new places the next time the app opens.

## Notes

- Tests: `python -m unittest discover -s supabase/tools/tests`.
- Riders can also add a place themselves from where they stand ("Not there?
  Add it yourself"); see [places-added-by-riders.md](places-added-by-riders.md).
