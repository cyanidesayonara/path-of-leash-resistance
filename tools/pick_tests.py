#!/usr/bin/env python3
"""Pick the tests a change needs, so a pull request runs one short job.

    python tools/pick_tests.py [BASE] > picks.txt
    PICK=picks.txt WALKS=1 bash tools/run_tests.sh

BASE is what the branch is compared with (default origin/main). Prints one item
a line, named as tools/run_tests.sh names them ("res://tests/test_x.gd", "walk
park"), within BUDGET seconds of a runner's time. Nothing is printed for a
change the game never reads (docs, the site, the changelog).

What is picked, in order, until the budget is spent:
 1. the changed tests, and the few every change runs (CORE);
 2. the walks whose module changed, or whose module uses a changed script;
 3. the tests named after a changed script, then those that mention one;
 4. for a change to what every walk stands on (WIDE), a few walks, which ones
    depending on the change, and the cheapest tests that are left.
The whole list runs on a version tag before anything is released, weekly on
main, and by hand (.github/workflows/ci.yml). It is the net; this is not.
"""
import hashlib
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUDGET = int(os.environ.get("BUDGET", "600"))
WALK_COST = 21
CORE = ["res://tests/test_wrap.gd", "res://tests/test_leash_setup.gd",
        "res://tests/test_walk_hooks.gd", "walk street"]
WIDE = re.compile(r"^(main\.gd|main\.tscn|project\.godot|autoload/|entities/(dog|human|leash|npc_figure)\.gd"
                  r"|world/(level_build|surfaces|edgelayer|vergelayer)\.gd|systems/(shape_batch|goals|shade|sky)\.gd"
                  r"|tools/(run_tests|godot_ci)\.sh|\.github/workflows/ci\.yml)")
GAME = re.compile(r"\.(gd|tscn|godot|gdshader|ttf|import)$|^tests/ci|^tools/(run_tests|godot_ci)\.sh$"
                  r"|^\.github/workflows/ci\.yml$")


def read(path) -> str:
    try:
        return (ROOT / path).read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return ""


def costs() -> dict:
    """Every test in the lists, with its seconds."""
    out, cost = {}, 5
    for f in [ROOT / "tests/ci_tests.txt"] + sorted((ROOT / "tests/ci.d").glob("*.txt")):
        for line in f.read_text(encoding="utf-8").splitlines():
            m = re.match(r"# cost (\d+)", line)
            if m:
                cost = int(m.group(1))
            elif line.strip() and not line.startswith("#"):
                t = re.search(r"res://tests/\w+\.gd", line)
                if t:
                    out[t.group(0)] = cost
                cost = 5
    return out


def walks() -> tuple:
    """The walks there are, and each walk's module."""
    levels = re.search(r"^const LEVELS: Array\[String\] = \[(.*)\]", read("autoload/game.gd"), re.M)
    names = re.findall(r'"(\w+)"', levels.group(1)) if levels else []
    mods = dict(re.findall(r'"(\w+)": preload\("res://([\w/]+\.gd)"\)', read("main.gd")))
    return names, {w: p for w, p in mods.items() if w in names}


def pick(changed: list) -> list:
    game = [c for c in changed if GAME.search(c)]
    if not game:
        return []
    cost = costs()
    names, mods = walks()
    scripts = [c for c in game if c.endswith(".gd") and not c.startswith(("tests/", "tools/"))]
    users = set(scripts)
    for path in mods.values():
        body = read(path)
        if any("res://" + s in body for s in scripts):
            users.add(path)
    bodies = {t: read(t[len("res://"):]) for t in cost}
    stems = [Path(s).stem for s in scripts]
    must = ["res://" + c for c in game if "res://" + c in cost] + CORE
    order = list(must)
    order += [f"walk {w}" for w, p in mods.items() if p in users]
    order += [t for t in bodies if any(Path(t).stem == f"test_{s}" for s in stems)]
    order += [t for t in bodies if any(s in Path(t).stem for s in stems if len(s) > 3)]
    order += sorted((t for t in bodies if any("res://" + s in bodies[t] for s in scripts if s != "main.gd")),
                    key=cost.get)
    if any(WIDE.search(c) for c in game):
        turn = int(hashlib.sha1("\n".join(game).encode()).hexdigest(), 16)
        if names:
            order += [f"walk {names[(turn + 13 * i) % len(names)]}" for i in range(4)]
        order += sorted(bodies, key=cost.get)
    out, spent = [], 0
    for item in order:
        if item in out or (item.startswith("res://") and item not in cost):
            continue
        c = cost.get(item, WALK_COST)
        if spent + c > BUDGET and item not in must:
            continue
        out.append(item)
        spent += c
    print(f"{len(out)} items, about {spent} s, for {len(game)} changed game files", file=sys.stderr)
    return out


def main() -> int:
    base = sys.argv[1] if len(sys.argv) > 1 else "origin/main"
    diff = subprocess.run(["git", "diff", "--name-only", f"{base}...HEAD"], cwd=ROOT,
                          capture_output=True, text=True, encoding="utf-8", check=True)
    for item in pick(diff.stdout.split("\n")):
        print(item)
    return 0


if __name__ == "__main__":
    sys.exit(main())
