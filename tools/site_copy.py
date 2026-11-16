"""The website's copy, from the sources the release checklist already keeps
current, so the site cannot drift from the game or the Store.

Fills every <!-- gen:NAME --> ... <!-- /gen:NAME --> block in site/index.html
and site/press/index.html:

    count        the walk count in words ("Thirty-nine"), from Game.LEVELS
    walks        the walk names in campaign order, from Game.LEVEL_NAMES
    features     the Store's product features (store/listing.md)
    whatsnew     the Store's "What's new in this version"
    description  the Store's description, one paragraph per <p>

    python tools/site_copy.py           rewrites the blocks in place
    python tools/site_copy.py --check   exits 1 if any block is stale
    python tools/site_copy.py --from=DIR
        takes the listing and the walk list from another checkout (the
        released commit) while filling this one's pages

The Pages workflow runs it before every deploy, so the published site always
says what the listing and the game say, whether or not the committed pages
were refreshed. Rerun it locally to preview.
"""

import html
import os
import re
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SRC = ROOT
sys.path.insert(0, os.path.join(ROOT, "tools"))
import store_listing  # noqa: E402

# each page and the blocks it must carry; a missing or unclosed marker fails
PAGES = {
    "site/index.html": ["features", "whatsnew", "count", "walks"],
    "site/press/index.html": ["description"],
}

ONES = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight",
        "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen",
        "sixteen", "seventeen", "eighteen", "nineteen"]
TENS = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy",
        "eighty", "ninety"]


def words(n: int) -> str:
    if n < 20:
        w = ONES[n]
    elif n < 100:
        w = TENS[n // 10] + ("-" + ONES[n % 10] if n % 10 else "")
    else:
        w = str(n)
    return w[0].upper() + w[1:]


def walks() -> list:
    src = open(os.path.join(SRC, "autoload/game.gd"), encoding="utf-8").read()
    m = re.search(r"^const LEVELS[^=]*=\s*\[(.*?)\]", src, re.S | re.M)
    if not m:
        raise SystemExit("autoload/game.gd has no LEVELS")
    ids = re.findall(r'"([^"]+)"', m.group(1))
    m = re.search(r"^const LEVEL_NAMES := \{(.*?)^\}", src, re.S | re.M)
    if not m:
        raise SystemExit("autoload/game.gd has no LEVEL_NAMES")
    names = dict(re.findall(r'"([^"]+)":\s*"([^"]+)"', m.group(1)))
    missing = [i for i in ids if i not in names]
    if missing:
        raise SystemExit(f"walks without a name in LEVEL_NAMES: {missing}")
    return [names[i] for i in ids]


def blocks() -> dict:
    md = open(os.path.join(SRC, "store/listing.md"), encoding="utf-8").read()
    f = store_listing.fields(md)
    names = walks()
    def e(t):
        return html.escape(t, quote=False)
    news = [ln.lstrip("-* ").strip() for ln in f["ReleaseNotes"].splitlines() if ln.strip()]
    paras = [p.strip() for p in re.split(r"\n\s*\n", f["Description"]) if p.strip()]
    return {
        "count": words(len(names)),
        "walks": "\n".join(f"  <li>{e(n)}</li>" for n in names),
        "features": "\n".join(f"  <li>{e(x)}</li>" for x in f["Features"]),
        "whatsnew": "\n".join(f"  <li>{e(x)}</li>" for x in news),
        "description": "\n".join(f"  <p>{e(p)}</p>" for p in paras),
    }


BLOCK = re.compile(r"(<!-- gen:(\w+) -->)(.*?)(<!-- /gen:\2 -->)", re.S)
OPEN = re.compile(r"<!-- gen:(\w+) -->")
CLOSE = re.compile(r"<!-- /gen:(\w+) -->")


def markers_ok(rel: str, page: str, want: list) -> None:
    opens = OPEN.findall(page)
    closes = CLOSE.findall(page)
    whole = [m.group(2) for m in BLOCK.finditer(page)]
    problems = []
    for name in want:
        if name not in opens:
            problems.append(f"no <!-- gen:{name} --> marker")
    for name in set(opens) | set(closes):
        if opens.count(name) != 1 or closes.count(name) != 1 or whole.count(name) != 1:
            problems.append(f"gen:{name} needs exactly one opening and one closing marker")
    if problems:
        raise SystemExit(f"{rel}: " + "; ".join(sorted(set(problems))))


def fill(page: str, vals: dict) -> str:
    def sub(m):
        name = m.group(2)
        if name not in vals:
            raise SystemExit(f"unknown block gen:{name}")
        v = vals[name]
        # inline when the marker sits inside a line, a block of lines otherwise
        if "\n" in m.group(3) or "\n" in v:
            return f"{m.group(1)}\n{v}\n{m.group(4)}"
        return f"{m.group(1)}{v}{m.group(4)}"
    return BLOCK.sub(sub, page)


def main() -> int:
    global SRC
    check = "--check" in sys.argv[1:]
    for a in sys.argv[1:]:
        if a.startswith("--from="):
            SRC = os.path.abspath(a[len("--from="):])
    vals = blocks()
    stale = []
    for rel, want in PAGES.items():
        p = os.path.join(ROOT, rel)
        with open(p, encoding="utf-8", newline="") as fh:
            old = fh.read()
        markers_ok(rel, old, want)
        new = fill(old, vals)
        if new != old:
            stale.append(rel)
            if not check:
                with open(p, "w", encoding="utf-8", newline="") as fh:
                    fh.write(new)
    if check and stale:
        print("stale site copy, run python tools/site_copy.py and commit: " + ", ".join(stale))
        return 1
    print(("stale: " if check else "updated: ") + (", ".join(stale) or "nothing"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
