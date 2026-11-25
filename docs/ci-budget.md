# What this repository asks of GitHub

On 2026-11-25 GitHub disabled this repository for a few hours over its terms,
without saying which. On the day before, it had used about 250 runner-hours of
Actions for 22 merges. Nothing proves that was the reason; it was far too much
for a game either way. These are the rules since, for people and agents alike.

## What runs, and when

| When | What | Roughly |
|---|---|---|
| A pull request | `attribution`, and `smoke`: the tests the change needs (`tools/pick_tests.py`) | 10 runner-minutes; 1 for docs |
| A draft pull request | nothing | 0 |
| A merge to main | nothing (the website, if its files changed) | 0 to 1 |
| Monday, if main moved | everything, in three shares | 75 |
| A version tag | everything, then the release, then the website's pictures | 140 |
| By hand only | the screenshot sweep, the idle soak, the store and credential checks | as asked |

The same day under the old setup: CI 69 minutes a pull request and 67 a merge,
the sweep 25 and 22, the soak 510 a merge, of which the sweep and the soak gated
nothing.

## Rules

- **Test here first.** Run `python tools/pick_tests.py > picks.txt` and
  `PICK=picks.txt WALKS=1 bash tools/run_tests.sh` before pushing, and the sweep
  (`tools/shot_sweep.sh`) and the soak (`tools/idle_soak.sh`) on your own machine.
  A push is for work believed done, never a way to find out.
- **Few pull requests.** Batch related work: at most 4 a day, and 2 open at once.
  Open as a draft until it is ready. Push a branch once, not after every commit.
- **Before tagging**, run CI by hand on main (Actions > CI > Run workflow) and tag
  only when it is green, so a tag is not the first to run everything.
- **No pictures in branches.** No `media/*` branches and no committed captures:
  show before and after in the session, or let Santtu drop them into the pull
  request.
- **Do not poll.** One look when the checks should be done; no loops over `gh`.
- **Clean up.** Merged branches are deleted as they merge.
- **A new workflow** says in its header what it costs and why it must run on
  its own. Nothing runs on every push to main without Santtu's word.

Check what a day cost: count its runs and add up their jobs' times
(`gh api repos/OWNER/REPO/actions/runs?created=YYYY-MM-DD`). Over 10
runner-hours in a day that had no release, stop and find out why.
