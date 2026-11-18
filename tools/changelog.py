"""Fold changelog.d/ fragments into CHANGELOG.md, or check them.

Each pull request adds its entry as its own file in changelog.d/ (see
changelog.d/README.md), so entries landing side by side never conflict.

    python tools/changelog.py           fold the fragments in, newest first, and delete them
    python tools/changelog.py --check   fail on a misnamed or misheaded fragment
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRAG_DIR = os.path.join(ROOT, "changelog.d")
LOG = os.path.join(ROOT, "CHANGELOG.md")
NAME = re.compile(r"^(\d{4}-\d{2}-\d{2})-[a-z0-9][a-z0-9-]*\.md$")
HEAD = re.compile(r"^## (\d{4}-\d{2}-\d{2}) - \S")


def fragments():
    out = []
    if not os.path.isdir(FRAG_DIR):
        return out
    for f in sorted(os.listdir(FRAG_DIR)):
        if f == "README.md" or not f.endswith(".md"):
            continue
        out.append(f)
    return out


def problems():
    bad = []
    for f in fragments():
        m = NAME.match(f)
        if not m:
            bad.append("%s: name it YYYY-MM-DD-short-slug.md" % f)
            continue
        text = open(os.path.join(FRAG_DIR, f), encoding="utf-8").read()
        first = text.lstrip("﻿").split("\n", 1)[0]
        h = HEAD.match(first)
        if not h:
            bad.append("%s: start with '## YYYY-MM-DD - Title'" % f)
        elif h.group(1) != m.group(1):
            bad.append("%s: the heading's date is not the file's" % f)
        if "\r" in text:
            bad.append("%s: LF line endings only" % f)
    return bad


def fold():
    frags = fragments()
    if not frags:
        print("changelog: no fragments")
        return
    log = open(LOG, encoding="utf-8").read()
    i = log.index("\n## ") + 1
    # newest first: by date, then the later file of a day first
    frags.sort(reverse=True)
    entries = []
    for f in frags:
        t = open(os.path.join(FRAG_DIR, f), encoding="utf-8").read().strip("\n") + "\n\n"
        entries.append(t)
    log = log[:i] + "".join(entries) + log[i:]
    with open(LOG, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(log)
    for f in frags:
        os.remove(os.path.join(FRAG_DIR, f))
    print("changelog: folded %d fragments" % len(frags))


if __name__ == "__main__":
    bad = problems()
    if bad:
        for b in bad:
            print("changelog: " + b)
        sys.exit(1)
    if "--check" in sys.argv:
        print("changelog: %d fragments, all fine" % len(fragments()))
        sys.exit(0)
    fold()
