#!/usr/bin/env python3
"""Fill walk/chapter sections in site/index.html and generate site/walks/<id>.html.

Reads walk, chapter, dog, training, wardrobe, and goal metadata dumped from the
game into tools/site_walks_data.json (by tools/site_walks.gd) together with
the place descriptions in site/walks.json.

Flags:
  --from=DIR   read DIR/tools/site_walks_data.json when present (used in CI on
               workflow_run triggers where the tagged release lives in DIR/)
  --godot=BIN  refresh tools/site_walks_data.json via BIN --headless --path .
               --script res://tools/site_walks.gd before generating
  --check      do not write; exit 1 if site/index.html or any page under
               site/walks/ is missing, extra, or differs from what would be
               written
"""
from __future__ import annotations

import html
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DATA_REL = pathlib.Path("tools/site_walks_data.json")
PLACE_FILE = ROOT / "site" / "walks.json"
INDEX_FILE = ROOT / "site" / "index.html"
WALKS_DIR = ROOT / "site" / "walks"
IMG_DIR = ROOT / "site" / "img"

FREEDOM_LABEL = {
    "yard": "Fenced dog yard",
    "placa": "Open plaça",
    "beach": "Dog beach",
    "clearing": "Wooded clearing",
    "lot": "Open lot",
}

SKY_LABEL = {
    "clear": "Clear",
    "wind": "Windy",
    "rain": "Rain",
    "snow": "Snow",
}

HOUR_LABEL = {
    "day": "Day",
    "dawn": "Dawn",
    "dusk": "Dusk",
    "night": "Night",
}

BOSS_INFO = {
    "ciutadella": (
        "El Mamut",
        "The life-size stone mammoth by Parc de la Ciutadella's cascada steps off its plinth. Wrap it up or bait its charge into the boating lake.",
    ),
    "guell": (
        "El Drac",
        "The trencadís mosaic dragon holds the grand stairway. Wind the leash round the stone columns, dodge the tail sweep, and trip the beast on the tiles.",
    ),
    "port": (
        "Els Lleons",
        "Twin bronze harbor lions guard Columbus's column along the wharf. Lead their pincer charge round the iron mooring bollards and into one another.",
    ),
    "raval": (
        "El Gat",
        "Rambla del Raval's plump bronze cat prowls beneath the palms, scattering pigeons and leaping across awnings until you fling your human straight into him.",
    ),
}

WALK_BLOCK = re.compile(
    r"<!--\s*walks:([a-z0-9_]+)\s*-->.*?<!--\s*/walks:\1\s*-->",
    re.DOTALL,
)
UNKNOWN_WALK = re.compile(r"<!--\s*walks:([a-z0-9_]+)\s*-->")


def esc(text: object) -> str:
    return html.escape(str(text), quote=True)


def sky_text(w: dict) -> str:
    weather = SKY_LABEL.get(w["weather"], w["weather"].title())
    hour = HOUR_LABEL.get(w["hour"], w["hour"].title())
    return f"{weather}, {hour.lower()}"


def kind_badge(w: dict) -> tuple[str, str]:
    if w.get("is_boss"):
        return ("Boss", "badge badge-boss")
    if w.get("is_chase"):
        return ("Chase", "badge badge-chase")
    if w.get("is_tutorial"):
        return ("Tutorial", "badge badge-tut")
    return ("", "")


def format_clock(seconds: int) -> str:
    if seconds <= 0:
        return ""
    mins, secs = divmod(seconds, 60)
    return f"{mins}:{secs:02d}"


def load_data(from_dir: pathlib.Path | None, godot_bin: str | None) -> dict:
    if godot_bin:
        cmd = [
            godot_bin,
            "--headless",
            "--path",
            str(ROOT),
            "--script",
            "res://tools/site_walks.gd",
        ]
        subprocess.run(cmd, check=True)
    candidates = []
    if from_dir is not None:
        candidates.append(from_dir / DATA_REL)
    candidates.append(ROOT / DATA_REL)
    for cand in candidates:
        if cand.is_file():
            return json.loads(cand.read_text(encoding="utf-8"))
    raise SystemExit(f"missing {ROOT / DATA_REL}; run tools/site_walks.gd first")


def validate_inputs(data: dict, places: dict, check_images: bool) -> list[str]:
    ordered_ids: list[str] = []
    for ch in data["chapters"]:
        for wid in ch:
            if wid not in data["walks"]:
                raise SystemExit(f"walk {wid!r} missing from tools/site_walks_data.json")
            if wid not in places:
                raise SystemExit(f"walk {wid!r} missing from site/walks.json")
            entry = places[wid]
            if not entry.get("about", "").strip():
                raise SystemExit(f"walk {wid!r} has empty 'about' in site/walks.json")
            shots = entry.get("shots", [])
            if len(shots) < 2 or len(shots) > 3:
                raise SystemExit(f"walk {wid!r} must have 2 or 3 shots in site/walks.json")
            if check_images:
                for shot in shots:
                    p = IMG_DIR / shot["file"]
                    if not p.is_file():
                        raise SystemExit(f"missing screenshot {p.relative_to(ROOT)} for {wid!r}")
            ordered_ids.append(wid)
    return ordered_ids


def render_chapter_nav(data: dict) -> str:
    items = []
    for idx, ch in enumerate(data["chapters"], 1):
        items.append(
            f'<a class="chapter-pill" href="#chapter-{idx}">'
            f'Chapter {idx} <span class="pill-count">({len(ch)})</span></a>'
        )
    return "\n  ".join(items)


def render_chapters(data: dict, places: dict) -> str:
    chapters = data["chapters"]
    walks = data["walks"]
    sections = []
    for idx, ch in enumerate(chapters, 1):
        end_w = walks[ch[-1]]
        if end_w["is_boss"]:
            boss_name = BOSS_INFO.get(end_w["id"], (end_w["name"], ""))[0]
            sub = f"{len(ch)} walks &middot; Ends on boss: {esc(end_w['name'])} ({esc(boss_name)})"
        else:
            sub = f"{len(ch)} walks &middot; Culminates at {esc(end_w['name'])}"
        cards = []
        for wid in ch:
            w = walks[wid]
            p = places[wid]
            shot = p["shots"][0]
            cls = ["walk-card"]
            if w["is_boss"]:
                cls.append("is-boss")
            elif w["is_chase"]:
                cls.append("is-chase")
            elif w["is_tutorial"]:
                cls.append("is-tutorial")
            badges = []
            b_label, b_cls = kind_badge(w)
            if b_label:
                badges.append(f'<span class="{b_cls}">{esc(b_label)}</span>')
            if w["weather"] != "clear" or w["hour"] != "day":
                badges.append(f'<span class="badge badge-sky">{esc(sky_text(w))}</span>')
            badge_html = (
                f'<span class="walk-badges">{"".join(badges)}</span>'
                if badges
                else ""
            )
            cards.append(
                f'<a class="{" ".join(cls)}" href="walks/{esc(wid)}.html">'
                f'<img src="img/{esc(shot["file"])}" alt="{esc(shot["alt"])}" '
                f'width="960" height="540" loading="lazy">'
                f'<span class="walk-card-body">'
                f'{badge_html}'
                f'<span class="walk-name">{esc(w["name"])}</span>'
                f'<span class="walk-gloss">{esc(w["gloss"])}</span>'
                f'</span>'
                f'</a>'
            )
        sections.append(
            f'<section class="chapter" id="chapter-{idx}">\n'
            f'  <div class="chapter-head">\n'
            f'    <h3>Chapter {idx}</h3>\n'
            f'    <p class="chapter-sub">{sub}</p>\n'
            f'  </div>\n'
            f'  <div class="walk-grid">\n'
            f'    ' + "\n    ".join(cards) + "\n"
            f'  </div>\n'
            f'</section>'
        )
    return "\n\n".join(sections)


def render_bosses(data: dict, places: dict) -> str:
    walks = data["walks"]
    cards = []
    for wid in data["boss_walks"]:
        w = walks[wid]
        p = places[wid]
        boss_name, blurb = BOSS_INFO[wid]
        shot = p["shots"][1] if len(p["shots"]) > 1 else p["shots"][0]
        cards.append(
            f'<a class="walk-card is-boss boss-card" href="walks/{esc(wid)}.html">'
            f'<img src="img/{esc(shot["file"])}" alt="{esc(shot["alt"])}" '
            f'width="960" height="540" loading="lazy">'
            f'<span class="walk-card-body">'
            f'<span class="walk-badges">'
            f'<span class="badge badge-boss">Chapter {w["chapter"]} boss</span>'
            f'</span>'
            f'<span class="walk-name">{esc(boss_name)} <span class="walk-place">({esc(w["name"])})</span></span>'
            f'<span class="walk-gloss">{esc(blurb)}</span>'
            f'</span>'
            f'</a>'
        )
    return "\n  ".join(cards)


def render_chases(data: dict) -> str:
    walks = data["walks"]
    links = []
    for wid in data["chase_walks"]:
        w = walks[wid]
        links.append(f'<li><a href="walks/{esc(wid)}.html">{esc(w["name"])}</a></li>')
    return "\n  ".join(links)


# a stat as a bar: where this dog's multiplier sits between the softest and the
# strongest of the pack, never quite empty
def _stat_bar(label: str, value: float, lo: float, hi: float) -> str:
    frac = 0.12 + 0.88 * max(0.0, min(1.0, (value - lo) / max(hi - lo, 0.001)))
    return (
        f'    <div class="dog-stat"><span class="dog-stat-name">{esc(label)}</span>'
        f'<span class="dog-stat-bar"><span style="width:{round(frac * 100)}%"></span></span></div>\n'
    )


def render_dogs(data: dict) -> str:
    dogs = data["dogs"]
    stats = [("Speed", "speed_mult"), ("Grip", "plant_mult"), ("Heft", "mass_mult")]
    span = {k: (min(d.get(k, 1.0) for d in dogs), max(d.get(k, 1.0) for d in dogs)) for _, k in stats}
    cards = []
    for dog in dogs:
        unlock = "Starter" if dog["stars"] == 0 else f'{dog["stars"]} stars'
        bars = "".join(_stat_bar(label, dog.get(k, 1.0), *span[k]) for label, k in stats)
        skill = ""
        if dog.get("skill"):
            skill = (
                f'  <p class="dog-skill"><span class="dog-skill-name">{esc(dog["skill"])}</span> '
                f'{esc(dog.get("skill_goal", ""))}</p>\n'
            )
        alt = f'{dog["name"]}, the {dog["breed"]}, side on'
        cards.append(
            '<div class="card dog-card">\n'
            f'  <img class="dog-portrait" src="img/dog-{esc(dog["id"])}.png" alt="{esc(alt)}" '
            'width="360" height="240" loading="lazy">\n'
            '  <div class="dog-head">\n'
            f'    <h3>{esc(dog["name"])}</h3>\n'
            f'    <span class="badge badge-star">{esc(unlock)}</span>\n'
            '  </div>\n'
            f'  <p class="dog-breed">{esc(dog["breed"])} &middot; {esc(dog["trait"])}</p>\n'
            f'  <p class="dog-desc">{esc(dog["desc"])}</p>\n'
            f'{skill}'
            f'  <div class="dog-stats">\n{bars}  </div>\n'
            '</div>'
        )
    return "\n".join(cards)


def render_wardrobe(data: dict) -> str:
    wd = data["wardrobe"]
    tr = data["training"]
    nl = wd["new_look"]

    collar_pills = []
    for c in wd["collars"]:
        cost = "Starter" if c["cost"] == 0 else f'{c["cost"]} bones'
        collar_pills.append(
            f'<span class="swatch-item">'
            f'<span class="swatch" style="background:{esc(c["color"])}"></span>'
            f'{esc(c["name"])} <span class="item-cost">({esc(cost)})</span>'
            f'</span>'
        )

    bandana_pills = []
    for b in wd["bandanas"]:
        if not b["color"]:
            continue
        bandana_pills.append(
            f'<span class="swatch-item">'
            f'<span class="swatch" style="background:{esc(b["color"])}"></span>'
            f'{esc(b["name"].replace(" bandana", ""))} <span class="item-cost">({b["cost"]} bones)</span>'
            f'</span>'
        )

    coat_pills = []
    for coat in wd["coats"]:
        cost = "Starter" if coat["cost"] == 0 else f'{coat["cost"]} bones'
        coat_pills.append(
            f'<span class="swatch-item">'
            f'<span class="swatch swatch-duo" style="background:linear-gradient(135deg, {esc(coat["fur"])} 55%, {esc(coat["mark"])} 55%)"></span>'
            f'{esc(coat["name"])} <span class="item-cost">({esc(cost)})</span>'
            f'</span>'
        )

    stats_list = ", ".join(s.capitalize() for s in tr["stats"])
    return (
        f'<div class="wardrobe-grid">\n'
        f'  <div class="card wardrobe-card">\n'
        f'    <h3>Collars</h3>\n'
        f'    <p>Sets the color of the leash itself.</p>\n'
        f'    <div class="swatch-list">{"".join(collar_pills)}</div>\n'
        f'  </div>\n'
        f'  <div class="card wardrobe-card">\n'
        f'    <h3>Bandanas</h3>\n'
        f'    <p>Optional cloth around the neck ({len(wd["bandanas"]) - 1} colors).</p>\n'
        f'    <div class="swatch-list">{"".join(bandana_pills)}</div>\n'
        f'  </div>\n'
        f'  <div class="card wardrobe-card">\n'
        f'    <h3>Coats</h3>\n'
        f'    <p>Six coat markings ({len(wd["coats"])} styles).</p>\n'
        f'    <div class="swatch-list">{"".join(coat_pills)}</div>\n'
        f'  </div>\n'
        f'  <div class="card wardrobe-card">\n'
        f'    <h3>Training &amp; New Look</h3>\n'
        f'    <p>Every buried find she digs up and every skill goal she meets is a training point for her. Spend them on {len(tr["stats"])} stats ({esc(stats_list)}), up to {tr["max_points"]} levels each; a level costs as many points as the level it reaches. Roll a <strong>New Look</strong> for your human before heading out: {nl["skins"]} skin tones, {nl["hair_colors"]} hair colors, {len(nl["her_styles"])} + {len(nl["his_styles"])} hairstyles, {nl["shirts"]} shirts, {nl["trousers"]} trousers and {nl["shoes"]} shoe styles.</p>\n'
        f'  </div>\n'
        f'</div>'
    )


def render_walk_page(
    wid: str,
    data: dict,
    places: dict,
    ordered_ids: list[str],
) -> str:
    w = data["walks"][wid]
    p = places[wid]
    idx = ordered_ids.index(wid)
    prev_id = ordered_ids[idx - 1] if idx > 0 else ""
    next_id = ordered_ids[idx + 1] if idx + 1 < len(ordered_ids) else ""
    walks = data["walks"]

    badges = [f'<a class="badge badge-chapter" href="../#chapter-{w["chapter"]}">Chapter {w["chapter"]}</a>']
    b_label, b_cls = kind_badge(w)
    if b_label:
        badges.append(f'<span class="{b_cls}">{esc(b_label)}</span>')
    badges.append(f'<span class="badge badge-sky">{esc(sky_text(w))}</span>')
    if w["star_gate"] > 0:
        badges.append(f'<span class="badge badge-star">Unlocks at {w["star_gate"]} stars</span>')
    elif w["chase_gate"]:
        badges.append(
            f'<span class="badge badge-star">Unlocks after {esc(w["chase_gate_name"])}</span>'
        )

    shots_html = []
    for shot in p["shots"]:
        shots_html.append(
            f'<figure>'
            f'<a href="../img/{esc(shot["file"])}">'
            f'<img src="../img/{esc(shot["file"])}" alt="{esc(shot["alt"])}" width="960" height="540" loading="lazy">'
            f'</a>'
            f'<figcaption>{esc(shot["caption"])}</figcaption>'
            f'</figure>'
        )

    facts = []
    if w["gate_text"]:
        free_desc = FREEDOM_LABEL.get(w["freedom_kind"], w["freedom_kind"])
        facts.append(
            f'<div><dt>Off-leash stop</dt><dd>{esc(w["gate_text"])} ({esc(free_desc)})</dd></div>'
        )
    if w["clock_target"] > 0:
        facts.append(
            f'<div><dt>Beat the clock</dt><dd>Under {esc(format_clock(w["clock_target"]))}</dd></div>'
        )
    if w.get("is_boss") and wid in BOSS_INFO:
        facts.append(
            f'<div><dt>Boss</dt><dd>{esc(BOSS_INFO[wid][0])}</dd></div>'
        )
    if w.get("is_chase") and w.get("chase_warning"):
        facts.append(
            f'<div><dt>Turnaround warning</dt><dd>{esc(w["chase_warning"])}</dd></div>'
        )

    facts_html = (
        f'<dl class="facts walk-facts">\n  ' + "\n  ".join(facts) + "\n</dl>"
        if facts
        else ""
    )

    if w["is_tutorial"]:
        lessons = []
        for lesson in w.get("lessons", []):
            tag = ' <span class="lesson-tag">off the leash</span>' if lesson["free"] else ""
            lessons.append(f'<li>{esc(lesson["title"])}{tag}</li>')
        goals_section = (
            f'<h2>Lessons ({len(lessons)})</h2>\n'
            f'<ol class="goal-list">\n  ' + "\n  ".join(lessons) + "\n</ol>"
        )
    else:
        goal_items = [f'<li>{esc(g["text"])}</li>' for g in w.get("goals", [])]
        goals_section = (
            f'<h2>Goals ({len(goal_items)})</h2>\n'
            f'<ol class="goal-list">\n  ' + "\n  ".join(goal_items) + "\n</ol>"
        )

    nav_parts = []
    if prev_id:
        pw = walks[prev_id]
        nav_parts.append(
            f'<a class="walk-pager-link" href="{esc(prev_id)}.html">&larr; {esc(pw["name"])}</a>'
        )
    else:
        nav_parts.append('<span></span>')
    nav_parts.append(
        f'<a class="walk-pager-mid" href="../#chapter-{w["chapter"]}">Chapter {w["chapter"]} walks</a>'
    )
    if next_id:
        nw = walks[next_id]
        nav_parts.append(
            f'<a class="walk-pager-link walk-pager-next" href="{esc(next_id)}.html">{esc(nw["name"])} &rarr;</a>'
        )
    else:
        nav_parts.append('<span></span>')

    first_shot = p["shots"][0]["file"]
    title = f'{w["name"]} — Path of Leash Resistance'
    desc = f'{w["gloss"]}. {p["about"]}'

    return (
        f'<!doctype html>\n'
        f'<html lang="en">\n'
        f'<head>\n'
        f'<meta charset="utf-8">\n'
        f'<meta name="viewport" content="width=device-width, initial-scale=1">\n'
        f'<title>{esc(title)}</title>\n'
        f'<meta name="description" content="{esc(desc)}">\n'
        f'<meta property="og:title" content="{esc(title)}">\n'
        f'<meta property="og:description" content="{esc(w["gloss"])}">\n'
        f'<meta property="og:type" content="website">\n'
        f'<meta property="og:image" content="../img/{esc(first_shot)}">\n'
        f'<link rel="icon" href="../img/icon.png">\n'
        f'<link rel="preload" href="../fonts/BricolageGrotesque.ttf" as="font" type="font/ttf" crossorigin>\n'
        f'<link rel="stylesheet" href="../palette.css">\n'
        f'<link rel="stylesheet" href="../style.css">\n'
        f'</head>\n'
        f'<body>\n'
        f'<div class="tiles"></div>\n'
        f'<div class="wrap">\n'
        f'\n'
        f'<nav class="crumb" aria-label="Breadcrumb">\n'
        f'  <a href="../">&larr; Path of Leash Resistance</a> &middot; '
        f'<a href="../#chapter-{w["chapter"]}">Chapter {w["chapter"]}</a>\n'
        f'</nav>\n'
        f'\n'
        f'<header class="top walk-top">\n'
        f'  <div class="walk-badges">{"".join(badges)}</div>\n'
        f'  <h1>{esc(w["name"])}</h1>\n'
        f'  <p class="pitch">{esc(w["gloss"])}</p>\n'
        f'</header>\n'
        f'\n'
        f'<div class="card walk-about">\n'
        f'  <p>{esc(p["about"])}</p>\n'
        f'</div>\n'
        f'\n'
        f'{facts_html}\n'
        f'\n'
        f'<h2>Screenshots</h2>\n'
        f'<div class="grid walk-shots">\n'
        f'  ' + "\n  ".join(shots_html) + "\n"
        f'</div>\n'
        f'\n'
        f'{goals_section}\n'
        f'\n'
        f'<nav class="walk-pager" aria-label="Walk navigation">\n'
        f'  ' + "\n  ".join(nav_parts) + "\n"
        f'</nav>\n'
        f'\n'
        f'<footer>\n'
        f'  <a href="../">Path of Leash Resistance</a> &middot; <a href="../press/">Press kit</a> &middot; Made by Santtu Nykänen\n'
        f'</footer>\n'
        f'\n'
        f'</div>\n'
        f'</body>\n'
        f'</html>\n'
    )


def fill_blocks(path: pathlib.Path, blocks: dict[str, str]) -> str:
    text = path.read_text(encoding="utf-8")
    seen: set[str] = set()

    def replace(m: re.Match[str]) -> str:
        name = m.group(1)
        seen.add(name)
        if name not in blocks:
            raise SystemExit(f"{path.relative_to(ROOT)}: unknown walks block {name!r}")
        return f"<!-- walks:{name} -->\n{blocks[name]}\n<!-- /walks:{name} -->"

    out = WALK_BLOCK.sub(replace, text)
    for m in UNKNOWN_WALK.finditer(out):
        if m.group(1) not in seen:
            raise SystemExit(f"{path.relative_to(ROOT)}: unclosed walks block {m.group(1)!r}")
    return out


def parse_args(argv: list[str]) -> tuple[bool, pathlib.Path | None, str | None]:
    check = False
    from_dir: pathlib.Path | None = None
    godot_bin: str | None = None
    for arg in argv:
        if arg == "--check":
            check = True
        elif arg.startswith("--from="):
            from_dir = pathlib.Path(arg.split("=", 1)[1])
        elif arg.startswith("--godot="):
            godot_bin = arg.split("=", 1)[1]
        else:
            raise SystemExit(f"unknown argument: {arg}")
    return check, from_dir, godot_bin


def main() -> int:
    check, from_dir, godot_bin = parse_args(sys.argv[1:])
    data = load_data(from_dir, godot_bin)
    places = json.loads(PLACE_FILE.read_text(encoding="utf-8"))
    ordered_ids = validate_inputs(data, places, check_images=check)

    blocks = {
        "chapter_nav": render_chapter_nav(data),
        "chapters": render_chapters(data, places),
        "bosses": render_bosses(data, places),
        "chases": render_chases(data),
        "dogs": render_dogs(data),
        "wardrobe": render_wardrobe(data),
    }

    stale: list[str] = []
    index_out = fill_blocks(INDEX_FILE, blocks)
    index_cur = INDEX_FILE.read_text(encoding="utf-8")
    if index_out != index_cur:
        if check:
            stale.append(str(INDEX_FILE.relative_to(ROOT)))
        else:
            INDEX_FILE.write_text(index_out, encoding="utf-8", newline="\n")

    if not check:
        WALKS_DIR.mkdir(parents=True, exist_ok=True)

    expected_files = {f"{wid}.html" for wid in ordered_ids}
    if WALKS_DIR.is_dir():
        for existing in sorted(WALKS_DIR.glob("*.html")):
            if existing.name not in expected_files:
                if check:
                    stale.append(f"extra:{existing.relative_to(ROOT)}")
                else:
                    existing.unlink()

    for wid in ordered_ids:
        page_path = WALKS_DIR / f"{wid}.html"
        page_out = render_walk_page(wid, data, places, ordered_ids)
        page_cur = page_path.read_text(encoding="utf-8") if page_path.is_file() else ""
        if page_out != page_cur:
            if check:
                stale.append(str(page_path.relative_to(ROOT)))
            else:
                page_path.write_text(page_out, encoding="utf-8", newline="\n")

    if stale:
        print(
            "stale walk pages (run python tools/site_walks.py): "
            + ", ".join(stale[:10])
            + (f" (+{len(stale) - 10} more)" if len(stale) > 10 else ""),
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
