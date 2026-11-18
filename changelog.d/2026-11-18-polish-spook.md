## 2026-11-18 - Polish La Castanyada

- The festival yard past the gate is paved from house front to house front, but off the walk's own width it handled as grass. It is paving now, the dance floor included, soft only in its tree pits and planters (`Castanyada.surface`, through `Surfaces.paved_past_gate`); the street up to the gate handles as before.
- The yard's trees drew the forest's roots, which poked out past their crowns like sticks. They stand in their pits as broadleaves now (`Castanyada.draw_grove`, through `main.broadleaf_grove`).
- The lanterns' light on the yard's ground and the lit windows' spill were stacks of flat discs, whose edges showed as faint rings. They are soft gradients now, in the same batch (`ShapeBatch.glow`).
- The yard was darker than the street that leads to it. Its house fronts carry wall lamps now, two down each side (`Castanyada.night_lights`: the street's own lamps and `main.freedom_side_lamps`). The walk's own night is unchanged.
- `tests/test_castanyada.gd` covers the yard's paving and a tree pit, the trees and the wall lamps.
