"""Landmarks from OpenStreetMap, as a Supabase migration.

Fetches named places for each city from the Overpass API, keeps the kinds
riders give a taxi driver (neighbourhoods, carrefours, markets, schools,
hospitals, churches, hotels, fuel stations...), drops shops and small
businesses, removes duplicates, and writes one SQL migration that upserts
them by OpenStreetMap id (so re-running it later refreshes places without
breaking the fares tied to them).

    python supabase/tools/osm_landmarks.py            # fetch + write migration
    python supabase/tools/osm_landmarks.py --cached   # reuse the last fetch

Data © OpenStreetMap contributors, ODbL 1.0. The app credits it in
Settings → About and in the terms of use.
"""

from __future__ import annotations

import argparse
import datetime as dt
import http.client
import json
import math
import re
import sys
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / "tools" / ".osm-cache"
OVERPASS = (
    "https://overpass-api.de/api/interpreter",
    "https://overpass.private.coffee/api/interpreter",
    "https://maps.mail.ru/osm/tools/overpass/api/interpreter",
)

# City: (south, west, north, east). Generous boxes: airports and edges in.
CITIES = {
    "Yaoundé": (3.70, 11.40, 3.98, 11.62),
    "Douala": (3.95, 9.60, 4.15, 9.85),
}

# Kinds kept, with a rank: when one name appears twice in a city, the
# better-known kind wins (a neighbourhood over the shop named after it).
KEEP: dict[str, dict[str, int]] = {
    "place": {"suburb": 1, "quarter": 1, "neighbourhood": 1, "locality": 2,
              "village": 2, "hamlet": 3, "square": 2},
    "aeroway": {"aerodrome": 1, "terminal": 2},
    "amenity": {
        "marketplace": 1, "bus_station": 1, "hospital": 2, "university": 2,
        "townhall": 2, "conference_centre": 2, "college": 3, "school": 4,
        "clinic": 4, "place_of_worship": 4, "fuel": 4, "bank": 5,
        "police": 4, "post_office": 4, "courthouse": 3, "cinema": 4,
        "theatre": 3, "pharmacy": 5, "library": 4, "embassy": 4,
        "taxi": 3, "fire_station": 4, "prison": 4,
    },
    "shop": {"mall": 2, "supermarket": 4, "department_store": 3},
    "tourism": {"hotel": 4, "museum": 3, "attraction": 3, "zoo": 3},
    "leisure": {"stadium": 2, "park": 3, "sports_centre": 4},
    "office": {"government": 4, "diplomatic": 4},
    "railway": {"station": 1, "halt": 3},
    "public_transport": {"station": 2},
    "historic": {"monument": 3, "memorial": 3},
    "healthcare": {"hospital": 2, "clinic": 4},
    "building": {"university": 2, "hospital": 2, "stadium": 2},
}

# Named road nodes count only when they are a junction riders name.
JUNCTION = re.compile(r"\b(carrefour|rond[- ]?point|rondpoint|entr[ée]e|"
                      r"montee|mont[ée]e|descente|pont|gare)\b", re.I)

ALIAS_TAGS = ("alt_name", "short_name", "loc_name", "old_name",
              "official_name", "name:fr", "name:en")

# Names too generic to tell places apart.
GENERIC = re.compile(
    r"^(ecole|école|eglise|église|mosquee|mosquée|pharmacie|hopital|hôpital|"
    r"clinique|station|total|tradex|ola|mrs|neptune|bocom|camwater|eneo|"
    r"chapelle|paroisse|marche|marché|hotel|hôtel|banque|police|"
    r"ecole publique|école publique|ecole maternelle|école maternelle|"
    r"lycee|lycée|college|collège|carrefour|gare|parking|stade)$", re.I)


def fold(s: str) -> str:
    """Lower case, no accents, single spaces: for comparing names."""
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return re.sub(r"\s+", " ", s).strip().lower()


def tidy(name: str) -> str:
    name = re.sub(r"\s+", " ", name).strip(" -,;")
    if name.islower() or name.isupper() and len(name) > 4:
        # "taro essos" / "CARREFOUR MVAN" → "Taro Essos" / "Carrefour Mvan"
        name = " ".join(w if len(w) <= 3 and w.isupper() else w.capitalize()
                        for w in name.split(" "))
    return name


def kind_of(tags: dict, node: bool) -> tuple[str, int] | None:
    for key, kinds in KEEP.items():
        value = tags.get(key)
        if value in kinds:
            return f"{key}={value}", kinds[value]
    # Neighbourhoods mapped as areas: their centre stands for the quarter.
    if tags.get("boundary") == "administrative" and             tags.get("admin_level") in ("9", "10", "11"):
        return "place=quarter", 1
    if tags.get("landuse") == "residential":
        return "place=neighbourhood", 2
    if node and "highway" in tags and JUNCTION.search(tags.get("name", "")):
        return f"highway={tags['highway']}", 2
    return None


def queries(box: tuple[float, float, float, float]) -> list[str]:
    """Small queries, one per tag: busy public servers answer these when
    they time out on one big union."""
    b = ",".join(str(x) for x in box)
    parts = []
    for key, kinds in KEEP.items():
        values = "|".join(kinds)
        parts.append(f'nw["{key}"~"^({values})$"]["name"]({b});')
    parts += [
        f'relation["place"]["name"]({b});',
        f'relation["boundary"="administrative"]["admin_level"~"^(9|10|11)$"]["name"]({b});',
        f'way["landuse"="residential"]["name"]({b});',
        f'node["highway"]["name"~"carrefour|rond|montee|montée|entree|entrée|pont|gare",i]({b});',
    ]
    return [f"[out:json][timeout:90];({p});out tags center;" for p in parts]


def ask(q: str) -> list[dict]:
    body = urllib.parse.urlencode({"data": q}).encode()
    error = None
    for attempt in range(4):
        for server in OVERPASS:  # busy servers answer 429/502/504: next one
            req = urllib.request.Request(
                server, body,
                headers={"User-Agent": "kombien-landmark-import/1.0"})
            try:
                with urllib.request.urlopen(req, timeout=120) as r:
                    return json.loads(r.read())["elements"]
            except (OSError, ValueError, http.client.HTTPException) as e:
                # refused, timed out, cut off mid-answer, or not JSON
                error = e
        time.sleep(15 * (attempt + 1))
    raise SystemExit(f"Overpass unavailable: {error}")


def fetch(city: str, box, cached: bool) -> list[dict]:
    CACHE.mkdir(parents=True, exist_ok=True)
    path = CACHE / f"{fold(city)}.json"
    if cached and path.exists():
        return json.loads(path.read_text(encoding="utf-8"))["elements"]
    seen, elements = set(), []
    for n, q in enumerate(queries(box), 1):
        part = CACHE / f"{fold(city)}.part{n}.json"  # resume after a failure
        if part.exists():
            got = json.loads(part.read_text(encoding="utf-8"))
        else:
            got = ask(q)
            part.write_text(json.dumps(got), encoding="utf-8")
        print(f"  {city} {n}/{len(queries(box))}: {len(got)}", file=sys.stderr)
        for e in got:
            if (e["type"], e["id"]) not in seen:
                seen.add((e["type"], e["id"]))
                elements.append(e)
    path.write_text(json.dumps({"elements": elements}), encoding="utf-8")
    return elements


def from_extract(pbf: Path) -> dict[str, list[dict]]:
    """Every city's elements from an OpenStreetMap extract (Geofabrik's
    .osm.pbf), shaped like Overpass answers. Needs `pip install osmium`."""
    import osmium  # only this path needs it

    def city_of(lat, lon):
        for city, (s_, w, n, e) in CITIES.items():
            if s_ <= lat <= n and w <= lon <= e:
                return city
        return None

    def wanted(tags, node):
        return "name" in tags and kind_of(tags, node) is not None

    out: dict[str, list[dict]] = {c: [] for c in CITIES}
    fp = (osmium.FileProcessor(str(pbf))
          .with_locations()
          .with_areas()
          .with_filter(osmium.filter.KeyFilter("name")))
    for o in fp:
        tags = dict(o.tags)
        if o.is_node():
            if not wanted(tags, True) or not o.location.valid():
                continue
            lat, lon = o.location.lat, o.location.lon
            kind, oid = "node", o.id
        elif o.is_area():
            if not wanted(tags, False):
                continue
            pts = [(n.lat, n.lon) for ring in o.outer_rings() for n in ring
                   if n.location.valid()]
            if not pts:
                continue
            lat = sum(p[0] for p in pts) / len(pts)
            lon = sum(p[1] for p in pts) / len(pts)
            kind = "way" if o.from_way() else "relation"
            oid = o.orig_id()
        elif o.is_way():
            # Named ways that are not closed areas (a stadium drawn as a
            # line is rare): skip, areas cover the rest.
            continue
        else:
            continue
        city = city_of(lat, lon)
        if city:
            out[city].append({"type": kind, "id": oid, "tags": tags,
                              "lat": lat, "lon": lon})
    return out


def metres(a, b) -> float:
    (la1, lo1), (la2, lo2) = a, b
    x = math.radians(lo2 - lo1) * math.cos(math.radians((la1 + la2) / 2))
    y = math.radians(la2 - la1)
    return 6_371_000 * math.hypot(x, y)


def places(elements: list[dict]) -> list[dict]:
    found = []
    for e in elements:
        tags = e.get("tags", {})
        name = tidy(tags.get("name", ""))
        k = kind_of(tags, e["type"] == "node")
        if not k or not 2 <= len(name) <= 120 or GENERIC.match(name):
            continue
        if "lat" in e:
            at = (e["lat"], e["lon"])
        elif "center" in e:
            at = (e["center"]["lat"], e["center"]["lon"])
        else:
            continue
        aliases = sorted({tidy(tags[t]) for t in ALIAS_TAGS if tags.get(t)}
                         - {name})
        found.append({"osm_id": f"{e['type']}/{e['id']}", "name": name,
                      "kind": k[0], "rank": k[1], "at": at,
                      "aliases": [a for a in aliases if 2 <= len(a) <= 120][:5]})

    # One place per name: the best-ranked one. A name used for places far
    # apart (a chain, "École Publique de ...") is kept only if one of them
    # clearly outranks the rest; otherwise riders couldn't tell which.
    by_name = defaultdict(list)
    for p in found:
        by_name[fold(p["name"])].append(p)
    kept = []
    for group in by_name.values():
        group.sort(key=lambda p: (p["rank"], p["osm_id"]))
        best = group[0]
        far = [p for p in group[1:] if metres(p["at"], best["at"]) > 700]
        if far and far[0]["rank"] == best["rank"]:
            continue
        kept.append(best)
    return sorted(kept, key=lambda p: fold(p["name"]))


def sql_text(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


def migration(per_city: dict[str, list[dict]]) -> str:
    today = dt.date.today().isoformat()
    out = [
        "-- Landmarks from OpenStreetMap (generated by",
        "-- supabase/tools/osm_landmarks.py; do not edit by hand).",
        f"-- Fetched {today}. Data © OpenStreetMap contributors, ODbL 1.0.",
        "-- Upserts by osm_id: re-running refreshes names and positions",
        "-- without changing landmark ids, so fares stay attached.",
        "",
    ]
    for city in per_city:
        out.append(f"insert into public.cities (name) values ({sql_text(city)})"
                   " on conflict (name) do nothing;")
    out.append("")
    for city, rows in per_city.items():
        out.append(f"-- {city}: {len(rows)} places")
        out.append("insert into public.landmarks"
                   " (city_id, name, aliases, location, kind, source, osm_id)")
        out.append("select c.id, v.name, v.aliases,")
        out.append("       extensions.st_setsrid(extensions.st_makepoint(v.lng, v.lat), 4326)::extensions.geography,")
        out.append("       v.kind, 'osm', v.osm_id")
        out.append(f"from public.cities c, (values")
        vals = []
        for p in rows:
            al = "array[" + ", ".join(sql_text(a) for a in p["aliases"]) + "]::text[]"
            vals.append(f"  ({sql_text(p['name'])}, {al}, {p['at'][0]:.6f}, "
                        f"{p['at'][1]:.6f}, {sql_text(p['kind'])}, "
                        f"{sql_text(p['osm_id'])})")
        out.append(",\n".join(vals))
        out.append(") as v(name, aliases, lat, lng, kind, osm_id)")
        out.append(f"where c.name = {sql_text(city)}")
        out.append("on conflict (osm_id) do update set name = excluded.name,")
        out.append("  aliases = excluded.aliases, location = excluded.location,")
        out.append("  kind = excluded.kind;")
        out.append("")
    return "\n".join(out)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--cached", action="store_true")
    ap.add_argument("--pbf", type=Path,
                    help="read an OpenStreetMap extract instead of Overpass")
    ap.add_argument("--out", type=Path)
    args = ap.parse_args()
    per_city = {}
    extract = from_extract(args.pbf) if args.pbf else None
    for city, box in CITIES.items():
        rows = places(extract[city] if extract is not None
                      else fetch(city, box, args.cached))
        per_city[city] = rows
        kinds = defaultdict(int)
        for p in rows:
            kinds[p["kind"]] += 1
        top = sorted(kinds.items(), key=lambda kv: -kv[1])[:8]
        print(f"{city}: {len(rows)} places  {top}")
    out = args.out or (ROOT / "migrations" /
                       f"{dt.date.today():%Y%m%d}120000_osm_landmarks.sql")
    out.write_text(migration(per_city), encoding="utf-8")
    print(f"wrote {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
