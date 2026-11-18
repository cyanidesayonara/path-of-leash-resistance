## 2026-11-18 - Polish Platja de Llevant

- The two groins out into the sea and the espigó across the water at the gate were rows of round pebbles of nearly one size, each with a pale dot on top, which read as strings of beads. They are runs of tipped granite now: two staggered courses of angular blocks of every size, each with its shadow and a lit facet (`Llevant._rock_run`, through `world/stones.gd`'s `Stones.lit_stone`).
- The espigó is the walk's own (`Llevant.draw_espigo`, a new `draw_espigo` hook on `main._draw_espigo`), so La Cremada's and Sitges' dog beaches keep their breakwater as it was.
- New `tests/test_llevant.gd` covers the groins' rock from end to end and on its line, and the espigó's hook.
