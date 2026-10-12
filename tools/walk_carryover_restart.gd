extends SceneTree

# The real game's restart path: the engine runs the walk (no hand stepping),
# then MenuFlow.restart_walk ("try again") reloads the scene in the same
# process, and the engine runs the walk again. For each second of each walk
# it prints how far the human and the dog moved against what their velocities
# account for. Run it as the game runs, without --fixed-fps:
#   godot --headless --path . --script res://tools/walk_carryover_restart.gd

const SECONDS := 6

var _m: Node2D
var _h_moved := 0.0
var _h_vel := 0.0
var _d_moved := 0.0
var _d_vel := 0.0
var _h_last := Vector2.INF
var _d_last := Vector2.INF
var _outside := 0


func _initialize() -> void:
	call_deferred("_run")


# Runs at the start of every engine physics step, before main's own
# _physics_process: the motion of the step before against its velocity.
func _on_physics() -> void:
	if _m == null or not is_instance_valid(_m) or _m.human == null:
		return
	var dt := _m.get_physics_process_delta_time()
	var hp: Vector2 = _m.human.global_position
	var dp: Vector2 = _m.dog.global_position
	if _h_last != Vector2.INF:
		_h_moved += hp.distance_to(_h_last)
		_d_moved += dp.distance_to(_d_last)
		_h_vel += _m.human.velocity.length() * dt
		_d_vel += _m.dog.velocity.length() * dt
	_h_last = hp
	_d_last = dp


func _measure(walk: int) -> Array:
	var rows: Array = []
	for s in range(SECONDS):
		_h_moved = 0.0
		_h_vel = 0.0
		_d_moved = 0.0
		_d_vel = 0.0
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 1000:
			await physics_frame
		print("  walk %d t=%d s: human moved %6.1f px (velocity %6.1f), dog moved %6.1f px (velocity %6.1f)" % [
			walk, s + 1, _h_moved, _h_vel, _d_moved, _d_vel])
		rows.append([_h_moved, _h_vel])
	return rows


func _run() -> void:
	physics_frame.connect(_on_physics)
	var game: Node = root.get_node("Game")
	game.level_id = "market"
	game.quick_start = true
	seed(1)
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	_m = current_scene
	print("walk 1 started: %s" % _m.started)
	await _measure(1)
	# what "try again" does
	var old := _m
	_m = null
	# main.gd preloads the menu flow; preloading it here first breaks its load
	old.get_script().get_script_constant_map()["MenuFlow"].restart_walk(old)
	while current_scene == null or current_scene == old or not is_instance_valid(current_scene):
		await process_frame
	await process_frame
	_m = current_scene
	_h_last = Vector2.INF
	_d_last = Vector2.INF
	print("walk 2 started: %s" % _m.started)
	await _measure(2)
	quit(0)
