## 2026-11-18 - No dark rim round the labels, sand that reads as sand, and two fixes

- Every walk's name had a dark rim round its pieces since the names were painted offscreen (#612): the offscreen pass leaves its colours multiplied by their coverage, and drawing it with plain alpha multiplied them again. `world/sign_layer.gd` draws it premultiplied.
- Passeig Marítim's name, laid in sand on the promenade, was a string of tan beads with a brown outline. It is a pale drift now (`WorldSign._sand`): a dusting along each stroke, low mounds lit on the sun's side with only a soft contact shadow, loose grains round them, and a paw spreads a heap flatter and paler and kicks its grains wider.
- The other dog walkers and their dogs walked through bin bags, cans and cones as if they were not there; they shove them aside now as your human does (`cone.gd`, `main.pairs_cache`). `tests/test_junk_pairs.gd`.
- The x2 STREAK chip on the vitals card sat over the last of the five marked drops. It starts after them, and where the word will not fit there (always, on that card) it is the bare count, "x2".
