# Freedom Traffic Isolation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep the off-leash freedom phase free of bikes, scooters, and leashed NPC pairs while preserving normal corridor traffic.

**Architecture:** `main.gd` pauses both rider spawners during freedom. Existing `bike.gd` and `otherpair.gd` entities independently remove themselves on their first freedom physics tick, before accessing movement or collision dependencies.

**Tech Stack:** Godot 4.7, GDScript, built-in `SceneTree` test scripts, GitHub Actions.

## Global Constraints

- Keep Godot 4.7 and GDScript; add no dependencies.
- Preserve traffic spawn intervals, positions, speeds, collision, and art.
- Preserve NPC-pair movement, direction, pathfinding, leash physics, and tangle behavior.
- Preserve freedom timing, fetch, greetings, owner parking, free dogs, and the ball.
- Do not add fence collision or traffic pathfinding.
- Do not use emoji.
- Update `CHANGELOG.md` at the end of the session.
- Do not create a git commit unless the user explicitly requests one.

## File map

- Create `tests/test_freedom_traffic.gd`: real-script cleanup regression.
- Modify `main.gd:932-935`: pause crossing and vertical rider spawners in freedom.
- Modify `bike.gd:46-48`: remove active riders immediately in freedom.
- Modify `otherpair.gd:48-50`: remove active leashed pairs immediately in freedom.
- Modify `.github/workflows/ci.yml:29-32`: run the new regression directly.
- Modify `CHANGELOG.md:5`: document the traffic-free freedom phase.

---

### Task 1: Remove and suppress freedom-phase traffic

**Files:**
- Create: `tests/test_freedom_traffic.gd`
- Modify: `main.gd:932-935`
- Modify: `bike.gd:46-48`
- Modify: `otherpair.gd:48-50`

**Interfaces:**
- Consumes: `main.phase: String` with the existing `"freedom"` value.
- Produces: active riders and pairs call `queue_free()` before movement when freedom begins; rider spawner timers do not advance during freedom.

- [ ] **Step 1: Write the failing real-script regression**

Create `tests/test_freedom_traffic.gd`:

```gdscript
extends SceneTree

var failures := 0


class FakeMain:
	extends Node2D

	var phase := "freedom"
	var frozen := true


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _make_traffic(script_path: String, main: Node2D) -> Node2D:
	var traffic := Node2D.new()
	traffic.set_script(load(script_path))
	traffic.visible = false
	traffic.set_physics_process(false)
	traffic.main = main
	root.add_child(traffic)
	return traffic


func _initialize() -> void:
	var main := FakeMain.new()
	root.add_child(main)

	var bike := _make_traffic("res://bike.gd", main)
	bike._physics_process(0.0)
	_check(bike.is_queued_for_deletion(), "active rider removes itself in freedom")

	var pair := _make_traffic("res://otherpair.gd", main)
	pair._physics_process(0.0)
	_check(pair.is_queued_for_deletion(), "active leashed pair removes itself in freedom")

	if failures > 0:
		print("test_freedom_traffic: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_freedom_traffic: OK")
		quit(0)
```

- [ ] **Step 2: Run the test and confirm current traffic remains active**

Run:

```powershell
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_freedom_traffic.gd
```

Expected: exit `1` with:

```text
FAIL: active rider removes itself in freedom
FAIL: active leashed pair removes itself in freedom
test_freedom_traffic: 2 FAILURES
```

The fake main is frozen so the pre-change scripts return without touching
their omitted dependencies, producing assertion failures rather than fixture
errors.

- [ ] **Step 3: Add the rider freedom guard**

At the start of `bike.gd/_physics_process`, before `main.frozen`, add:

```gdscript
	if main.phase == "freedom":
		queue_free()
		return
```

- [ ] **Step 4: Add the NPC-pair freedom guard**

At the start of `otherpair.gd/_physics_process`, before `main.frozen`, add:

```gdscript
	if main.phase == "freedom":
		queue_free()
		return
```

- [ ] **Step 5: Pause rider spawners during freedom**

In `main.gd/_physics_process`, replace:

```gdscript
	_apply_leash(delta)
	_lanes(delta)
	_vlane(delta)
	_squirrels(delta)
```

with:

```gdscript
	_apply_leash(delta)
	if phase != "freedom":
		_lanes(delta)
		_vlane(delta)
	_squirrels(delta)
```

Keep `_pairs(delta)` unconditional because it owns detached-leash cleanup and
already gates pair spawning outside freedom.

- [ ] **Step 6: Run focused and existing regressions**

Run:

```powershell
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_freedom_traffic.gd
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_tangle_latch.gd
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_critter_chase.gd
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_wrap.gd
```

Expected: all commands exit `0` and print:

```text
test_freedom_traffic: OK
test_tangle_latch: OK
test_critter_chase: OK
test_wrap: OK
```

- [ ] **Step 7: Review the focused diff**

Confirm the production diff adds only two early cleanup guards and one phase
gate around rider spawners. Confirm pair spawning, `_pairs(delta)`, free dogs,
fetch, traffic tuning, movement, collision, and art remain unchanged.

- [ ] **Step 8: Commit only if explicitly requested**

Do not create a freedom-only commit from this mixed checkout. The shared files
contain preceding stabilization work, so staging whole files or directories
would mix scopes. The preceding stabilization work must be isolated first.

If the user requests a commit, first inspect the current status and diffs, then
ask whether to commit the accumulated stabilization work together or isolate
the freedom changes in a clean worktree after the preceding work is committed.
Do not use interactive staging, broad directory staging, or any command that
silently includes unrelated work. Otherwise, leave the changes uncommitted.

---

### Task 2: Add CI coverage and document the fix

**Files:**
- Modify: `.github/workflows/ci.yml:29-32`
- Modify: `CHANGELOG.md:5`

**Interfaces:**
- Consumes: `tests/test_freedom_traffic.gd`, which exits nonzero on failure.
- Produces: a direct CI gate named `Freedom traffic regression test`; a newest-first changelog entry.

- [ ] **Step 1: Add the direct CI test step**

Insert immediately after `Tangle event regression test`:

```yaml
      - name: Freedom traffic regression test
        run: ./Godot_v4.7-stable_linux.x86_64 --headless --path . --script res://tests/test_freedom_traffic.gd
```

- [ ] **Step 2: Add the newest changelog entry**

Insert before the existing tangle-events entry:

```markdown
## 2026-07-15 — traffic-free freedom phase

- Entering the off-leash area now removes active bikes, scooters and leashed
  NPC pairs immediately; rider spawners pause until the home leg.
- Added a real-script headless regression for freedom-phase traffic cleanup.
```

- [ ] **Step 3: Run all level smoke tests**

Run:

```powershell
foreach ($lv in "street","park","beach","market") {
  Write-Host "=== $lv ==="
  godot\Godot_v4.7-stable_win64_console.exe --headless --path . --quit-after 1800 -- --level=$lv
  if ($LASTEXITCODE -ne 0) { throw "Smoke test failed: $lv" }
}
```

Expected: every level exits `0` with no `SCRIPT ERROR`, `Parse Error`, or
`Failed to load script`.

- [ ] **Step 4: Run the full-walk traversal**

Run:

```powershell
godot\Godot_v4.7-stable_win64_console.exe --headless --fixed-fps 60 --path . --quit-after 12000 -- --level=street --autowalk
```

Expected: exit `0`, no script or parse errors, and output containing
`AUTOWALK FINISHED`.

- [ ] **Step 5: Perform the manual freedom check**

Run:

```powershell
godot\Godot_v4.7-stable_win64.exe --path .
```

Enter freedom with traffic still active. Confirm bikes, scooters, and leashed
pairs disappear immediately; none spawn during freedom; free dogs and fetch
remain active; traffic resumes after beginning the home leg.

- [ ] **Step 6: Review the complete diff**

Confirm the product change contains only:

- the new freedom-traffic regression;
- the two active-entity cleanup guards;
- the rider-spawner phase gate;
- the dedicated CI step;
- the newest changelog entry;
- the approved design and implementation plan documents.

- [ ] **Step 7: Commit only if explicitly requested**

Do not create a freedom-only commit from this mixed checkout. The shared files
contain preceding stabilization work, so staging whole files or directories
would mix scopes. The preceding stabilization work must be isolated first.

If the user requests a commit, first inspect the current status and diffs, then
ask whether to commit the accumulated stabilization work together or isolate
the freedom changes in a clean worktree after the preceding work is committed.
Do not use interactive staging, broad directory staging, or any command that
silently includes unrelated work. Otherwise, leave the worktree uncommitted.
