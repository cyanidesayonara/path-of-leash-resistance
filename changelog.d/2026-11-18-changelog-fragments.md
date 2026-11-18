## 2026-11-18 - Changelog entries as fragments

- Every change adds its changelog entry as its own file in `changelog.d/` (`YYYY-MM-DD-short-slug.md`, the entry as it will read) instead of at the top of `CHANGELOG.md`, where pull requests landing side by side all conflicted on the same lines. `python tools/changelog.py` folds the fragments in, newest first; `--check` runs in CI. `changelog.d/README.md` says how, and AGENTS.md points to it.
