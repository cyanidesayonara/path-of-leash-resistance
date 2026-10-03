# Menu shell and tutorial reach (Pass 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The tutorial's nose lesson can be finished by eating the snack, every held lesson's target is inside leash reach, and the pause menu becomes a two-axis grid with THIS WALK, confirmations, and a desktop-only EXIT GAME (also on the title).

**Architecture:** Tutorial steps gain an optional `stand` side; main turns it into a standing x for the held human, and pins the reel at full length while a lesson holds. The menu stays a model/draw split: `hud/menu_flow.gd` gains the grid, a confirm state, a walk card and an exit hook; `hud/menu_screen.gd` draws the three new layouts in the `ui_kit` look.

**Tech Stack:** Godot 4.7 GDScript, headless SceneTree tests, the shot sweep.

**Spec:** `docs/superpowers/specs/2026-10-03-menu-terrain-design.md`, Pass 1.

## Global constraints

- Branch from `origin/main` as `menu-shell-tutorial-reach`. Never push to main; one PR.
- Before starting, count player-facing items in "Awaiting acceptance" on https://github.com/users/cyanidesayonara/projects/4. Must be below 5 (it was 2 when this plan was written: #127, #128).
- Commits authored only by Santtu Nykänen, no `Co-authored-by` trailers, no AI acknowledgements, no emoji. The environment injects a trailer the commit-msg hook rejects, so commit with:

```powershell
git add -A
$treeHash = git write-tree
$parent = git rev-parse HEAD
$env:GIT_AUTHOR_NAME="Santtu Nykänen"; $env:GIT_COMMITTER_NAME="Santtu Nykänen"
$env:GIT_AUTHOR_EMAIL=(git config user.email); $env:GIT_COMMITTER_EMAIL=(git config user.email)
$c = "SUBJECT" | git -c core.hooksPath=NUL commit-tree $treeHash -p $parent
git update-ref HEAD $c
```

- No key name in any UI string; prompt bars only through `Flow.prompts`. Voice: menu headings in capitals, body in plain sentences, British spelling, "leash".
- Never read `Time.get_ticks_msec()` in a `_draw`; use `AnimClock.msec()`.
- `tools/behaviour_snapshot.sh` output must stay byte-identical (the tutorial is not in it; the reel change only acts while a tutorial lesson holds).
- `G` below means `godot\Godot_v4.7-stable_win64_console.exe`. If the worktree has no `godot\` folder, use the main checkout's copy by absolute path.

## File map

| File | Change |
|---|---|
| `systems/tutorial.gd` | `"stand"` on nose (-1) and teeter (1) |
| `main.gd` | `TUT_STAND_IN`, `tut_hold_point()`, hold x and reel pin in `_tick_tutorial`, `confirm_id`, `pause_view`, `--no-exit`, shot menus |
| `entities/human.gd` | `tut_hold_x`, walk to it while held, no reel fiddling while a lesson holds |
| `world/level_build.gd` | nose snack moved next to the west standing spot |
| `hud/menu_flow.gd` | grid ids and moves, confirm, exit hook, walk card, prompts |
| `hud/menu_screen.gd` | grid, walk card and confirm drawing |
| `tests/test_tutorial_stations.gd` | reach invariant, snack on grass, live eat |
| `tests/test_menu_flow.gd` | grid, web omission, confirmations, exit hook, walk card, prompt actions |
| `tools/shot_sweep.sh` | `walkcard` and `confirm` shots |
| `AGENTS.md`, `README.md`, `CHANGELOG.md`, `HANDOVER.md` | current claims |

---

### Task 1: Failing tutorial reach tests

**Files:** Modify `tests/test_tutorial_stations.gd`

- [ ] **Step 1: Add the static reach invariant after the existing "none of El Barri's furniture" check**

```gdscript
	# every held lesson's target is inside leash reach from where the owner
	# waits: a full leash, short of the stretch cap, from the worst spot the
	# owner can stand (their own spot if the lesson gives one, otherwise
	# either end of their weave across the path)
	var Surfaces: GDScript = load("res://world/surfaces.gd")
	var reach: float = float(m.LEASH_LENGTH) - 20.0
	var targets := {
		"pee": [(m.hydrants[0].pos as Vector2)],
		"sniff": [(m.hydrants[1].pos as Vector2)],
		"nose": [(m.kebabs[0].pos as Vector2)],
		"vault": [(m.poles[0] as Vector2)],
		"fling": [(m.poles[1] as Vector2)],
	}
	for id: String in targets.keys():
		var i: int = TUT.index_of(id)
		var hp: Vector2 = m.tut_hold_point(i)
		var spots: Array[Vector2] = []
		if hp.x < INF:
			spots.append(hp)
		else:
			var e: Vector2 = m.walk_edges(hp.y)
			var cx := (e.x + e.y) * 0.5
			var sway := minf(110.0, (e.y - e.x) * 0.5 - 60.0)
			spots.append(Vector2(cx - sway, hp.y))
			spots.append(Vector2(cx + sway, hp.y))
		for s: Vector2 in spots:
			var far := 0.0
			for t: Vector2 in targets[id]:
				far = maxf(far, s.distance_to(t))
			_check(far <= reach, "the %s lesson's target is in reach from (%.0f, %.0f): %.0f > %.0f" % [id, s.x, s.y, far, reach] if far > reach else "the %s lesson's target is in reach" % id)
	# the pond's near edge, from the brink lesson's spot
	var tp: Vector2 = m.tut_hold_point(TUT.index_of("teeter"))
	var near_pond := Vector2(clampf(tp.x, pond.position.x, pond.end.x), clampf(tp.y, pond.position.y, pond.end.y))
	_check(tp.x < INF and tp.distance_to(near_pond) <= reach,
		"the brink lesson's owner waits within reach of the pond (%.0f)" % tp.distance_to(near_pond))
	# the snack is on grass, not pavement
	var kp0: Vector2 = m.kebabs[0].pos
	_check(m.surface_at(kp0) == Surfaces.S.GRASS, "the nose lesson's snack lies on grass")
```

- [ ] **Step 2: Add the live eat check, just before the "nothing turns up" block**

```gdscript
	# the nose lesson can be finished, not only skipped: from where the owner
	# waits, the dog walks to the snack and eats it
	m.started = true
	m.frozen = false
	m.tut_step = TUT.index_of("nose")
	m._tick_tutorial(0.0)
	var stand: Vector2 = m.tut_hold_point(m.tut_step)
	human.global_position = stand
	human.velocity = Vector2.ZERO
	m.leash_len = float(m.LEASH_LENGTH)
	m.dog.global_position = stand + Vector2(0.0, -40.0)
	m.dog.velocity = Vector2.ZERO
	m.leash.resnap()
	var snack: Vector2 = m.kebabs[0].pos
	var ate_before: int = m.kebabs_eaten
	m.dog.auto = true
	for f in range(900):
		m.dog.auto_move = (snack - m.dog.global_position).normalized()
		await physics_frame
		if m.kebabs_eaten > ate_before:
			break
	m.dog.auto = false
	m.dog.auto_move = Vector2.ZERO
	_check(m.kebabs_eaten > ate_before,
		"the dog reaches and eats the snack (stopped at %.0f from it)" % m.dog.global_position.distance_to(snack))
```

`leash_len` is main's live length (the one `_tut_step_done("pull")` reads). If the name differs, use the variable `_tut_step_done` uses.

- [ ] **Step 3: Run it and confirm it fails**

Run: `G --headless --path . --script res://tests/test_tutorial_stations.gd`
Expected: a script error on `tut_hold_point` (it does not exist yet). That is the failing state.

---

### Task 2: Standing spots, a pinned reel, and the snack within reach

**Files:** Modify `systems/tutorial.gd`, `main.gd`, `entities/human.gd`, `world/level_build.gd`

- [ ] **Step 1: Give two lessons a standing side in `systems/tutorial.gd`**

Add `"stand": -1,` to the nose step and `"stand": 1,` to the teeter step, after `"hold": true,`. Extend the header comment's last paragraph with:

```gdscript
# "stand" (-1 west, 1 east) puts the waiting owner by that edge of the path,
# for a lesson whose target is off to one side.
```

- [ ] **Step 2: In `main.gd`, next to `const TUT_HOLD_BACK := 150.0`, add**

```gdscript
# how far in from the path's edge a lesson's "stand" puts the waiting owner
const TUT_STAND_IN := 60.0
```

- [ ] **Step 3: Add `tut_hold_point` above `_tick_tutorial` in `main.gd`**

```gdscript
# Where the owner waits for lesson i: y short of the station, and x by the
# path's edge when the lesson gives a "stand" (INF when it does not, so the
# owner keeps their own place in the weave).
func tut_hold_point(i: int) -> Vector2:
	var st: Dictionary = TutorialSteps.step(i)
	if not bool(st.get("hold", false)):
		return Vector2(INF, -INF)
	var y := float(st["at"]) + TUT_HOLD_BACK
	var side := int(st.get("stand", 0))
	if side == 0:
		return Vector2(INF, y)
	var e := walk_edges(y)
	return Vector2((e.x + TUT_STAND_IN) if side < 0 else (e.y - TUT_STAND_IN), y)
```

- [ ] **Step 4: In `_tick_tutorial`, replace the `human.tut_hold_y = ...` line with**

```gdscript
	var hp := tut_hold_point(tut_step)
	human.tut_hold_y = hp.y
	human.tut_hold_x = hp.x
	# a waiting owner leaves the reel alone at full length: a lesson's target
	# is laid out for the whole leash, and a click to 170 would put it out of reach
	if bool(st.get("hold", false)) and leash_target < LEASH_LENGTH:
		set_leash_target(LEASH_LENGTH)
```

- [ ] **Step 5: In `entities/human.gd`, under `var tut_hold_y := -INF`, add**

```gdscript
var tut_hold_x := INF
```

and near the other tuning constants:

```gdscript
# how far short of a lesson's stop the owner starts drifting to its standing x
const TUT_STAND_LEAD := 420.0
```

- [ ] **Step 6: Replace the hold branch at the top of `_walk`**

```gdscript
	# the tutorial's owner waits at a lesson (main.TUT_HOLD_BACK): stood still
	# on the phone until it is done, shuffling over to the lesson's spot first
	if global_position.y <= tut_hold_y and not homeward:
		var want := Vector2.ZERO
		if tut_hold_x < INF and absf(global_position.x - tut_hold_x) > 6.0:
			want = Vector2(signf(tut_hold_x - global_position.x) * WALK_SPEED * 0.6, 0.0)
		velocity = velocity.move_toward(want, 400.0 * delta)
		move_and_slide()
		return
```

- [ ] **Step 7: Steer toward the spot on the approach**

Directly after `var tx := cx + sin(t * 0.35 + wobble_seed) * minf(110.0, half - 60.0)` add:

```gdscript
	if tut_hold_x < INF and global_position.y < tut_hold_y + TUT_STAND_LEAD:
		tx = tut_hold_x
```

- [ ] **Step 8: Stop reel fiddling while a lesson holds**

In `_fiddle_with_reel`, after the `reel_pending_t` block and before the state check, add:

```gdscript
	if tut_hold_y > -INF:
		reel_pending_t = 0.0
		return
```

- [ ] **Step 9: Move the snack in `world/level_build.gd`**

Replace the nose kebab line with:

```gdscript
		# on the grass beside where the owner waits (the lesson stands west),
		# well inside a full leash but off the path, so the nose still finds it
		var ne: Vector2 = m.walk_edges(TUT.at("nose"))
		m.kebabs.append({"pos": Vector2(ne.x - 70.0, TUT.at("nose") - 20.0), "eaten": false, "off_path": true})
```

- [ ] **Step 10: Run the tutorial test**

Run: `G --headless --path . --script res://tests/test_tutorial_stations.gd`
Expected: `test_tutorial_stations: OK`.

If only the live eat check fails and the dog stopped near the path's west edge with the leash slack, something solid sits on the verge. Do not move the snack back onto pavement and do not delete the collision blindly: use superpowers:systematic-debugging to find which collider stops the dog there (print `dog.get_last_slide_collision()` collider names), and remove it only if it is not an authored solid. Record what it was in the PR.

- [ ] **Step 11: Regression runs**

```
G --headless --path . --script res://tests/test_reel.gd
G --headless --path . --script res://tests/test_tutorial_isolation.gd
G --headless --path . --quit-after 1200 -- --tutorial
bash tools/behaviour_snapshot.sh > ../snap-after.txt
```

Compare the snapshot against one taken on `origin/main` before Task 2 (`git stash`, run, `git stash pop`). Expected: identical. Smoke log contains no `SCRIPT ERROR`.

- [ ] **Step 12: Commit** with subject `Keep every tutorial target inside leash reach`.

---

### Task 3: Pause grid model

**Files:** Modify `hud/menu_flow.gd`, `tests/test_menu_flow.gd`

- [ ] **Step 1: Write failing tests**

In `tests/test_menu_flow.gd`, replace the line `_check(Flow.pause_rows(main).size() == Flow.PAUSE_ROWS.size(), "one pause row per action")` with:

```gdscript
	Flow.exit_hidden = false
	var ids: Array = Flow.pause_ids(main)
	_check(ids == ["resume", "walk", "restart", "settings", "select", "exit"] or OS.has_feature("web"),
		"desktop pause grid order (%s)" % [ids])
	_check(Flow.pause_labels(main).size() == ids.size(), "one label per pause cell")
	Flow.exit_hidden = true
	_check(not Flow.pause_ids(main).has("exit") and Flow.pause_ids(main).size() == 5,
		"without exit the grid has five cells and no disabled one")
	Flow.exit_hidden = false
	# two axes: right, down, left, up all move one cell
	main.pause_idx = 0
	Flow.pause_move(main, 1, 0)
	_check(main.pause_idx == 1, "right moves to the next column")
	Flow.pause_move(main, 0, 1)
	_check(main.pause_idx == 3, "down moves one row")
	Flow.pause_move(main, -1, 0)
	_check(main.pause_idx == 2, "left moves back a column")
	Flow.pause_move(main, 0, -1)
	Flow.pause_move(main, 0, -1)
	_check(main.pause_idx == 4, "up from the top row wraps to the bottom")
	Flow.exit_hidden = true
	main.pause_idx = 1
	Flow.pause_move(main, 0, 2)
	_check(main.pause_idx == 4, "a five-cell grid lands on its lone last cell")
	Flow.exit_hidden = false
	main.pause_idx = 0
```

- [ ] **Step 2: Run, confirm failure**

Run: `G --headless --path . --script res://tests/test_menu_flow.gd`
Expected: error on `exit_hidden` / `pause_ids`.

- [ ] **Step 3: Implement in `hud/menu_flow.gd`**

Replace `const PAUSE_ROWS := [...]` with:

```gdscript
const PAUSE_CELLS := ["resume", "walk", "restart", "settings", "select", "exit"]
const PAUSE_LABELS := {"resume": "RESUME", "walk": "THIS WALK", "restart": "START AGAIN",
	"settings": "SETTINGS", "select": "WALK SELECT", "exit": "EXIT GAME"}
const PAUSE_COLS := 2

# Leaving the application is a desktop thing: a browser tab is closed by
# the browser. `--no-exit` and tests set this to see the web layout anywhere.
static var exit_hidden := false
```

Replace `pause_rows` with:

```gdscript
static func can_exit() -> bool:
	return not exit_hidden and not OS.has_feature("web")


static func pause_ids(m: Node2D) -> Array:
	var out := PAUSE_CELLS.duplicate()
	if not can_exit():
		out.erase("exit")
	return out


static func pause_labels(m: Node2D) -> Array:
	var out := []
	for id: String in pause_ids(m):
		out.append(PAUSE_LABELS[id])
	return out


# One step across the grid. Rows wrap; a short last row (the web's five
# cells) only has its left cell, so landing on the gap takes that instead.
static func pause_move(m: Node2D, dx: int, dy: int) -> void:
	var n := pause_ids(m).size()
	var rows := (n + PAUSE_COLS - 1) / PAUSE_COLS
	var col: int = int(m.pause_idx) % PAUSE_COLS
	var row: int = int(m.pause_idx) / PAUSE_COLS
	if dx != 0:
		col = wrapi(col + dx, 0, PAUSE_COLS)
	if dy != 0:
		row = wrapi(row + dy, 0, rows)
	var i := row * PAUSE_COLS + col
	if i >= n:
		i = row * PAUSE_COLS
	m.pause_idx = i
	Sfx.play("ui")
```

Replace the move and plant branches of `tick_pause` (keep the resume and `pee` branches as they are):

```gdscript
	elif Input.is_action_just_pressed("move_down"):
		pause_move(m, 0, 1)
	elif Input.is_action_just_pressed("move_up"):
		pause_move(m, 0, -1)
	elif Input.is_action_just_pressed("move_right"):
		pause_move(m, 1, 0)
	elif Input.is_action_just_pressed("move_left"):
		pause_move(m, -1, 0)
	elif Input.is_action_just_pressed("pee"):
		open_settings(m)
	elif Input.is_action_just_pressed("plant"):
		pause_activate(m)
```

and add:

```gdscript
static func pause_activate(m: Node2D) -> void:
	match String(pause_ids(m)[m.pause_idx]):
		"resume":
			resume(m)
		"walk":
			open_walk_card(m)
		"restart":
			open_confirm(m, "restart")
		"settings":
			open_settings(m)
		"select":
			to_walk_select(m)
		"exit":
			open_confirm(m, "exit")
```

`open_walk_card` and `open_confirm` arrive in Tasks 4 and 5; to keep this task green, add them now as stubs that only set `m.pause_view = "walk"` and `m.confirm_id = which`, plus the two vars in Step 4.

Change the pause prompts to `return [["move", "pick"], ["plant", "select"], ["pause", "resume"]]`.

- [ ] **Step 4: In `main.gd`, next to `var pause_idx := 0`, add**

```gdscript
# a question the menus are waiting on ("restart", "exit"), and which pause
# card is open over the grid ("walk"); empty when neither
var confirm_id := ""
var pause_view := ""
```

and in `_ready`, beside `var autowalk_requested := ...`, add:

```gdscript
	if "--no-exit" in OS.get_cmdline_user_args():
		MenuFlow.exit_hidden = true
```

- [ ] **Step 5: Update `hud/menu_screen.gd`'s `_pause` minimally** so it still runs: replace `Flow.pause_rows(main)` with `Flow.pause_labels(main)`. The grid look arrives in Task 6.

- [ ] **Step 6: Run** `G --headless --path . --script res://tests/test_menu_flow.gd`. Expected: `MENU FLOW OK`.

- [ ] **Step 7: Commit** with subject `Lay the pause menu out as a grid`.

---

### Task 4: Confirmations and EXIT GAME

**Files:** Modify `hud/menu_flow.gd`, `tests/test_menu_flow.gd`

- [ ] **Step 1: Write failing tests** after the grid checks:

```gdscript
	# START AGAIN and EXIT GAME ask first; cancelling returns to the grid
	var quit_calls := [0]
	Flow.quit_hook = func() -> void: quit_calls[0] += 1
	main.pause_idx = Flow.pause_ids(main).find("exit")
	Flow.pause_activate(main)
	_dump(main, "confirm_exit")
	_check(Flow.screen(main) == "confirm" and main.confirm_id == "exit" and quit_calls[0] == 0,
		"EXIT GAME asks before quitting")
	_check(_verbs(main) == ["yes", "cancel"], "a question offers yes and cancel (%s)" % [_verbs(main)])
	_check(String(Flow.confirm_card(main).body) == "Quit the game?", "the exit question")
	Flow.confirm_cancel(main)
	_check(Flow.screen(main) == "pause" and quit_calls[0] == 0, "cancel returns to the pause grid")
	Flow.open_confirm(main, "exit")
	Flow.confirm_accept(main)
	_check(quit_calls[0] == 1, "yes quits, once")
	main.confirm_id = ""
	main.pause_idx = Flow.pause_ids(main).find("restart")
	Flow.pause_activate(main)
	_check(main.confirm_id == "restart" and String(Flow.confirm_card(main).body) == "Start this walk again?",
		"START AGAIN asks first")
	Flow.confirm_cancel(main)
	Flow.quit_hook = Callable()
```

And in the title section, after the step loop:

```gdscript
	main.menu_step = 0
	main._apply_menu_step()
	Flow.exit_hidden = false
	_check(_verbs(main).has("exit game") or OS.has_feature("web"), "the title offers EXIT GAME on desktop")
	Flow.exit_hidden = true
	_check(not _verbs(main).has("exit game"), "and not where the game cannot quit")
	Flow.exit_hidden = false
	Flow.open_confirm(main, "exit")
	_check(Flow.screen(main) == "confirm", "exit from the title asks first")
	Flow.confirm_cancel(main)
	_check(Flow.screen(main) == "title", "cancel returns to the title")
```

Add a prompt-action check at the end of the pause section:

```gdscript
	var Prompts: GDScript = load("res://hud/prompts.gd")
	for which in ["title", "pause", "confirm", "walkcard"]:
		for it: Array in Flow.prompts(main, which):
			_check(Prompts.NAMES.has(String(it[0])), "%s prompt '%s' is an action Prompts knows" % [which, it[0]])
```

- [ ] **Step 2: Run, confirm failure** on `quit_hook`.

- [ ] **Step 3: Implement in `hud/menu_flow.gd`**

```gdscript
# tests swap this in so a confirmed exit can be checked without ending the run
static var quit_hook := Callable()

const CONFIRMS := {
	"restart": {"title": "START AGAIN", "body": "Start this walk again?"},
	"exit": {"title": "EXIT GAME", "body": "Quit the game?"},
}


static func open_confirm(m: Node2D, which: String) -> void:
	m.confirm_id = which
	Sfx.play("ui")


static func confirm_card(m: Node2D) -> Dictionary:
	return CONFIRMS.get(String(m.confirm_id), {"title": "", "body": ""})


static func confirm_cancel(m: Node2D) -> void:
	m.confirm_id = ""
	Sfx.play("ui")


static func confirm_accept(m: Node2D) -> void:
	var which := String(m.confirm_id)
	m.confirm_id = ""
	match which:
		"restart":
			restart_walk(m)
		"exit":
			quit_game(m)


static func quit_game(m: Node2D) -> void:
	if quit_hook.is_valid():
		quit_hook.call()
		return
	m.get_tree().quit()


static func tick_confirm(m: Node2D) -> void:
	if Input.is_action_just_pressed("plant"):
		confirm_accept(m)
	elif Input.is_action_just_pressed("bark") or Input.is_action_just_pressed("pause"):
		confirm_cancel(m)
```

In `screen()`, directly after the `in_settings` check:

```gdscript
	if m.confirm_id != "":
		return "confirm"
```

In `prompts()`:

```gdscript
		"title":
			var out := [["plant", "start"], ["pause", "settings"]]
			if can_exit():
				out.append(["bark", "exit game"])
			return out
		"confirm":
			return [["plant", "yes"], ["bark", "cancel"]]
```

At the top of `tick_title`:

```gdscript
	if m.confirm_id != "":
		tick_confirm(m)
		return true
```

and in its `0:` branch, after the plant check:

```gdscript
			elif Input.is_action_just_pressed("bark") and can_exit():
				open_confirm(m, "exit")
```

At the top of `tick_pause`:

```gdscript
	if m.confirm_id != "":
		tick_confirm(m)
		return
```

Remove the Task 3 `open_confirm` stub.

- [ ] **Step 4: Run** `G --headless --path . --script res://tests/test_menu_flow.gd` and `G --headless --path . --script res://tests/test_prompts.gd`. Expected: both OK.

- [ ] **Step 5: Commit** with subject `Ask before starting again or quitting, and offer EXIT GAME on desktop`.

---

### Task 5: THIS WALK card

**Files:** Modify `hud/menu_flow.gd`, `tests/test_menu_flow.gd`

- [ ] **Step 1: Write failing tests** after the confirmation checks:

```gdscript
	main.pause_idx = Flow.pause_ids(main).find("walk")
	Flow.pause_activate(main)
	_dump(main, "walkcard")
	var wc: Dictionary = Flow.walk_card(main)
	_check(Flow.screen(main) == "walkcard", "THIS WALK opens its card")
	_check(String(wc.name) == main._walk_name() and wc.has("gloss"), "the card names the walk and its gloss")
	_check((wc.goals as Array).size() == main.active_quests.size(), "one line per goal on this walk")
	_check(_verbs(main) == ["back"], "the card's only way on is back")
	Flow.close_walk_card(main)
	_check(Flow.screen(main) == "pause", "back returns to the pause grid")
```

- [ ] **Step 2: Run, confirm failure** on `walk_card`.

- [ ] **Step 3: Implement**

Add preloads at the top of `hud/menu_flow.gd`:

```gdscript
const Goals := preload("res://systems/goals.gd")
const TutorialSteps := preload("res://systems/tutorial.gd")
```

(If `goals.gd` preloads `menu_flow.gd`, the cycle fails to parse; then read `quest_text` through `m.Goals` instead.)

```gdscript
static func open_walk_card(m: Node2D) -> void:
	m.pause_view = "walk"
	Sfx.play("ui")


static func close_walk_card(m: Node2D) -> void:
	m.pause_view = ""
	Sfx.play("ui")


# The walk you are on, from what the game already knows: its name and gloss,
# then each goal with how far along it is, or the lesson in the tutorial.
static func walk_card(m: Node2D) -> Dictionary:
	var key := "tutorial" if m.tutorial_mode else String(m.lvl)
	var out := {"name": m._walk_name(), "gloss": String(Game.LEVEL_SUBTITLES.get(key, "")),
		"time": clock(float(m.elapsed)), "goals": [], "lesson": ""}
	if m.tutorial_mode:
		var st: Dictionary = TutorialSteps.step(m.tut_step)
		if String(st.id) != "":
			out.lesson = "Lesson %d of %d: %s" % [int(m.tut_step) + 1, TutorialSteps.step_count(), String(st.title)]
		return out
	for q: Dictionary in m.active_quests:
		var target := int(q.target)
		var done: bool = m.run_goals_hit.has(q.id) or ((not Game.daily) and Game.goal_done(m.lvl, q.id))
		var got := target if done else mini(int(q.fn.call()), target)
		out.goals.append({"text": Goals.quest_text(q), "got": got, "target": target, "done": done})
	return out


static func tick_walk_card(m: Node2D) -> void:
	if (Input.is_action_just_pressed("bark") or Input.is_action_just_pressed("pause")
			or Input.is_action_just_pressed("plant")):
		close_walk_card(m)
```

In `screen()`, replace `if m.paused: return "pause"` with:

```gdscript
	if m.paused:
		return "walkcard" if m.pause_view == "walk" else "pause"
```

In `prompts()`: `"walkcard": return [["bark", "back"]]`.

In `tick_pause`, after the confirm check: `if m.pause_view == "walk": tick_walk_card(m); return`.

In `open_pause` and `resume`, add `m.pause_view = ""` and `m.confirm_id = ""`.

Remove the Task 3 `open_walk_card` stub.

- [ ] **Step 4: Run** `G --headless --path . --script res://tests/test_menu_flow.gd`. Expected: `MENU FLOW OK`.

- [ ] **Step 5: Commit** with subject `Show the walk's name and goals from the pause menu`.

---

### Task 6: Draw the grid, the walk card and the question

**Files:** Modify `hud/menu_screen.gd`, `main.gd`, `tools/shot_sweep.sh`

- [ ] **Step 1: Constants** in `hud/menu_screen.gd`, replacing `PAUSE_W` and `PAUSE_ROW_H`:

```gdscript
const PAUSE_W := 560.0
const PAUSE_CELL_H := 58.0
const PAUSE_GAP := 12.0
const WALKCARD_W := 620.0
const CONFIRM_W := 460.0
```

- [ ] **Step 2: Dispatch** in `_draw`'s match:

```gdscript
		"walkcard":
			_walk_card(vs)
		"confirm":
			_confirm(vs)
```

A confirm over the title draws its card on top of the title's world name; nothing else changes on the title.

- [ ] **Step 3: Replace `_pause` with the grid**

```gdscript
func _pause(vs: Vector2) -> void:
	var acc := Kit.accent("pause")
	var labels := Flow.pause_labels(main)
	var rows := (labels.size() + Flow.PAUSE_COLS - 1) / Flow.PAUSE_COLS
	var h := 110.0 + float(rows) * (PAUSE_CELL_H + PAUSE_GAP) + 14.0
	var r := Rect2(vs.x * 0.5 - PAUSE_W * 0.5, vs.y * 0.5 - h * 0.5 - 20.0, PAUSE_W, h)
	Kit.card(self, r, acc)
	Kit.heading(self, Vector2(r.position.x, r.position.y + 50.0), "PAUSED", 30, acc,
		HORIZONTAL_ALIGNMENT_CENTER, PAUSE_W)
	var sub := "%s    %s" % [String(main._walk_name()), Flow.clock(float(main.elapsed))]
	draw_string(Kit.body(), Vector2(r.position.x, r.position.y + 78.0), sub, HORIZONTAL_ALIGNMENT_CENTER,
		PAUSE_W, 15, Kit.INK_FAINT)
	var f := Kit.display()
	var cw := (PAUSE_W - 48.0 - PAUSE_GAP) * 0.5
	for i in range(labels.size()):
		var col := i % Flow.PAUSE_COLS
		var row := i / Flow.PAUSE_COLS
		var cell := Rect2(r.position.x + 24.0 + float(col) * (cw + PAUSE_GAP),
			r.position.y + 100.0 + float(row) * (PAUSE_CELL_H + PAUSE_GAP), cw, PAUSE_CELL_H)
		var picked: bool = i == int(main.pause_idx)
		draw_rect(cell, Color(acc.r, acc.g, acc.b, 0.16) if picked else Color(1, 1, 1, 0.04))
		draw_rect(cell, acc if picked else Color(1, 1, 1, 0.10), false, 2.0 if picked else 1.0)
		if picked:
			Kit.chevron(self, Vector2(cell.position.x + 20.0, cell.get_center().y), 8.0, acc)
		draw_string(f, Vector2(cell.position.x + 36.0, cell.get_center().y + 7.0), String(labels[i]),
			HORIZONTAL_ALIGNMENT_LEFT, cw - 44.0, 19, Kit.INK if picked else Kit.INK_SOFT)
```

- [ ] **Step 4: Add `_walk_card` and `_confirm`**

```gdscript
func _walk_card(vs: Vector2) -> void:
	var acc := Kit.accent("pause")
	var wc := Flow.walk_card(main)
	var goals: Array = wc.goals
	var lines := goals.size() if String(wc.lesson) == "" else 1
	var h := 130.0 + float(maxi(lines, 1)) * 30.0 + 20.0
	var r := Rect2(vs.x * 0.5 - WALKCARD_W * 0.5, vs.y * 0.5 - h * 0.5 - 20.0, WALKCARD_W, h)
	Kit.card(self, r, acc)
	Kit.heading(self, Vector2(r.position.x, r.position.y + 52.0), String(wc.name), 30, acc,
		HORIZONTAL_ALIGNMENT_CENTER, WALKCARD_W)
	draw_string(Kit.body(), Vector2(r.position.x, r.position.y + 80.0), "%s    %s" % [String(wc.gloss), String(wc.time)],
		HORIZONTAL_ALIGNMENT_CENTER, WALKCARD_W, 15, Kit.INK_FAINT)
	var y := r.position.y + 122.0
	var body := Kit.body()
	if String(wc.lesson) != "":
		draw_string(body, Vector2(r.position.x, y), String(wc.lesson), HORIZONTAL_ALIGNMENT_CENTER,
			WALKCARD_W, 17, Kit.INK_SOFT)
		return
	if goals.is_empty():
		draw_string(body, Vector2(r.position.x, y), "No goals on this walk.", HORIZONTAL_ALIGNMENT_CENTER,
			WALKCARD_W, 17, Kit.INK_FAINT)
		return
	for g: Dictionary in goals:
		var done := bool(g.done)
		Icons.draw_check(self, Vector2(r.position.x + 32.0, y - 11.0), 14.0,
			Icons.Check.DONE_NOW if done else (Icons.Check.PARTIAL if int(g.got) > 0 else Icons.Check.OPEN))
		draw_string(body, Vector2(r.position.x + 56.0, y), String(g.text), HORIZONTAL_ALIGNMENT_LEFT,
			WALKCARD_W - 180.0, 17, Kit.INK_FAINT if done else Kit.INK)
		if int(g.target) > 1 and not done:
			draw_string(body, Vector2(r.end.x - 110.0, y), "%d / %d" % [int(g.got), int(g.target)],
				HORIZONTAL_ALIGNMENT_RIGHT, 80.0, 15, Kit.INK_SOFT)
		y += 30.0


func _confirm(vs: Vector2) -> void:
	var acc := Kit.accent("notice")
	var c := Flow.confirm_card(main)
	var h := 150.0
	var r := Rect2(vs.x * 0.5 - CONFIRM_W * 0.5, vs.y * 0.5 - h * 0.5 - 20.0, CONFIRM_W, h)
	Kit.card(self, r, acc)
	Kit.heading(self, Vector2(r.position.x, r.position.y + 56.0), String(c.title), 28, acc,
		HORIZONTAL_ALIGNMENT_CENTER, CONFIRM_W)
	draw_string(Kit.body(), Vector2(r.position.x, r.position.y + 100.0), String(c.body),
		HORIZONTAL_ALIGNMENT_CENTER, CONFIRM_W, 19, Kit.INK_SOFT)
```

Check `Icons.Check` names against `hud/ui_icons.gd` (the goals card uses `DONE_NOW`, `DONE_BEFORE`, `PARTIAL`, `OPEN`).

- [ ] **Step 5: Screenshot entry points** in `main.gd` `_shot_menu`:

```gdscript
		"walkcard":
			_skip_title()
			MenuFlow.open_pause(self)
			MenuFlow.open_walk_card(self)
		"confirm":
			_skip_title()
			MenuFlow.open_pause(self)
			MenuFlow.open_confirm(self, "exit")
```

Update the comment above the `--shot-menu=` loop to list `walkcard|confirm`. In `tools/shot_sweep.sh` change the loop to `for sc in walk details shop progress pause walkcard confirm notice; do`.

- [ ] **Step 6: Photograph and look**

```
G --path . --quit-after 340 -- --shot --shot-menu=pause --level=street --shot-out=build/pause.png --shot-quit
G --path . --quit-after 340 -- --shot --shot-menu=walkcard --level=street --shot-out=build/walkcard.png --shot-quit
G --path . --quit-after 340 -- --shot --shot-menu=confirm --level=street --shot-out=build/confirm.png --shot-quit
G --path . --quit-after 340 -- --shot --shot-menu=pause --level=street --no-exit --shot-out=build/pause-web.png --shot-quit
G --path . --quit-after 340 -- --shot --shot-title --shot-out=build/title.png --shot-quit
```

Read each PNG. Check: six cells on two columns with the first picked; five with `--no-exit` and the last on its own; the walk card lists the street's goals; the confirm card reads EXIT GAME / Quit the game?; the title's bar includes EXIT GAME. Text stays inside its cell at 844x390 too (repeat the pause shot with `--resolution 844x390` if the sweep does that size).

- [ ] **Step 7: Run all menu-adjacent tests**

```
G --headless --path . --script res://tests/test_menu_flow.gd
G --headless --path . --script res://tests/test_prompts.gd
G --headless --path . --script res://tests/test_touch_controls.gd
G --headless --path . --quit-after 1800
```

- [ ] **Step 8: Commit** with subject `Draw the pause grid, the walk card and the questions`.

---

### Task 7: Docs, full verification, PR

**Files:** `AGENTS.md`, `README.md`, `CHANGELOG.md`, `HANDOVER.md`

- [ ] **Step 1: Docs**
  - `AGENTS.md`: `--shot-menu=` list gains `walkcard|confirm`; add `--no-exit` (shows the web menus on desktop); one line that EXIT GAME is desktop-only and goes through `Flow.quit_game`.
  - `README.md`: wherever controls or menus are described, mention the pause grid and EXIT GAME on desktop. If README says nothing about menus, leave it.
  - `CHANGELOG.md`: newest-first entry for the session: the nose snack fix (cause: held owner too far from the snack, random reel, weave), standing spots, pinned reel, pause grid, THIS WALK, confirmations, EXIT GAME.
  - `HANDOVER.md`: current state, the PR, WIP count.

- [ ] **Step 2: Full CI-equivalent run.** Run every `--script res://tests/...` step listed in `.github/workflows/ci.yml` (read the file for the list), the tutorial smoke, and `bash tools/behaviour_snapshot.sh` against the `origin/main` baseline. All green, snapshot identical.

- [ ] **Step 3: Commit** with subject `Document the pause grid and tutorial reach`, push the branch, and open the PR with `gh pr create`. Body: summary, test evidence, the before/after screenshots from Task 6, and:

```markdown
## Feel card

1. `--level=tutorial`: follow the nose lesson without skipping. The human waits by the west edge, the snack is visibly on grass, scent leads to it, and the dog can reach and eat it.
2. `--level=street`, press pause: the grid moves in both directions. START AGAIN and EXIT GAME ask first. WALK SELECT goes straight to walk select.
3. From the title on desktop: EXIT GAME asks first, then the game closes. Cancel returns to the title.
4. Launch with `-- --no-exit` (the web layout): neither the title nor pause offers EXIT GAME, and the grid has five cells.
5. Pause, THIS WALK: the walk's name, gloss and goals with progress; back returns to the grid.
```

- [ ] **Step 4: Watch CI** with `gh run watch`. Fix failures before asking for merge. After Santtu merges, add the PR to the project board and set Status to "Awaiting acceptance" (project `PVT_kwHOAbzYws4BkbBT`, field `PVTSSF_lAHOAbzYws4BkbBTzhjLpDY`, option `4e56e73b`).
