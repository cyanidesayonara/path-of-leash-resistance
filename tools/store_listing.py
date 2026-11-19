"""The Store listing's text, from store/listing.md into a Partner Center draft.

store/listing.md has "## Current listing" (English, en-US), plus localized
"## Current listing (ca-ES)" and "## Current listing (es-ES)" sections. Each
field is a "### <name>" heading followed by one fenced block. Lists (product
features, keywords) are one item per line.

    python tools/store_listing.py --check store/listing.md
        checks every field in all three languages is inside the Store's limits

    python tools/store_listing.py submission.json store/listing.md out.json
        reads the JSON that `msstore submission get` printed (log lines and
        all), updates matching language entries in Listings (cloning en-US's
        BaseListing structure for ca-ES and es-ES when missing), and saves
        the payload for `msstore submission updateMetadata`

    python tools/store_listing.py --selftest store/listing.md
        smoke-checks the submission updater against a synthetic submission in
        a temporary directory

The screenshots and logos are staged by tools/store_images.py.
"""

import copy
import json
import os
import re
import sys
import tempfile

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
# these live on the submission itself; the rest on each language's BaseListing
SUBMISSION_LEVEL = {"NotesForCertification"}

LANG_ALIASES = {
    "en": "en-US",
    "en-us": "en-US",
    "ca": "ca-ES",
    "ca-es": "ca-ES",
    "es": "es-ES",
    "es-es": "es-ES",
}
CHECK_LANGS = ("en-US", "ca-ES", "es-ES")


def normalize_lang(lang: str) -> str:
    norm = LANG_ALIASES.get(lang.strip().lower().replace("_", "-"))
    if not norm:
        raise SystemExit(f"unsupported listing language: {lang}")
    return norm


def lang_for_listing_key(key: str):
    low = key.strip().lower().replace("_", "-")
    if low == "en" or low.startswith("en-"):
        return "en-US"
    if low == "ca" or low.startswith("ca-"):
        return "ca-ES"
    if low == "es" or low.startswith("es-"):
        return "es-ES"
    return None


def current_section(md: str, lang: str = "en") -> str:
    canon = normalize_lang(lang)
    if canon == "en-US":
        pat = r"^## Current listing[ \t]*\n(.*?)(?=^## |\Z)"
        label = "## Current listing"
    else:
        pat = r"^## Current listing \(" + re.escape(canon) + r"\)[ \t]*\n(.*?)(?=^## |\Z)"
        label = f"## Current listing ({canon})"
    m = re.search(pat, md, re.S | re.M)
    if not m:
        raise SystemExit(f'store/listing.md has no "{label}" section')
    return m.group(1)


def fields(md: str, lang: str = "en") -> dict:
    canon = normalize_lang(lang)
    sec = current_section(md, canon)
    label = "## Current listing" if canon == "en-US" else f"## Current listing ({canon})"
    out = {}
    for name, (key, is_list, _, _) in FIELDS.items():
        if key in SUBMISSION_LEVEL and canon != "en-US":
            continue
        m = re.search(r"^### " + re.escape(name) + r"[^\n]*\n+```\n(.*?)\n```", sec, re.S | re.M)
        if not m:
            raise SystemExit(f'"{label}" has no "### {name}" block')
        text = m.group(1).strip()
        out[key] = [ln.strip() for ln in text.splitlines() if ln.strip()] if is_list else text
    return out


def check(vals: dict, lang: str = "en") -> list:
    canon = normalize_lang(lang)
    problems = []
    for name, (key, is_list, limit, most) in FIELDS.items():
        if key in SUBMISSION_LEVEL and canon != "en-US":
            continue
        if key not in vals:
            problems.append(f"{name}: missing")
            continue
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
    if "Keywords" in vals:
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


def update_submission(sub: dict, by_lang: dict, verbose: bool = True) -> dict:
    listings = sub.get("Listings")
    if not isinstance(listings, dict) or not listings:
        raise SystemExit("submission JSON has no Listings")

    # pick a template entry (preferring en-US / en*) to clone BaseListing for missing locales
    template_key = None
    for k in listings:
        if k.lower().replace("_", "-") == "en-us":
            template_key = k
            break
    if template_key is None:
        for k in listings:
            if lang_for_listing_key(k) == "en-US":
                template_key = k
                break
    if template_key is None:
        template_key = next(iter(listings))
    template_entry = listings[template_key]
    template_base = template_entry.get("BaseListing") if isinstance(template_entry, dict) else None
    if not isinstance(template_base, dict):
        raise SystemExit(f"listing {template_key} has no BaseListing")

    matched_langs = set()
    for lang_key, entry in listings.items():
        base = entry.get("BaseListing") if isinstance(entry, dict) else None
        if not isinstance(base, dict):
            raise SystemExit(f"listing {lang_key} has no BaseListing")
        target = lang_for_listing_key(lang_key)
        if not target:
            if verbose:
                print(f"note: leaving unknown listing {lang_key} untouched")
            continue
        matched_langs.add(target)
        for key, v in by_lang[target].items():
            if key in SUBMISSION_LEVEL:
                continue
            if key not in base and verbose:
                print(f"note: {lang_key} BaseListing had no {key}; adding it")
            base[key] = v

    for target in ("ca-ES", "es-ES"):
        if target in matched_langs:
            continue
        cloned_entry = {"BaseListing": copy.deepcopy(template_base)}
        if "PlatformOverrides" in template_entry and not template_entry["PlatformOverrides"]:
            cloned_entry["PlatformOverrides"] = {}
        for key, v in by_lang[target].items():
            if key in SUBMISSION_LEVEL:
                continue
            cloned_entry["BaseListing"][key] = v
        listings[target] = cloned_entry
        if verbose:
            print(f"note: added {target} listing cloned from {template_key}")

    for key in SUBMISSION_LEVEL:
        if key not in sub and verbose:
            print(f"note: the submission had no {key}; adding it")
        sub[key] = by_lang["en-US"][key]
    return sub


def selftest(listing_path: str) -> int:
    md = open(listing_path, encoding="utf-8").read()
    by_lang = {lang: fields(md, lang) for lang in CHECK_LANGS}
    with tempfile.TemporaryDirectory() as tmp:
        # Case 1: only en-US exists -> ca-ES and es-ES must be cloned and localized
        sub_path = os.path.join(tmp, "submission.json")
        out_path = os.path.join(tmp, "out.json")
        synthetic = {
            "Id": "115292150569",
            "Listings": {
                "en-US": {
                    "BaseListing": {
                        "Title": "Path of Leash Resistance",
                        "ShortTitle": "Leash Resistance",
                        "CopyrightAndTrademarkInfo": "© 2026 Santtu Nykänen",
                        "DevelopedBy": "Santtu Nykänen",
                        "Description": "stale",
                        "ShortDescription": "stale",
                        "Features": ["stale"],
                        "Keywords": ["stale"],
                        "ReleaseNotes": "stale",
                        "Images": [{"ImageType": "Screenshot", "FileName": "shot.png"}],
                    },
                    "PlatformOverrides": {},
                }
            },
            "NotesForCertification": "stale",
        }
        with open(sub_path, "w", encoding="utf-8") as fh:
            fh.write("msstore: fetching draft...\n" + json.dumps(synthetic) + "\ndone.\n")
        _run_update(sub_path, listing_path, out_path, verbose=False)
        out = json.load(open(out_path, encoding="utf-8"))
        for lang in CHECK_LANGS:
            assert lang in out["Listings"], f"missing {lang}"
            base = out["Listings"][lang]["BaseListing"]
            assert base["Title"] == "Path of Leash Resistance"
            assert base["Images"] == [{"ImageType": "Screenshot", "FileName": "shot.png"}]
            for key, v in by_lang[lang].items():
                if key not in SUBMISSION_LEVEL:
                    assert base[key] == v, f"{lang} mismatch on {key}"
        assert out["NotesForCertification"] == by_lang["en-US"]["NotesForCertification"]

        # Case 2: lowercase ca-es already present -> updated in place without adding ca-ES
        sub2_path = os.path.join(tmp, "sub2.json")
        out2_path = os.path.join(tmp, "out2.json")
        synthetic2 = copy.deepcopy(synthetic)
        synthetic2["Listings"]["ca-es"] = {"BaseListing": {"Title": "Path of Leash Resistance"}}
        with open(sub2_path, "w", encoding="utf-8") as fh:
            json.dump(synthetic2, fh)
        _run_update(sub2_path, listing_path, out2_path, verbose=False)
        out2 = json.load(open(out2_path, encoding="utf-8"))
        assert set(out2["Listings"].keys()) == {"en-US", "ca-es", "es-ES"}
        assert out2["Listings"]["ca-es"]["BaseListing"]["Description"] == by_lang["ca-ES"]["Description"]
    print("store listing selftest: OK (synthetic submission cases passed)")
    return 0


def _run_update(sub_path: str, listing_path: str, out_path: str, verbose: bool = True) -> dict:
    md = open(listing_path, encoding="utf-8").read()
    by_lang = {}
    all_problems = []
    for lang in CHECK_LANGS:
        vals = fields(md, lang)
        by_lang[lang] = vals
        for p in check(vals, lang):
            all_problems.append(f"{lang}: {p}")
    if all_problems:
        raise SystemExit("\n".join(all_problems))
    sub = submission(open(sub_path, encoding="utf-8").read())
    update_submission(sub, by_lang, verbose=verbose)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(sub, f, indent=2, ensure_ascii=False)
    return by_lang


def main() -> int:
    if len(sys.argv) == 3 and sys.argv[1] == "--check":
        md = open(sys.argv[2], encoding="utf-8").read()
        all_problems = []
        counts = {}
        for lang in CHECK_LANGS:
            vals = fields(md, lang)
            counts[lang] = len(vals)
            for p in check(vals, lang):
                all_problems.append(f"{lang}: {p}")
        for p in all_problems:
            print("STORE LISTING: " + p)
        if not all_problems:
            summary = ", ".join(f"{lang}: {counts[lang]} fields" for lang in CHECK_LANGS)
            print(f"store listing ({summary}), all inside the Store's limits")
        return 1 if all_problems else 0
    if len(sys.argv) == 3 and sys.argv[1] == "--selftest":
        return selftest(sys.argv[2])
    if len(sys.argv) < 4:
        raise SystemExit(
            "usage: store_listing.py --check LISTING.md | --selftest LISTING.md | SUBMISSION.json LISTING.md OUT.json"
        )
    sub_path, listing_path, out_path = sys.argv[1:4]
    by_lang = _run_update(sub_path, listing_path, out_path, verbose=True)
    out = json.load(open(out_path, encoding="utf-8"))
    print(f"Listing text set for {', '.join(out['Listings'])}:")
    for lang, vals in by_lang.items():
        print(f"=== {lang} ===")
        for key, v in vals.items():
            print(f"--- {key}")
            print("\n".join(v) if isinstance(v, list) else v)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
