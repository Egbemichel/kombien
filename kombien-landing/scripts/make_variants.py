"""Makes colour variants of the two cut-out characters (sprites/girl.png, boy.png).

The illustration stays exactly as the app draws it; only the colours of the
clothes, shoes, bag and skin tone change, region by region, so a crowd of them
reads as different people instead of copies.

Writes sprites/girl-1..5.png and boy-1..5.png (variant 1 is the original).
Run from kombien-landing/: python scripts/make_variants.py [contact_sheet.png]
"""
import sys
from pathlib import Path

import cv2
import numpy as np

SPR = Path(__file__).resolve().parents[1] / "sprites"


def hue(deg):
    """Degrees (0-360) to OpenCV's 0-179."""
    return (deg % 360) / 2


# Where each garment lives, in OpenCV HSV. Skin is told apart from the coral
# jacket and the orange trousers by being darker (V < 170).
REGIONS = {
    "girl": {
        "hoodie": dict(h=[(118, 140)], s=(55, 255), v=(60, 255)),
        "pants": dict(h=[(12, 24)], s=(150, 255), v=(170, 255)),
        "shoes": dict(h=[(0, 6), (172, 179)], s=(90, 255), v=(150, 255), below=0.70),  # not her mouth
        "bag": dict(h=[(78, 96)], s=(100, 255), v=(60, 255)),
        "skin": dict(h=[(4, 22)], s=(80, 210), v=(55, 168)),
    },
    "boy": {
        "jacket": dict(h=[(0, 8), (172, 179)], s=(100, 255), v=(170, 255)),
        "bag": dict(h=[(12, 24)], s=(150, 255), v=(170, 255)),
        "shoes": dict(h=[(78, 96)], s=(90, 255), v=(60, 255)),
        "pants": dict(h=[(0, 179)], s=(0, 85), v=(0, 110), below=0.49),  # dark trousers
        "skin": dict(h=[(4, 22)], s=(80, 210), v=(55, 168), above=0.49),
    },
}

# Each rule: hue in degrees (None keeps it), saturation (multiplier, or ("set", n)),
# value multiplier. The shading inside each garment survives because only the
# base tone moves.
KEEP = None
VARIANTS = {
    "girl": [
        {},
        dict(hoodie=(172, 1.0, 1.0), pants=(222, ("set", 150), .52), shoes=(36, 1.0, 1.0), bag=(356, 1.0, 1.0), skin=(None, 1.0, 1.4)),
        dict(hoodie=(348, .9, 1.0), pants=(208, .5, .95), shoes=(258, .9, .9), bag=(36, 1.0, 1.0), skin=(None, 1.0, .85)),
        dict(hoodie=(42, 1.0, 1.0), pants=(148, .8, .6), shoes=(172, 1.0, 1.0), bag=(258, 1.0, 1.0), skin=(None, 1.0, 1.6)),
        dict(hoodie=(40, ("set", 34), 1.13), pants=(305, .8, .75), skin=(None, 1.0, 1.2)),
    ],
    "boy": [
        {},
        dict(jacket=(258, .8, .95), bag=(36, 1.0, 1.0), pants=(222, ("set", 120), 1.5), shoes=(358, 1.0, 1.0), skin=(None, 1.0, 1.35)),
        dict(jacket=(172, 1.0, .95), pants=(40, ("set", 85), 2.5), bag=(258, 1.0, 1.0), shoes=(36, 1.0, 1.0), skin=(None, 1.0, .85)),
        dict(jacket=(40, .95, 1.0), bag=(172, 1.0, 1.0), shoes=(358, 1.0, 1.0), skin=(None, 1.0, 1.6)),
        dict(jacket=(40, ("set", 36), 1.06), pants=(78, ("set", 95), 2.1), bag=(356, 1.0, 1.0), shoes=(258, .9, .9), skin=(None, 1.0, 1.2)),
    ],
}


def region_mask(hsv, spec, alpha):
    h, s, v = hsv[:, :, 0].astype(int), hsv[:, :, 1].astype(int), hsv[:, :, 2].astype(int)
    m = np.zeros(h.shape, bool)
    for lo, hi in spec["h"]:
        m |= (h >= lo) & (h <= hi)
    m &= (s >= spec["s"][0]) & (s <= spec["s"][1]) & (v >= spec["v"][0]) & (v <= spec["v"][1]) & (alpha > 20)
    rows = np.arange(h.shape[0])[:, None] / h.shape[0]
    if "below" in spec:
        m &= rows >= spec["below"]
    if "above" in spec:
        m &= rows < spec["above"]
    return m


def recolor(rgba, name, rules):
    out = rgba.copy()
    bgr, alpha = out[:, :, :3], out[:, :, 3]
    hsv = cv2.cvtColor(bgr, cv2.COLOR_BGR2HSV).astype(np.float32)
    masks = {key: region_mask(hsv, spec, alpha) for key, spec in REGIONS[name].items()}
    for key, (h_deg, sat, val) in rules.items():
        m = masks[key]
        if h_deg is not None:
            hsv[:, :, 0][m] = hue(h_deg)
        if isinstance(sat, tuple):
            hsv[:, :, 1][m] = sat[1]
        else:
            hsv[:, :, 1][m] = np.clip(hsv[:, :, 1][m] * sat, 0, 255)
        hsv[:, :, 2][m] = np.clip(hsv[:, :, 2][m] * val, 0, 255)
    out[:, :, :3] = cv2.cvtColor(hsv.astype(np.uint8), cv2.COLOR_HSV2BGR)
    return out


sheet = []
for name, variants in VARIANTS.items():
    base = cv2.imread(str(SPR / f"{name}.png"), cv2.IMREAD_UNCHANGED)
    for i, rules in enumerate(variants, 1):
        img = recolor(base, name, rules) if rules else base
        cv2.imwrite(str(SPR / f"{name}-{i}.png"), img)
        sheet.append(img)
print("wrote", len(sheet), "sprites")

if len(sys.argv) > 1:
    th = 360
    tiles = [cv2.resize(s, (round(s.shape[1] * th / s.shape[0]), th), interpolation=cv2.INTER_AREA) for s in sheet]
    w = sum(t.shape[1] for t in tiles[:5]) + 30 * 6
    canvas = np.full((th * 2 + 90, w + 60, 3), (235, 238, 244), np.uint8)
    for row in (0, 1):
        x = 30
        for t in tiles[row * 5:(row + 1) * 5]:
            a = t[:, :, 3:4] / 255.0
            y = 30 + row * (th + 30)
            region = canvas[y:y + th, x:x + t.shape[1]]
            region[:] = (t[:, :, :3] * a + region * (1 - a)).astype(np.uint8)
            x += t.shape[1] + 30
    cv2.imwrite(sys.argv[1], canvas)
