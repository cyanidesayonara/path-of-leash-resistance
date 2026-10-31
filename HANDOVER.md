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

## Where things stand (2026-10-31)

**Released: v1.67** (tag at `a0ad9cf`), on both itch channels and submitted
to the Microsoft Store. Santtu has played and accepted everything up to and
including #380; the board has nothing awaiting acceptance.

**What v1.67 added since 1.64:** six walks (La Carretera de les Aigües, El
Laberint d'Horta, Platja de Llevant, Els Senglars, Festa de Gràcia and the
finale, the Rambla del Raval with El Gat de Botero), five dogs with stat
upgrades, dare-givers with their own tunes, fifteen goals a walk (spell
LEASH, a hidden pernil, a par time), separate poop and pick-up buttons with
key layouts and rebinding, the Badalona rework of Passeig Marítim, and the
LANGUAGE setting. The roster is **27 walks**. Walks open by stars and, past
each chase, by finishing that chase (`Game.chase_gate_needed`).

**When the Store submission is live:** move 1.67's What's new into "Past
What's new" in `store/listing.md` and write the next version's notes as you
go, not before the tag.

**Next (PROJECT.md "Agreed next" item 6):** story films on the chase walks,
played just before the threat strikes. Items 1-5 shipped in 1.67.

**Known, not yet fixed:** the intro's breed meshes do not match the chosen
dog; El Port's gulls are drawn but do nothing; `main.gd` keeps gaining
per-walk flags (`if m.lvl == ...`). `tests/test_mercat_owner_path.gd` passes
but can exceed `run_tests.sh`'s 300 s locally (TIMEOUT=600 for it).

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

Update the What's new in `store/listing.md` and `docs/itch-page.md` as
their own PR before the tag. Santtu runs the
Store submit workflow. When a submission goes live, copy its What's new into
"Past What's new".
