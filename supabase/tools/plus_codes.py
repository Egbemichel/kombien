"""Plus Codes (Open Location Code) to a latitude and longitude.

Google Maps shows a place's Plus Code when you search for it ("VGQH+XQ5,
Yaoundé" or the full "6FMHVGQH+XV"). A code is a point-in-a-grid, not
anyone's data, and the algorithm is open (https://github.com/google/open-location-code).
This is a small decoder: full codes, and short codes completed from a
reference point (the city the place is in).
"""

from __future__ import annotations

import re

ALPHABET = "23456789CFGHJMPQRVWX"
SEPARATOR = "+"
PAIR_LEN = 10          # digits in pairs, before the 4 x 5 grid refinement
GRID_ROWS, GRID_COLS = 5, 4


class PlusCodeError(ValueError):
    pass


def _clean(code: str) -> str:
    return code.strip().upper().replace(" ", "")


def is_short(code: str) -> bool:
    c = _clean(code)
    return SEPARATOR in c and c.index(SEPARATOR) < 8


def decode(code: str) -> tuple[float, float, float]:
    """(lat, lng, half_size_in_degrees) of the centre of a FULL code's cell."""
    c = _clean(code)
    if c.count(SEPARATOR) != 1 or c.index(SEPARATOR) != 8:
        raise PlusCodeError(f"not a full Plus Code: {code!r}")
    digits = c.replace(SEPARATOR, "").rstrip("0")
    if len(digits) < 2 or any(ch not in ALPHABET for ch in digits):
        raise PlusCodeError(f"bad characters in {code!r}")
    lat, lng = -90.0, -180.0
    pair = digits[:PAIR_LEN]
    res = 20.0
    for i in range(0, len(pair), 2):
        lat += ALPHABET.index(pair[i]) * res
        lng += ALPHABET.index(pair[i + 1]) * res
        last = res
        res /= 20.0
    lat_size = lng_size = last
    for ch in digits[PAIR_LEN:]:
        v = ALPHABET.index(ch)
        lat_size /= GRID_ROWS
        lng_size /= GRID_COLS
        lat += (v // GRID_COLS) * lat_size
        lng += (v % GRID_COLS) * lng_size
    return lat + lat_size / 2, lng + lng_size / 2, max(lat_size, lng_size) / 2


def _encode_prefix(lat: float, lng: float, digits: int) -> str:
    lat = min(max(lat, -90.0), 90.0) + 90.0
    lng = ((lng + 180.0) % 360.0)
    out = []
    res = 20.0
    for _ in range(digits // 2):
        out.append(ALPHABET[int(lat // res)])
        out.append(ALPHABET[int(lng // res)])
        lat %= res
        lng %= res
        res /= 20.0
    return "".join(out)


def recover(short: str, ref_lat: float, ref_lng: float) -> str:
    """The full code for a short code, choosing the one nearest the reference."""
    s = _clean(short)
    if s.count(SEPARATOR) != 1:
        raise PlusCodeError(f"not a Plus Code: {short!r}")
    pad = 8 - s.index(SEPARATOR)
    if pad <= 0:
        return s
    prefix = _encode_prefix(ref_lat, ref_lng, pad)
    lat, lng, _ = decode(prefix + s)
    # The cell the reference falls in may not be the nearest one: step by one
    # cell of the prefix's size when the answer is more than half a cell away.
    cell = 20.0 ** (2 - pad / 2)
    if lat - ref_lat > cell / 2:
        lat -= cell
    elif lat - ref_lat < -cell / 2:
        lat += cell
    if lng - ref_lng > cell / 2:
        lng -= cell
    elif lng - ref_lng < -cell / 2:
        lng += cell
    return _encode_prefix(lat, lng, pad) + s


def to_point(code: str, ref_lat: float | None = None,
             ref_lng: float | None = None) -> tuple[float, float]:
    """(lat, lng) for a full code, or a short one given a reference point."""
    # "VGQH+XQ5, Nv Rte Omnisport, Yaoundé" -> the code is the first word.
    c = _clean(re.split(r"[,\s]+", code.strip())[0])
    if is_short(c):
        if ref_lat is None or ref_lng is None:
            raise PlusCodeError(f"{code!r} is a short code: a reference point is needed")
        c = recover(c, ref_lat, ref_lng)
    lat, lng, _ = decode(c)
    return round(lat, 6), round(lng, 6)
