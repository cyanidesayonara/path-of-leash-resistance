## 2026-11-18 - Polish La Neteja

- Every walk's name had a dark rim round its pieces since the names were painted offscreen (#612): the offscreen pass leaves its colours multiplied by their coverage, and drawing it with plain alpha multiplied them again. `world/sign_layer.gd` draws it premultiplied.
- Passeig Marítim's name, laid in sand on the promenade, was a string of tan beads with a brown outline. It is a pale drift now (`WorldSign._sand`): a dusting along each stroke, low mounds lit on the sun's side with only a soft contact shadow, loose grains round them, and a paw spreads a heap flatter and paler and kicks its grains wider.
- The other dog walkers and their dogs walked through bin bags, cans and cones as if they were not there; they shove them aside now as your human does (`cone.gd`, `main.pairs_cache`). `tests/test_junk_pairs.gd`.
- La Rambla's carnation names were hard to read: on the bare cream paving the flower heads blended in. Each is planted in a municipal flower bed now (`WorldSign._flower_planter`): a granite kerb round a rectangle of dark soil and fine ground cover, the letters a band of bright foliage set with the carnations, which stays when the flowers are kicked about.
- The x2 STREAK chip on the vitals card sat over the last of the five marked drops. It starts after them, and where the word will not fit there (always, on that card) it is the bare count, "x2".
- The plaça's worn patch was a hard-edged flat disc. It is drawn soft now, fading into the flags (La Neteja is on `main.SOFT_WEAR`).
- The plaça handled as grass wall to wall but is paved. It is pavement now, soft only in its plane trees' pits (`Neteja.surface`, through `Surfaces.paved_past_gate`). Surface-check mismatches in the off-leash area went from 377 to 50, and at the shot before the gate from 99 to 36.
- The plaça's plane trees drew the forest's roots, which poked out past their crowns like sticks. They stand in their pits as broadleaves now (`Neteja.draw_grove`, through `main.broadleaf_grove`).
- After dark the plaça was unlit. Its house fronts carry wall lamps now, two down each side (`Neteja.night_lights`: the street's own lamps and `main.freedom_side_lamps`). The walk's own dawn is unchanged.
- `tests/test_neteja_polish.gd` covers the paving, a tree pit, the street short of the gate, the soft wear, the trees and the wall lamps.
