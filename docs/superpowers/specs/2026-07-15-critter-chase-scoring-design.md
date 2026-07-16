# Critter chase scoring restoration

## Context

Squirrels, rats, and Tofu enter their flee state before the contact reward
check in `squirrel.gd`. The reward check excludes the flee state, so an
ordinary approach causes the critter to flee and permanently prevents the
player from earning the chase reward. This also makes the rotating
"chase squirrels" quest effectively impossible during normal play.

## Goal

Restore the intended contact reward while preserving each critter's current
movement:

- A dog that gets within 26 pixels of a squirrel or rat earns the chase
  reward once, even after the critter has started fleeing.
- A dog that gets within 26 pixels of Tofu earns one boop reward while Tofu
  continues relocating to cover.
- A critter never awards more than once.
- Barking or merely entering the alert radius does not award anything.

## Non-goals

- Do not retune temptation strength, alert distance, flee distance, or speed.
- Do not change critter spawning or quest selection.
- Do not implement the future "bring Tofu home" quest.
- Do not refactor unrelated gameplay code.

## Design

Move contact scoring out of the state restriction. After the current state
update, check whether the critter is unscored and the dog-to-critter distance
is below the existing 26-pixel contact threshold.

On first contact:

1. Latch the critter as scored.
2. Call `main.on_critter_chase(global_position, kind)`.
3. Call `scare()`.

`scare()` already returns safely when the critter is fleeing. That preserves
the current escape trajectory for squirrels and rats and the current cover
target for Tofu.

The change remains inside `squirrel.gd`; `main.gd` continues to own bones,
quest counters, and feedback text through its existing callback.

## Regression test

Add `tests/test_critter_chase.gd` using the repository's lightweight
`SceneTree` test pattern.

The test supplies a minimal fake main node and dog, then verifies:

1. A fleeing squirrel within contact distance calls the reward callback.
2. Reprocessing the same squirrel does not call it again.
3. Tofu contact calls the reward callback and retains a finite cover target.
4. A bark-style scare outside contact distance does not award a chase.

The script exits nonzero on failure and prints a stable success marker.
CI runs it as a separate step before the level smoke tests.

## Error handling and compatibility

The implementation introduces no save-data or scene-format changes. Existing
daily seeds remain valid. The fake test main exposes only the fields and
callbacks consumed by `squirrel.gd`, so failures identify changes to that
contract directly.

## Acceptance criteria

- All regression assertions pass.
- The existing rope regression test still passes.
- The four level smoke tests report no script or parse errors.
- Manual play confirms one squirrel chase reward and one Tofu boop, with no
  repeat reward from the same critter.
- `CHANGELOG.md` records the restored chase reward and new regression test.
