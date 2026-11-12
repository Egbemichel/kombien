"""Shared pieces of the open-dataset place imports (Overture, GeoNames).

An import turns a dataset's places into landmarks Kombien does not have yet:

  1. keep only the kinds riders give a taxi driver (done per dataset);
  2. drop what Kombien already has: the same name, or a very similar name
     right there (read from the OpenStreetMap migration in this repository);
  3. keep one place per name per city, the best-ranked one (two branches of a
     chain with the same name could not be told apart by a rider);
  4. write a report and one SQL migration that upserts by the dataset's own id.

Nothing here touches a database: the migration is reviewed, then applied with
`supabase db push`.
"""

from __future__ import annotations

import datetime as dt
import math
import re
import sys
from collections import defaultdict
from difflib import SequenceMatcher
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
SUPABASE = TOOLS.parent
sys.path.insert(0, str(TOOLS))

# The OSM importer already has the name helpers and the city boxes; share them.
from osm_landmarks import CITIES, GENERIC, fold, metres, sql_text, tidy  # noqa: E402

__all__ = ["CITIES", "GENERIC", "fold", "metres", "sql_text", "tidy"]

# Names that are an advert or contact detail, not a place riders name.
NOISE = re.compile(r"(\d{6,})|(@)|(https?:)|(www\.)|(officiel)|(\bwhatsapp\b)", re.I)


def city_of(lat: float, lng: float) -> str | None:
    for city, (s, w, n, e) in CITIES.items():
        if s <= lat <= n and w <= lng <= e:
            return city
    return None


def clean_name(raw: str | None) -> tuple[str, list[str]] | None:
    """(name, aliases) from a dataset's name, or None when it is not a usable
    place name. "A / B" (two languages) becomes name A with alias B."""
    if not raw:
        return None
    # "Hotel X, Bastos, Yaoundé, Cameroon": the address tail is not the name.
    raw = re.sub(r",\s*[^,]*\b(yaound[ée]|douala|cameroun|cameroon)\b.*$", "",
                 raw, flags=re.I)
    parts = [p for p in re.split(r"\s+/\s+|\s+\|\s+", raw) if p.strip()]
    name = tidy(parts[0]) if parts else ""
    if not 2 <= len(name) <= 80 or GENERIC.match(name) or NOISE.search(name):
        return None
    aliases = []
    for p in parts[1:3]:
        a = tidy(p)
        if 2 <= len(a) <= 120 and not NOISE.search(a) and fold(a) != fold(name):
            aliases.append(a)
    return name, aliases


# ---------------------------------------------------------------- existing

_TUPLE = re.compile(
    r"^\s*\('((?:[^']|'')*)',\s*array\[(.*?)\]::text\[\],\s*"
    r"(-?[\d.]+),\s*(-?[\d.]+),", re.M)
_QUOTED = re.compile(r"'((?:[^']|'')*)'")


def load_existing(migrations: Path = SUPABASE / "migrations") -> list[dict]:
    """What Kombien already has, from the OpenStreetMap import migration(s):
    name, aliases and position of every place."""
    out = []
    for path in sorted(migrations.glob("*_osm_landmarks.sql")):
        for m in _TUPLE.finditer(path.read_text(encoding="utf-8")):
            lat, lng = float(m.group(3)), float(m.group(4))
            city = city_of(lat, lng)
            if not city:
                continue
            aliases = [a.replace("''", "'") for a in _QUOTED.findall(m.group(2))]
            out.append({"city": city, "name": m.group(1).replace("''", "'"),
                        "aliases": aliases, "at": (lat, lng)})
    return out


class Index:
    """Existing places, searchable by name and by position."""

    CELL = 0.0015  # degrees: about 165 m

    def __init__(self, places: list[dict]):
        self.names: dict[str, set[str]] = defaultdict(set)  # city -> folded names
        self.cells: dict[tuple[str, int, int], list[tuple[str, tuple[float, float]]]] = \
            defaultdict(list)
        for p in places:
            for name in [p["name"], *p["aliases"]]:
                self.names[p["city"]].add(fold(name))
            self.cells[self._key(p["city"], p["at"])].append((fold(p["name"]), p["at"]))

    def _key(self, city, at):
        return (city, int(at[0] / self.CELL), int(at[1] / self.CELL))

    def duplicate_of(self, city: str, name: str, at) -> str | None:
        """Why this place is already known, or None."""
        f = fold(name)
        if f in self.names[city]:
            return "same name"
        ky, kx = self._key(city, at)[1:]
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                for other, pos in self.cells.get((city, ky + dy, kx + dx), ()):
                    d = metres(at, pos)
                    if d > 150:
                        continue
                    short, long_ = sorted((f, other), key=len)
                    if len(short) >= 5 and short in long_ and d <= 120:
                        return "one name inside the other, close by"
                    if SequenceMatcher(None, f, other).ratio() >= 0.82:
                        return "very similar name, close by"
        return None


# ---------------------------------------------------------------- choosing

def one_per_name(places: list[dict]) -> list[dict]:
    """One place per name per city: the best ranked, then the most confident.
    A name used for places far apart at the same rank (a chain's branches) is
    dropped: a rider could not tell which one is meant."""
    by_name: dict[tuple[str, str], list[dict]] = defaultdict(list)
    for p in places:
        by_name[(p["city"], fold(p["name"]))].append(p)
    kept = []
    for group in by_name.values():
        group.sort(key=lambda p: (p["rank"], -p.get("confidence", 0), p["external_id"]))
        best = group[0]
        far = [p for p in group[1:] if metres(p["at"], best["at"]) > 700]
        if far and far[0]["rank"] == best["rank"]:
            continue
        kept.append(best)
    return sorted(kept, key=lambda p: (p["city"], fold(p["name"])))


# ---------------------------------------------------------------- writing

def migration(source: str, header: list[str], places: list[dict]) -> str:
    """One SQL migration: upserts the places by (source, external_id), and
    skips any whose name a place in that city already has (the table keeps one
    place per name, and riders may have added one since this was generated)."""
    today = dt.date.today().isoformat()
    out = [f"-- Places from {header[0]} (generated by the import tool; do not",
           "-- edit by hand). Re-running refreshes names and positions without",
           "-- changing landmark ids, so fares stay attached.",
           f"-- Generated {today}.", *[f"-- {h}" for h in header[1:]], ""]
    by_city: dict[str, list[dict]] = defaultdict(list)
    for p in places:
        by_city[p["city"]].append(p)
    for city, rows in by_city.items():
        out += [f"-- {city}: {len(rows)} places",
                "insert into public.landmarks",
                "  (city_id, name, aliases, location, kind, source, external_id)",
                "select c.id, v.name, v.aliases,",
                "       extensions.st_setsrid(extensions.st_makepoint(v.lng, v.lat), 4326)::extensions.geography,",
                f"       v.kind, {sql_text(source)}, v.external_id",
                "from public.cities c, (values"]
        vals = []
        for p in rows:
            al = "array[" + ", ".join(sql_text(a) for a in p["aliases"]) + "]::text[]"
            vals.append(f"  ({sql_text(p['name'])}, {al}, {p['at'][0]:.6f}, "
                        f"{p['at'][1]:.6f}, {sql_text(p['kind'])}, "
                        f"{sql_text(p['external_id'])})")
        out += [",\n".join(vals),
                ") as v(name, aliases, lat, lng, kind, external_id)",
                f"where c.name = {sql_text(city)}",
                "  and not exists (select 1 from public.landmarks l",
                "                  where l.city_id = c.id and l.name = v.name",
                f"                    and (l.source <> {sql_text(source)} or l.external_id <> v.external_id))",
                "on conflict (source, external_id) where external_id is not null",
                "do update set name = excluded.name, aliases = excluded.aliases,",
                "  location = excluded.location, kind = excluded.kind;", ""]
    return "\n".join(out)


def report(title: str, found: dict, kept: list[dict], dropped: dict[str, int]) -> str:
    """A short Markdown report: what was found, what was dropped and why, and
    what would be added, by city and kind, with a sample to eyeball."""
    lines = [f"# {title}", ""]
    lines += ["| step | places |", "|---|---:|"]
    for k, v in found.items():
        lines.append(f"| {k} | {v} |")
    for k, v in sorted(dropped.items(), key=lambda kv: -kv[1]):
        lines.append(f"| dropped: {k} | {v} |")
    lines.append(f"| **to add** | **{len(kept)}** |")
    by = defaultdict(lambda: defaultdict(int))
    for p in kept:
        by[p["city"]][p["kind"]] += 1
    for city, kinds in by.items():
        lines += ["", f"## {city}: {sum(kinds.values())} places", "",
                  "| kind | places |", "|---|---:|"]
        for k, v in sorted(kinds.items(), key=lambda kv: -kv[1]):
            lines.append(f"| {k} | {v} |")
    lines += ["", "## A sample to check by eye", ""]
    step = max(1, len(kept) // 60)
    for p in kept[::step][:60]:
        lines.append(f"- {p['city']}: **{p['name']}** ({p['kind']}, "
                     f"{p.get('confidence', '')})")
    return "\n".join(lines) + "\n"
