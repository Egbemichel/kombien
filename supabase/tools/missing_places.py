"""The places riders searched for and did not find, most wanted first.

    python supabase/tools/missing_places.py                 # top 40, writes missing_places.csv
    python supabase/tools/missing_places.py --top 100 --out wanted.csv

Reads `search_misses` (typed words, city, how many times: no rider identity)
from the linked database, drops what the database now has, and writes a CSV
you fill in: put each place's Plus Code (search it on Google Maps; the code
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
select m.query, m.city, m.times, m.last_seen::date as last_seen
from public.search_misses m
where not exists (
  select 1 from public.landmarks l
  where public.landmark_search_text(l.name, l.aliases)
        like '%%' || lower(extensions.unaccent('extensions.unaccent'::regdictionary, m.query)) || '%%'
)
order by m.times desc, m.last_seen desc
limit %d
"""

COLUMNS = ["query", "city", "times", "last_seen", "name", "plus_code", "kind", "aliases"]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--top", type=int, default=40)
    ap.add_argument("--out", type=Path, default=Path("missing_places.csv"))
    args = ap.parse_args()

    found = dbq.rows(SQL % max(1, min(args.top, 500)))
    if not found:
        print("Nothing missing: every search that found nothing has been added.")
        return 0

    print(f"{'times':>5}  {'city':<8} query")
    for r in found:
        print(f"{r['times']:>5}  {(r['city'] or '?'):<8} {r['query']}")

    with args.out.open("w", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS)
        w.writeheader()
        for r in found:
            w.writerow({
                "query": r["query"], "city": r["city"] or "Yaoundé",
                "times": r["times"], "last_seen": r["last_seen"],
                "name": r["query"].title(), "plus_code": "", "kind": "", "aliases": "",
            })
    print(f"\nWrote {args.out}: fill in plus_code (and fix name/kind), then run "
          f"places_from_plus_codes.py on it.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
