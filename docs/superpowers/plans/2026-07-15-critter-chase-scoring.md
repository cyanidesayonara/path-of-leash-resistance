# Critter Chase Scoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore one-time squirrel, rat, and Tofu contact rewards so the rotating chase quest is achievable during normal play.

**Architecture:** Keep movement and scoring responsibilities unchanged: `squirrel.gd` detects first contact and calls the existing `main.on_critter_chase` callback, while `main.gd` owns counters, bones, and feedback. Add one isolated `SceneTree` regression script following `tests/test_wrap.gd`, then run it directly in CI.

**Tech Stack:** Godot 4.7, GDScript, built-in `SceneTree` test scripts, GitHub Actions.

## Global Constraints

- Keep Godot 4.7 and GDScript; add no dependencies.
- Keep GL Compatibility and web export behavior unchanged.
- Preserve the existing alert, flee, temptation, and Tofu relocation tuning.
- Do not add separate critter bookkeeping outside `squirrel.gd`.
- Do not use emoji.
- Update `CHANGELOG.md` at the end of the session.
- Do not create a git commit unless the user explicitly requests one.

## File map

- Create `tests/test_critter_chase.gd`: isolated first-contact regression coverage.
- Modify `squirrel.gd:72-75`: allow first contact to score in every movement state.
- Modify `.github/workflows/ci.yml:23-26`: run the new regression before smoke tests.
- Modify `CHANGELOG.md:3-5`: record the restored reward and test.

---

### Task 1: Restore first-contact scoring with a regression test

**Files:**
- Create: `tests/test_critter_chase.gd`
- Modify: `squirrel.gd:72-75`

**Interfaces:**
- Consumes: `squirrel.gd.setup(m: Node2D, d: Node2D, k: String)`, `main.on_critter_chase(pos: Vector2, kind: String)`, and `main.nearest_cover(from: Vector2, threat: Vector2) -> Vector2`.
- Produces: unchanged critter interface; each critter invokes `on_critter_chase` at most once when dog distance is below `26.0`.

- [ ] **Step 1: Write the failing regression test**

Create `tests/test_critter_chase.gd`:

```gdscript
extends SceneTree

const CONTACT_POS := Vector2(20, 0)

var failures := 0


class FakeMain:
	extends Node2D

	var frozen := false
	var riders_cache: Array = []
	var cam := Node2D.new()
	var chase_count := 0
	var last_kind := ""

	func on_critter_chase(_pos: Vector2, kind: String) -> void:
		chase_count += 1
		last_kind = kind

	func nearest_cover(_from: Vector2, _threat: Vector2) -> Vector2:
		return Vector2(140, 80)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _make_critter(main: Node2D, dog: Node2D, kind: String) -> Node2D:
	var critter := Node2D.new()
	critter.set_script(load("res://squirrel.gd"))
	root.add_child(critter)
	critter.setup(main, dog, kind)
	return critter


func _initialize() -> void:
	var main := FakeMain.new()
	var dog := Node2D.new()
	root.add_child(main)
	root.add_child(dog)
	dog.global_position = Vector2.ZERO

	var squirrel := _make_critter(main, dog, "squirrel")
	squirrel.global_position = CONTACT_POS
	squirrel.state = 2
	squirrel._physics_process(0.0)
	_check(main.chase_count == 1, "a fleeing squirrel scores on contact")
	_check(main.last_kind == "squirrel", "squirrel contact reports its kind")

	squirrel._physics_process(0.0)
	_check(main.chase_count == 1, "the same squirrel cannot score twice")

	var tofu := _make_critter(main, dog, "cat")
	tofu.global_position = CONTACT_POS
	tofu.state = 1
	tofu._physics_process(0.0)
	_check(main.chase_count == 2, "Tofu scores one boop on contact")
	_check(tofu.hide_target == Vector2(140, 80), "Tofu keeps relocating after the boop")

	var rat := _make_critter(main, dog, "rat")
	rat.global_position = Vector2(100, 0)
	rat.scare()
	rat._physics_process(0.0)
	_check(main.chase_count == 2, "a scare outside contact range does not score")

	if failures > 0:
		print("test_critter_chase: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_critter_chase: OK")
		quit(0)
```

- [ ] **Step 2: Run the test and confirm the existing bug**

Run:

```powershell
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_critter_chase.gd
```

Expected: exit code `1`, including:

```text
FAIL: a fleeing squirrel scores on contact
FAIL: Tofu scores one boop on contact
test_critter_chase: 5 FAILURES
```

- [ ] **Step 3: Implement the minimal state-independent contact latch**

In `squirrel.gd`, replace:

```gdscript
	if not chased and state != 2 and dd < 26.0:
		chased = true
		main.on_critter_chase(global_position, kind)
		scare()
```

with:

```gdscript
	if not chased and dd < 26.0:
		chased = true
		main.on_critter_chase(global_position, kind)
		scare()
```

- [ ] **Step 4: Run focused and rope regression tests**

Run:

```powershell
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_critter_chase.gd
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_wrap.gd
```

Expected: both commands exit `0` and print:

```text
test_critter_chase: OK
test_wrap: OK
```

- [ ] **Step 5: Review the focused diff**

Confirm the production diff in `squirrel.gd` removes only the flee-state exclusion. Confirm no tuning constants, movement branches, callbacks, or reward values changed.

- [ ] **Step 6: Commit only if explicitly requested**

If the user explicitly requests a commit:

```powershell
git add tests/test_critter_chase.gd squirrel.gd
git commit -m "fix critter chase contact scoring"
```

Otherwise, leave the changes uncommitted.

---

### Task 2: Add the regression to CI and document the fix

**Files:**
- Modify: `.github/workflows/ci.yml:23-26`
- Modify: `CHANGELOG.md:3-5`

**Interfaces:**
- Consumes: `tests/test_critter_chase.gd`, which exits nonzero on any assertion failure.
- Produces: a dedicated CI gate named `Critter chase regression test`; a newest-first changelog entry.

- [ ] **Step 1: Add the direct CI test step**

Insert after the leash regression step in `.github/workflows/ci.yml`:

```yaml
      - name: Critter chase regression test
        run: ./Godot_v4.7-stable_linux.x86_64 --headless --path . --script res://tests/test_critter_chase.gd
```

- [ ] **Step 2: Add the newest changelog entry**

Insert after the changelog introduction:

```markdown
## 2026-07-15 — critter chase scoring restored

- Squirrels, rats and Tofu now award their chase or boop reward on first
  contact even after they start fleeing; the same critter cannot score twice.
- Added a headless regression test for fleeing contact, Tofu relocation and
  scare-without-contact behavior.
```

- [ ] **Step 3: Run all four level smoke tests**

Run:

```powershell
$levels = "street", "park", "beach", "market"
foreach ($level in $levels) {
  $output = & godot\Godot_v4.7-stable_win64_console.exe --headless --path . --quit-after 1800 -- --level=$level 2>&1
  $exitCode = $LASTEXITCODE
  $output
  if ($exitCode -ne 0 -or $output -match "SCRIPT ERROR|Parse Error|Failed to load script") {
    throw "Smoke test failed: $level"
  }
}
```

Expected: every command exits `0` with no `SCRIPT ERROR`, `Parse Error`, or `Failed to load script`.

- [ ] **Step 4: Perform the manual feel check**

Run:

```powershell
godot\Godot_v4.7-stable_win64.exe --path .
```

Verify:

1. Catching one fleeing squirrel or rat displays exactly one `almost got it! +2`.
2. Remaining near that same critter does not add another reward.
3. Reaching Tofu displays exactly one `boop! +4`.
4. Tofu continues to a new cover location after the boop.
5. Barking at a critter from outside 26 pixels does not award bones.

- [ ] **Step 5: Review the complete diff**

Confirm the complete change contains only:

- the new regression script;
- the one-condition production fix;
- the dedicated CI step;
- the newest changelog entry;
- the approved design and plan documents.

- [ ] **Step 6: Commit only if explicitly requested**

If the user explicitly requests a commit after reviewing the complete diff:

```powershell
git add .github/workflows/ci.yml CHANGELOG.md docs/superpowers tests/test_critter_chase.gd squirrel.gd
git commit -m "test critter scoring in CI"
```

Otherwise, leave the worktree uncommitted.
