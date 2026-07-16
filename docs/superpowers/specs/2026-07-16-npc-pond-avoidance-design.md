# NPC pair pond avoidance

## Context

NPC dog-walker owners currently move by adding a fixed vertical velocity, and
their dogs follow an unconstrained wander/curiosity target. In the park,
pairs whose lane intersects the pond therefore walk directly through the
water instead of using the bridge.

This task addresses only the rectangular park pond. Circular pole/obstacle
avoidance and leash-endpoint wrapping remain separate follow-up work.

## Goal

- NPC owners and dogs use the bridge side of the park pond on both travel
  directions.
- Avoidance begins early enough to look like steering rather than a snap.
- Owners return to their original lane after clearing the pond.
- Other levels and all pair spawning, speed, leash, and tangle behavior remain
  unchanged.

## Steering model

Add these constants to `otherpair.gd`:

```gdscript
const POND_LOOKAHEAD := 240.0
const POND_CLEARANCE := 38.0
const OWNER_LATERAL_SPEED := 90.0
```

Store `lane_x = start.x` during setup. Keep the existing randomized `vel`
unchanged.

Add pure helpers:

```gdscript
func _pond_route_x(pos: Vector2, original_lane_x: float, pond: Rect2) -> float:
	if pond.size.x <= 0.0 or pond.size.y <= 0.0:
		return original_lane_x
	if pos.y < pond.position.y - POND_LOOKAHEAD or pos.y > pond.end.y + POND_LOOKAHEAD:
		return original_lane_x
	return maxf(original_lane_x, pond.end.x + POND_CLEARANCE)


func _owner_step_avoiding_pond(pos: Vector2, original_lane_x: float, velocity: Vector2, pond: Rect2, delta: float) -> Vector2:
	var target_x := _pond_route_x(pos, original_lane_x, pond)
	return Vector2(
		move_toward(pos.x, target_x, OWNER_LATERAL_SPEED * delta),
		pos.y + velocity.y * delta
	)


func _pond_safe_dog_target(target: Vector2, pond: Rect2) -> Vector2:
	if pond.size.x <= 0.0 or pond.size.y <= 0.0:
		return target
	if target.y >= pond.position.y - POND_LOOKAHEAD and target.y <= pond.end.y + POND_LOOKAHEAD:
		target.x = maxf(target.x, pond.end.x + POND_CLEARANCE)
	return target
```

The pond occupies the left portion of the park path; its bridge begins at the
pond's right edge. `maxf` preserves lanes already farther right.

## Integration

When not rooted by a tangle, replace the owner's direct `position += vel *
delta` with `_owner_step_avoiding_pond(..., main.pond, delta)`.

Build the dog's existing target exactly as before, then pass it through
`_pond_safe_dog_target(target, main.pond)` before `move_toward`. Keep the
existing dog speed, wander, curiosity, and leash-length clamp.

No hard position clamp or teleport is added. The 240px approach band gives an
owner at the leftmost park spawn lane enough time to reach the bridge at the
maximum 82px/s forward speed.

## Regression

Add `tests/test_pair_pond_avoidance.gd` using the real `otherpair.gd` script
without adding it to the scene tree.

Simulate fixed 60Hz owner steps through the park pond:

- outbound from below the pond at x=520 and y=-2200 with y velocity -82;
- homebound from above at x=520 and y=-3230 with y velocity +82.

For both simulations, verify no step lies inside the pond, the route reaches
the bridge side, and the owner returns close to x=520 after clearing it.

Also verify:

- a dog target inside the approach band is moved to the bridge side;
- a dog target outside the band is unchanged;
- an empty pond leaves owner movement and dog targets unchanged.

The test exits nonzero on failure and prints
`test_pair_pond_avoidance: OK`. Add it to CI after the owner-label regression.

## Manual acceptance

In the park, observe pairs approaching the pond on outbound and home legs:

1. Owners whose normal lane intersects water steer onto the bridge.
2. Their dogs follow the bridge and do not wander into the pond.
3. Pairs already on the right remain on their lane.
4. Pairs return toward their original lane after the pond.
5. Direction mix, speed, leash behavior, tangling, and freedom cleanup remain
   unchanged.

## Scope

Do not change pond rendering, player/human wading, pair speed, spawn logic,
pathfinding outside the pond band, pole collision, leash physics, or tangle
rewards. Update `CHANGELOG.md` and `HANDOVER.md` when verified.
