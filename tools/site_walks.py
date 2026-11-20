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

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import site_i18n as I  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
DATA_REL = pathlib.Path("tools/site_walks_data.json")
PLACE_FILE = ROOT / "site" / "walks.json"
INDEX_FILE = ROOT / "site" / "index.html"
# every landing page: its language and the prefix from it to the site root
INDEX_PAGES = [
    (ROOT / "site" / "index.html", "en", ""),
    (ROOT / "site" / "ca" / "index.html", "ca", "../"),
    (ROOT / "site" / "es" / "index.html", "es", "../"),
]
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

BOSS_INFO = I.BOSS["en"]

WALK_BLOCK = re.compile(
    r"<!--\s*walks:([a-z0-9_]+)\s*-->.*?<!--\s*/walks:\1\s*-->",
    re.DOTALL,
)
UNKNOWN_WALK = re.compile(r"<!--\s*walks:([a-z0-9_]+)\s*-->")


def esc(text: object) -> str:
    return html.escape(str(text), quote=True)


def sky_text(w: dict, lang: str = "en") -> str:
    weather = I.SKY[lang].get(w["weather"], w["weather"].title())
    hour = I.HOUR[lang].get(w["hour"], w["hour"])
    return f"{weather}, {hour}"


def kind_badge(w: dict, lang: str = "en") -> tuple[str, str]:
    if w.get("is_boss"):
        return (I.ui(lang, "boss"), "badge badge-boss")
    if w.get("is_chase"):
        return (I.ui(lang, "chase"), "badge badge-chase")
    if w.get("is_tutorial"):
        return (I.ui(lang, "tutorial"), "badge badge-tut")
    return ("", "")


def gloss_of(w: dict, lang: str) -> str:
    return w.get(f"gloss_{lang}") or w["gloss"] if lang != "en" else w["gloss"]


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


def render_chapter_nav(data: dict, lang: str = "en") -> str:
    items = []
    for idx, ch in enumerate(data["chapters"], 1):
        items.append(
            f'<a class="chapter-pill" href="#chapter-{idx}">'
            f'{esc(I.ui(lang, "chapter", n=idx))} <span class="pill-count">({len(ch)})</span></a>'
        )
    return "\n  ".join(items)


def render_chapters(data: dict, places: dict, lang: str = "en", base: str = "") -> str:
    chapters = data["chapters"]
    walks = data["walks"]
    sections = []
    for idx, ch in enumerate(chapters, 1):
        end_w = walks[ch[-1]]
        n_walks = I.ui(lang, "walks_n", n=len(ch))
        if end_w["is_boss"]:
            boss_name = I.BOSS[lang].get(end_w["id"], (end_w["name"], ""))[0]
            tail = I.ui(lang, "ends_on_boss", walk=esc(end_w["name"]), boss=esc(boss_name))
        else:
            tail = I.ui(lang, "culminates", walk=esc(end_w["name"]))
        sub = f"{n_walks} &middot; {tail}"
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
            b_label, b_cls = kind_badge(w, lang)
            if b_label:
                badges.append(f'<span class="{b_cls}">{esc(b_label)}</span>')
            if w["weather"] != "clear" or w["hour"] != "day":
                badges.append(f'<span class="badge badge-sky">{esc(sky_text(w, lang))}</span>')
            badge_html = (
                f'<span class="walk-badges">{"".join(badges)}</span>'
                if badges
                else ""
            )
            gloss = gloss_of(w, lang)
            alt = shot["alt"] if lang == "en" else I.ui(lang, "card_alt", name=w["name"], gloss=gloss)
            cards.append(
                f'<a class="{" ".join(cls)}" href="{base}walks/{esc(wid)}.html">'
                f'<img src="{base}img/{esc(shot["file"])}" alt="{esc(alt)}" '
                f'width="960" height="540" loading="lazy">'
                f'<span class="walk-card-body">'
                f'{badge_html}'
                f'<span class="walk-name">{esc(w["name"])}</span>'
                f'<span class="walk-gloss">{esc(gloss)}</span>'
                f'</span>'
                f'</a>'
            )
        sections.append(
            f'<section class="chapter" id="chapter-{idx}">\n'
            f'  <div class="chapter-head">\n'
            f'    <h3>{esc(I.ui(lang, "chapter", n=idx))}</h3>\n'
            f'    <p class="chapter-sub">{sub}</p>\n'
            f'  </div>\n'
            f'  <div class="walk-grid">\n'
            f'    ' + "\n    ".join(cards) + "\n"
            f'  </div>\n'
            f'</section>'
        )
    return "\n\n".join(sections)


def render_bosses(data: dict, places: dict, lang: str = "en", base: str = "") -> str:
    walks = data["walks"]
    cards = []
    for wid in data["boss_walks"]:
        w = walks[wid]
        p = places[wid]
        boss_name, blurb = I.BOSS[lang][wid]
        shot = p["shots"][1] if len(p["shots"]) > 1 else p["shots"][0]
        alt = shot["alt"] if lang == "en" else f'{boss_name} ({w["name"]})'
        cards.append(
            f'<a class="walk-card is-boss boss-card" href="{base}walks/{esc(wid)}.html">'
            f'<img src="{base}img/{esc(shot["file"])}" alt="{esc(alt)}" '
            f'width="960" height="540" loading="lazy">'
            f'<span class="walk-card-body">'
            f'<span class="walk-badges">'
            f'<span class="badge badge-boss">{esc(I.ui(lang, "chapter_boss", n=w["chapter"]))}</span>'
            f'</span>'
            f'<span class="walk-name">{esc(boss_name)} <span class="walk-place">({esc(w["name"])})</span></span>'
            f'<span class="walk-gloss">{esc(blurb)}</span>'
            f'</span>'
            f'</a>'
        )
    return "\n  ".join(cards)


def render_chases(data: dict, lang: str = "en", base: str = "") -> str:
    walks = data["walks"]
    links = []
    for wid in data["chase_walks"]:
        w = walks[wid]
        links.append(f'<li><a href="{base}walks/{esc(wid)}.html">{esc(w["name"])}</a></li>')
    return "\n  ".join(links)


# every chase walk's film, in campaign order; a chase without a film yet is left out
def render_chase_films(data: dict, lang: str = "en", base: str = "") -> str:
    figs = []
    for wid in data["chase_walks"]:
        if wid not in I.CHASE_FILMS:
            continue
        clip, words = I.CHASE_FILMS[wid]
        alt, cap = words[lang]
        figs.append(
            f'<figure><a href="{base}walks/{esc(wid)}.html"><img src="{base}img/{esc(clip)}.gif" alt="{esc(alt)}" '
            f'width="320" height="180" loading="lazy"></a><figcaption>{esc(cap)}</figcaption></figure>'
        )
    return "\n  ".join(figs)


# a stat as a bar: her value against the best in the pack, so an ordinary
# dog shows as middling rather than as nothing
def _stat_bar(label: str, value: float, best: float) -> str:
    frac = max(0.08, min(1.0, value / max(best, 0.001)))
    return (
        f'    <div class="dog-stat"><span class="dog-stat-name">{esc(label)}</span>'
        f'<span class="dog-stat-bar"><span style="width:{round(frac * 100)}%"></span></span></div>\n'
    )


DOG_STATS = ["speed", "agility", "plant", "nose", "herd"]


def render_dogs(data: dict, lang: str = "en", base: str = "") -> str:
    dogs = data["dogs"]
    best = {k: max(d["stats"][k] for d in dogs) for k in DOG_STATS}
    cards = []
    for dog in dogs:
        did = dog["id"]
        unlock = I.ui(lang, "starter") if dog["stars"] == 0 else I.ui(lang, "stars", n=dog["stars"])
        bars = "".join(_stat_bar(I.STATS[lang][k], dog["stats"][k], best[k]) for k in DOG_STATS)
        breed = dog["breed"] if lang == "en" else I.BREED[lang].get(dog["breed"], dog["breed"])
        trait = dog["trait"] if lang == "en" else (dog.get(f"trait_{lang}") or dog["trait"])
        desc = dog["desc"] if lang == "en" else I.DOG_DESC[lang].get(did, dog["desc"])
        goal = dog["skill_goal"] if lang == "en" else (dog.get(f"skill_goal_{lang}") or dog["skill_goal"])
        skill = ""
        if goal:
            skill = (
                f'  <p class="dog-skill"><span class="dog-skill-name">{esc(I.SKILL[lang][did])}</span> '
                f'{esc(goal)}</p>\n'
            )
        alt = I.ui(lang, "dog_alt", name=dog["name"], breed=breed if lang != "en" else dog["breed"])
        cards.append(
            '<div class="card dog-card">\n'
            f'  <img class="dog-portrait" src="{base}img/dog-{esc(did)}.png" alt="{esc(alt)}" '
            'width="360" height="240" loading="lazy">\n'
            '  <div class="dog-head">\n'
            f'    <h3>{esc(dog["name"])}</h3>\n'
            f'    <span class="badge badge-star">{esc(unlock)}</span>\n'
            '  </div>\n'
            f'  <p class="dog-breed">{esc(breed)} &middot; {esc(trait)}</p>\n'
            f'  <p class="dog-desc">{esc(desc)}</p>\n'
            f'{skill}'
            f'  <div class="dog-stats">\n{bars}  </div>\n'
            '</div>'
        )
    return "\n".join(cards)


def _item_name(item: dict, lang: str) -> str:
    return item["name"] if lang == "en" else (item.get(f"name_{lang}") or item["name"])


def render_wardrobe(data: dict, lang: str = "en") -> str:
    wd = data["wardrobe"]
    tr = data["training"]
    nl = wd["new_look"]

    def cost_text(c: int) -> str:
        return I.ui(lang, "starter") if c == 0 else I.ui(lang, "bones", n=c)

    collar_pills = []
    for c in wd["collars"]:
        collar_pills.append(
            f'<span class="swatch-item">'
            f'<span class="swatch" style="background:{esc(c["color"])}"></span>'
            f'{esc(_item_name(c, lang))} <span class="item-cost">({esc(cost_text(c["cost"]))})</span>'
            f'</span>'
        )

    bandana_pills = []
    for b in wd["bandanas"]:
        if not b["color"]:
            continue
        name = _item_name(b, lang)
        if lang == "en":
            name = name.replace(" bandana", "")
        bandana_pills.append(
            f'<span class="swatch-item">'
            f'<span class="swatch" style="background:{esc(b["color"])}"></span>'
            f'{esc(name)} <span class="item-cost">({esc(cost_text(b["cost"]))})</span>'
            f'</span>'
        )

    coat_pills = []
    for coat in wd["coats"]:
        coat_pills.append(
            f'<span class="swatch-item">'
            f'<span class="swatch swatch-duo" style="background:linear-gradient(135deg, {esc(coat["fur"])} 55%, {esc(coat["mark"])} 55%)"></span>'
            f'{esc(_item_name(coat, lang))} <span class="item-cost">({esc(cost_text(coat["cost"]))})</span>'
            f'</span>'
        )

    stats_list = ", ".join(I.STATS[lang][s] for s in tr["stats"])
    training_p = I.ui(
        lang, "training_p", n=len(tr["stats"]), stats=esc(stats_list), max=tr["max_points"],
        skins=nl["skins"], hair=nl["hair_colors"], styles=len(nl["her_styles"]) + len(nl["his_styles"]),
        shirts=nl["shirts"], trousers=nl["trousers"], shoes=nl["shoes"],
    )
    return (
        f'<div class="wardrobe-grid">\n'
        f'  <div class="card wardrobe-card">\n'
        f'    <h3>{I.ui(lang, "collars")}</h3>\n'
        f'    <p>{I.ui(lang, "collars_p")}</p>\n'
        f'    <div class="swatch-list">{"".join(collar_pills)}</div>\n'
        f'  </div>\n'
        f'  <div class="card wardrobe-card">\n'
        f'    <h3>{I.ui(lang, "bandanas")}</h3>\n'
        f'    <p>{I.ui(lang, "bandanas_p", n=len(wd["bandanas"]) - 1)}</p>\n'
        f'    <div class="swatch-list">{"".join(bandana_pills)}</div>\n'
        f'  </div>\n'
        f'  <div class="card wardrobe-card">\n'
        f'    <h3>{I.ui(lang, "coats")}</h3>\n'
        f'    <p>{I.ui(lang, "coats_p", n=len(wd["coats"]))}</p>\n'
        f'    <div class="swatch-list">{"".join(coat_pills)}</div>\n'
        f'  </div>\n'
        f'  <div class="card wardrobe-card">\n'
        f'    <h3>{I.ui(lang, "training")}</h3>\n'
        f'    <p>{training_p}</p>\n'
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

    stale: list[str] = []
    for page, lang, base in INDEX_PAGES:
        blocks = {
            "chapter_nav": render_chapter_nav(data, lang),
            "chapters": render_chapters(data, places, lang, base),
            "bosses": render_bosses(data, places, lang, base),
            "chases": render_chases(data, lang, base),
            "chase_films": render_chase_films(data, lang, base),
            "dogs": render_dogs(data, lang, base),
            "wardrobe": render_wardrobe(data, lang),
        }
        out = fill_blocks(page, blocks)
        cur = page.read_text(encoding="utf-8")
        if out != cur:
            if check:
                stale.append(str(page.relative_to(ROOT)))
            else:
                page.write_text(out, encoding="utf-8", newline="\n")

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
