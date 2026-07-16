# Owner-Label Casing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep the owner label canonically formatted after every owner toggle.

**Architecture:** A pure formatter in `main.gd` becomes the single presentation path for both menu entry and toggle refresh. A real-script regression protects exact casing and spacing.

**Tech Stack:** Godot 4.7, GDScript, `SceneTree` test, GitHub Actions.

## Global Constraints

- Preserve owner state, choices, input, menu layout, save data, and gameplay.
- Do not add dependencies or external assets.
- Do not use emoji.
- Update `CHANGELOG.md` and `HANDOVER.md`.
- Do not commit unless explicitly requested.

### Task 1: Canonical owner label

**Files:**
- Create: `tests/test_owner_label.gd`
- Modify: `main.gd:780-821,1027-1029`
- Modify: `.github/workflows/ci.yml:38-41`
- Modify: `CHANGELOG.md:5`
- Modify: `HANDOVER.md:145-150`

**Interfaces:**
- Produces: `_owner_label_text(owner_id: String) -> String`.

- [ ] **Step 1: Write the failing regression**

Create `tests/test_owner_label.gd`:

```gdscript
extends SceneTree

var failures := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _initialize() -> void:
	var main := Node2D.new()
	main.set_script(load("res://main.gd"))
	if not main.has_method("_owner_label_text"):
		_check(false, "main exposes owner label formatter")
	else:
		_check(main._owner_label_text("him") == "WALKING:  HIM", "formats him")
		_check(main._owner_label_text("her") == "WALKING:  HER", "formats her")
		_check(main._owner_label_text("HeR") == "WALKING:  HER", "normalizes casing")
	main.free()
	if failures > 0:
		print("test_owner_label: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_owner_label: OK")
		quit(0)
```

- [ ] **Step 2: Confirm RED**

Run:

```powershell
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_owner_label.gd
```

Expected: exit `1` with `FAIL: main exposes owner label formatter`.

- [ ] **Step 3: Add and use the formatter**

Insert before `_apply_menu_step()`:

```gdscript
func _owner_label_text(owner_id: String) -> String:
	return "WALKING:  %s" % owner_id.to_upper()
```

Replace both owner-label assignments with:

```gdscript
owner_l.text = _owner_label_text(Game.owner_id)
```

- [ ] **Step 4: Add CI coverage**

Insert immediately after the bandana preview regression:

```yaml
      - name: Owner label regression test
        run: ./Godot_v4.7-stable_linux.x86_64 --headless --path . --script res://tests/test_owner_label.gd
```

- [ ] **Step 5: Update documentation**

Add before the current newest changelog entry:

```markdown
## 2026-07-16 — consistent owner label

- The walk-details owner label now remains `WALKING:  HIM/HER` after toggling.
- Added a real-script regression for canonical casing and spacing.
```

Remove the resolved capitalization item from `HANDOVER.md`. Preserve the NPC
environment and tangle-feel items, renumbered 1–2.

- [ ] **Step 6: Run regressions**

Run the new owner test, bandana, pair direction, freedom traffic, tangle,
critter, and wrap regressions. Expected: every command exits `0` with its
respective `OK` marker.

- [ ] **Step 7: Run smoke and autowalk**

Run all four level smoke tests and the fixed-FPS street autowalk. Expected:
clean exits and `AUTOWALK FINISHED`.

- [ ] **Step 8: Manual check**

On walk-details step 2, toggle HIM/HER repeatedly and confirm the label remains
uppercase with identical spacing.

- [ ] **Step 9: Leave the mixed checkout uncommitted**

Do not stage whole files or directories. If the user requests a commit, first
inspect accumulated work and ask whether to commit all stabilization together.
