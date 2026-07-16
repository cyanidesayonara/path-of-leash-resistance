# Freedom-zone traffic isolation

## Context

The off-leash freedom phase is intended to be a protected dog-park reward.
`main.gd` currently calls both traffic spawners during freedom, and riders or
leashed NPC pairs that already exist continue their independent physics after
the transition. Bikes, scooters, and leashed walkers can therefore appear in
or cross the off-leash area.

## Goal

- Entering freedom immediately removes active bikes, scooters, and leashed
  NPC pairs.
- No crossing-lane or vertical-lane riders spawn during freedom.
- No NPC pairs spawn during freedom.
- Traffic spawning resumes normally on the home leg.
- Free dogs and the fetch ball remain active and unchanged.

## Non-goals

- Do not change traffic spawn intervals, positions, speeds, collision, or art.
- Do not change NPC-pair movement, direction, pathfinding, leash physics, or
  tangle behavior.
- Do not add fence collision or constrain traffic around the fence.
- Do not change freedom timing, fetch, greetings, or owner parking.

## Design

### Spawn gating

In `main.gd/_physics_process`, call `_lanes(delta)` and `_vlane(delta)` only
when `phase != "freedom"`. Their timers pause during freedom and resume on the
home leg. `_pairs(delta)` continues running because its spawn block is already
gated outside freedom and its detached-leash cleanup is required during the
transition.

### Active-entity cleanup

At the start of `bike.gd/_physics_process` and
`otherpair.gd/_physics_process`, before checking `main.frozen` or accessing
dogs, humans, leashes, or camera state:

```gdscript
if main.phase == "freedom":
	queue_free()
	return
```

This makes every active traffic entity remove itself on its first freedom
physics tick. It also provides defense in depth if an entity is created by a
future path that bypasses the current spawners.

Queueing deletion rather than deleting synchronously is compatible with
Godot's frame processing and group iteration. At most, a queued entity remains
valid until the end of the current frame; it performs no movement, collision,
or feedback after the guard.

## Regression test

Add `tests/test_freedom_traffic.gd` using the lightweight `SceneTree` pattern.
The test creates a fake main node with `phase = "freedom"` and instantiates
the real `bike.gd` and `otherpair.gd` scripts as invisible, physics-disabled
nodes. It directly invokes each script's `_physics_process(0.0)` and verifies
that each node is queued for deletion.

The fixtures intentionally omit dog, human, leash, and camera dependencies.
Passing proves the freedom guard runs before those dependencies are accessed.
The script exits nonzero on failure and prints
`test_freedom_traffic: OK` on success.

CI runs the test directly after the tangle-event regression.

## Manual acceptance

1. Approach the gate with riders and/or an NPC pair still active.
2. Enter freedom and confirm all leashed traffic disappears immediately.
3. Remain in freedom and confirm no bikes, scooters, or leashed pairs appear.
4. Begin the home leg and confirm normal traffic spawning resumes.
5. Confirm free dogs and fetch continue normally.

## Compatibility

The change introduces no save-data, scene, input, or export changes. It
preserves corridor traffic and all freedom-phase activities except the
unintended traffic.
