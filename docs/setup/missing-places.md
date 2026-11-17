# Finding and adding the places riders look for

Two things feed the list of places to add:

- **Searches that found nothing**, noted anonymously (words, city, how many
  times, no rider identity).
- **"Tell us about it"**: a rider who is *not* at the place names it and says
  where it is ("behind the Messassi market"). It is saved for you (kept on the
  phone until it can be sent). A rider who *is* there and has location on
  adds it at once, where they stand (see
  [places-added-by-riders.md](places-added-by-riders.md)); those never need you.

This is the routine that turns the list into places in the app, and then tells
the riders who asked.

## 1. What is missing

```bash
python supabase/tools/missing_places.py            # the 40 most searched
python supabase/tools/missing_places.py --top 100 --out wanted.csv
```

It prints the list (most wanted first, without anything the database now
has) and writes `missing_places.csv`. Each row says where it came from
(`search`, `rider`, or both) and, for riders, the **note** on where the place
is. Needs `supabase` logged in and linked, like `supabase db push`.

## 2. Look each place up

For each row, search the place on Google Maps yourself and copy its **Plus
Code** (it shows under the name, like `VGQH+XQ5`; the full form
`6FMHVGQH+XV` also works). Put it in the `plus_code` column. Fix `name` if the
search was a misspelling (list several spellings the place answers in `query`,
separated by `;`), and set `kind` (market, supermarket, neighbourhood,
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
twice, clears the answered searches from the missing list, and **links the
riders' requests to the new place** so they are told (next section).

## 4. Review and apply

Read the printed list, open the migration, then:

```bash
supabase db push --linked --dry-run
supabase db push --linked
```

Commit the migration file so the repository matches the database. Phones pick
up the new places the next time the app opens.

## 5. The riders are told

Riders who turned notifications on get **"<place> is now on Kombien"**: the ones
who searched for it (only riders with notifications on have their searches
kept, tied to their phone's anonymous ID; everyone else stays anonymous) and the
ones who used "Tell us about it". The message reminds them they looked for it,
that it is on the app now, and that Kombien is working tirelessly to add more
places. Several places become one notification.

It goes out with the daily 08:30 (Cameroon) reminder job, or straight away if you
run the function by hand (needs the `NOTIFY_SECRET`):

```bash
curl -X POST "$SUPABASE_URL/functions/v1/notify-unlocked"   -H "apikey: $KEY" -H "Authorization: Bearer $KEY"   -H "x-notify-secret: $NOTIFY_SECRET" -H "Content-Type: application/json"   -d '{"job":"places"}'
```

Never at night, never a second notification the same day. A place added any
other way (an OpenStreetMap re-import, a rider adding it) also answers requests
that it matches by name, as long as it was added after the request.
Notifications turned off: the rider's searches are forgotten at once.

Look at what is waiting:

```sql
select kind, name, note, city, status, created_at::date
from public.place_requests where status = 'open' order by created_at desc;
```

## Notes

- Tests: `python -m unittest discover -s supabase/tools/tests`.
- Riders can also add a place themselves from where they stand ("Not there?
  Add it yourself"); see [places-added-by-riders.md](places-added-by-riders.md).
