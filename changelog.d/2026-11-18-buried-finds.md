## 2026-11-18 - Buried finds, and training that buys her stats

- Every walk has three finds buried just off the path (`systems/buried_finds.gd`): in grass, sand or mud, never paving; on a paved walk in a street tree's pit or a stash tucked by a bench or a bin. The same spots every run, from a hash of the walk, never the RNG. 133 of the 138 are placed; a walk with nowhere soft to hide one has fewer.
- A faint scent rises off a find when she is close, further with a better nose. Stand still over it and she digs it up: a shout, three bones, and the first time that dog has it, a training point. A find she has had before is just a hole.
- Training, as a skater's stats are: each dog has her own points, earned by what she digs up, and spends them on her own stats in the wardrobe, a level at a time (level n costs n points, a maxed stat 15, a maxed dog 75). Stats no longer cost bones. A new stat, NOSE, reaches finds from further away; Millie, the beagle, starts with a better one (`nose_mult` 1.3).
- Every walk's finds are each dog's own, so 138 points are there for every dog, more than the 75 a dog can spend.
- Saved with the records (`Game.training`, `Game.finds_found`). `tests/test_buried_finds.gd`, listed in `tests/ci.d/buried-finds.txt`.
- `tests/ci.d/README.md` gave the wrong line format; it is the editor's arguments, as in `tests/ci_tests.txt`.
- `--shot-tab=collar|bandana|coat|stats` opens that wardrobe tab in a `--shot-menu=shop` shot.
