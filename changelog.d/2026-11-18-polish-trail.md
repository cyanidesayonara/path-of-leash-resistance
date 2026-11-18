## 2026-11-18 - Polish El Bosc

- La Clariana, the clearing past the gate, is drawn as grass from edge to edge, but it handled as pavement down the middle, where the trail's width ran on past the gate. It is lawn underfoot right across now (`Bosc.surface`, through `Surfaces.lawn_past_gate`); the trail up to the gate handles as before.
- The trodden earth in the middle of the clearing was a hard-edged flat disc. It is drawn soft now, fading into the grass (El Bosc is on `main.SOFT_WEAR`).
- `tests/test_bosc.gd` covers the clearing's lawn, the way in from the gate, the trail itself and the soft wear.
