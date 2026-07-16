# Mixed NPC-pair direction

## Context

NPC dog-walker pairs are described as oncoming traffic, but the current route
logic always spawns them behind the player and gives them the player's travel
direction. This happens on both the outbound and home legs because the spawn
offset and velocity signs are both reversed relative to the comment.

The desired behavior is an even random mix: half the pairs approach head-on,
while half remain ambient same-direction walkers.

## Goal

- Each actual NPC-pair spawn independently has a 50% chance to be oncoming.
- Oncoming pairs spawn ahead of the player and move toward the camera.
- Same-direction pairs preserve the current behavior: spawn behind the player
  at their current speed and may remain ambient background traffic.
- The behavior works symmetrically on outbound and home legs.
- Spawn distance shortens symmetrically from 560 to 360 pixels near route
  ends so both directions remain equally available.
- Pair spawning pauses when both routes cannot fit at least 360 pixels from
  the camera, avoiding visible pop-in and biased endpoint traffic.

## Non-goals

- Do not change NPC-pair speed, movement, pathfinding, obstacle avoidance,
  leash physics, tangling, spawning interval, population cap, or art.
- Do not address pond entry or pole wrapping in this task.
- Do not change freedom-phase traffic cleanup.
- Do not guarantee an exact alternating sequence.
- Do not change the 6–11 second interval between successful spawns.

## Route model

Add two pure helpers and two named tuning constants to `main.gd`:

```gdscript
const PAIR_SPAWN_DIST := 560.0
const PAIR_MIN_SPAWN_DIST := 360.0


func _pair_spawn_distance(camera_y: float) -> float:
	var max_distance := minf(
		PAIR_SPAWN_DIST,
		minf(camera_y - (GATE_Y + 60.0), (START_Y + 100.0) - camera_y)
	)
	return max_distance if max_distance >= PAIR_MIN_SPAWN_DIST else 0.0


func _pair_spawn_route(walk_phase: String, oncoming: bool, camera_y: float) -> Dictionary:
	var player_dir_y := -1.0 if walk_phase == "out" else 1.0
	var pair_dir_y := -player_dir_y if oncoming else player_dir_y
	var spawn_distance := _pair_spawn_distance(camera_y)
	return {
		"y": camera_y - pair_dir_y * spawn_distance,
		"direction": Vector2(0.0, pair_dir_y),
	}
```

The distance helper finds the largest symmetric distance up to 560 pixels that
fits both spawn positions inside the existing walk bounds. It returns zero
when less than 360 pixels fits. The route helper places the pair opposite its
own travel direction, so it always moves toward the camera:

- outbound oncoming: spawn above, move down;
- outbound same-direction: spawn below, move up;
- home oncoming: spawn below, move up;
- home same-direction: spawn above, move down.

When the pair timer elapses, `_pairs(delta)` snapshots
`cam.get_screen_center_position().y`. This is the actual visible center after
Camera2D smoothing and offset, unlike the camera node's target position. It
uses that same snapshot for both the distance and route calculations.

If the distance is zero, the timer remains ready and no direction random
number is consumed. Once a valid distance is available, `_pairs` resets the
existing 6–11 second timer, rolls `randf() < 0.5`, requests the route, keeps
the existing walk-bound check as defense in depth, and passes the route
direction to `otherpair.gd/setup`. Every actual spawn therefore receives an
unbiased route choice without endpoint rejections changing effective cadence
or camera smoothing pulling the spawn anchor inside the chosen screen edge.

The comment above `_pairs` describes mixed-direction walkers rather than
claiming all pairs are oncoming. No random speed or X-position tuning changes.

## Regression test

Add `tests/test_pair_direction.gd` using the existing `SceneTree` pattern.
Instantiate the real `main.gd` script without adding it to the scene tree, then
call `_pair_spawn_route` for all four phase/mode combinations.

Assert the exact central-corridor spawn offset and direction for:

- outbound oncoming;
- outbound same-direction;
- home oncoming;
- home same-direction.

Also assert:

- the central corridor uses 560 pixels;
- the upper and lower edge cases shorten to exactly 360 pixels;
- positions one pixel farther into either endpoint margin return zero;
- shortened routes remain symmetric and point toward the camera.

Exit nonzero on failure and print `test_pair_direction: OK` on success.

Add the test as a direct CI step after the freedom traffic regression.

## Manual acceptance

Play through both walk legs long enough to observe several pairs:

1. Confirm some pairs approach head-on.
2. Confirm some pairs travel in the player's direction.
3. Confirm outbound and home traffic mirror correctly.
4. Confirm walkers do not visibly pop into existence at route ends.
5. Confirm speed, leash behavior, tangle rewards, and freedom cleanup remain
   unchanged.

## Compatibility

The change introduces no scene, save-data, input, export, or dependency
changes. Random spawn selection remains nondeterministic outside seeded daily
runs, matching existing traffic generation.
