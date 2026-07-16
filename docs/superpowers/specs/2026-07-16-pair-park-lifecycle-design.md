# NPC pair dog-park lifecycle

## Goal

NPC dog-walker pairs persist through the freedom transition and visibly use
the dog park. A pair can arrive leashed, wait while its dog roams off leash,
recall and re-leash the dog, then depart through the gate.

This pass does not redesign NPC owner art, add breeds, change player leash
physics, or add deliberate pole-snag recovery.

## State machine

`otherpair.gd` owns one persistent lifecycle:

```text
WALKING -> ARRIVING -> PARKED -> RECALLING -> DEPARTING -> WALKING
```

- `WALKING`: existing route-planned path behavior.
- `ARRIVING`: an upward-moving pair that reaches the gate reserves a park
  waiting spot and moves into the yard together, still leashed.
- `PARKED`: owner remains at the reserved spot. The pair leash is detached and
  hidden, rope samples are empty, and the same dog node roams inside the
  freedom bounds.
- `RECALLING`: the dog physically returns to the owner. The leash remains
  hidden until the dog is close.
- `DEPARTING`: the leash is shown and resnapped, the pair walks down through
  the gate, then resumes ordinary `WALKING`.

Entering the home phase immediately recalls every arrived pair. A state change
never creates or destroys a replacement dog, preserving colors, greeting
identity and owner linkage.

## Park slots

`main.gd` owns a fixed set of waiting spots along the park fence, excluding the
player owner's bench. It explicitly reserves a slot before dispatching an
arrival or parked departure to `otherpair.gd`. Reservations release when a
departing owner clears the gate or the pair leaves the tree.

If no spot is free, an arriving pair continues through the park instead of
blocking at the gate.

## Freedom traffic

`otherpair.gd` no longer deletes itself solely because `phase == "freedom"`.
Existing upward pairs can arrive and downward pairs can finish departing.

During freedom, `_pairs()` uses the existing pair cap and a slower timer to
spawn a sparse mix of:

- arrivals from the path below the gate;
- parked pairs whose short timer leads into a visible recall and departure.

Bikes and scooters remain removed and unspawned during freedom.

## Parked dog behavior

The dog keeps the existing pair node and renderer. While parked it uses a
small off-leash wander loop:

- random milling velocity with damping;
- occasional movement toward the player dog when nearby;
- hard bounds inside the freedom yard;
- no owner motion, leash tick, rope samples or invisible tangles.

The existing greeting system continues to use the pair instance ID.

## Transitions and cleanup

- Arrival keeps the real leash visible and ticking until both reach the spot.
- Parking hides/detaches the leash and clears sampled rope points.
- Recall holds the owner still and moves the dog toward them.
- Re-leashing requires close range, then calls `leash.resnap()` before making
  it visible.
- Departure first reaches a bounded gate-exit waypoint, releases its slot, then
  restores downward desired speed and shared obstacle routing.
- `_exit_tree` releases any reserved spot.
- Tangle state is disarmed while parked; existing tangle rewards and latching
  remain unchanged on the walking legs.

## Tests

Add `tests/test_pair_park_lifecycle.gd` using real `otherpair.gd`, planner and
leash with hidden manually ticked fixtures. Cover:

- walking upward reserves a slot and reaches `ARRIVING`;
- arrival reaches `PARKED` with stationary owner, hidden leash and empty rope
  samples;
- parked dog remains inside bounds and keeps the same node/identity;
- timer and home-phase interruption both enter `RECALLING`;
- leash remains hidden until close, then resnaps and becomes visible;
- departure crosses the gate downward and returns to `WALKING`;
- slot exhaustion continues through instead of blocking;
- reservations release on departure and cleanup;
- failed/rapid phase changes do not leak slots or produce invisible tangles.

Update `tests/test_freedom_traffic.gd`: riders still remove themselves in
freedom, while a configured pair persists.

Add focused main-helper coverage for reservation capacity and freedom spawn
policy. Retain all avoidance, tangle, rope, smoke and autowalk checks.

## Manual acceptance

- A pair can walk through the gate into the park without disappearing.
- Waiting owners occupy distinct spots away from the player owner.
- Their dogs visibly roam off leash and can be greeted.
- Recall happens before the leash appears.
- Departing pairs cross the gate and continue down the walk.
- Riders remain absent during freedom.
- No invisible leash tangles, slot stacking or transition snaps occur.
