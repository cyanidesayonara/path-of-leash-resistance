## 2026-11-24 - The campaign starts fresh

- A save from before the finished campaign starts again: walks, stars, bones, the wardrobe, dogs, training, finds, achievements, your human's look and the tutorial are all a new player's. Settings are kept (`Game.SAVE_VERSION`).
- A returning player is told on the main menu, until their first new save. Loading writes nothing, and the old file is kept beside the new one as `records_before_campaign.cfg`.
- The gate tables of four older campaign orders, and the code that kept walks open across them, are gone.
- A screenshot run no longer saves anything: losing focus wrote its `--lang` into the player's settings.
- `tests/test_save_reset.gd`.
