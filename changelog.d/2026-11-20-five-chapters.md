## 2026-11-20 - The campaign stays five chapters as walks are added

- `Game.chapters()` still cuts the carousel after each boss, but now halves the longest run between bosses until there are five chapters (`Game.CHAPTERS`), one for each chapter achievement. Before, a run past twelve walks split on its own, so adding one walk to the last chapter made a sixth chapter with no achievement, which failed `test_achievements` on the Tarragona, Vic and theme park PRs. Today's chapters are unchanged.
- `Game.chapters_of(carousel)` gives the chapters any carousel would make; `tests/test_chapters.gd` uses it to check that four more walks still make five chapters.
