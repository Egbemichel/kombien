"""Places from GeoNames, as a Supabase migration.

Reads GeoNames' Cameroon file (a ~600 KB download, no account), keeps the
settlements and the few kinds of landmark it has in Yaoundé and Douala, drops
what Kombien already has, and writes a report and one SQL migration that
upserts by GeoNames id.

    python supabase/tools/geonames_places.py              # download + write
    python supabase/tools/geonames_places.py --file CM.txt   # use a saved file

An honest note: GeoNames has only a couple of hundred entries inside the two
cities, mostly outlying villages. It adds little next to OpenStreetMap and
Overture; the report says exactly how much.

Data from GeoNames (https://www.geonames.org), CC BY 4.0. The app credits it
in Settings → About and in the terms of use.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import io
import sys
import urllib.request
import zipfile
from collections import defaultdict
from pathlib import Path

import place_import as pi

URL = "https://download.geonames.org/export/dump/CM.zip"
CACHE = pi.TOOLS / ".geonames-cache"

# (feature class, feature code) -> (kind, rank). GeoNames' own codes:
# https://www.geonames.org/export/codes.html
KEEP: dict[tuple[str, str], tuple[str, int]] = {
    ("P", "PPLX"): ("place=neighbourhood", 1),   # section of a populated place
    ("P", "PPL"): ("place=locality", 3),         # populated place
    ("S", "HTL"): ("tourism=hotel", 4),
    ("S", "UNIV"): ("amenity=university", 2),
    ("S", "AIRP"): ("aeroway=aerodrome", 1),
    ("S", "HSP"): ("amenity=hospital", 2),
    ("S", "STDM"): ("leisure=stadium", 2),
    ("S", "MKT"): ("amenity=marketplace", 1),
    ("S", "CH"): ("amenity=place_of_worship", 4),
    ("S", "MSQE"): ("amenity=place_of_worship", 4),
    ("S", "SCH"): ("amenity=school", 4),
    ("S", "RSTN"): ("railway=station", 1),
    ("S", "PO"): ("amenity=post_office", 4),
    ("S", "MUS"): ("tourism=museum", 3),
    ("S", "BANK"): ("amenity=bank", 5),
    ("S", "CTHSE"): ("amenity=courthouse", 3),
}


def read_file(path: Path | None) -> str:
    if path:
        return path.read_text(encoding="utf-8")
    CACHE.mkdir(parents=True, exist_ok=True)
    cached = CACHE / "CM.txt"
    if not cached.exists():
        with urllib.request.urlopen(URL, timeout=120) as r:
            data = r.read()
        with zipfile.ZipFile(io.BytesIO(data)) as z:
            cached.write_bytes(z.read("CM.txt"))
    return cached.read_text(encoding="utf-8")


def candidates(text: str) -> tuple[list[dict], dict[str, int], int]:
    dropped: dict[str, int] = defaultdict(int)
    out, total = [], 0
    for r in csv.reader(io.StringIO(text), delimiter="\t", quoting=csv.QUOTE_NONE):
        gid, name, alts = r[0], r[1], r[3]
        lat, lng, fclass, fcode = float(r[4]), float(r[5]), r[6], r[7]
        city = pi.city_of(lat, lng)
        if not city:
            continue
        total += 1
        k = KEEP.get((fclass, fcode))
        if not k:
            dropped["rivers, creeks, regions and the like"] += 1
            continue
        cleaned = pi.clean_name(name)
        if not cleaned:
            dropped["not a usable name"] += 1
            continue
        aliases = list(cleaned[1])
        for a in alts.split(","):
            c = pi.clean_name(a)
            if c and pi.fold(c[0]) != pi.fold(cleaned[0]) and c[0] not in aliases:
                aliases.append(c[0])
            if len(aliases) >= 3:
                break
        out.append({"external_id": gid, "city": city, "name": cleaned[0],
                    "aliases": aliases[:3], "kind": k[0], "rank": k[1],
                    "at": (lat, lng)})
    return out, dropped, total


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", type=Path, help="a saved CM.txt instead of downloading")
    ap.add_argument("--out", type=Path, help="where to write the migration")
    ap.add_argument("--report", type=Path, help="where to write the report (Markdown)")
    args = ap.parse_args()

    cands, dropped, total = candidates(read_file(args.file))
    found = {"GeoNames entries inside the two cities": total,
             "of a kind riders name": len(cands)}

    index = pi.Index(pi.load_existing())
    fresh = []
    for p in cands:
        why = index.duplicate_of(p["city"], p["name"], p["at"])
        if why:
            dropped["already in Kombien (" + why + ")"] += 1
        else:
            fresh.append(p)
    kept = pi.one_per_name(fresh)
    dropped["same name more than once"] = len(fresh) - len(kept)

    text = pi.report("GeoNames: what an import would add", found, kept, dict(dropped))
    print(text)

    out = args.out or (pi.SUPABASE / "migrations" /
                       f"{dt.date.today():%Y%m%d}140000_geonames_places.sql")
    out.write_text(pi.migration(
        "geonames",
        ["GeoNames (https://www.geonames.org)",
         "Data from GeoNames, CC BY 4.0."], kept), encoding="utf-8")
    print(f"wrote {out}", file=sys.stderr)
    if args.report:
        args.report.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
