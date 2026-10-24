# HANDOVER — Path of Leash Resistance

Thin current sitrep for the next agent. Details live in the canonical docs.
Do not treat archived handover notes as current truth.

## Read first

1. `AGENTS.md` — tech map, rope architecture, commands, conventions
2. `PROJECT.md` — design pillars and living release plan
3. `CHANGELOG.md` — newest-first session history
4. `.github/workflows/ci.yml` + `release.yml` — what must stay green to ship

Historical sitrep (NPC owner appearances, 2026-07-17):
`docs/handover/ARCHIVE-2026-07-17-npc-owner-appearances.md`.

## What this is

Top-down physics comedy in Godot 4.7 / GDScript. You are the dog; the
phone-distracted human walks on autopilot; the leash is real verlet-rope
physics. Ships to itch (`html5` + `windows`) on a version tag after green CI.

## Where things stand (2026-10-24)

**Released: v1.63** (tag at `5c79395`). **v1.64 is ready on `main`,
untagged.** Its What's new is in `docs/itch-page.md` and `store/listing.md`.

**What v1.64 adds:**
- Walk 20, El Veterinari (`systems/vet.gd`): the clinic escape chase.
- Walk 21, El Tibidabo (`systems/tibidabo.gd`, `world/funicular_layer.gd`):
  the mountain road with the funicular running beside it, ending at its
  bottom station.
- Every walk's exit is a real place (`systems/exit_portals.gd`): a home block
  dressed for its walk, the station, a metro stair, the funicular, a trail
  gate, the flood wall ramp. The arrival walks the pair in over the last
  140 px with gait, facing and a straightened leash (`systems/arrival.gd`).
- The agility course is in El Barri only (`FreedomGames.AGILITY_WALKS`).
- Hardening after an audit of the 1.63 work (#315, #316, #320): the vet
  chase crash, the vet cats, El Somni's and Plaça Reial's goal credit, the
  detour's rope radii, the rails duplicate, an `intro_skip` input action
  that did not exist (now caught by `tests/test_input_actions.gd`), and
  tests that could not fail.

The roster is **21 walks**. The 26-walk campaign plan is issue #170.

**Board:** #317, #318 and #319 await acceptance (the voice fixes, the agility
scope, the arrival and exits). Everything older is Done. Open cards are
later work: #260 Steam, #13 a real phone.

**Known, not yet fixed:** El Port's gulls are drawn but do nothing. The
detour autopilot and El Besòs's flood apron are suspect and unconfirmed.
`main.gd` keeps gaining per-walk flags (`if m.lvl == ...`); move them into
the walk modules before they spread further.

**Next, when Santtu asks:** tag v1.64. Not before. After the tag, he runs
the Store submit. When that submission is live, move the 1.64 What's new
into the past list.

## Standing rules

Commits are authored only by Santtu Nykänen. Never add `Co-authored-by`
trailers or any AI acknowledgement. Never push to `main`. Every change is a
PR. Santtu approves. Merge with `land.sh` once CI is green. Ask before
tagging. Ask before downloading. Never handle secrets. Do not change system
or security settings.

Board: https://github.com/users/cyanidesayonara/projects/4. A merged
player-facing PR goes to Awaiting acceptance. Only Santtu moves a card to
Done, after playing it. At most 5 player-facing changes awaiting acceptance.
At the limit, only fixes, tests, refactors and tooling may land.

Every PR has a `## Feel card` (3-5 numbered checks, with the flags that get
there) and a `CHANGELOG.md` entry. A new script needs its `.gd.uid`.

Player-facing text is American English. "leash", never "lead". they/them.
Catalan place names keep their accents. No emoji. Key names only through
`Prompts` tokens.

Landing scripts, in `~/projects/pol-tools/`: `land.sh PR` waits for green
checks, merges, and boards the PR. `land_after.sh PREV PR WORKTREE BRANCH`
waits for the previous PR, merges `origin/main`, and resolves CHANGELOG and
`ci.yml` conflicts by keeping both sides. `godot --import` dirties
`assets/concept/*.svg.import` and `icon.png.import`. Restore those before
landing.

## Intro, if you touch the film

Spec: `docs/superpowers/specs/2026-10-12-intro-polish-design.md`. Plan:
`docs/superpowers/plans/2026-10-12-intro-polish.md`.

The stage stays a contain fit (`min` of the two axes). Cover would crop a
tall window to a strip. Wall, floor and sky paint from (-800, -1100) out
past the 1280x720 frame. The yank eases and arrives at 9.22 on the bark.
The street stays the white flash at `TITLE_AT` 10.1. The opening is seven
bars of the title theme, marimba and a half-velocity shaker, at loop
loudness. A skip starts the title theme from the top. Do not copy the music
job's seed to make the shaker match. The hashed noise in the new cues is
biased. Change it only if a cue sounds harsh.

The film plays once per process, on a plain launch only. Any command-line
user argument, including `--level`, skips it. Engine arguments
(`--maximized`, `--rendering-method`) do not.

## Release ritual

1. Green CI on the commit you intend to ship
2. Update `CHANGELOG.md` (the in-game version label is stamped from the tag)
3. Ask Santtu, then `git tag vX.Y && git push --tags`
4. `release.yml` waits for CI on that SHA, then exports and publishes.
   Missing `BUTLER_API_KEY` fails the job.

The 1.64 What's new is already in `store/listing.md` and `docs/itch-page.md`.
Next time, update those as their own PR before the tag. Santtu runs the
Store submit workflow. When a submission goes live, copy its What's new into
"Past What's new".
