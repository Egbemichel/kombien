"""Places from Overture Maps, as a Supabase migration.

Reads Overture's Places theme (public bucket, no account) for Yaoundé and
Douala, keeps the kinds riders give a taxi driver, drops low-confidence and
closed places, drops what Kombien already has, keeps one place per name, and
writes a report and one SQL migration that upserts by Overture id.

    python supabase/tools/overture_places.py                 # fetch + write
    python supabase/tools/overture_places.py --slice s.parquet   # use a saved slice

Needs `pip install duckdb`. Fetching two cities takes a few minutes on a fast
connection (GitHub's runners are fast: see .github/workflows/place-imports.yml).

Data © Overture Maps Foundation. Licences are per source dataset (Meta and
Microsoft: CDLA Permissive 2.0; Foursquare: Apache 2.0; AllThePlaces: CC0).
The app credits Overture in Settings → About and in the terms of use.
"""

from __future__ import annotations

import argparse
import datetime as dt
import sys
import time
import urllib.request
from collections import defaultdict
from pathlib import Path

import place_import as pi

BUCKET = "overturemaps-us-west-2"
CACHE = pi.TOOLS / ".overture-cache"

# Overture's finer category (taxonomy.primary) -> (kind, rank, minimum
# confidence). Kinds are OpenStreetMap-style tags, so the app ranks them the
# way it ranks OSM places. Rank: when one name appears twice, the lower wins.
HOTEL = ("tourism=hotel", 4, 0.6)
SCHOOL = ("amenity=school", 4, 0.6)
WORSHIP = ("amenity=place_of_worship", 4, 0.6)
FOOD = ("amenity=restaurant", 6, 0.85)
DRINK = ("amenity=bar", 6, 0.85)
MARKET = ("amenity=marketplace", 1, 0.5)
KEEP: dict[str, tuple[str, int, float]] = {
    # sleeping
    "hotel": HOTEL, "lodging": HOTEL, "resort": HOTEL, "motel": HOTEL,
    "bed_and_breakfast": HOTEL, "hostel": HOTEL, "guest_house": HOTEL,
    # getting around
    "gas_station": ("amenity=fuel", 4, 0.6),
    "airport": ("aeroway=aerodrome", 1, 0.5),
    "bus_station": ("amenity=bus_station", 1, 0.5),
    "train_station": ("railway=station", 1, 0.5),
    "railway_station": ("railway=station", 1, 0.5),
    # money, post, government
    "bank": ("amenity=bank", 5, 0.6), "bank_or_credit_union": ("amenity=bank", 5, 0.6),
    "post_office": ("amenity=post_office", 4, 0.6),
    "government_office": ("office=government", 4, 0.6),
    "embassy": ("amenity=embassy", 4, 0.6),
    "city_hall": ("amenity=townhall", 2, 0.5), "town_hall": ("amenity=townhall", 2, 0.5),
    "police_department": ("amenity=police", 4, 0.6),
    "courthouse": ("amenity=courthouse", 3, 0.5),
    # health
    "hospital": ("amenity=hospital", 2, 0.5),
    "clinic": ("amenity=clinic", 4, 0.6), "medical_center": ("amenity=clinic", 4, 0.6),
    "pharmacy": ("amenity=pharmacy", 5, 0.6),
    # learning
    "college_university": ("amenity=university", 2, 0.5),
    "university": ("amenity=university", 2, 0.5),
    "school": SCHOOL, "elementary_school": SCHOOL, "middle_school": SCHOOL,
    "high_school": SCHOOL, "private_school": SCHOOL, "public_school": SCHOOL,
    "primary_school": SCHOOL, "secondary_school": SCHOOL,
    # worship
    "religious_organization": WORSHIP, "christian_place_of_worship": WORSHIP,
    "roman_catholic_place_of_worship": WORSHIP, "protestant_place_of_worship": WORSHIP,
    "place_of_worship": WORSHIP, "church": WORSHIP, "cathedral": WORSHIP,
    "mosque": WORSHIP, "islamic_place_of_worship": WORSHIP,
    # shopping that riders name
    "supermarket": ("shop=supermarket", 4, 0.6), "hypermarket": ("shop=supermarket", 4, 0.6),
    "department_store": ("shop=supermarket", 4, 0.6),
    "grocery_store": ("shop=supermarket", 4, 0.7),
    "shopping_mall": ("shop=mall", 2, 0.5), "shopping_center": ("shop=mall", 2, 0.5),
    "marketplace": MARKET, "public_market": MARKET, "farmers_market": MARKET,
    # culture and leisure
    "stadium_arena": ("leisure=stadium", 2, 0.5), "sports_stadium": ("leisure=stadium", 2, 0.5),
    "museum": ("tourism=museum", 3, 0.5),
    "movie_theater": ("amenity=cinema", 4, 0.6), "cinema": ("amenity=cinema", 4, 0.6),
    "historic_site": ("historic=monument", 3, 0.6), "monument": ("historic=monument", 3, 0.6),
    "public_plaza": ("place=square", 2, 0.6), "plaza": ("place=square", 2, 0.6),
    "park": ("leisure=park", 3, 0.6), "zoo": ("tourism=zoo", 3, 0.5),
    # places riders meet at: only the well-established ones
    "restaurant": FOOD, "african_restaurant": FOOD, "french_restaurant": FOOD,
    "bar_and_grill_restaurant": FOOD, "casual_eatery": FOOD, "cafe": FOOD,
    "coffee_shop": FOOD, "buffet_restaurant": FOOD,
    "bar": DRINK, "lounge": DRINK, "dance_club": DRINK, "nightclub": DRINK, "pub": DRINK,
}

CLOSED = {"closed", "permanently_closed", "temporarily_closed"}


def latest_release() -> str:
    url = f"https://{BUCKET}.s3.amazonaws.com/?prefix=release/&delimiter=/"
    with urllib.request.urlopen(url, timeout=60) as r:
        body = r.read().decode()
    releases = sorted(p.split("/")[1] for p in
                      __import__("re").findall(r"<Prefix>(release/[^<]+)/</Prefix>", body))
    if not releases:
        raise SystemExit("could not list Overture releases")
    return releases[-1]


def fetch(release: str, out: Path) -> Path:
    """Saves the two cities' places to a local parquet file (resumable: a
    failed attempt just retries)."""
    import duckdb

    out.parent.mkdir(parents=True, exist_ok=True)
    url = f"s3://{BUCKET}/release/{release}/theme=places/type=place/*"
    where = " OR ".join(
        f"(bbox.xmin BETWEEN {w} AND {e} AND bbox.ymin BETWEEN {s} AND {n})"
        for s, w, n, e in pi.CITIES.values())
    sql = f"""
      COPY (
        SELECT id, names.primary AS name, basic_category,
               taxonomy.primary AS taxonomy_primary, confidence, operating_status,
               list_transform(sources, lambda x: x.dataset) AS datasets,
               (bbox.ymin + bbox.ymax) / 2 AS lat, (bbox.xmin + bbox.xmax) / 2 AS lng
        FROM read_parquet('{url}', hive_partitioning=1)
        WHERE {where}
      ) TO '{out.as_posix()}' (FORMAT parquet)"""
    for attempt in range(1, 6):
        try:
            con = duckdb.connect()
            con.execute("INSTALL httpfs; LOAD httpfs; SET s3_region='us-west-2'; "
                        "SET s3_url_style='path'; SET http_timeout=300; "
                        "SET http_retries=5; SET http_retry_wait_ms=2000;")
            t = time.time()
            con.execute(sql)
            print(f"fetched Overture {release} in {time.time() - t:.0f}s", file=sys.stderr)
            return out
        except Exception as e:  # network: wait and try again
            print(f"  attempt {attempt} failed: {str(e)[:140]}", file=sys.stderr)
            time.sleep(10 * attempt)
    raise SystemExit("Overture unavailable")


def candidates(rows: list[tuple], min_confidence: float) -> tuple[list[dict], dict[str, int]]:
    """Places worth keeping from the raw rows, and why the rest were dropped."""
    dropped: dict[str, int] = defaultdict(int)
    out = []
    for oid, name, basic, tax, conf, status, datasets, lat, lng in rows:
        k = KEEP.get(tax or "") or KEEP.get(basic or "")
        if not k:
            dropped["a kind riders do not name"] += 1
            continue
        kind, rank, kind_min = k
        if status in CLOSED:
            dropped["closed"] += 1
            continue
        if conf is None or conf < max(kind_min, min_confidence):
            dropped["low confidence"] += 1
            continue
        city = pi.city_of(lat, lng)
        cleaned = pi.clean_name(name)
        if not city or not cleaned:
            dropped["not a usable name or outside the cities"] += 1
            continue
        out.append({"external_id": oid, "city": city, "name": cleaned[0],
                    "aliases": cleaned[1], "kind": kind, "rank": rank,
                    "confidence": round(conf, 2), "at": (lat, lng)})
    return out, dropped


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--release", help="Overture release, e.g. 2026-10-21.0 (default: latest)")
    ap.add_argument("--slice", type=Path, help="use a saved parquet slice instead of fetching")
    ap.add_argument("--min-confidence", type=float, default=0.0,
                    help="raise the bar for every kind (each kind has its own minimum)")
    ap.add_argument("--out", type=Path, help="where to write the migration")
    ap.add_argument("--report", type=Path, help="where to write the report (Markdown)")
    args = ap.parse_args()

    import duckdb

    release = args.release or ("saved slice" if args.slice else latest_release())
    path = args.slice or (CACHE / f"places-{release}.parquet")
    if not path.exists():
        fetch(release, path)

    con = duckdb.connect()
    rows = con.execute(
        "SELECT id, name, basic_category, taxonomy_primary, confidence, "
        "operating_status, datasets, lat, lng FROM read_parquet(?) "
        "WHERE name IS NOT NULL", [str(path)]).fetchall()

    found = {"places in Overture for the two cities": len(rows)}
    cands, dropped = candidates(rows, args.min_confidence)
    found["of a kind riders name, open, confident"] = len(cands)

    index = pi.Index(pi.load_existing())
    fresh = []
    for p in cands:
        why = index.duplicate_of(p["city"], p["name"], p["at"])
        if why:
            dropped["already in Kombien (" + why + ")"] += 1
        else:
            fresh.append(p)
    kept = pi.one_per_name(fresh)
    dropped["same name more than once (best kept, or ambiguous)"] = len(fresh) - len(kept)

    text = pi.report(f"Overture Places {release}: what an import would add",
                     found, kept, dict(dropped))
    print(text)

    stamp = dt.date.today()
    out = args.out or (pi.SUPABASE / "migrations" / f"{stamp:%Y%m%d}130000_overture_places.sql")
    out.write_text(pi.migration(
        "overture",
        [f"Overture Maps (release {release})",
         "Data © Overture Maps Foundation. Licences are per source dataset: Meta and",
         "Microsoft under CDLA Permissive 2.0, Foursquare under Apache 2.0,",
         "AllThePlaces under CC0 1.0. See https://docs.overturemaps.org/attribution/"],
        kept), encoding="utf-8")
    print(f"wrote {out}", file=sys.stderr)
    if args.report:
        args.report.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
