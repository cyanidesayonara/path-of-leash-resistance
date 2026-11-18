## 2026-11-18 - Each walk declares what main asks of it in its own file

- Walk PRs side by side kept colliding on shared lists: `SOFT_WEAR` in main.gd four times in one day, the hook declarations in `tests/test_walk_hooks.gd`, the end of `tests/ci_tests.txt`. Each now lives with the walk:
  - a walk module's hooks are its own `const HOOKS := [...]` (all 46 moved); `tests/test_walk_hooks.gd` reads them from each module and fails a module that declares none;
  - a soft worn patch past the gate is `const SOFT_WEAR := true` in the module, read into `main.soft_wear` when the walk is set (La Neteja, El Besòs, Sarrià, El Tibidabo);
  - `tools/run_tests.sh` reads `tests/ci.d/*.txt` after `tests/ci_tests.txt`, so a walk's or feature's new tests go in a file of its own (`tests/ci.d/README.md`).
- No player-facing change.
