"""Hold what each walk's ground handles as against what is drawn there.

    python tools/surface_check.py DIR

DIR holds tools/surface_map.sh's dump output (SURF_DUMP=1): a clean shot
LEVEL_Y.png and its points LEVEL_Y.txt (`SURF screen_x screen_y surface`).
Each point's drawn colour (the median of a small patch round it) is read as a
material, and wherever that disagrees with surface_at() in a way a player
would feel - water you cannot swim in, a lawn that handles as paving, paving
that handles as grass, sand that handles as pavement - the point is counted
and ringed in DIR/check-LEVEL_Y.png. A summary per shot is printed, worst
first. Colour is only a guess at material, so this finds places to look at,
not verdicts: a sandy gravel path is drawn warm and pale and is pavement by
design.
"""
import os
import sys
from statistics import median
from PIL import Image, ImageDraw

PAVEMENT, GRASS, SAND, MUD, WATER, TILE = range(6)
NAMES = ['pavement', 'grass', 'sand', 'mud', 'water', 'tile']
# the HUD at 1280x720: status card, banner, goals card, version label
HUD = [(0, 0, 220, 110), (300, 0, 860, 60), (850, 0, 1280, 220), (1140, 680, 1280, 720)]
PATCH = 4


def drawn(px):
    r, g, b = [v / 255.0 for v in px]
    hi, lo = max(r, g, b), min(r, g, b)
    sat = (hi - lo) / max(hi, 0.001)
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    if b - r > 0.10 and g >= r - 0.02:
        return 'water'
    if g - r > -0.01 and g - b > 0.05:
        return 'grass'
    if r - b > 0.12 and lum > 0.55:
        return 'sandy'
    if sat < 0.12:
        return 'grey'
    return 'other'


# (drawn, handled) pairs worth a look, and what to call them
FLAGS = {
    ('water', PAVEMENT): 'water that handles as pavement',
    ('water', GRASS): 'water that handles as grass',
    ('water', SAND): 'water that handles as sand',
    ('grass', PAVEMENT): 'lawn that handles as pavement',
    ('grey', GRASS): 'paving that handles as grass',
    ('sandy', GRASS): 'sand or gravel that handles as grass',
    ('grey', WATER): 'paving that handles as water',
    ('grass', WATER): 'lawn that handles as water',
    ('sandy', WATER): 'sand that handles as water',
}


def in_hud(x, y):
    return any(x0 <= x < x1 and y0 <= y < y1 for x0, y0, x1, y1 in HUD)


def check(d, stem):
    im = Image.open(os.path.join(d, stem + '.png')).convert('RGB')
    pts = []
    for line in open(os.path.join(d, stem + '.txt'), encoding='utf-8', errors='replace'):
        if line.startswith('SURF '):
            _, x, y, s = line.split()
            pts.append((int(x), int(y), int(s)))
    w, h = im.size
    px = im.load()
    marks = ImageDraw.Draw(im)
    counts = {}
    for x, y, s in pts:
        if x < PATCH or y < PATCH or x >= w - PATCH or y >= h - PATCH or in_hud(x, y):
            continue
        rs, gs, bs = [], [], []
        for dx in range(-PATCH, PATCH + 1, 2):
            for dy in range(-PATCH, PATCH + 1, 2):
                p = px[x + dx, y + dy]
                rs.append(p[0])
                gs.append(p[1])
                bs.append(p[2])
        kind = drawn((median(rs), median(gs), median(bs)))
        flag = FLAGS.get((kind, s))
        if flag:
            counts[flag] = counts.get(flag, 0) + 1
            marks.ellipse((x - 7, y - 7, x + 7, y + 7), outline=(255, 0, 0), width=2)
    if counts:
        im.save(os.path.join(d, 'check-' + stem + '.png'))
    return counts


def main():
    d = sys.argv[1]
    rows = []
    for name in sorted(os.listdir(d)):
        if name.endswith('.txt') and os.path.exists(os.path.join(d, name[:-4] + '.png')):
            c = check(d, name[:-4])
            if c:
                rows.append((sum(c.values()), name[:-4], c))
    rows.sort(reverse=True)
    for n, stem, c in rows:
        print('%-18s %4d  %s' % (stem, n, ', '.join('%s %d' % (k, v) for k, v in sorted(c.items(), key=lambda kv: -kv[1]))))
    if not rows:
        print('no mismatches')


if __name__ == '__main__':
    main()
