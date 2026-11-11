"""Cuts the app's two onboarding characters out of their backgrounds.

Reads app/assets/illustrations/splash-girl.webp and splash-boy.webp, isolates
each person with GrabCut inside a hand-drawn outline, tidies the edge, and
writes transparent PNGs to sprites/ (and a preview sheet to the path
given as argv[1], if any).

The outline only has to be roughly right (a few pixels): the sprites are drawn
at under a fifth of their size in the hero, so edge error is invisible there.

Run from kombien-landing/: python scripts/cut_people.py [preview.png]
"""
import sys
from pathlib import Path

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "app" / "assets" / "illustrations"
OUT = Path(__file__).resolve().parents[1] / "sprites"
OUT.mkdir(parents=True, exist_ok=True)

# Outline around each person, in source pixels (x, y).
# "keep_out" polygons are background that sits inside the outline (the gap
# between the legs, the gap under the raised arm) and is forced to background.
PEOPLE = {
    "girl": {
        "file": "splash-girl.webp",
        "outline": [
            (195, 572), (255, 585), (283, 568), (296, 538), (322, 533), (342, 552),
            (342, 588), (322, 602), (300, 660), (284, 708), (304, 712), (306, 752),
            (275, 778), (265, 820), (277, 875), (277, 930), (273, 1012), (300, 1048),
            (303, 1090), (30, 1092), (28, 1040), (36, 930), (92, 915), (150, 820),
            (120, 790), (120, 735), (128, 690), (111, 645), (112, 620), (120, 600),
            (160, 590),
        ],
        "keep_out": [
            [(128, 975), (200, 918), (203, 1034), (104, 1034), (104, 985)],     # under the back leg, between the legs
            [(100, 846), (156, 834), (150, 862), (112, 905), (92, 900)],        # asphalt above the back leg
            [(0, 900), (40, 900), (38, 1034), (0, 1034)],                       # pavement left of the back shoe
            [(40, 985), (100, 985), (104, 1034), (40, 1034)],                   # pavement between shoe and splash
            [(270, 752), (298, 752), (298, 796), (270, 796)],                   # building below the hand
            [(268, 1005), (302, 1005), (302, 1040), (280, 1040)],               # pavement right of the ankle
            [(293, 1030), (306, 1030), (306, 1096), (293, 1096)],               # pavement right of the shoe
            [(250, 586), (286, 584), (262, 626), (248, 640)],                   # gap between head and raised arm
            [(300, 668), (338, 610), (345, 680), (310, 700)],                   # sky right of the sleeve
            [(302, 702), (345, 702), (345, 795), (302, 795)],                   # building right of the phone
        ],
        # definitely her: the phone and the hand holding it
        "sure_fg": [[(270, 703), (298, 703), (298, 727), (270, 727)]],
        # her colours are all saturated, so grey and cream background tones can be stripped
        "strip_greys": True,
    },
    "boy": {
        "file": "splash-boy.webp",
        "outline": [
            (212, 570), (235, 557), (262, 565), (262, 598), (300, 620), (336, 640),
            (345, 575), (380, 568), (408, 585), (412, 640), (432, 654), (462, 662),
            (470, 700), (505, 760), (520, 820), (520, 860), (505, 862), (495, 980),
            (527, 1015), (520, 1055), (500, 1085), (455, 1088), (452, 1055),
            (437, 1002), (372, 1045), (372, 1085), (275, 1082), (275, 1060),
            (312, 1000), (312, 890), (335, 830), (327, 800), (330, 750), (342, 705),
            (247, 615),
        ],
        "keep_out": [
            [(380, 1000), (430, 1000), (410, 1040), (380, 1040)],               # below the knees, between the legs
            [(402, 892), (376, 1005), (438, 1003), (430, 962)],                 # between the legs
            [(500, 872), (526, 872), (528, 1000), (498, 985)],                  # road right of the leg
            [(412, 575), (440, 575), (440, 650), (412, 645)],                   # building beside the head
        ],
        # (polygon, value min, value max, saturation max): road and wall tones that
        # sit inside the outline but are lighter than his charcoal trousers
        "strip_regions": [
            ([(430, 858), (532, 856), (532, 1002), (440, 1002)], 64, 105, 45),
            ([(448, 788), (524, 788), (524, 864), (448, 864)], 64, 105, 45),
            ([(333, 582), (360, 582), (360, 642), (333, 642)], 90, 235, 70),
            ([(402, 568), (446, 568), (446, 660), (402, 660)], 90, 235, 70),
        ],
    },
}


def cut(name, spec):
    img = cv2.imread(str(SRC / spec["file"]), cv2.IMREAD_COLOR)
    h, w = img.shape[:2]

    outline = np.zeros((h, w), np.uint8)
    cv2.fillPoly(outline, [np.array(spec["outline"], np.int32)], 255)
    probable = cv2.dilate(outline, np.ones((9, 9), np.uint8))

    mask = np.full((h, w), cv2.GC_BGD, np.uint8)
    mask[probable > 0] = cv2.GC_PR_BGD          # a thin band outside: could go either way
    mask[outline > 0] = cv2.GC_PR_FGD           # inside: probably the person
    core = cv2.erode(outline, np.ones((25, 25), np.uint8))
    mask[core > 0] = cv2.GC_FGD                 # deep inside: certainly the person
    for poly in spec["keep_out"]:
        cv2.fillPoly(mask, [np.array(poly, np.int32)], cv2.GC_BGD)
    for poly in spec.get("sure_fg", []):
        cv2.fillPoly(mask, [np.array(poly, np.int32)], cv2.GC_FGD)

    bgd = np.zeros((1, 65), np.float64)
    fgd = np.zeros((1, 65), np.float64)
    cv2.grabCut(img, mask, None, bgd, fgd, 8, cv2.GC_INIT_WITH_MASK)
    fg = np.where((mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD), 255, 0).astype(np.uint8)

    if spec.get("strip_greys"):
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        hue, sat, val = hsv[:, :, 0].astype(int), hsv[:, :, 1].astype(int), hsv[:, :, 2].astype(int)
        grey = (sat < 70) & (val > 55) & (val < 222)                      # asphalt, building glass
        cream = (hue >= 15) & (hue <= 32) & (sat >= 18) & (sat <= 70) & (val > 205)  # pavement
        strip = (grey | cream).astype(np.uint8) * 255
        strip = cv2.morphologyEx(strip, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
        for poly in spec.get("sure_fg", []):
            cv2.fillPoly(strip, [np.array(poly, np.int32)], 0)
        fg[strip > 0] = 0

    for poly, vmin, vmax, smax in spec.get("strip_regions", []):
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        region = np.zeros((h, w), np.uint8)
        cv2.fillPoly(region, [np.array(poly, np.int32)], 255)
        tone = (hsv[:, :, 2] >= vmin) & (hsv[:, :, 2] <= vmax) & (hsv[:, :, 1] <= smax)
        fg[(region > 0) & tone] = 0

    n, lab, stats, _ = cv2.connectedComponentsWithStats(fg)
    if n > 1:
        keep = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
        fg = np.where(lab == keep, 255, 0).astype(np.uint8)
    fg = cv2.morphologyEx(fg, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
    fg = cv2.erode(fg, np.ones((3, 3), np.uint8), iterations=1)
    alpha = cv2.GaussianBlur(fg, (0, 0), 1.2)

    rgba = np.dstack([img, alpha])
    ys, xs = np.where(alpha > 8)
    rgba = rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    cv2.imwrite(str(OUT / f"{name}.png"), rgba)
    print(name, rgba.shape[1], "x", rgba.shape[0])
    return rgba


sheet = [cut(name, spec) for name, spec in PEOPLE.items()]

if len(sys.argv) > 1:
    hmax = max(s.shape[0] for s in sheet)
    wtot = sum(s.shape[1] for s in sheet) + 40 * (len(sheet) + 1)
    canvas = np.full((hmax + 80, wtot, 3), (160, 215, 235), np.uint8)  # flat sky blue, to judge edges
    x = 40
    for s in sheet:
        a = s[:, :, 3:4] / 255.0
        region = canvas[40:40 + s.shape[0], x:x + s.shape[1]]
        region[:] = (s[:, :, :3] * a + region * (1 - a)).astype(np.uint8)
        x += s.shape[1] + 40
    cv2.imwrite(sys.argv[1], canvas)
