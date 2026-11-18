## 2026-11-18 - Each dog's skill, and a skill goal on every walk

- Every dog has a signature skill and, on every walk, one skill goal that only she has (`systems/dog_skills.gd`). It is a row of its own under the walk's goals, set apart by a rule and her turquoise, and never counts toward the walk's goals or stars, so the campaign is as fair with one dog as another. The first time a dog meets it on a walk it is a training point for her, spent on her stats in the wardrobe like a buried find's; met again, it is the quieter "again" toast.
  - Millie, the nose: "Sniff out and dig up a buried find".
  - Pipa, the sprint: "Sprint flat out for 2 seconds", well past her own top speed on turbo, without a break.
  - Mochi, the plant: "Dig in and trip your human 2 times", planted as the leash yanks.
  - Bruna, the herd: "Herd your human for 5 seconds", leading him across the path on a steady pull while he walks on.
  - Tito, the squeeze: "Slip through 3 gaps only you fit", where a normal dog's body would touch solid things on both sides ("Squeeze!"). Her gaps are counted along the walk in the first seconds, a few rows a frame, and her target is what the walk has, up to three; a walk with none has no skill goal for her.
- Saved with the records (`Game.skills_done`). `--dog=NAME` walks that dog for a run, unsaved, for screenshots and playtests.
- `tests/test_dog_skills.gd` (32 checks), listed in `tests/ci.d/dog-skills.txt`.
