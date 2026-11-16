"""The places riders searched for and did not find, most wanted first.

    python supabase/tools/missing_places.py                 # top 40, writes missing_places.csv
    python supabase/tools/missing_places.py --top 100 --out wanted.csv

Reads two lists from the linked database and merges them:

  - `search_misses`: what riders searched for and did not find (typed words,
    city, how many times; no rider identity), and
  - the places riders sent with "Tell us about it" (`place_requests`, kind
    suggestion): the name, where they said it is, and how many riders sent it.

It drops what the database now has, and writes a CSV you fill in: put each place's Plus Code (search it on Google Maps; the code
shows under the name, like "VGQH+XQ5") in the `plus_code` column, fix `name`
if the search was a misspelling, and run:

    python supabase/tools/places_from_plus_codes.py missing_places.csv

See docs/setup/missing-places.md.
"""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

import dbq

SQL = """
with wanted as (
  select m.query, m.city, m.times::int as times, m.last_seen,
         'search' as src, '' as note
  from public.search_misses m
  union all
  select lower(r.name), r.city, count(distinct r.user_id)::int, max(r.created_at),
         'rider',
         coalesce(string_agg(distinct r.note, ' | ') filter (where r.note is not null), '')
  from public.place_requests r
  where r.kind = 'suggestion' and r.status = 'open'
  group by lower(r.name), r.city
)
select w.query, w.city, sum(w.times)::int as times, max(w.last_seen)::date as last_seen,
       string_agg(distinct w.src, '+') as source,
       coalesce(string_agg(distinct nullif(w.note, ''), ' | '), '') as note
from wanted w
where not exists (
  select 1 from public.landmarks l
  where public.landmark_search_text(l.name, l.aliases)
        like '%%' || lower(extensions.unaccent('extensions.unaccent'::regdictionary, w.query)) || '%%'
)
group by w.query, w.city
order by times desc, last_seen desc
limit %d
"""

# source: "search" (searched, found nothing), "rider" (sent with Tell us about
# it), or "search+rider". note: where the riders said it is.
COLUMNS = ["query", "city", "times", "last_seen", "source", "note",
           "name", "plus_code", "kind", "aliases"]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--top", type=int, default=40)
    ap.add_argument("--out", type=Path, default=Path("missing_places.csv"))
    args = ap.parse_args()

    found = dbq.rows(SQL % max(1, min(args.top, 500)))
    if not found:
        print("Nothing missing: every search that found nothing has been added.")
        return 0

    print(f"{'times':>5}  {'city':<8} {'from':<12} query")
    for r in found:
        extra = f"   <- {r['note']}" if r.get("note") else ""
        print(f"{r['times']:>5}  {(r['city'] or '?'):<8} {r['source']:<12} {r['query']}{extra}")

    with args.out.open("w", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS)
        w.writeheader()
        for r in found:
            w.writerow({
                "query": r["query"], "city": r["city"] or "Yaoundé",
                "times": r["times"], "last_seen": r["last_seen"],
                "source": r["source"], "note": r.get("note", ""),
                "name": r["query"].title(), "plus_code": "", "kind": "", "aliases": "",
            })
    print(f"\nWrote {args.out}: fill in plus_code (and fix name/kind), then run "
          f"places_from_plus_codes.py on it.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
