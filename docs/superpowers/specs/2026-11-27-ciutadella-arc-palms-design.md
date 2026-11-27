# La Ciutadella: Arc crown and promenade palms

Approved 2026-11-27. One player-facing art change. No gameplay change.

## Problem

On the Passeig de Lluís Companys the street palms are seven green sticks in a
square pit. The Arc de Triomf's crown is two gold discs with a pair of lines
for wings. Both read as unfinished against the rest of the walk.

## Approach

Reuse the palm the beach and the port already draw (`main._palm_crown`,
`main._palm_trunk`). Redraw only the Arc crown as Barcelona's shield and bat
from above. One file: `systems/ciutadella.gd`.

## Palms

In `draw_edge_layer`, keep the granite kerb and soil pit. Drop the stick
burst and the small trunk disc. Call `m._palm_crown(b, pp)` so the trunk,
seven fronds and leaflets match the beach. Keep a ground shadow disc, a
little larger than today, under the crown. Still inside the edge
`ShapeBatch`, so no new draw call.

## Arc crown

In `draw_overhead`, keep the brick span and the stone frieze. Replace the
two discs and wing lines with:

- a pointed gold shield
- Sant Jordi's cross (pale arms)
- the four bars (red stripes on gold in the lower half)
- a bat above the shield whose wings are two tapered shapes

Same gold already used on that span. Still one overhead batch flush.

## Out of scope

Les Atraccions art, El Mamut feel, chase feel, a shared palm helper kit,
and the Cascada's Quadriga (already drawn with horses).

## Check

- Existing `tests/test_ciutadella.gd` stays green.
- Shot of the Arc (`--level=ciutadella --shot-y=-80`) and of the promenade
  palms (`--level=ciutadella --shot-y=100`): palms read as palms, the crown
  reads as Barcelona's shield and bat.
