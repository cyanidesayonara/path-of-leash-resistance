## 2026-11-18 - Polish Sarrià

- The worn patch in the middle of the Plaça de Sant Vicenç, past the gate, was a hard-edged flat disc. It is drawn soft now, fading into the flags (Sarrià is on `main.SOFT_WEAR`).
- The plaça's plane trees drew the forest's roots, which poked out past their crowns like sticks. They stand in their pits as broadleaves now (`Sarria.draw_grove`, through `main.broadleaf_grove`).
- The plaça handled as paving right across, its tree pits and planters included. They are soft earth now (`Sarria.surface`, through `Surfaces.paved_past_gate`); the rest of the walk is paved as before.
- After dark the plaça was unlit. Its house fronts carry wall lamps now, two down each side (`Sarria.night_lights`: the street's own lamps and `main.freedom_side_lamps`). The walk's own dawn is unchanged.
- `tests/test_sarria.gd` covers the paving and a tree pit, the soft wear, the trees and the wall lamps.
