# NPC Pair Pond Avoidance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make NPC dog-walker pairs steer across the park bridge instead of entering the pond on either walk direction.

**Architecture:** Keep pair movement local to `otherpair.gd`. Add pure pond-route helpers around the existing vertical velocity and dog target, then exercise those helpers through deterministic 60Hz simulations using the real script.

**Tech Stack:** Godot 4.7, GDScript, SceneTree headless regression tests, GitHub Actions.

## Global Constraints

- Preserve the existing randomized pair speed, spawn directions, leash physics, tangle behavior, and freedom cleanup.
- Apply no avoidance on levels whose `main.pond` is an empty `Rect2`.
- Do not add hard position clamps or teleports.
- Do not change player/human wading, pond rendering, pole collision, or pathfinding outside the pond approach band.
- Use no external dependencies or assets.
- Use no emoji.

---

### Task 1: Add deterministic bridge steering

**Files:**
- Create: `tests/test_pair_pond_avoidance.gd`
- Modify: `otherpair.gd:8-75`

**Interfaces:**
- Consumes: `main.pond: Rect2`, the existing `vel: Vector2`, and the existing dog follow target.
- Produces: `_pond_route_x(pos: Vector2, original_lane_x: float, pond: Rect2) -> float`.
- Produces: `_owner_step_avoiding_pond(pos: Vector2, original_lane_x: float, velocity: Vector2, pond: Rect2, delta: float) -> Vector2`.
- Produces: `_pond_safe_dog_target(target: Vector2, pond: Rect2) -> Vector2`.

- [ ] **Step 1: Write the failing real-script regression**

Create `tests/test_pair_pond_avoidance.gd`:

```gdscript
extends SceneTree

const PARK_POND := Rect2(300.0, -2950.0, 360.0, 470.0)
const LEFT_LANE_X := 520.0
const BRIDGE_X := 698.0

var failures := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _simulate_route(pair: Node2D, start: Vector2, velocity: Vector2, label: String) -> void:
	var pos := start
	var max_x := pos.x
	var entered_pond := false
	for _frame in range(900):
		pos = pair._owner_step_avoiding_pond(
			pos,
			LEFT_LANE_X,
			velocity,
			PARK_POND,
			1.0 / 60.0
		)
		max_x = maxf(max_x, pos.x)
		if PARK_POND.has_point(pos):
			entered_pond = true
	_check(not entered_pond, label + " owner stays out of pond")
	_check(max_x >= BRIDGE_X - 0.01, label + " owner reaches bridge")
	_check(absf(pos.x - LEFT_LANE_X) < 0.01, label + " owner returns to lane")


func _finish() -> void:
	if failures > 0:
		print("test_pair_pond_avoidance: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_pair_pond_avoidance: OK")
		quit(0)


func _initialize() -> void:
	var pair := Node2D.new()
	pair.set_script(load("res://otherpair.gd"))
	var required := [
		"_pond_route_x",
		"_owner_step_avoiding_pond",
		"_pond_safe_dog_target",
	]
	for method: String in required:
		_check(pair.has_method(method), "pair exposes " + method)
	if failures > 0:
		pair.free()
		_finish()
		return

	_simulate_route(pair, Vector2(LEFT_LANE_X, -2200.0), Vector2(0.0, -82.0), "outbound")
	_simulate_route(pair, Vector2(LEFT_LANE_X, -3230.0), Vector2(0.0, 82.0), "homebound")

	var inside_target := pair._pond_safe_dog_target(Vector2(500.0, -2700.0), PARK_POND)
	_check(inside_target.is_equal_approx(Vector2(BRIDGE_X, -2700.0)), "dog target moves to bridge")
	var right_target := pair._pond_safe_dog_target(Vector2(740.0, -2700.0), PARK_POND)
	_check(right_target.is_equal_approx(Vector2(740.0, -2700.0)), "right-side dog target stays put")
	var outside_target := pair._pond_safe_dog_target(Vector2(500.0, -2100.0), PARK_POND)
	_check(outside_target.is_equal_approx(Vector2(500.0, -2100.0)), "dog target outside approach stays put")

	var empty_pond := Rect2()
	var empty_step := pair._owner_step_avoiding_pond(
		Vector2(LEFT_LANE_X, -1000.0),
		LEFT_LANE_X,
		Vector2(0.0, -70.0),
		empty_pond,
		1.0
	)
	_check(empty_step.is_equal_approx(Vector2(LEFT_LANE_X, -1070.0)), "empty pond preserves owner route")
	var empty_target := pair._pond_safe_dog_target(Vector2(500.0, -1000.0), empty_pond)
	_check(empty_target.is_equal_approx(Vector2(500.0, -1000.0)), "empty pond preserves dog target")

	pair.free()
	_finish()
```

- [ ] **Step 2: Run the focused test and verify the intended failure**

Run:

```powershell
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_pair_pond_avoidance.gd
```

Expected: nonzero exit and failures that `otherpair.gd` does not expose the three pond helpers. There must be no parse error in the test itself.

- [ ] **Step 3: Add the steering constants and original lane**

At the top of `otherpair.gd`, add:

```gdscript
const TANGLE_REARM_S := 0.5
const POND_LOOKAHEAD := 240.0
const POND_CLEARANCE := 38.0
const OWNER_LATERAL_SPEED := 90.0
```

Add the lane property beside `vel`:

```gdscript
var vel := Vector2.ZERO
var lane_x := 0.0
```

In `setup`, preserve the spawn lane immediately after assigning `vel`:

```gdscript
	vel = direction * randf_range(58.0, 82.0)
	lane_x = start.x
```

- [ ] **Step 4: Add the pure pond-route helpers**

Insert before `_physics_process` in `otherpair.gd`:

```gdscript
func _pond_route_x(pos: Vector2, original_lane_x: float, pond: Rect2) -> float:
	if pond.size.x <= 0.0 or pond.size.y <= 0.0:
		return original_lane_x
	if pos.y < pond.position.y - POND_LOOKAHEAD or pos.y > pond.end.y + POND_LOOKAHEAD:
		return original_lane_x
	return maxf(original_lane_x, pond.end.x + POND_CLEARANCE)


func _owner_step_avoiding_pond(
	pos: Vector2,
	original_lane_x: float,
	velocity: Vector2,
	pond: Rect2,
	delta: float
) -> Vector2:
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

- [ ] **Step 5: Route the owner and dog through the helpers**

In `_physics_process`, replace:

```gdscript
	if tangled_t <= 0.0:
		npc_owner.position += vel * delta
```

with:

```gdscript
	if tangled_t <= 0.0:
		npc_owner.position = _owner_step_avoiding_pond(
			npc_owner.position,
			lane_x,
			vel,
			main.pond,
			delta
		)
```

After building the existing dog target, constrain only that target:

```gdscript
	var target := npc_owner.position + Vector2(30, 24) + wander + curious
	target = _pond_safe_dog_target(target, main.pond)
	npc_dog.position = npc_dog.position.move_toward(target, 90.0 * delta)
```

- [ ] **Step 6: Run the focused regression**

Run:

```powershell
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_pair_pond_avoidance.gd
```

Expected:

```text
test_pair_pond_avoidance: OK
```

- [ ] **Step 7: Run adjacent pair and leash regressions**

Run:

```powershell
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_pair_direction.gd
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_freedom_traffic.gd
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_tangle_latch.gd
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_wrap.gd
```

Expected: each test prints its own `: OK` line and exits zero.

---

### Task 2: Integrate the regression and document the resolved pond defect

**Files:**
- Modify: `.github/workflows/ci.yml:41-44`
- Modify: `CHANGELOG.md:5`
- Modify: `HANDOVER.md:70-72,134-148`

**Interfaces:**
- Consumes: `tests/test_pair_pond_avoidance.gd` from Task 1.
- Produces: Linux CI coverage and an accurate handover record.

- [ ] **Step 1: Add the focused regression to CI**

After the owner-label step in `.github/workflows/ci.yml`, add:

```yaml
      - name: NPC pond avoidance regression test
        run: ./Godot_v4.7-stable_linux.x86_64 --headless --path . --script res://tests/test_pair_pond_avoidance.gd
```

- [ ] **Step 2: Add the changelog entry**

Insert immediately after the changelog preamble:

```markdown
## 2026-07-16 — NPC bridge steering

- NPC dog-walker pairs now steer across the park bridge instead of walking
  through the pond on outbound or homebound routes.
- Their dogs keep wander and curiosity targets on the bridge side near the
  pond, then both return to their original lane after clearing it.
- Added a deterministic real-script regression for both travel directions,
  dog targeting, and levels without ponds.

```

- [ ] **Step 3: Update the handover**

Change the CI summary to:

```markdown
- **CI** (`.github/workflows/ci.yml`, Ubuntu): focused rope, critter, tangle,
  freedom-traffic, pair-direction, bandana, owner-label, and pair-pond
  regressions + 4-level smoke + full autowalk traversal. Green on every push.
```

Replace the first open bug with:

```markdown
1. **NPC pairs still need circular-obstacle work.** Pond/bridge avoidance and
   mixed oncoming/same-direction traffic are fixed. Pole wrapping remains
   open: the NPC leash uses the real rope and receives the level pole list,
   but its plain `Node2D` owner/dog endpoints can walk through poles and drag
   pinned rope ends across them. Add endpoint obstacle steering without
   separate leash wrap bookkeeping.
```

- [ ] **Step 4: Run all focused regressions**

Run:

```powershell
$tests = @(
  "test_pair_pond_avoidance.gd",
  "test_owner_label.gd",
  "test_bandana_preview.gd",
  "test_pair_direction.gd",
  "test_freedom_traffic.gd",
  "test_tangle_latch.gd",
  "test_critter_chase.gd",
  "test_wrap.gd"
)
foreach ($test in $tests) {
  .\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script "res://tests/$test"
  if ($LASTEXITCODE -ne 0) { throw "$test failed" }
}
```

Expected: every test prints `: OK`; `test_wrap.gd` also prints rope metrics.

- [ ] **Step 5: Run the four-level smoke test**

Run:

```powershell
foreach ($level in @("street", "park", "beach", "market")) {
  .\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --quit-after 1800 -- "--level=$level"
  if ($LASTEXITCODE -ne 0) { throw "$level smoke failed" }
}
```

Expected: all four commands exit zero without `SCRIPT ERROR`, `Parse Error`, or `Failed to load script`.

- [ ] **Step 6: Perform the park manual acceptance check**

Run:

```powershell
.\godot\Godot_v4.7-stable_win64.exe --path .
```

Select the park and observe NPC pairs around the pond on both walk legs. Verify:

1. left-lane owners visibly steer right before the pond;
2. owners and dogs stay on the bridge;
3. right-lane pairs do not shift left;
4. pairs return toward their spawn lane afterward;
5. no change is visible in speed mix, direction mix, tangles, or freedom cleanup.

Do not mark the task complete if any pair snaps sideways or a dog enters the pond.

- [ ] **Step 7: Review the final diff**

Run:

```powershell
git diff --check
git diff -- otherpair.gd tests/test_pair_pond_avoidance.gd .github/workflows/ci.yml CHANGELOG.md HANDOVER.md
```

Expected: `git diff --check` exits zero; the diff contains only the approved pond steering, regression, CI, and documentation changes.
