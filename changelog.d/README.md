# Changelog fragments

Each change adds its entry here as its own file, never at the top of
`CHANGELOG.md`, so that pull requests landing side by side do not all
conflict on the same lines.

- One file per pull request, named `YYYY-MM-DD-short-slug.md` (the date the
  change was made, then a few words: `2026-11-18-buried-finds.md`).
- The file is the entry exactly as it will read in `CHANGELOG.md`: a
  `## YYYY-MM-DD - Title` heading, a blank line, then the bullets.
- `python tools/changelog.py` folds every fragment into `CHANGELOG.md`, newest
  first under its header, and deletes the fragments. Run it in its own PR
  now and then, and always before a release's notes are written.
- `python tools/changelog.py --check` (run by CI) fails on a fragment that
  is not named or headed that way.
