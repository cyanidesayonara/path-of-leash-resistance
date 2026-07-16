# Mixed NPC-Pair Direction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make NPC dog-walker traffic an even random mix of oncoming and ambient same-direction pairs on both walk legs.

**Architecture:** A pure distance helper finds a symmetric 360–560px off-screen distance at which both directions fit, and a pure route helper converts walk phase plus an oncoming choice into spawn Y and travel direction. `_pairs(delta)` makes the 50% choice only after both routes are available.

**Tech Stack:** Godot 4.7, GDScript, built-in `SceneTree` test scripts, GitHub Actions.

## Global Constraints

- Keep Godot 4.7 and GDScript; add no dependencies.
- Preserve NPC-pair speed, movement, pathfinding, obstacle avoidance, leash physics, tangling, the 6–11 second interval between successful spawns, population cap, and art.
- Preserve freedom-phase traffic cleanup.
- Do not address pond entry or pole wrapping.
- Do not guarantee an exact alternating sequence.
- Do not use emoji.
- Update `CHANGELOG.md` at the end of the session.
- Do not create a git commit unless the user explicitly requests one.
- This is a mixed uncommitted checkout; do not stage whole shared files or directories as a direction-only commit.

## File map

- Create `tests/test_pair_direction.gd`: pure distance and route regression using the real `main.gd` script.
- Modify `main.gd:14-24,1406-1420`: add named distances, route helpers, and an unbiased 50% oncoming roll.
- Modify `.github/workflows/ci.yml:32-35`: run the route regression directly.
- Modify `CHANGELOG.md:5`: document mixed NPC-pair traffic.

---

### Task 1: Implement and test mixed pair routes

**Files:**
- Create: `tests/test_pair_direction.gd`
- Modify: `main.gd:1406-1420`

**Interfaces:**
- Produces: `_pair_spawn_distance(camera_y: float) -> float`.
- Produces: `_pair_spawn_route(walk_phase: String, oncoming: bool, camera_y: float) -> Dictionary`.
- Dictionary keys: `"y": float`, `"direction": Vector2`.
- Consumes: existing phases `"out"` and `"home"`; `_pairs(delta)` never calls the helper during freedom.

- [ ] **Step 1: Write the failing real-script regression**

Create `tests/test_pair_direction.gd`:

```gdscript
extends SceneTree

var failures := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _check_distance(main: Node2D, camera_y: float, expected: float, label: String) -> void:
	var distance := float(main.call("_pair_spawn_distance", camera_y))
	_check(is_equal_approx(distance, expected), label)


func _check_route(main: Node2D, walk_phase: String, oncoming: bool, camera_y: float, expected_y: float, expected_direction: Vector2, label: String) -> void:
	var route: Dictionary = main.call("_pair_spawn_route", walk_phase, oncoming, camera_y)
	var route_y := float(route["y"])
	var direction: Vector2 = route["direction"]
	_check(is_equal_approx(route_y, expected_y), label + " spawn position")
	_check(direction.is_equal_approx(expected_direction), label + " direction")
	_check((camera_y - route_y) * direction.y > 0.0, label + " moves toward camera")


func _finish() -> void:
	if failures > 0:
		print("test_pair_direction: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_pair_direction: OK")
		quit(0)


func _initialize() -> void:
	var main := Node2D.new()
	main.set_script(load("res://main.gd"))
	if not main.has_method("_pair_spawn_distance") or not main.has_method("_pair_spawn_route"):
		_check(false, "main exposes pair spawn helpers")
		main.free()
		_finish()
		return

	var camera_y := -1000.0
	_check_distance(main, camera_y, 560.0, "central spawn distance")
	_check_route(main, "out", true, camera_y, -1560.0, Vector2.DOWN, "outbound oncoming")
	_check_route(main, "out", false, camera_y, -440.0, Vector2.UP, "outbound same-direction")
	_check_route(main, "home", true, camera_y, -440.0, Vector2.UP, "home oncoming")
	_check_route(main, "home", false, camera_y, -1560.0, Vector2.DOWN, "home same-direction")

	_check_distance(main, -100.0, 460.0, "upper intermediate spawn distance")
	_check_route(main, "out", true, -100.0, -560.0, Vector2.DOWN, "upper intermediate outbound oncoming")
	_check_route(main, "out", false, -100.0, 360.0, Vector2.UP, "upper intermediate outbound same-direction")

	_check_distance(main, 0.0, 360.0, "upper edge shortens to viewport edge")
	_check_route(main, "out", true, 0.0, -360.0, Vector2.DOWN, "upper edge oncoming")
	_check_route(main, "out", false, 0.0, 360.0, Vector2.UP, "upper edge same-direction")
	_check_distance(main, 1.0, 0.0, "upper margin pauses spawning")

	_check_distance(main, -4480.0, 460.0, "lower intermediate spawn distance")
	_check_route(main, "home", true, -4480.0, -4020.0, Vector2.UP, "lower intermediate home oncoming")
	_check_route(main, "home", false, -4480.0, -4940.0, Vector2.DOWN, "lower intermediate home same-direction")

	_check_distance(main, -4580.0, 360.0, "lower edge shortens to viewport edge")
	_check_route(main, "home", true, -4580.0, -4220.0, Vector2.UP, "lower edge oncoming")
	_check_route(main, "home", false, -4580.0, -4940.0, Vector2.DOWN, "lower edge same-direction")
	_check_distance(main, -4581.0, 0.0, "lower margin pauses spawning")

	main.free()
	_finish()
```

- [ ] **Step 2: Run the test and confirm the helper is missing**

Run:

```powershell
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_pair_direction.gd
```

Expected: exit `1` with:

```text
FAIL: main exposes pair spawn helpers
test_pair_direction: 1 FAILURES
```

- [ ] **Step 3: Add named spawn distances and pure helpers**

Add near the existing top-level tuning constants:

```gdscript
const PAIR_SPAWN_DIST := 560.0
const PAIR_MIN_SPAWN_DIST := 360.0
```

Insert immediately before `_pairs(delta)`:

```gdscript
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

- [ ] **Step 4: Roll direction only when both routes fit**

Replace the timer-expired spawn block in `main.gd/_pairs`:

```gdscript
			pair_spawn_t = randf_range(6.0, 11.0)
			var route := _pair_spawn_route(phase, randf() < 0.5, cam.position.y)
			var y: float = route["y"]
			if y >= GATE_Y + 60.0 and y <= START_Y + 100.0:
				var p := Node2D.new()
				p.set_script(load("res://otherpair.gd"))
				add_child(p)
				var direction: Vector2 = route["direction"]
				p.setup(self, dog, poles, Vector2(randf_range(walk_cx - 120.0, walk_cx + 120.0), y), direction)
```

with:

```gdscript
			var camera_y := cam.get_screen_center_position().y
			var spawn_distance := _pair_spawn_distance(camera_y)
			if spawn_distance > 0.0:
				pair_spawn_t = randf_range(6.0, 11.0)
				var route := _pair_spawn_route(phase, randf() < 0.5, camera_y)
				var y: float = route["y"]
				if y >= GATE_Y + 60.0 and y <= START_Y + 100.0:
					var p := Node2D.new()
					p.set_script(load("res://otherpair.gd"))
					add_child(p)
					var direction: Vector2 = route["direction"]
					p.setup(self, dog, poles, Vector2(randf_range(walk_cx - 120.0, walk_cx + 120.0), y), direction)
```

Update the `_pairs` comment to describe mixed-direction walkers. Keep the
timer range, population cap, X range, bounds check, setup function, and all
post-spawn tangle processing unchanged. When less than 360 pixels fits, leave
the expired timer ready and consume no direction random number. Snapshot
`get_screen_center_position().y` once so Camera2D smoothing and offset cannot
make the distance and route use different visible centers.

- [ ] **Step 5: Run focused and existing regressions**

Run:

```powershell
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_pair_direction.gd
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_freedom_traffic.gd
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_tangle_latch.gd
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_critter_chase.gd
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_wrap.gd
```

Expected: all commands exit `0` and print their respective `OK` markers.

- [ ] **Step 6: Review the focused diff**

Confirm that both helpers have no side effects, production uses the actual
screen center rather than the smoothed camera target, the direction roll
occurs only for an actual spawn, each spawn still consumes one existing random
speed roll inside `otherpair.gd/setup`, and no post-spawn behavior changed.

- [ ] **Step 7: Leave the mixed checkout uncommitted**

Do not create a direction-only commit from this checkout. If the user requests
a commit, inspect the full status and diff, then ask whether to commit the
accumulated stabilization work together or isolate it after the preceding work
is committed.

---

### Task 2: Add CI coverage and document mixed pair traffic

**Files:**
- Modify: `.github/workflows/ci.yml:32-35`
- Modify: `CHANGELOG.md:5`

**Interfaces:**
- Consumes: `tests/test_pair_direction.gd`, which exits nonzero on failure.
- Produces: direct CI gate `NPC pair direction regression test`; newest-first changelog entry.

- [ ] **Step 1: Add the direct CI test step**

Insert immediately after `Freedom traffic regression test`:

```yaml
      - name: NPC pair direction regression test
        run: ./Godot_v4.7-stable_linux.x86_64 --headless --path . --script res://tests/test_pair_direction.gd
```

- [ ] **Step 2: Add the newest changelog entry**

Insert before the freedom-traffic entry:

```markdown
## 2026-07-15 — mixed NPC walker directions

- NPC dog-walker pairs now spawn as an even random mix of head-on encounters
  and ambient same-direction walkers on both legs of the walk.
- Spawn positions shorten to the viewport edge near route ends while preserving
  unbiased oncoming/same-direction selection.
- Added a real-script headless regression covering outbound and home routes.
```

- [ ] **Step 3: Run all-level smoke and full autowalk**

Run:

```powershell
foreach ($lv in "street","park","beach","market") {
  Write-Host "=== $lv ==="
  godot\Godot_v4.7-stable_win64_console.exe --headless --path . --quit-after 1800 -- --level=$lv
  if ($LASTEXITCODE -ne 0) { throw "Smoke test failed: $lv" }
}

godot\Godot_v4.7-stable_win64_console.exe --headless --fixed-fps 60 --path . --quit-after 12000 -- --level=street --autowalk
```

Expected: clean exits for all levels and output containing
`AUTOWALK FINISHED`.

- [ ] **Step 4: Perform the manual route check**

Run:

```powershell
godot\Godot_v4.7-stable_win64.exe --path .
```

Observe several pairs on both legs. Confirm that some approach head-on and
some travel in the player's direction, no pair visibly pops in near a route
end, and speed, leash, tangling, and freedom cleanup remain unchanged.

- [ ] **Step 5: Review the complete diff**

Confirm the change contains only the helper, 50% route selection, route test,
CI step, changelog entry, and approved docs. Confirm pond avoidance and pole
wrapping remain explicitly deferred.

- [ ] **Step 6: Leave the mixed checkout uncommitted**

Do not stage whole files or directories for a direction-only commit. If the
user requests a commit, inspect the accumulated checkout and ask whether to
commit all stabilization work together or isolate after preceding work is
committed.
