"""Draws the hero's roadside scene (web/assets/img/scene.svg).

Flat shapes in the app's palette: three layers of city, trees, a kerb, two
traffic lights, a kiosk with a parasol, a bench, and yellow taxis on the road.
The people along the pavement are the app's own onboarding characters, cut out
by scripts/cut_people.py, recoloured into different outfits by
scripts/make_variants.py, and embedded here, so the hero is drawn in the same
hand as the app.

Scale, in scene units:
  person    ~150 tall with the raised hand, ~130 standing
  taxi      425 long, 145 tall: in the near lane, so a head above the people
  kiosk     ~1.9 people tall, traffic lights ~2.9, trees 3 to 5
  buildings 3 to 8 people tall; their windows shrink with distance

Run from kombien-landing/, after cut_people.py and make_variants.py:
  python scripts/make_scene.py
"""
import base64
import random
from pathlib import Path

import cv2

W, H = 1440, 680
GROUND = 476  # top of the pavement
SPRITE_H = 150  # the cut-out people, in units, raised hand included
rnd = random.Random(11)
out = []
add = out.append

SPRITES = Path("sprites")


def sprite(name):
    """Embeds a cut-out person as a WebP data URI under the id p-<name>."""
    img = cv2.imread(str(SPRITES / f"{name}.png"), cv2.IMREAD_UNCHANGED)
    h, w = img.shape[:2]
    px_h = 300  # enough for a 2x screen at full width
    small = cv2.resize(img, (round(w * px_h / h), px_h), interpolation=cv2.INTER_AREA)
    ok, buf = cv2.imencode(".webp", small, [cv2.IMWRITE_WEBP_QUALITY, 88])
    assert ok
    uri = "data:image/webp;base64," + base64.b64encode(buf.tobytes()).decode()
    uw, uh = SPRITE_H * w / h, SPRITE_H
    add(f'<image id="p-{name}" x="{-uw / 2:.2f}" y="{-uh:.2f}" width="{uw:.2f}" height="{uh:.2f}" href="{uri}"/>')


def buildings(layer, fill, h_min, h_max, wmin, wmax, cell, lit=0.0):
    """One layer of the skyline. cell = (window pitch x, window pitch y)."""
    cw, ch = cell
    x = -30
    add(f'<g id="{layer}">')
    while x < W + 30:
        w = rnd.randint(wmin, wmax)
        h = rnd.randint(h_min, h_max)
        top = GROUND - h
        add(f'<rect x="{x}" y="{top}" width="{w}" height="{h + 6}" fill="{fill}"/>')
        add(f'<rect x="{x + cw // 2}" y="{top + ch // 2}" width="{max(w - cw, 4)}" height="{h - ch}" fill="url(#win-{layer})"/>')
        kind = rnd.random()
        if kind < .22:
            add(f'<rect x="{x + w // 2 - 2}" y="{top - 30}" width="5" height="30" fill="{fill}"/>')
        elif kind < .36:
            add(f'<rect x="{x + 8}" y="{top - 16}" width="{w - 16}" height="16" fill="{fill}"/>')
        if lit:
            cols = max((w - cw) // cw, 1)
            rows = max((h - ch) // ch, 1)
            for _ in range(int(cols * rows * lit)):
                cx = x + cw // 2 + rnd.randrange(cols) * cw
                cy = top + ch // 2 + rnd.randrange(rows) * ch
                add(f'<rect x="{cx + cw * .25:.0f}" y="{cy + ch * .2:.0f}" width="{cw * .5:.0f}" height="{ch * .5:.0f}" rx="1.5" fill="#F4A340"/>')
        x += w + rnd.randint(0, 8)
    add('</g>')


add(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" preserveAspectRatio="xMidYMax slice">')
add('<defs>')
for name, col, (cw, ch) in (("far", "#EDE3CD", (14, 18)), ("mid", "#E0D4BA", (19, 25)), ("near", "#C9BEA6", (26, 34))):
    add(f'<pattern id="win-{name}" width="{cw}" height="{ch}" patternUnits="userSpaceOnUse"><rect x="{cw * .25:.1f}" y="{ch * .2:.1f}" width="{cw * .5:.1f}" height="{ch * .5:.1f}" rx="1" fill="{col}"/></pattern>')
add('<radialGradient id="glowR"><stop offset="0" stop-color="#FF5A4F" stop-opacity=".55"/><stop offset="1" stop-color="#FF5A4F" stop-opacity="0"/></radialGradient>')
add('<radialGradient id="glowG"><stop offset="0" stop-color="#34D07A" stop-opacity=".5"/><stop offset="1" stop-color="#34D07A" stop-opacity="0"/></radialGradient>')

# who stands where: (x, sprite, scale, mirrored). Small groups, as people wait
# for a taxi together; every sprite is a different outfit and skin tone.
PEOPLE = (
    (140, "girl-2", 1.00, False), (240, "boy-3", .95, True), (340, "girl-4", .90, True),
    (720, "boy-2", 1.00, False), (820, "girl-5", .96, True),
    (960, "girl-3", 1.02, False), (1055, "boy-5", .92, True),
    (1196, "boy-4", .97, True), (1352, "girl-1", .94, False),
)
for name in sorted({p[1] for p in PEOPLE}):
    sprite(name)
add('</defs>')

# city, far to near: taller and finer in the distance, shorter and chunkier up close
buildings("far", "#E8DDC6", 340, 460, 100, 190, (14, 18))
buildings("mid", "#D8CCB1", 260, 390, 90, 170, (19, 25))
buildings("near", "#B9AE96", 170, 290, 80, 150, (26, 34), lit=.07)


def tree(x, s=1.0, dark=False):
    s *= 2.5  # trees are 3 to 5 people tall
    c1, c2 = ("#0E6B34", "#14803F") if dark else ("#3B8F56", "#4CA168")
    add(f'<rect x="{x - 3 * s}" y="{GROUND - 44 * s}" width="{6 * s}" height="{48 * s}" fill="#5B4A36"/>')
    add(f'<circle cx="{x}" cy="{GROUND - 66 * s}" r="{30 * s}" fill="{c1}"/>')
    add(f'<circle cx="{x - 20 * s}" cy="{GROUND - 52 * s}" r="{22 * s}" fill="{c2}"/>')
    add(f'<circle cx="{x + 22 * s}" cy="{GROUND - 50 * s}" r="{23 * s}" fill="{c1}"/>')


for x, s, d in ((50, 1.0, True), (535, .95, False), (890, .85, True), (1405, .9, False)):
    tree(x, s, d)

# pavement, kerb, road
add(f'<rect x="0" y="{GROUND}" width="{W}" height="44" fill="#F0E7D0"/>')
add(f'<rect x="0" y="{GROUND + 44}" width="{W}" height="10" fill="#D9CCA8"/>')
add(f'<rect x="0" y="{GROUND + 54}" width="{W}" height="{H - GROUND - 54}" fill="#3F3E43"/>')
for x in range(40, W, 180):
    add(f'<rect x="{x}" y="{GROUND + 128}" width="100" height="8" rx="4" fill="#8F8C86"/>')


def traffic_light(x, lit, k=1.3):
    """A traffic light on a pole, scaled about its foot. lit is 'red' or 'green'."""
    top = GROUND - 235
    box_w, box_h = 38, 104
    on = {"red": "#FF4B43", "amber": "#F4A340", "green": "#34D07A"}
    add(f'<g transform="translate({x} {GROUND + 6}) scale({k}) translate({-x} {-(GROUND + 6)})">')
    add(f'<ellipse cx="{x}" cy="{GROUND + 6}" rx="18" ry="4" fill="#CDBF99"/>')
    add(f'<rect x="{x - 4}" y="{top + box_h - 4}" width="8" height="{235 - box_h + 8}" rx="3" fill="#202020"/>')
    for i, key in enumerate(("red", "amber", "green")):
        if key == lit:
            add(f'<circle cx="{x}" cy="{top + 22 + i * 30}" r="62" fill="url(#glow{"R" if key == "red" else "G"})"/>')
    add(f'<rect x="{x - box_w / 2}" y="{top}" width="{box_w}" height="{box_h}" rx="9" fill="#202020"/>')
    add(f'<rect x="{x - box_w / 2 + 5}" y="{top + 5}" width="{box_w - 10}" height="{box_h - 10}" rx="6" fill="#2B2B2E"/>')
    for i, key in enumerate(("red", "amber", "green")):
        cy = top + 22 + i * 30
        add(f'<circle cx="{x}" cy="{cy}" r="11" fill="{on[key] if key == lit else "#47474B"}"/>')
        add(f'<path d="M{x - 13} {cy - 9} a13 13 0 0 1 26 0" fill="none" stroke="#202020" stroke-width="3" stroke-linecap="round"/>')
    add('</g>')


traffic_light(430, "red")
traffic_light(1120, "green")

# kiosk with an awning and a parasol, scaled about its foot
kx = 1190
add(f'<g transform="translate({kx} {GROUND}) scale(1.3) translate({-kx} {-GROUND})">')
add(f'<ellipse cx="{kx + 70}" cy="{GROUND + 20}" rx="104" ry="8" fill="#CDBF99"/>')
add(f'<rect x="{kx}" y="{GROUND - 100}" width="140" height="114" fill="#F2D9A8"/>')
add(f'<rect x="{kx + 12}" y="{GROUND - 66}" width="50" height="80" fill="#D9B87A"/>')
add(f'<rect x="{kx + 80}" y="{GROUND - 72}" width="48" height="36" rx="4" fill="#BFE3F7"/>')
for i in range(7):
    c = "#F4A340" if i % 2 == 0 else "#FFF1D8"
    add(f'<path d="M{kx - 8 + i * 22} {GROUND - 118} h22 l 4 26 h-22 z" fill="{c}"/>')
add(f'<rect x="{kx + 150}" y="{GROUND - 112}" width="5" height="128" fill="#202020"/>')
add(f'<path d="M{kx + 108} {GROUND - 110} a 44 30 0 0 1 88 0 z" fill="#FF6B8A"/>')
add(f'<rect x="{kx - 38}" y="{GROUND - 24}" width="32" height="26" fill="#C48A3A"/>')
add(f'<rect x="{kx - 38}" y="{GROUND - 24}" width="32" height="7" fill="#D9A04E"/>')
add('</g>')

# a bench to wait on (seat about half a person high)
bx = 590
add(f'<g transform="translate({bx} {GROUND + 18}) scale(.8)">')
add('<ellipse cx="50" cy="8" rx="66" ry="8" fill="#CDBF99"/>')
add('<rect x="0" y="-50" width="100" height="10" rx="3" fill="#C48A3A"/>')
add('<rect x="0" y="-80" width="100" height="8" rx="3" fill="#D9A04E"/>')
for dx, dy, h in ((10, -42, 44), (84, -42, 44), (10, -76, 28), (84, -76, 28)):
    add(f'<rect x="{dx}" y="{dy}" width="6" height="{h}" fill="#202020"/>')
add('</g>')

# ---- the app's own people, waiting along the pavement ------------------------
FEET = GROUND + 40
for x, name, s, flip in PEOPLE:
    sx = -s if flip else s
    add(f'<ellipse cx="{x}" cy="{FEET}" rx="{34 * s:.0f}" ry="6" fill="#CDBF99"/>')
    add(f'<use href="#p-{name}" transform="translate({x} {FEET}) scale({sx:.3f} {s:.3f})"/>')


# ---- yellow taxis on the road -------------------------------------------------
def taxi(x, flip=False):
    """Drawn 170 long, 58 tall, scaled 2.5 to 425 x 145: near-lane size."""
    by = H - 20  # tyres sit here
    k = 2.5
    sx = -k if flip else k
    add(f'<g transform="translate({x} {by}) scale({sx} {k})">')
    add('<ellipse cx="85" cy="2" rx="92" ry="5" fill="#2F2E33"/>')
    add('<path d="M4 -24 q0 -10 10 -10 h24 l18 -18 h58 l20 18 h20 q10 0 10 10 v14 h-160 z" fill="#FFC93C"/>')
    add('<path d="M4 -14 h160 v6 h-160 z" fill="#E9A91F"/>')
    add('<path d="M60 -33 l13 -16 h26 v16 z" fill="#2E3A44"/>')
    add('<path d="M104 -33 v-16 h11 l16 16 z" fill="#2E3A44"/>')
    add('<rect x="80" y="-58" width="26" height="7" rx="3" fill="#FFF1D8"/>')
    add('<rect x="87" y="-56" width="12" height="3" rx="1.5" fill="#F4A340"/>')
    add('<rect x="161" y="-25" width="6" height="7" rx="2" fill="#FFF1D8"/>')
    add('<rect x="3" y="-25" width="5" height="7" rx="2" fill="#E24B4B"/>')
    for wx in (36, 132):
        add(f'<circle cx="{wx}" cy="-4" r="12" fill="#202020"/><circle cx="{wx}" cy="-4" r="5" fill="#D9D3C5"/>')
    add('</g>')


taxi(10, False)    # spans x 10-435
taxi(960, True)    # mirrored, spans x 535-960
taxi(1000, False)  # spans x 1000-1425

# foreground leaves at the corners
add(f'<circle cx="8" cy="{H + 8}" r="54" fill="#0E6B34"/><circle cx="72" cy="{H + 16}" r="44" fill="#14803F"/>')
add(f'<circle cx="{W - 8}" cy="{H + 8}" r="56" fill="#0E6B34"/><circle cx="{W - 76}" cy="{H + 16}" r="42" fill="#14803F"/>')

add('</svg>')
open("web/assets/img/scene.svg", "w", encoding="utf-8").write("\n".join(out))
print("scene.svg", len("\n".join(out)) // 1024, "KB")
