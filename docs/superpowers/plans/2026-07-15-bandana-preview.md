# Bandana Visibility and Wardrobe Preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make bandanas visibly trail over Millie's back and show highlighted cosmetics on a live dog preview in the wardrobe.

**Architecture:** `dog.gd` remains the single renderer and gains a collision-free preview mode, cosmetic overrides, and testable bandana geometry. `main.gd` hosts that renderer in a two-column wardrobe and updates its overrides from the highlighted item without mutating equip state.

**Tech Stack:** Godot 4.7, GDScript, procedural `_draw()` art, built-in `SceneTree` tests, GitHub Actions.

## Global Constraints

- Keep Godot 4.7 and GDScript; add no dependencies or external assets.
- Preserve cosmetic prices, ownership, purchasing, equipping, persistence, and save format.
- Preserve all gameplay dog movement, collision, input, art, and animation except the approved bandana geometry.
- Preview unowned highlighted items without equipping or purchasing them.
- Keep `No bandana` free, owned, and able to clear the preview/equipped neckerchief.
- Do not redesign title screens outside the wardrobe body.
- Do not use emoji.
- Update `CHANGELOG.md` and `HANDOVER.md` at the end of the session.
- Do not create a git commit unless the user explicitly requests one.
- This is a mixed uncommitted checkout; do not stage whole shared files or directories as a bandana-only commit.

## File map

- Create `tests/test_bandana_preview.gd`: real-renderer preview and geometry regression.
- Modify `dog.gd:34-52,154-217`: preview mode, resolved cosmetic keys, trailing outlined triangle.
- Modify `main.gd:169-174,710-723,800-847,963-977`: live preview panel, visibility, highlighted-item updates.
- Modify `.github/workflows/ci.yml:35-38`: direct bandana preview regression.
- Modify `CHANGELOG.md:5`: newest-first bandana preview entry.
- Modify `HANDOVER.md:138-147`: remove the resolved bandana bug while preserving open NPC-environment issues.

---

### Task 1: Add preview-safe dog cosmetics and trailing bandana geometry

**Files:**
- Create: `tests/test_bandana_preview.gd`
- Modify: `dog.gd:34-52,154-217`

**Interfaces:**
- Produces: `set_cosmetic_preview(collar_key: String, bandana_key: String) -> void`.
- Produces: `_cosmetic_collar_key() -> String`.
- Produces: `_cosmetic_bandana_key() -> String`.
- Produces: `_bandana_points(shoulder: Vector2, forward: Vector2) -> PackedVector2Array`.
- `preview_mode: bool` must be set before the node enters the scene tree.

- [ ] **Step 1: Write the failing real-renderer regression**

Create `tests/test_bandana_preview.gd`:

```gdscript
extends SceneTree

var failures := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _finish() -> void:
	if failures > 0:
		print("test_bandana_preview: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_bandana_preview: OK")
		quit(0)


func _initialize() -> void:
	var dog := CharacterBody2D.new()
	dog.set_script(load("res://dog.gd"))
	var required := [
		"set_cosmetic_preview",
		"_cosmetic_collar_key",
		"_cosmetic_bandana_key",
		"_bandana_points",
	]
	for method: String in required:
		if not dog.has_method(method):
			_check(false, "dog exposes " + method)
	if failures > 0:
		dog.free()
		_finish()
		return

	dog.preview_mode = true
	dog.set_cosmetic_preview("blue", "navy")
	seed(424242)
	var expected_next_random := randf()
	seed(424242)
	root.add_child(dog)
	var actual_next_random := randf()
	_check(dog.get_child_count() == 0, "preview mode creates no collision child")
	_check(is_equal_approx(actual_next_random, expected_next_random), "preview creation preserves global RNG")
	_check(dog._cosmetic_collar_key() == "blue", "preview collar override resolves")
	_check(dog._cosmetic_bandana_key() == "navy", "preview bandana override resolves")

	dog.set_cosmetic_preview("red", "none")
	_check(dog._cosmetic_bandana_key() == "none", "none clears preview bandana")

	var forward := Vector2.UP
	var points: PackedVector2Array = dog._bandana_points(Vector2.ZERO, forward)
	_check(points.size() == 3, "bandana is a triangle")
	if points.size() == 3:
		var base_mid := (points[0] + points[1]) * 0.5
		var base_width := points[0].distance_to(points[1])
		var twice_area := absf((points[1] - points[0]).cross(points[2] - points[0]))
		_check(base_width >= 14.0, "bandana has a broad neck base")
		_check(twice_area > 1.0, "bandana triangle has area")
		_check((points[2] - base_mid).dot(forward) < 0.0, "bandana point trails behind")

	dog.free()
	_finish()
```

- [ ] **Step 2: Run the test and confirm preview methods are missing**

Run:

```powershell
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_bandana_preview.gd
```

Expected: exit `1` with four missing-method failures and
`test_bandana_preview: 4 FAILURES`.

- [ ] **Step 3: Add preview state and cosmetic resolution**

After `var main: Node2D` in `dog.gd`, add:

```gdscript
var preview_mode := false
var preview_collar := ""
var preview_bandana := ""
```

Before `_ready`, add:

```gdscript
func set_cosmetic_preview(collar_key: String, bandana_key: String) -> void:
	preview_collar = collar_key
	preview_bandana = bandana_key
	queue_redraw()


func _cosmetic_collar_key() -> String:
	if preview_mode and Game.COLLARS.has(preview_collar):
		return preview_collar
	return Game.collar if Game.COLLARS.has(Game.collar) else "red"


func _cosmetic_bandana_key() -> String:
	if preview_mode and Game.BANDANAS.has(preview_bandana):
		return preview_bandana
	return Game.bandana if Game.BANDANAS.has(Game.bandana) else "none"


func _bandana_points(shoulder: Vector2, forward: Vector2) -> PackedVector2Array:
	var side := forward.orthogonal()
	var base := shoulder - forward
	return PackedVector2Array([
		base + side * 7.0,
		base - side * 7.0,
		shoulder - forward * 15.0,
	])
```

- [ ] **Step 4: Skip gameplay collision and isolate preview fleck RNG**

Replace the collision setup at the start of `_ready`:

```gdscript
	collision_layer = 2
	collision_mask = 1
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 14.0
	cs.shape = sh
	add_child(cs)
```

with:

```gdscript
	if not preview_mode:
		collision_layer = 2
		collision_mask = 1
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = 14.0
		cs.shape = sh
		add_child(cs)
		for i in range(14):
			flecks.append(Vector2.from_angle(randf() * TAU) * randf_range(2.0, 9.5))
	else:
		var preview_rng := RandomNumberGenerator.new()
		preview_rng.seed = 1729
		for i in range(14):
			flecks.append(Vector2.from_angle(preview_rng.randf() * TAU) * preview_rng.randf_range(2.0, 9.5))
```

Remove the old unconditional fleck loop. Keep gameplay fleck generation
byte-for-byte equivalent and use only the local deterministic generator for
preview flecks.

- [ ] **Step 5: Draw resolved cosmetics and the trailing outlined triangle**

Replace the current cosmetic block in `_draw`:

```gdscript
	var col := Game.collar_color()
	if Game.collar == "rainbow":
		col = Color.from_hsv(fmod(t * 0.35, 1.0), 0.7, 0.9)
	# a bandana, if equipped: a little triangle at the throat
	if Game.bandana != "none":
		var bcol: Color = Game.BANDANAS[Game.bandana].col
		var nb := shoulder + facing * 7.0
		draw_colored_polygon(PackedVector2Array([nb + side * 6.0, nb - side * 6.0, nb + facing * 8.0]), bcol)
```

with:

```gdscript
	var collar_key := _cosmetic_collar_key()
	var col: Color = Game.COLLARS[collar_key].col
	if collar_key == "rainbow":
		col = Color.from_hsv(fmod(t * 0.35, 1.0), 0.7, 0.9)
	var bandana_key := _cosmetic_bandana_key()
	if bandana_key != "none":
		var bcol: Color = Game.BANDANAS[bandana_key].col
		var bandana := _bandana_points(shoulder, facing)
		var edge := bcol.darkened(0.35)
		draw_colored_polygon(bandana, bcol)
		draw_line(bandana[0], bandana[1], edge, 1.5)
		draw_line(bandana[1], bandana[2], edge, 1.5)
		draw_line(bandana[2], bandana[0], edge, 1.5)
```

Keep the collar, neck, head, and remaining art drawing immediately afterward.

- [ ] **Step 6: Run focused and existing regressions**

Run:

```powershell
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_bandana_preview.gd
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_pair_direction.gd
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_freedom_traffic.gd
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_tangle_latch.gd
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_critter_chase.gd
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_wrap.gd
```

Expected: all commands exit `0` and print their respective `OK` markers.

- [ ] **Step 7: Review Task 1 scope**

Confirm the gameplay dog still creates one collision shape, reads equipped
Game cosmetics, and draws all non-bandana art unchanged. Confirm preview mode
has no gameplay dependency, consumes no global RNG, and invalid saved keys
fall back to red/none.

---

### Task 2: Add the live highlighted-item wardrobe preview

**Files:**
- Modify: `main.gd:169-174,710-723,800-847,963-977`

**Interfaces:**
- Consumes: `dog.gd/set_cosmetic_preview(collar_key, bandana_key)`.
- Produces: `shop_preview_bg: ColorRect`, `shop_preview_l: Label`, and `shop_preview: CharacterBody2D`.

- [ ] **Step 1: Add wardrobe preview fields**

After the existing shop fields in `main.gd`, add:

```gdscript
var shop_preview_bg: ColorRect
var shop_preview_l: Label
var shop_preview: CharacterBody2D
```

- [ ] **Step 2: Build the preview panel before the shop labels**

Immediately before `shop_title_l = _hud_label(...)` in `_build_hud`, add:

```gdscript
	shop_preview_bg = ColorRect.new()
	shop_preview_bg.position = Vector2(60.0, 190.0)
	shop_preview_bg.size = Vector2(440.0, 390.0)
	shop_preview_bg.color = Color(0.05, 0.06, 0.07, 0.72)
	shop_preview_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_preview_bg.visible = false
	hud.add_child(shop_preview_bg)
	var preview := CharacterBody2D.new()
	preview.set_script(load("res://dog.gd"))
	preview.preview_mode = true
	preview.position = Vector2(280.0, 365.0)
	preview.scale = Vector2(3.0, 3.0)
	preview.visible = false
	hud.add_child(preview)
	preview.z_index = 1
	shop_preview = preview
```

After the shop title setup and before `shop_l`, add:

```gdscript
	shop_preview_l = _hud_label(Vector2(60.0, 145.0), 18)
	shop_preview_l.size = Vector2(440.0, 30.0)
	shop_preview_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_preview_l.text = "HIGHLIGHTED LOOK"
	shop_preview_l.visible = false
```

Change the item-list geometry from:

```gdscript
	shop_l = _hud_label(Vector2(0, 150), 20)
	shop_l.size = Vector2(1280, 460)
```

to:

```gdscript
	shop_l = _hud_label(Vector2(430.0, 150.0), 20)
	shop_l.size = Vector2(800.0, 460.0)
```

- [ ] **Step 3: Show the preview with the wardrobe**

At the end of `_open_shop`, before `_refresh_shop()`, add:

```gdscript
	shop_preview_bg.visible = true
	shop_preview_l.visible = true
	shop_preview.visible = true
```

- [ ] **Step 4: Update preview overrides from the highlighted item**

At the end of `_refresh_shop`, after assigning `shop_l.text`, add:

```gdscript
	var highlighted: Dictionary = shop_items[shop_idx]
	var preview_collar: String = Game.collar
	var preview_bandana: String = Game.bandana
	if highlighted.kind == "collar":
		preview_collar = highlighted.key
	else:
		preview_bandana = highlighted.key
	shop_preview.set_cosmetic_preview(preview_collar, preview_bandana)
```

This must not mutate `Game.collar`, `Game.bandana`, ownership, or bones.

- [ ] **Step 5: Hide all preview elements when leaving**

In the shop `bark` close branch, add:

```gdscript
			shop_preview_bg.visible = false
			shop_preview_l.visible = false
			shop_preview.visible = false
```

before `_apply_menu_step()`.

- [ ] **Step 6: Run all-level smoke and full autowalk**

Run:

```powershell
foreach ($lv in "street","park","beach","market") {
  Write-Host "=== $lv ==="
  godot\Godot_v4.7-stable_win64_console.exe --headless --path . --quit-after 1800 -- --level=$lv
  if ($LASTEXITCODE -ne 0) { throw "Smoke test failed: $lv" }
}

godot\Godot_v4.7-stable_win64_console.exe --headless --fixed-fps 60 --path . --quit-after 12000 -- --level=street --autowalk
```

Expected: clean exits for every level and output containing
`AUTOWALK FINISHED`.

- [ ] **Step 7: Review Task 2 scope**

Confirm the preview is the real `dog.gd`, stays static, updates while browsing,
previews unowned items, and cannot buy/equip without the existing confirm
action. Confirm all non-wardrobe menu geometry is unchanged.

---

### Task 3: Add CI coverage and document the resolved bug

**Files:**
- Modify: `.github/workflows/ci.yml:35-38`
- Modify: `CHANGELOG.md:5`
- Modify: `HANDOVER.md:138-147`

**Interfaces:**
- Consumes: `tests/test_bandana_preview.gd`, which exits nonzero on failure.
- Produces: direct CI gate `Bandana preview regression test`; current changelog and handover.

- [ ] **Step 1: Add the direct CI test**

Insert immediately after `NPC pair direction regression test`:

```yaml
      - name: Bandana preview regression test
        run: ./Godot_v4.7-stable_linux.x86_64 --headless --path . --script res://tests/test_bandana_preview.gd
```

- [ ] **Step 2: Add the newest changelog entry**

Insert before the mixed NPC walker entry:

```markdown
## 2026-07-15 — visible bandanas and wardrobe preview

- Bandanas now read as outlined neckerchiefs trailing over Millie's back
  instead of disappearing beneath her head and collar.
- The wardrobe now previews every highlighted collar and bandana on the real
  dog renderer before purchase or equip.
- Added a real-renderer regression for preview overrides, `No bandana`, and
  backward-pointing geometry.
```

- [ ] **Step 3: Update HANDOVER open bugs**

Remove the resolved bandana bug from the open-bug list. Keep the NPC
environment, tangle-feel, and capitalization items open and renumber them.
Add one concise nearby sentence that bandana geometry and the highlighted-item
wardrobe preview are fixed.

- [ ] **Step 4: Perform manual acceptance**

Run:

```powershell
godot\Godot_v4.7-stable_win64.exe --path .
```

Follow every manual acceptance step in the approved design. Pay particular
attention to navy against black fur, `No bandana`, unowned-item browsing,
rainbow animation, list readability, and persistence across a walk.

- [ ] **Step 5: Review the complete diff**

Confirm the complete change contains only the preview-safe renderer changes,
trailing bandana, wardrobe preview, focused regression, CI step, changelog,
handover, and approved docs.

- [ ] **Step 6: Leave the mixed checkout uncommitted**

Do not stage whole files or directories for a bandana-only commit. If the user
requests a commit, inspect the accumulated checkout and ask whether to commit
all stabilization work together or isolate after preceding work is committed.
