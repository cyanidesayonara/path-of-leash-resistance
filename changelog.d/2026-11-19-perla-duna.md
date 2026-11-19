## 2026-11-19 - Two new dogs: Perla the ratonero and Duna the podenco

- **Perla**, a ratonero bodeguero, the Andalusian ratter of the wine cellars, unlocked at 55 stars: small, square and busy. A white dog with her coat's colour as a saddle and a head, a white blaze, tan brow spots, small pricked ears with folded tips and a short tail carried high (drawn on the mongrel's frame at 0.84, `entities/dog.gd` BODY_PLAN). She digs in about half the time (`dig_mult` 1.9, buried finds and a yard's dig patches), noses a little further, and is quick off the mark. Her skill goal: "Dig up 2 holes".
- **Duna**, a podenco, unlocked at 65 stars: the galgo's long frame with huge upright ears, a white chest and blaze, and a long stride. Running into a bench, she clears it in a standing jump: the bench lets her through for the leap while she arcs over it ("Hup!", `DogSkills.tick_leap`). Her skill goal: "Leap 2 benches".
- In the films Duna is drawn on the galgo's side-on frame and Perla on Millie's, at full size for now.
- Resetting the save now also clears training points, dug-up finds and met skill goals (`Game._reset_persisted_state`), which it had missed since they were added.
- "Finish a walk with every dog" instead of "with all 5 dogs".
- Each has an idle quirk and a bark of her own: Perla a quick scrabble at the ground and a sharp terrier double bark; Duna ears up tall, listening, and a hound's higher yelp.
- `tests/test_dog_skills.gd` covers both dogs' goals, Perla's digging, Duna's leap (meeting a real bench, passing through it, landing, the bench solid again, one leap per bench) and the reset.
