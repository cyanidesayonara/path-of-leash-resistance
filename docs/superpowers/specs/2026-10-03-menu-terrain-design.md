# Menu shell, tutorial reach, and natural terrain

Approved 2026-10-03. Two player-facing changes, shipped as separate pull
requests. Check the acceptance board before starting each one. Docs and tests
do not count against the WIP limit; each pull request still needs a feel card.

## Problem

- Desktop play has no in-game way to leave the application. Pause offers
  "QUIT TO WALK SELECT", which reloads into walk select. Closing the window
  is the only process exit. Web play remains bound to the browser tab.
- The tutorial's nose lesson asks the dog to find a snack on the grass. Grass
  is already traversable. The snack is unreachable because the held human and
  the leash geometry cap leave it outside the dog's reach.
- Natural ground already has one feel table, but some verges, patches and
  water read as blocked or visually flat. Grass, sand, mud, puddles and water
  should be places the dog can enter, and each should be recognisable in
  motion as well as in the handling.

## Pass 1: menu shell and tutorial reach

### Pause grid

`hud/menu_flow.gd` remains the model and `hud/menu_screen.gd` remains the
drawing. The pause screen changes from a vertical list to a two-column grid
in the existing card, accent and prompt-bar look.

Desktop cells, in reading order:

1. RESUME
2. THIS WALK
3. START AGAIN
4. SETTINGS
5. WALK SELECT
6. EXIT GAME

Web omits EXIT GAME, leaving five cells. There is no disabled exit row.

Keyboard, pad and touch all move a single selection with the existing move
actions, including left and right. `plant` activates the selection. `pause`
or `bark` resumes. Prompt text continues to come only from `Prompts`; no key
name is written into a label.

THIS WALK opens a pause card of information the game already has: the walk's
Catalan name and English gloss, the current goals, and progress through them.
It is not a new geographic map.

START AGAIN asks "Start this walk again?" before reloading. WALK SELECT keeps
the current behaviour, including leaving the tutorial onto El Barri. SETTINGS
still returns to the screen that opened it.

### Exit

EXIT GAME appears on the title prompt bar and in the desktop pause grid. Both
ask "Quit the game?" before calling `get_tree().quit()`. `bark` or `pause`
cancels. The action is absent wherever `OS.has_feature("web")` is true.

Copy is short, sentence case for questions, and capitals for grid labels.
Button hints stay in the prompt bar.

### Tutorial reach

The nose snack stays on grass, off the pavement, and is still found by scent.
Its lesson still completes by eating it. The fix is geometric: from the held
human's position, the snack plus the eat radius must lie inside the leash
length times its stretch cap, with enough margin that a taut leash does not
stop the dog short of the pickup.

The same invariant covers every held tutorial station and its required target.
A station may move, or its target may move, but neither may be solved by
blocking or unblocking grass. Skipping a lesson remains available.

## Pass 2: natural terrain

`world/surfaces.gd` stays the only feel table. Do not add a second terrain
system, and do not retune its speed, grip or scent numbers in this pass.
Water's existing top-speed multiplier is the slowest allowed footing. No
surface may trap the dog or the human.

### Access

Grass, sand, mud, puddles, shallow water and deep water are traversable.
Movement is blocked only by authored solids and the outer level edge:
buildings, walls, poles, furniture, vehicles, gates and props that are solid
on purpose.

The audit covers every walk. A natural-surface sample inside the level edge
must not sit inside static collision unless that collision is one of those
authored solids. `surface_at` and the drawn ground must name the same kind.
The dog can be placed on each sampled kind and receive that surface. The human
still prefers the pavement and telegraphs that route, but the leash can pull
them onto grass, sand or into a wade. Deep water remains a swim for the dog
and a reluctant phone-up wade for the human.

### Look and motion

All new ground detail stays procedural and vector-drawn. No raster texture
dependency is added.

- Grass has layered clumps, seed heads and sparse flowers. Paws flatten a
  short-lived trail.
- Sand has wind ripples and grain clusters. Dents persist, the gait shortens,
  and a few kicked grains show the weak purchase.
- Mud has wet highlights, pooled edges, ruts and suction rings. It splatters
  and keeps the existing transferable marks until water washes them off.
- Water has depth bands, shoreline foam, current lines and expanding rings.
  The dog gets a paddle cycle and a wake. The human wades with the phone up.
- Pavement gains restrained aggregate, repairs, drains and cracks.
- Mosaic tile keeps a readable tessellation, chipped edges and sparse glints.
- Surface boundaries are organic blends, not rectangles.

Gait cadence, body bob, paw depth and skid distance come from the current
surface. New procedural sound is limited to a restrained rustle, grit,
squelch, splash and claw tick, using the existing audio autoload.

### Performance

Static detail goes through the existing cached world layers and `ShapeBatch`.
It is redrawn when the camera reveals new ground, not rebuilt for the whole
walk every frame. Dynamic marks and particles are pooled, capped and
deterministic. Cosmetic motion reads `AnimClock.msec()`.

A pure drawing change leaves the behaviour snapshot byte-identical. A
collision correction that changes an autowalk route is allowed only with a
line-by-line explanation. Draw-call cost must stay independent of walk length
on the cached path. The particle cap is 24 live marks. Browser measurement
runs only when the Godot 4.7 no-thread web templates are already installed;
otherwise the pull request records that absence and does not download them.

## Tests and documentation

Pass 1 extends `tests/test_menu_flow.gd`, `tests/test_prompts.gd` and
`tests/test_tutorial_stations.gd`. The menu tests cover grid order, web
omission, both confirmations, and quit calling the scene tree only after
confirmation. The tutorial test fails if any held target is outside leash
reach or if the nose snack is not on grass, and it drives the dog to the
snack until `kebabs_eaten` increases.

Pass 2 extends `tests/test_surfaces.gd` and the level self-tests. They sample
every walk's grass, sand, mud, puddles and water, and check kind agreement,
absence of accidental collision, dog surface selection, and the water floor.
Screenshot sweeps are expected to change and are reviewed from contact sheets.
The behaviour snapshot and draw-cost probe are recorded as above.

Update `README.md`, `AGENTS.md`, `PROJECT.md`, `HANDOVER.md`,
`docs/LEVEL_DESIGN.md` and `CHANGELOG.md` in the pass that changes their
current claims. Player-facing strings follow the existing voice: dry, fond,
British spelling, and "leash" rather than "lead".

## Feel cards

Pass 1:

1. `--level=tutorial`: follow the nose lesson without skipping. The snack is
   visibly on grass, scent leads to it, and the dog can reach and eat it.
2. Pause on desktop: the grid moves in two axes. START AGAIN and EXIT GAME
   ask first. WALK SELECT returns to walk select without quitting.
3. From the title on desktop: EXIT GAME asks first, then the application
   closes. Cancel returns to the title.
4. A web export, or a launch with the web feature: neither title nor pause
   offers EXIT GAME.
5. THIS WALK shows the current walk name and goals, and BACK returns to the
   pause grid.

Pass 2:

1. `--level=tutorial` and `--level=street`: walk the dog from pavement onto
   grass. The verge is open, the gait changes, and the human can be pulled
   onto it.
2. `--level=beach`: sand slows and dents, shallow water paddles, and neither
   stops the walk home.
3. `--level=trail`: mud marks the paws and splashes, and stepping into water
   washes those marks off.
4. `--level=guell`: mosaic tile looks different from pavement and remains the
   fast, slippery footing.
5. A full walk at the normal camera speed stays smooth. New ground detail does
   not appear in batches as the camera scrolls.
