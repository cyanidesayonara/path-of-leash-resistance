# Distinct Tangle Event Latch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert continuous leash-crossing frames into one reward and apology per distinct snag, rearming after 0.5 seconds of separation.

**Architecture:** `otherpair.gd` owns a per-pair rising-edge latch and separation timer through `update_tangle_state(crossing, delta) -> bool`. `main.gd` remains responsible for crossing detection and awards only when that method reports a newly armed event.

**Tech Stack:** Godot 4.7, GDScript, built-in `SceneTree` test scripts, GitHub Actions.

## Global Constraints

- Keep Godot 4.7 and GDScript; add no dependencies.
- Keep GL Compatibility and web export behavior unchanged.
- Preserve rope collision, wrapping, capstan behavior, and the 17-pixel crossing threshold.
- Preserve NPC movement, speed, pathfinding, pair spawn direction, and freedom-zone traffic.
- Preserve the `+3` reward, quest target, and existing feedback text.
- Do not use emoji.
- Update `CHANGELOG.md` at the end of the session.
- Do not create a git commit unless the user explicitly requests one.

## File map

- Create `tests/test_tangle_latch.gd`: isolated rising-edge and rearm regression.
- Modify `otherpair.gd:19-20,76-82`: replace the reaction toggle with per-pair latch state.
- Modify `main.gd:99,1422-1442`: report crossing state per pair and award only new events.
- Modify `.github/workflows/ci.yml:26-29`: run the new regression directly.
- Modify `CHANGELOG.md:5`: document the behavior and test.

---

### Task 1: Implement and test the per-pair tangle latch

**Files:**
- Create: `tests/test_tangle_latch.gd`
- Modify: `otherpair.gd:19-20,76-82`
- Modify: `main.gd:99,1422-1442`

**Interfaces:**
- Consumes: `main._ropes_crossing(a: Array[Vector2], b: Array[Vector2]) -> bool`, `main.float_text(pos: Vector2, text: String, color: Color)`, and the existing `tangles` and `bones` counters.
- Produces: `otherpair.update_tangle_state(crossing: bool, delta: float) -> bool`, returning `true` only for a newly armed crossing.

- [ ] **Step 1: Write the failing latch regression**

Create `tests/test_tangle_latch.gd`:

```gdscript
extends SceneTree

var failures := 0


class FakeMain:
	extends Node2D

	var apologies := 0

	func float_text(_pos: Vector2, text: String, _color: Color) -> void:
		if text == "oh - sorry!":
			apologies += 1


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _make_pair(main: Node2D) -> Node2D:
	var pair := Node2D.new()
	pair.set_script(load("res://otherpair.gd"))
	pair.main = main
	pair.npc_owner = Node2D.new()
	pair.add_child(pair.npc_owner)
	return pair


func _initialize() -> void:
	var main := FakeMain.new()
	root.add_child(main)
	var pair := _make_pair(main)

	_check(pair.update_tangle_state(true, 0.016), "first crossing is a new event")
	_check(is_equal_approx(pair.tangled_t, 0.4), "crossing refreshes the root timer")
	_check(main.apologies == 1, "first crossing displays one apology")

	_check(not pair.update_tangle_state(true, 0.016), "sustained crossing does not retrigger")
	_check(main.apologies == 1, "sustained crossing does not repeat the apology")

	_check(not pair.update_tangle_state(false, 0.49), "short separation does not emit an event")
	_check(pair.tangle_active, "short separation does not rearm")
	_check(not pair.update_tangle_state(true, 0.016), "one-frame recross remains the same snag")
	_check(main.apologies == 1, "geometry flicker does not repeat the apology")

	_check(not pair.update_tangle_state(false, 0.5), "full separation only rearms")
	_check(not pair.tangle_active, "half-second separation rearms the pair")
	_check(pair.update_tangle_state(true, 0.016), "later crossing is a new event")
	_check(main.apologies == 2, "later crossing displays one new apology")

	pair.free()
	if failures > 0:
		print("test_tangle_latch: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_tangle_latch: OK")
		quit(0)
```

- [ ] **Step 2: Run the test and confirm the missing latch**

Run:

```powershell
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_tangle_latch.gd
```

Expected: nonzero exit with an error that `update_tangle_state` does not exist.

- [ ] **Step 3: Replace the reaction toggle with per-pair state**

In `otherpair.gd`, add the tuning constant below the file comment:

```gdscript
const TANGLE_REARM_S := 0.5
```

Replace:

```gdscript
var tangled_t := 0.0
var reacted := false
var sampled: Array[Vector2] = []
```

with:

```gdscript
var tangled_t := 0.0
var tangle_active := false
var tangle_clear_t := 0.0
var sampled: Array[Vector2] = []
```

Replace `note_tangle()` with:

```gdscript
func update_tangle_state(crossing: bool, delta: float) -> bool:
	if crossing:
		tangled_t = 0.4
		tangle_clear_t = 0.0
		if tangle_active:
			return false
		tangle_active = true
		main.float_text(npc_owner.position, "oh - sorry!", Color(1, 0.9, 0.8))
		return true
	if tangle_active:
		tangle_clear_t += delta
		if tangle_clear_t >= TANGLE_REARM_S:
			tangle_active = false
			tangle_clear_t = 0.0
	return false
```

- [ ] **Step 4: Replace the global score cooldown with pair event returns**

Remove this variable from `main.gd`:

```gdscript
var tangle_cd := 0.0
```

Replace the tangle-feed block beginning at `# tangle feed` with:

```gdscript
	# tangle feed: our rope and theirs each become obstacles for the other
	leash.dynamic_obstacles.clear()
	if leash.detached:
		for p in pairs:
			p.leash.dynamic_obstacles.clear()
			p.update_tangle_state(false, delta)
		return
	my_rope_sample.clear()
	for i in range(0, leash.N, 2):
		my_rope_sample.append(leash.pts[i])
	for p in pairs:
		var crossing := false
		if dog.global_position.distance_to(p.npc_owner.position) > 320.0:
			p.leash.dynamic_obstacles.clear()
		else:
			leash.dynamic_obstacles.append_array(p.sampled)
			p.leash.dynamic_obstacles = my_rope_sample.duplicate()
			crossing = _ropes_crossing(my_rope_sample, p.sampled)
		if p.update_tangle_state(crossing, delta):
			tangles += 1
			bones += 3
			float_text(dog.global_position, "TANGLED! +3", Color(1, 0.85, 0.7))
```

- [ ] **Step 5: Run focused and existing regressions**

Run:

```powershell
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_tangle_latch.gd
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_critter_chase.gd
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_wrap.gd
```

Expected: all commands exit `0` and print:

```text
test_tangle_latch: OK
test_critter_chase: OK
test_wrap: OK
```

- [ ] **Step 6: Review the focused diff**

Confirm the production diff changes only event latching, detached/far-pair
state reporting, and removal of the obsolete global cooldown. Confirm crossing
distance, rope sampling, dynamic-obstacle feeding, reward values, and quest
logic remain unchanged.

- [ ] **Step 7: Commit only if explicitly requested**

If the user explicitly requests a commit:

```powershell
git add tests/test_tangle_latch.gd otherpair.gd main.gd
git commit -m "fix repeated leash tangle events"
```

Otherwise, leave the changes uncommitted.

---

### Task 2: Add the regression to CI and document the fix

**Files:**
- Modify: `.github/workflows/ci.yml:26-29`
- Modify: `CHANGELOG.md:5`

**Interfaces:**
- Consumes: `tests/test_tangle_latch.gd`, which exits nonzero on any assertion failure.
- Produces: a direct CI gate named `Tangle event regression test`; a newest-first changelog entry.

- [ ] **Step 1: Add the direct CI test step**

Insert immediately after `Critter chase regression test`:

```yaml
      - name: Tangle event regression test
        run: ./Godot_v4.7-stable_linux.x86_64 --headless --path . --script res://tests/test_tangle_latch.gd
```

- [ ] **Step 2: Add the newest changelog entry**

Insert before the existing critter chase entry:

```markdown
## 2026-07-15 — distinct leash tangle events

- A continuous NPC leash crossing now triggers one apology, quest increment
  and `TANGLED! +3` reward instead of repeating every few frames.
- A pair rearms only after half a second fully separated, with a headless
  regression covering sustained crossings, geometry flicker and recrossing.
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

- [ ] **Step 5: Perform the manual tangle check**

Run:

```powershell
godot\Godot_v4.7-stable_win64.exe --path .
```

Verify one continuous crossing longer than two seconds emits one apology and
one reward. Separate for at least half a second, recross the same pair, and
verify exactly one second event.

- [ ] **Step 6: Review the complete diff**

Confirm the complete product change contains only:

- the new tangle regression;
- the per-pair latch;
- main-loop integration and obsolete cooldown removal;
- the dedicated CI step;
- the newest changelog entry;
- the approved design and implementation plan documents.

- [ ] **Step 7: Commit only if explicitly requested**

If the user explicitly requests a commit after reviewing the complete diff:

```powershell
git add .github/workflows/ci.yml CHANGELOG.md docs/superpowers main.gd otherpair.gd tests
git commit -m "fix repeated leash tangle events"
```

Otherwise, leave the worktree uncommitted.
