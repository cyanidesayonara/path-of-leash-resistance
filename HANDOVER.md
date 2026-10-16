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

## Where things stand (2026-10-16)

**Released: v1.60** at `00576db`. itch (web and Windows) and the GitHub
release are published. The Microsoft Store submission went in on 2026-10-12.
Certification was still pending at the last check. Do not copy 1.60 into
"Past What's new" in `store/listing.md` until Santtu says it is live.

**On `origin/main`:** `32e1855` (merge of #233). The local `main` checkout at
`path-of-leash-resistance` is behind that, at `21fca92`. Branch new work
from `origin/main`, not from that checkout.

Since the tag: #230 icon and Store art, #231 the 1.60 listing record, #232
HUMAN STUCK no longer misfires, #233 the rope-tug tests stay clear of the
live park. #233 is a test-only change. It does not count against the WIP
limit.

**Open, this session's work:** [PR 234](https://github.com/cyanidesayonara/path-of-leash-resistance/pull/234)
`intro-polish` at `125c4d7`, worktree `~/projects/pol-intro`. CI on that SHA
is green (smoke, idle soak, screenshot sweep). Do not merge it. Santtu
approves, then `land.sh` merges and boards it as Awaiting acceptance. Leave
the worktree in place until that happens.

The film was watched maximized. Two things that looked like bugs were not
picture bugs:

- A volume key skipped the film, because every key was a skip. Volume up,
  volume down and mute now pass through. Every other key, click, tap and
  pad button still skips. That fix is `125c4d7`.
- A later play was silent because Windows had the Godot window muted, after
  those volume keys. The game's own volumes were the defaults (master 0.85,
  effects 0.9, music 0.55). Headphones (EDIFIER) were the default device.
  Unmute the app in the Windows volume mixer if a launch is silent.

The feel card on the PR is still unchecked. Santtu has not said the film is
accepted.

**Next task: DOG STUCK in the playtest.** `tools/playtest.gd` logs it when a
direction is held, she is not planted, tumbling, teetering or dragged, and
she moved under 4 px in a second. The 1.60 runs hit it mostly where the
scripted steps push her into solids:

- market, about (700, -1185)
- oldtown (681, -884)
- scrap, about (795, -2819)
- guell, about (670, -815)
- station, y -2982 and -3235

Separate from those spots: when she walks dead on into a pole beside her
human, she ends up on top of them, because the two bodies do not collide.
Fix bugs before adding features. This is a player-facing change if the dog's
movement changes, so it needs a feel card, a CHANGELOG entry, and a fresh
worktree off `origin/main`. If #234 is still open, land them in sequence:
both edit `CHANGELOG.md`.

**After that, still open from the 1.60 list:**

- Record 1.60 as live in `store/listing.md` once certification passes.
- Market NPC pair through a block: a rare report, not reproduced.
- Per-walk audit issues: #149, #151, #152, #155-#162.
- Web perf re-measure on an idle machine (#45). 1.60 showed 13-18 more draw
  calls on beach, rain, market and station. Frame times were too noisy to read.
- Longer term: #170 chase walks, #169 onboarding, #147 platforms, #13 phone
  check, #14 leash weight.

**Left on purpose, not this task:**

- `tutorial-kerb` in `pol-kerb`: unmerged commit `a2f0a6e`, "Lay a kerb to
  ride along the tutorial's grind station". Its remote is gone.
- `mercat-beside`: local only, one commit about keeping your human in the
  aisle beside a market block. Behind `origin/main`.
- `polr2-living-districts`: two commits on a provisional POLR2 note. Far
  behind `origin/main`.
- `tug-flake` in `pol-tugflake`: already merged as #233. Safe to remove
  when nobody is using that checkout.
- `pol-tools` (landing scripts) lives outside the repo.

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

Before a tag, update "What's new" in `store/listing.md` and `docs/itch-page.md`
as their own PR. Santtu runs the Store submit workflow. When a submission
goes live, copy its What's new into "Past What's new".
