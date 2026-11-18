## 2026-11-18 - Polish El Tibidabo

- The worn patch in the middle of the mirador, past the gate, was a hard-edged flat disc. It is drawn soft now, fading into the flags (El Tibidabo is on `main.SOFT_WEAR`).
- The mirador's trees drew the forest's roots, which poked out past their crowns like sticks. They stand in their pits as broadleaves now (`Tibidabo.draw_grove`, through `main.broadleaf_grove`).
- The mirador's flags handled as grass wall to wall. They are paving now, soft only in the tree pits and planters (`Tibidabo.surface`, through `Surfaces.paved_past_gate`), and the strip just inside the gate is paving too; the road up is paved as before.
- After dark the mirador was unlit. Its house fronts carry wall lamps now, two down each side (`Tibidabo.night_lights`: the street's own lamps and `main.freedom_side_lamps`). The walk's own foggy morning is unchanged.
- `tests/test_tibidabo.gd` covers the paving, the strip inside the gate and a tree pit, the soft wear, the trees and the wall lamps.
