"""Put this release's "What's new" into a Partner Center submission.

Reads the JSON that `msstore submission get` printed (log lines and all),
takes the text of the first "What's new in this version" block in
store/listing.md, writes it to every listing's ReleaseNotes, and saves the
payload for `msstore submission updateMetadata`. The description, features
and keywords are left as they are in Partner Center.

    python tools/store_whats_new.py submission.json store/listing.md out.json
"""

import json
import re
import sys


def whats_new(listing_md: str) -> str:
    m = re.search(r"### What's new in this version[^\n]*\n+```\n(.*?)\n```", listing_md, re.S)
    if not m:
        raise SystemExit("store/listing.md has no \"What's new in this version\" block")
    return m.group(1).strip()


def submission(raw: str) -> dict:
    # msstore prints log lines around the JSON
    start, end = raw.find("{"), raw.rfind("}")
    if start < 0 or end < start:
        raise SystemExit("no JSON in the submission output")
    return json.loads(raw[start:end + 1])


def main() -> int:
    sub_path, listing_path, out_path = sys.argv[1:4]
    sub = submission(open(sub_path, encoding="utf-8").read())
    notes = whats_new(open(listing_path, encoding="utf-8").read())
    listings = sub.get("Listings")
    if not isinstance(listings, dict) or not listings:
        raise SystemExit("submission JSON has no Listings")
    for lang, entry in listings.items():
        base = entry.get("BaseListing")
        if not isinstance(base, dict):
            raise SystemExit(f"listing {lang} has no BaseListing")
        base["ReleaseNotes"] = notes
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(sub, f, indent=2)
    print(f"ReleaseNotes set for {', '.join(listings)}:\n{notes}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
