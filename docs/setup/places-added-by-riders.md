# Places riders add themselves

When a rider can't find a place, they can add it: **Add this place** on the
not-found card (or **Not there? Add it yourself** under Google's suggestions).
It is saved as a place everyone can find and report fares against.

## How a rider says where it is

Nothing can prove a rider is at the place, so they choose how they know:

| Choice | What is sent | What the server requires |
|---|---|---|
| **I'm here now** | the phone's position and its accuracy | a fresh fix, accurate to **100 m or better**, inside the city |
| **It's near a place I know** | that place, and about how far (50 / 200 / 500 m) | the place exists in the same city and has a location; the new place gets *its* position, marked approximate |
| **I'm not sure where** | the name only | nothing; found by name, not by distance |

The accuracy (or the distance) is saved with the place as `location_accuracy_m`,
so you can tell a 20 m GPS fix from "about 200 m from Carrefour X".

## What the server does (`add_rider_place`)

- Needs a (possibly anonymous) signed-in rider; at most **20 additions a day**
  per rider (shared with places added through Google).
- Refuses names that look personal (email, link, phone number), positions
  outside the city's area (`cities.south/west/north/east`), and weak positions.
- **Never creates a duplicate.** The same name (accents and case ignored) is the
  same place, as in the OpenStreetMap import. A very similar name (similarity
  0.6 or more) within 150 m is too. The rider gets the existing place back.
- Records who claimed it in `place_claims` (not readable through the API) and
  marks the place `source = 'rider'`.

Places are visible to everyone at once. Trust rests on the checks above, the
rate limit, and review: you can see and remove what riders add.

## Reviewing what riders add

```sql
-- newest first, with how sure the position is and how many riders claimed it
select l.created_at::date as day, c.name as city, l.name, l.source,
       l.location_accuracy_m as accuracy_m, count(pc.id) as riders
from public.landmarks l
join public.cities c on c.id = l.city_id
left join public.place_claims pc on pc.landmark_id = l.id
where l.source in ('rider', 'google')
group by l.id, c.name
order by l.created_at desc
limit 100;
```

Fix a bad name with `update public.landmarks set name = '...' where id = '...'`.
A place with fares attached can't be deleted (the fares point at it), so rename
it or fix its position instead; one without fares can be deleted.

## Where it lives

- Database: `supabase/migrations/20261112000200_add_rider_place.sql`
- App: `app/lib/components/k_new_place_sheet.dart`, `app/lib/data/rider_places.dart`
