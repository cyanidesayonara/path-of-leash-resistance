# HANDOVER — Path of Leash Resistance

A complete brief for another AI agent (or human) picking up this project.
Read this first, then `AGENTS.md` (technical map), `PROJECT.md` (design +
release plan), and `CHANGELOG.md` (what changed when).

---

## 1. What this is

A top-down physics comedy game in **Godot 4.7 / GDScript**. You play a
dog. Your owner is glued to their phone and walks on autopilot. You are
joined by a **leash that is real verlet-rope physics** — the heart of
the game. A walk is a round trip: out to a destination, an off-leash
romp, then home.

- **Title:** Path of Leash Resistance. **Tagline:** "you are the dog. go
  touch grass." (Renamed from "Touch Grass" — that name is a trademarked
  Steam game. "touch grass" survives as flavor only.)
- **Repo:** github.com/cyanidesayonara/path-of-leash-resistance (public).
  Local: `c:\Users\Santtu\projects\path-of-leash-resistance`.
- **Ships to:** itch.io as a browser (HTML5) build for playtesting; the
  intended product is a premium Steam desktop release; mobile is a later
  port (touch controls already work).
- **Real pets are cameos:** the dog is **Millie** (scruffy black mutt,
  salt-and-pepper on head/muzzle, floppy ears, whippy tail, butt wiggle,
  red harness, white-tipped paws). The cat is **Tofu** (white with brown
  on top, pink harness, friendly but skittish, keeps a respectful
  distance — and in real life is an escape artist, which is why a
  "bring Tofu home" quest is planned).
- The owner (Santtu) is a Gofore full-stack dev in Barcelona; the
  passeig level is his actual daily walk (Passeig Marítim, Badalona).
  His girlfriend is a watercolor/oil artist who will do the real art.

## 2. Design pillars (do not violate)

1. The comedy is the mechanic — physics produces the jokes, not cutscenes.
2. Temptation vs duty — score/joy on one side, the owner's safety on the
   other; every level negotiates between them.
3. The human is a payload, not an AI — dumb, heavy, predictable,
   telegraphed. Never unfair.
4. Soft failure — slapstick, dense checkpoints, instant retry. The phone
   cracks (3 = over) or someone falls down a hole (instant over); nobody
   truly gets hurt.
5. The leash is an honest rope, exaggerated — winding, cinching,
   tetherball, flinging are core verbs. THE ROPE IS THE SINGLE SOURCE OF
   TRUTH: never reintroduce separate wrap/pivot bookkeeping (three past
   attempts all desynced from the visual rope — see CHANGELOG "the rope
   IS the constraint"). Physics claims get a headless test BEFORE
   shipping.

## 3. How to run / test / release (Windows, PowerShell + Bash tools)

Godot 4.7 lives portably in `godot/` (gitignored). Key commands:

- **Play it:** `godot\Godot_v4.7-stable_win64.exe --path .`
- **Rope regression test:**
  `godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_wrap.gd`
- **Per-level smoke test (catches script errors):**
  `...console.exe --headless --path . --quit-after 1800 -- --level=park`
  (levels: street, park, beach, market; add `--daily` for the daily.)
- **Full-loop attract/CI bot (out→freedom→home→finish):**
  `...console.exe --headless --fixed-fps 60 --path . --quit-after 12000 -- --level=street --autowalk`
  MUST use `--fixed-fps 60` or headless frame count ≠ physics time and it
  falsely "stalls". Look for `AUTOWALK FINISHED` in the log.
- **Web export + zip for itch:**
  `...console.exe --headless --path . --export-release "Web" build/web/index.html`
  then `Compress-Archive -Path build\web\* -DestinationPath leash-resistance-web.zip -Force`
  (export templates are installed at `%APPDATA%\Godot\export_templates\4.7.stable\`).
- **CI** (`.github/workflows/ci.yml`, Ubuntu): focused rope, critter, tangle,
  freedom-traffic, pair-direction, bandana, owner-label, bypasser-route,
  rider-avoidance, and generalized pair-obstacle regressions + 4-level smoke
  + full autowalk traversal. The suite runs on every push.

**Release ritual each version:** implement → run all tests + launch to
eyeball → update CHANGELOG.md + version label in main.gd (`version_l`) →
`git commit`, `git tag vX.Y`, `git push --tags` → re-export zip. Santtu
uploads the zip to itch manually.

**Gotcha:** renaming the project folder tends to hit a Windows directory
lock; use robocopy /MOVE as a fallback (has happened twice).

## 4. Architecture

Single gameplay scene `main.tscn` = one Node2D running `main.gd` (~2100
lines — the god object: level data, state machine, HUD, all systems).
Everything is procedural vector art drawn in `_draw()`; no art assets.

- `game.gd` — **autoload `Game`**: session + save state (level/owner/
  night/weather, records, stars, bones wallet, cosmetics, daily seed).
  Save file `user://records.cfg`.
- `main.gd` — level build (branch per level in `_build_level_data`),
  `_physics_process` loop, phase machine (`phase` = out|freedom|home),
  HUD (`hud_panel.gd` card + quest card), menu (`_apply_menu_step`,
  steps 0 splash / 1 choose-walk / 2 ready, + shop), all spawners and
  interactions, `_draw` for the world.
- `dog.gd` — Millie (player). Move/plant/pee/turbo, swimming, drawing
  incl. equipped cosmetics. `auto`/`auto_move` for the bot.
- `human.gd` — the owner (payload). Autopilot walk (homeward flag flips
  direction on the way back), telegraphed events (call/text/dash/selfie/
  film/bench), whirl (tetherball), chore chain (poop→bag→bin), wading,
  parked (off-leash).
- `leash.gd` — the verlet rope AND the gameplay constraint. Segment-vs-
  circle pole collision, stick-slip friction, capstan, `detached` (off-
  leash), `resnap()`, `dynamic_obstacles` (another rope's points → the
  tangle).
- Entities: `bike.gd` (riders: bikes + kids), `squirrel.gd` (squirrel/
  rat/cat=Tofu), `pigeon.gd` (pigeons/gulls), `duckling.gd`, `cone.gd`
  (kickable), `astand.gd` (toppleable), `ball.gd` (fetch), `freedog.gd`
  (off-leash dogs), `otherpair.gd` (NPC owner+dog+their own leash).
- `weather_overlay.gd`, `touch_controls.gd`, `hud_panel.gd`.
- Concept art mocks (SVG, layout guides for the watercolour artist) in
  `assets/concept/`.

**Performance pattern (important):** entities must NOT call
`get_tree().get_nodes_in_group()` per frame. main builds
`riders_cache` / `critters_cache` / `birds_cache` once per physics tick
and entities read those. `_draw` culls to the camera window. HUD strings
rebuild at ~7 Hz, not every frame.

## 5. Feature state at v1.5 (all shipped, tested)

4 walks (street/park/beach/market) + a seeded Daily Walk. Day/night +
weather (clear/rain/wind) selectable. Rope leash with tetherball whirl,
pole-wrap capstan, fling with bungee. Tug-of-war (human 4× dog mass).
Retractable leash (human-owned "click!"). Round-trip walk (out → off-
leash freedom romp with fetch + free dogs → home). Turbo/zoomies energy.
Rotating quests (3/walk from a pool) → up to 3 stars/walk → star-gated
unlocks. Chore chain (bag the poop, deliver to bin). Pee/marking +
fountains to drink. Bodily needs as mechanics. Two owners (him/her).
Millie + Tofu cameos. NPC dog-walker pairs with leash-vs-leash tangling.
Cosmetics shop (collars + bandanas from the bones wallet). Touch
controls, controller-aware prompts. Attract/CI autowalk bot.

## 6. OPEN FOLLOW-UPS — from Santtu's v1.4/v1.5 playtest

The off-leash area and the NPC dogs need the most love. In priority-ish
order:

Trailing bandana geometry and the highlighted-item wardrobe preview are fixed.
Fixed-obstacle avoidance is implemented and automated for riders and NPC
dog-walker pairs. Connected blocker clusters use their outer expanded bounds,
spawn placement validates the first speed-scaled forward sweep, and pair
runtime routing checks the actual owner/dog formation. Blockers are normalized
once when each route is configured. Non-touching park-slalom trees can extend
one navigation route when their commanded sweeps touch; pair steering validates
current, side-specific detour, and clear-return dog paths without adding a
second clearance release margin. Clear return checks all configured blockers
and clamps the commanded wander/curiosity target to route bounds. Non-daily CI
autowalk seeds before level construction and finishes on a deterministic
120.0-second fixed-fps gate; ordinary player randomness is unchanged. The NPC
leash remains the real rope: never introduce separate leash pivot or wrap
bookkeeping.

1. **Pair persistence and arrival/departure behavior** through the freedom/dog
   park transition still needs design and implementation.
2. **Richer NPC owner presentation** remains open: phone, coffee, and
   conversation variants should use visual language comparable to the player
   owner.
3. **Optional deliberate pole-snag/recovery** may be added as a rare state only
   if coordinated avoidance feels too clean after playtesting.
4. **Tangle feel needs broader playtesting.** The repeated reward/apology spam
   is fixed with a separation latch, but the snag should still read as
   something the player deliberately works out of.

## 7. NEXT FEATURES (Santtu's explicit asks for the off-leash area / v1.6)

- **Make the off-leash area a real dog park:** fencing around it,
  benches for humans, a gate — it currently reads as bare grass.
- **Develop the fetch into a real minigame:** the OWNER throws the ball,
  the dog fetches and **brings it back to the owner** (not just touch-to-
  catch). Other owners in the park should also throw balls to their dogs;
  catching one of theirs scores too.
- **Other dogs should resemble real dogs** — different breeds with
  distinct features. IMPORTANT: build this so it can back a future **dog
  selector / playable breeds** (Santtu wants to choose Millie's breed
  later). Save distinct breeds for that.
- **Make other dogs more interactive** in the play area (play bows,
  chase, wrestle, share the ball).
- **Bring Tofu home quest** (the inside joke): Tofu is a runaway; you
  herd her home (keep her distance, never grab). Fits the walk-home
  structure.
- **Level five: Rainy Day** (rainy by default, storm drains, umbrella
  crowds). Weather system already supports rain.
- **Shareable daily results card.**

## 8. Then v2.0 — The Product

Watercolour art integration (girlfriend's paintings replacing the vector
placeholders; keep a consistent hand on Millie/Tofu/owners, recolour
asset-pack environments to match). Sound + music pass. Trademark
verification at EUIPO/USPTO ("Path of Leash Resistance" searched clear;
verify before the store page). Steam page (GIF-first trailer). Next Fest
demo. Also unresolved: the 2D-vs-3D question — a one-week Godot 3D spike
(low-poly, rail camera) was always meant to happen before committing
art; the 2D loop has proven itself, so this is a real fork to weigh.

## 9. Conventions

No emoji anywhere. Plain comments stating constraints, not narration.
Honest incremental git history, imperative commit subjects, a tag per
release. Feel/tuning decisions are made by playtesting, not argument —
tuning constants live named at the top of scripts. Update CHANGELOG.md
every session. Never commit the itch secret URL. The repo is public but
has no LICENSE on purpose (all rights reserved, commercial WIP).
