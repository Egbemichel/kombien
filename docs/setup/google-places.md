# Google place suggestions

When a rider searches for a place Kombien doesn't have, the app can ask Google
Places for suggestions. The rider picks the right one, names it in their own
words, and it becomes a place everyone can report fares against.

It is **off until a key is set**. Without a key the app behaves exactly as
before and never contacts Google.

## How it works

1. Search Kombien's own places first (the city saved on the phone, instantly).
2. Nothing found, rider stops typing for 0.6 s, phone online: look up places
   other riders already added (`find_rider_places`, our own database, free).
3. Still nothing: ask Google Autocomplete (New), restricted to Cameroon and the
   rider's city. Show up to 5 suggestions with Google's credit ("Google Maps").
4. Rider picks one and confirms a name. The name starts as what they typed.
5. `add_google_place` saves a landmark named with **the rider's words**, tied to
   the **Google place ID**, or reuses the one already linked to that place. The
   rider reports against it like any other place; so does everyone after them.

## What is kept, and why

Google's policy allows a **place ID to be stored indefinitely**, but not its
names or addresses, and coordinates only for 30 days. So Kombien keeps the ID
plus the rider's own words, and nothing else from Google. Places added this way
have no coordinates of their own (so no "nearest first", and they are not in
the offline city packs; the phone remembers the ones it added).

Google's text is only shown while the rider chooses, never saved. If this
design changes, re-read Google's
[Places API policies](https://developers.google.com/maps/documentation/places/web-service/policies)
and the Maps Platform Service Specific Terms first.

## Setup (once, by the project owner)

1. In Google Cloud, create a project and **enable Places API (New)**.
2. Attach a billing account. The free allowance covers 10,000 Autocomplete
   requests a month; see Google's pricing page for the current rates.
3. Create an **API key**, then restrict it:
   - Application restriction: **Websites** → `https://kombien.egbemichel.tech/*`
   - API restriction: **Places API (New)** only
4. **Set a hard daily quota** on "Autocomplete requests" (Quotas & system limits
   in the console) and a **budget alert**. The quota is what stops a surprise
   bill: when it is reached Google answers with an error and the app quietly
   falls back to the usual "Couldn't find that place" card.
5. Add the key to the repository as the secret **`GOOGLE_PLACES_KEY`**
   (Settings → Secrets and variables → Actions). The next deploy of the app
   includes it (`--dart-define=GOOGLE_PLACES_KEY=...`).

The key ships inside the app, like Supabase's publishable key, so restriction
and quota are its protection, not secrecy.

## Attribution

Where Google's suggestions are shown, the app shows the text credit
**Google Maps** (Roboto, 12 sp, grey, not translated). Google asks for its logo
"whenever possible"; the text form is allowed where space is limited. To use the
logo, download it from the policies page above and replace `GoogleAttribution`
in `app/lib/components/k_add_place_sheet.dart`.

## Database

`supabase/migrations/20261112000100_google_places.sql`: `landmarks` gains
`google_place_id` (and no longer requires a location), `place_claims` records
who added what (not readable through the API), `add_google_place()` and
`find_rider_places()`. `city_landmarks()` skips places without a location.
