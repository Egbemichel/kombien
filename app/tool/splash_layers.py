"""Split the flattened splash JPEG into depth layers for the splash animation.

Outputs full-frame transparent PNGs (704x1520, the original's frame) so the
layers stack with no positioning maths.

Buildings (far, mid, towers, near): each layer keeps the original pixels where
it is visible and is filled with its own colour where nearer layers hide it,
so it reads as a solid silhouette while it rises alone.
Plants (back trees, front bushes): cut by colour against the building colour
behind them, with soft unmixed edges, so no building pixels travel with them.

Run from app/:  python tool/splash_layers.py   (needs Pillow and numpy)
Reads brand/product/image/splash-city.svg (a JPEG inside an SVG wrapper)
and writes app/assets/splash/*.png.
"""
import base64
import io
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image

APP = Path(__file__).resolve().parents[1]
SRC = APP.parent / 'brand' / 'product' / 'image' / 'splash-city.svg'
OUT = str(APP / 'assets' / 'splash') + '/'
CHECK = '--check' in sys.argv  # also write composite.png and sheet.png here

jpeg = base64.b64decode(
    re.search(r'base64,([^"]+)"', SRC.read_text(encoding='utf-8')).group(1))
a = np.asarray(Image.open(io.BytesIO(jpeg)).convert('RGB')).astype(float)
H, W = a.shape[:2]
SKY = np.array([244, 238, 227.])
CITY_TOP = 700

cent = {
    'sky': (243, 239, 227), 'far': (234, 228, 210), 'mid': (210, 204, 184),
    'near': (162, 156, 138), 'dark': (102, 102, 90), 'win': (240, 240, 228),
    'mango': (244, 168, 72), 'dg': (12, 96, 48), 'lg': (54, 132, 82),
    'cloud': (248, 246, 240), 'peach': (252, 216, 168),
}
names = list(cent)
C = np.array([cent[k] for k in names], float)
lab = ((a[:, :, None, :] - C[None, None]) ** 2).sum(-1).argmin(-1)
L = {k: (lab == i) for i, k in enumerate(names)}
green_px = L['dg'] | L['lg']
# Greenness: green clearly above red. Catches anti-aliased plant edges too.
greenish = (a[:, :, 1] - a[:, :, 0]) > 12
tinted = (a[:, :, 1] - a[:, :, 0]) > 4  # even faint green blends

# ---------------------------------------------------------------- depth map
d = np.zeros((H, W), int)
d[L['far']] = 1
d[L['mid']] = 2
d[L['dark']] = 3
d[L['near'] | L['mango']] = 4
d[:CITY_TOP] = 0

# Tower stripes and windows share the near colour: a near-coloured pixel with
# tower on both sides along its row (within 20 px) is tower.
dark = L['dark'].copy(); dark[:CITY_TOP] = False
left = np.zeros_like(dark); right = np.zeros_like(dark)
for s in range(1, 21):
    left[:, s:] |= dark[:, :-s]
    right[:, :-s] |= dark[:, s:]
d[(d == 4) & left & right] = 3


def top_of(mask, start=CITY_TOP):
    """First row >= start where mask holds 3 rows running, per column."""
    out = np.full(W, H)
    m = mask[start:]
    run = m[:-2] & m[1:-1] & m[2:]
    for x in range(W):
        ys = np.nonzero(run[:, x])[0]
        if len(ys):
            out[x] = ys[0] + start
    return out


def smooth(t):
    p = np.pad(t, 1, mode='edge')
    return np.median(np.stack([p[:-2], p[1:-1], p[2:]]), axis=0).astype(int)


def opening(t, w=25):
    """Drops skyline spikes narrower than w (antennas, poles)."""
    r = w // 2
    p = np.pad(t, r, mode='edge')
    er = np.max(np.stack([p[i:i + W] for i in range(w)]), axis=0)
    p = np.pad(er, r, mode='edge')
    return np.min(np.stack([p[i:i + W] for i in range(w)]), axis=0)


# Plants: back trees start high; the front bushes start at the mound line.
gtop = top_of(green_px, 1150)
xs = np.arange(W)
tree_cols = gtop < 1385
yb = gtop.astype(float)
yb[tree_cols] = np.interp(xs[tree_cols], xs[~tree_cols], gtop[~tree_cols])
yb = yb.astype(int)
rows = np.arange(H)[:, None]

# Buildings: skyline per depth (cumulative: depth >= k), green ignored.
tops = {k: opening(smooth(top_of(d >= k))) for k in range(1, 5)}
for k in range(2, 5):
    tops[k] = np.maximum(tops[k], tops[k - 1])
tops[5] = yb  # the near layer runs down to the bush line
raw_top = top_of(d >= 1)

base = {1: (234, 228, 210), 2: (210, 204, 184), 3: (102, 102, 90),
        4: (162, 156, 138)}
out_names = {1: 'city-far', 2: 'city-mid', 3: 'city-towers', 4: 'city-near'}

imgs = {}
for k in range(1, 5):
    img = np.zeros((H, W, 4), np.uint8)
    imgs[k] = img
    t0, t1 = tops[k], tops[k + 1]
    for x in range(W):
        y0 = t0[x]
        if y0 >= H or t1[x] - y0 < 2:
            continue  # absent here: a nearer layer is taller
        if y0 - 1 >= CITY_TOP:  # soft row keeps the original edge blend
            img[y0 - 1, x, :3] = a[y0 - 1, x]
            img[y0 - 1, x, 3] = 128
        # Thin details above the topmost smoothed edge belong to it.
        if all(tops[j][x] - tops[j - 1][x] < 2 for j in range(2, k + 1)):
            for y in range(raw_top[x], y0):
                if d[y, x] >= 1:
                    img[y, x, :3] = a[y, x]
                    img[y, x, 3] = 255
        img[y0:t1[x], x, :3] = a[y0:t1[x], x]
        img[y0:t1[x], x, 3] = 255
        img[max(y0, t1[x] - 2):, x, :3] = base[k]
        img[t1[x]:, x, 3] = 255
    # Plants are their own layers: whatever green fell in here becomes this
    # layer's colour (the plant layers carry the real edges).
    g = tinted & (img[:, :, 3] > 0)
    img[g, :3] = base[k]

# Details of a nearer layer that sit inside a farther layer's area (a roof
# railing over a far building, an antenna over a mid one) move to their own
# layer, so they rise with the building they belong to.
# A detail moves only when it stands directly on (within 45 px above) the top
# of the first layer present at its column from depth j on.
present = {j: (tops[j + 1] - tops[j]) >= 2 for j in range(1, 5)}
for k in range(1, 4):
    for j in range(k + 1, 5):
        owner = np.full(W, 0)
        for jj in range(4, j - 1, -1):
            owner[present[jj]] = jj
        for x in range(W):
            jj = owner[x]
            if jj == 0:
                continue
            ys = np.nonzero((imgs[k][:, x, 3] == 255) & (d[:, x] == j))[0]
            ys = ys[(ys < tops[jj][x]) & (ys >= tops[jj][x] - 45)]
            if len(ys):
                imgs[jj][ys, x, :3] = a[ys, x]
                imgs[jj][ys, x, 3] = 255
                imgs[k][ys, x, :3] = base[k]
for k in range(1, 5):
    Image.fromarray(imgs[k]).save(OUT + out_names[k] + '.png', optimize=True)

# ---------------------------------------------------------------- plants
BEHIND = np.array(base[4], float)  # the near-building colour behind plants
DG, LG = np.array(cent['dg'], float), np.array(cent['lg'], float)


def unmix(region):
    """Alpha and colour of plant pixels laid over the building colour."""
    dist = np.linalg.norm(a - BEHIND, axis=-1)
    full = min(np.linalg.norm(DG - BEHIND), np.linalg.norm(LG - BEHIND))
    alpha = np.clip(dist / full, 0, 1)
    alpha[~(greenish | green_px)] = 0
    alpha[~region] = 0
    al = np.maximum(alpha, 1e-3)[..., None]
    col = np.clip((a - (1 - al) * BEHIND) / al, 0, 255)
    img = np.zeros((H, W, 4), np.uint8)
    img[..., :3] = col
    img[..., 3] = (alpha * 255).round()
    return img


back_region = (rows < yb[None, :]) & (rows >= 1150)
back = unmix(back_region)
fill = np.broadcast_to(rows >= yb[None, :], (H, W))
back[fill] = (*cent['dg'], 255)  # hidden below the bushes: a solid hedge
Image.fromarray(back).save(OUT + 'plants-back.png', optimize=True)

front = unmix(np.broadcast_to(rows >= yb[None, :], (H, W)))
Image.fromarray(front).save(OUT + 'plants-front.png', optimize=True)

# ---------------------------------------------------------------- sky objects
def dilate(m, r=2):
    out = m.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            out |= np.roll(np.roll(m, dy, 0), dx, 1)
    return out


def save_obj(name, m):
    m = dilate(m, 2)
    img = np.zeros((H, W, 4), np.uint8)
    img[m, :3] = a[m]
    img[m, 3] = 255
    Image.fromarray(img).save(OUT + name + '.png', optimize=True)


sun = L['mango'].copy(); sun[CITY_TOP:] = False; sun[:, 300:] = False
sun[260:] = False
clouds = L['cloud'] | L['peach']; clouds[CITY_TOP:] = False
cl = clouds.copy(); cl[:, 320:] = False; cl[:240] = False
cr = clouds.copy(); cr[:, :320] = False
save_obj('sun', sun)
save_obj('cloud-left', cl)
save_obj('cloud-right', cr)

# ---------------------------------------------------------------- check
order = ['sun', 'cloud-left', 'cloud-right', 'city-far', 'city-mid',
         'city-towers', 'city-near', 'plants-back', 'plants-front']
comp = np.zeros((H, W, 3)); comp[:] = SKY
for n in order:
    l = np.asarray(Image.open(OUT + n + '.png')).astype(float)
    al = l[..., 3:] / 255
    comp = comp * (1 - al) + l[..., :3] * al
diff = np.abs(comp - a).max(-1)
print('composite px off by >24: %.3f%%' % ((diff > 24).mean() * 100))
if CHECK:
    Image.fromarray(comp.astype(np.uint8)).save('composite.png')

tiles = []
acc = np.zeros((H, W, 3)); acc[:] = SKY
for n in order[3:]:
    l = np.asarray(Image.open(OUT + n + '.png')).astype(float)
    al = l[..., 3:] / 255
    alone = SKY * (1 - al) + l[..., :3] * al
    acc = acc * (1 - al) + l[..., :3] * al
    for im in (alone, acc):
        tiles.append(Image.fromarray(im.astype(np.uint8)).crop(
            (0, 700, 704, 1520)).resize((235, 274)))
sheet = Image.new('RGB', (235 * 4 + 30, 274 * 3 + 20), (255, 255, 255))
for i, t in enumerate(tiles):
    sheet.paste(t, ((i % 4) * 245, (i // 4) * 284))
if CHECK:
    sheet.save('sheet.png')

# ---------------------------------------------------------------- overshoot room
# The spring overshoots ~4 %: extend every city and plant layer 140 px below
# the frame by repeating its last row, so a layer that rises past its rest
# never opens a gap at the bottom of the screen.
EXTRA = 140
for n in order[3:]:
    l = np.asarray(Image.open(OUT + n + '.png'))
    ext = np.concatenate([l, np.repeat(l[-1:], EXTRA, axis=0)], axis=0)
    Image.fromarray(ext).save(OUT + n + '.png', optimize=True)
print('extended to', H + EXTRA)
