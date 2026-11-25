## 2026-11-25 - A lighter touch on GitHub

- A pull request runs one test job with only the tests its change needs (`tools/pick_tests.py`); a merge runs nothing again; everything runs on a version tag, weekly and by hand. The screenshot sweep and the idle soak are by hand only. The rules are in `docs/ci-budget.md`.
