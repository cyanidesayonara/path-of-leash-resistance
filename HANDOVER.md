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

**Released: v1.63** tagged on `main` at `5c79395` (2026-10-24). itch export
and GitHub release action triggered on the tag. The Store listing in
`store/listing.md` and `docs/itch-page.md` records 1.63 notes. Santtu submits
the Store package. Do not treat a submission as live until he says so.

**What v1.63 added:**
- **Walk 18: El Port** (`systems/port.gd`): Moll dels Pescadors working wharf,
  timber boardwalk, iron mooring bollards for leash wrapping, fishing boats with
  swaying rigging, flocking seagulls, fish market stalls with crushed ice, and
  Plaça del Far lighthouse.
- **Walk 19: Plaça Reial** (`systems/reial.gd`): Royal arcaded square in the
  Gothic Quarter with Antoni Gaudí's 6-armed dragon lampposts, Three Graces
  fountain with drinking trough, dining terraces, and guitar busker duet barking.
- **Free Play (Demo) Mode** (`autoload/game.gd`, `hud/menu_screen.gd`): Settings
  toggle and `--free-play` flag allowing all walks to be played freely without
  star gating; career save persistence is cleanly bypassed during practice.
- **Artsy Detour «El Somni»** (`systems/detour.gd`): First secret-in-plain-sight
  side gallery off Carrer del Gòtic paying homage to Salvador Dalí, with melting
  bronze lampposts and the Golden Dream Bone.
- **HUD Vitals & Messaging System Polish** (`hud/ui_icons.gd`, `hud/event_feed.gd`):
  Smartphone HP pips with hairline cracked glass, liquid glass bladder and sprint
  tubes with vector glyphs, concentric mark rings, and 4-tier event hierarchy.
- **Responsive Mobile Navigation & Juice**: Progress card scales cleanly down
  to 6px rows on all landscape mobile viewports, dynamic tail wags, kerb skids.

The campaign roster stands at **19 walks** (out of 26 total in the Grand Campaign
Roadmap). All 19 walks have dedicated tests, pass selftest, headless smoke, and
full idle soak (21/21 matrix checks green).

**Board:** nothing is awaiting acceptance (all merged PRs through #300 are
marked `Done` on Project #4). The open cards are later work,
not this tag: #260 Steam, #237 Montjuïc extras, #170 chase finales, #147
platforms, #13 a real phone, #12 whether SCARED belongs in the sweeper
chase, #11 mood readability. #271 (fear before the sweeper is visible) is
fixed on main (`f187426`) and closed.

**The Grand Campaign Roadmap (26 Walks to v1.7X):** Issue #170 has been updated into the master roadmap tracking the 26-walk campaign structure (chases every 5th walk: 5 La Neteja, 10 El Besòs, 15 Festa de Gràcia, 20 El Veterinari; Walk 25 Els Búnquers; Walk 26 Rambla del Raval El Gat de Botero boss finale). Obsolete issues #11, #12, #147, and #237 have been cleaned up and closed. PR #303 added dual respites and midpoint checkpoint fixes to El Besòs. Free Play / Demo mode toggle is implemented in Settings.

The local checkout at `path-of-leash-resistance` is synced to `origin/main`
and stale worktrees have been cleaned up. Always branch new work from
`origin/main`.

**Next, when Santtu asks:** tag v1.62. Not before. After the tag, he runs
the Store submit. When that submission is live, move the 1.62 What's new
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

The 1.62 What's new is already in `store/listing.md` and `docs/itch-page.md`.
Next time, update those as their own PR before the tag. Santtu runs the
Store submit workflow. When a submission goes live, copy its What's new into
"Past What's new".
