# Distinct tangle event latch

## Context

`main.gd` reports a rope crossing every physics frame. `otherpair.gd`
currently flips `reacted` on every call, so its apology reappears every other
frame. A global 1.5-second cooldown limits score feedback but still awards
repeated bones while the same uninterrupted snag remains crossed.

## Goal

Treat a leash crossing as one event until that same NPC pair's ropes have
stayed separated for 0.5 seconds:

- A new crossing displays one NPC apology and awards one `TANGLED! +3`.
- A sustained crossing keeps the NPC owner rooted but emits no further
  dialogue, bones, or quest increments.
- A one-frame crossing gap does not rearm the event.
- After 0.5 seconds continuously separated, a later crossing may trigger and
  reward again.
- Each NPC pair tracks and rewards its own distinct crossings.

## Non-goals

- Do not change rope collision, wrapping, capstan behavior, or crossing
  distance.
- Do not retune NPC movement, speed, pathfinding, or pond avoidance.
- Do not change pair spawn direction or freedom-zone traffic.
- Do not change the `+3` reward, quest target, or feedback text.

## Design

### Per-pair state

Replace `reacted` with:

- `tangle_active: bool`, initially `false`;
- `tangle_clear_t: float`, initially `0.0`;
- `TANGLE_REARM_S := 0.5`.

Add:

```gdscript
func update_tangle_state(crossing: bool, delta: float) -> bool
```

When `crossing` is true, the method refreshes `tangled_t` to `0.4`, clears the
separation timer, and returns `true` only when transitioning from armed to
active. That transition also displays the existing `"oh - sorry!"` feedback.

When `crossing` is false, the method accumulates continuous separation time.
After `TANGLE_REARM_S`, it clears `tangle_active` and resets the timer. It
always returns `false` while separated.

### Main-loop integration

`main.gd/_pairs` continues to calculate rope proximity and feed each rope's
dynamic obstacles. For every pair and every `_pairs` call, it passes the
current crossing boolean to `update_tangle_state`.

Only a `true` return increments `tangles`, adds three bones, and displays
`"TANGLED! +3"`. The global `tangle_cd` variable and cooldown logic are
removed because event suppression is now correctly scoped per pair.

Pairs outside the 320-pixel interaction range receive `crossing = false`.
When the player leash is detached, each pair's dynamic obstacles are cleared
and receives `crossing = false` before `_pairs` returns. This prevents stale
collision and latch state from surviving a non-interacting period.

Two different pairs may each trigger one event in the same frame. They are
distinct tangles and are not suppressed by shared global state.

## Regression test

Add `tests/test_tangle_latch.gd` using the existing lightweight `SceneTree`
test pattern. It instantiates the real `otherpair.gd` script with a minimal
fake main node and verifies:

1. The first crossing returns `true`, refreshes the root timer, and displays
   one apology.
2. Repeated crossing frames return `false` and do not repeat the apology.
3. A 0.49-second separation followed by another crossing does not rearm.
4. A fresh 0.5-second continuous separation rearms the pair.
5. The next crossing returns `true` and displays exactly one new apology.

The script exits nonzero on failure and prints `test_tangle_latch: OK` on
success. CI runs it directly after the critter chase regression.

## Manual acceptance

During a normal walk:

1. Cross one NPC leash and remain snagged for longer than two seconds.
2. Observe one apology, one `TANGLED! +3`, and one three-bone award.
3. Separate the ropes for at least half a second.
4. Cross that pair again and observe exactly one new event and reward.

## Compatibility

The change introduces no save-data, scene-format, input, or export changes.
It preserves current reward values and quest semantics while preventing
continuous-event farming.
