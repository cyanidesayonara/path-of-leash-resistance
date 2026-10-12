"""The Store listing's text, from store/listing.md into a Partner Center draft.

store/listing.md has one "## Current listing" section: what the Store should
say for the next submission. Each field is a "### <name>" heading followed by
one fenced block. Lists (product features, keywords) are one item per line.

    python tools/store_listing.py --check store/listing.md
        checks every field is there and inside the Store's limits (CI runs it)

    python tools/store_listing.py submission.json store/listing.md out.json
        reads the JSON that `msstore submission get` printed (log lines and
        all), writes every field into it, and saves the payload for
        `msstore submission updateMetadata` (.github/workflows/store-submit.yml)

Screenshots and logos are images and stay a Partner Center upload by hand.
"""

import json
import re
import sys

# heading in store/listing.md -> (key in the submission JSON, is a list, limit
# per item in characters, most items). Limits are Partner Center's.
FIELDS = {
    "Description": ("Description", False, 10000, 1),
    "Short description": ("ShortDescription", False, 1000, 1),
    "Product features": ("Features", True, 200, 20),
    "Keywords": ("Keywords", True, 30, 7),
    "What's new in this version": ("ReleaseNotes", False, 1500, 1),
    "Notes for certification": ("NotesForCertification", False, 2000, 1),
}
# these live on each language's BaseListing; the rest on the submission itself
SUBMISSION_LEVEL = {"NotesForCertification"}


def current_section(md: str) -> str:
    m = re.search(r"^## Current listing[^\n]*\n(.*?)(?=^## |\Z)", md, re.S | re.M)
    if not m:
        raise SystemExit('store/listing.md has no "## Current listing" section')
    return m.group(1)


def fields(md: str) -> dict:
    sec = current_section(md)
    out = {}
    for name, (key, is_list, _, _) in FIELDS.items():
        m = re.search(r"^### " + re.escape(name) + r"[^\n]*\n+```\n(.*?)\n```", sec, re.S | re.M)
        if not m:
            raise SystemExit(f'"## Current listing" has no "### {name}" block')
        text = m.group(1).strip()
        out[key] = [ln.strip() for ln in text.splitlines() if ln.strip()] if is_list else text
    return out


def check(vals: dict) -> list:
    problems = []
    for name, (key, is_list, limit, most) in FIELDS.items():
        v = vals[key]
        items = v if is_list else [v]
        if not items or not any(items):
            problems.append(f"{name}: empty")
        if len(items) > most:
            problems.append(f"{name}: {len(items)} items, the Store takes {most}")
        for it in items:
            if len(it) > limit:
                problems.append(f"{name}: {len(it)} characters, the Store takes {limit}: {it[:60]}...")
    # and no more than 21 words across all the search terms
    words = sum(len(k.split()) for k in vals["Keywords"])
    if words > 21:
        problems.append(f"Keywords: {words} words in all, the Store takes 21")
    return problems


def submission(raw: str) -> dict:
    # msstore prints log lines around the JSON
    start, end = raw.find("{"), raw.rfind("}")
    if start < 0 or end < start:
        raise SystemExit("no JSON in the submission output")
    return json.loads(raw[start:end + 1])


def main() -> int:
    if len(sys.argv) == 3 and sys.argv[1] == "--check":
        vals = fields(open(sys.argv[2], encoding="utf-8").read())
        problems = check(vals)
        for p in problems:
            print("STORE LISTING: " + p)
        if not problems:
            print("store listing: %d fields, all inside the Store's limits" % len(vals))
        return 1 if problems else 0
    sub_path, listing_path, out_path = sys.argv[1:4]
    vals = fields(open(listing_path, encoding="utf-8").read())
    problems = check(vals)
    if problems:
        raise SystemExit("\n".join(problems))
    sub = submission(open(sub_path, encoding="utf-8").read())
    listings = sub.get("Listings")
    if not isinstance(listings, dict) or not listings:
        raise SystemExit("submission JSON has no Listings")
    for lang, entry in listings.items():
        base = entry.get("BaseListing")
        if not isinstance(base, dict):
            raise SystemExit(f"listing {lang} has no BaseListing")
        for key, v in vals.items():
            if key in SUBMISSION_LEVEL:
                continue
            if key not in base:
                print(f"note: {lang} BaseListing had no {key}; adding it")
            base[key] = v
    for key in SUBMISSION_LEVEL:
        if key not in sub:
            print(f"note: the submission had no {key}; adding it")
        sub[key] = vals[key]
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(sub, f, indent=2, ensure_ascii=False)
    print(f"Listing text set for {', '.join(listings)}:")
    for key, v in vals.items():
        print(f"--- {key}")
        print("\n".join(v) if isinstance(v, list) else v)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
