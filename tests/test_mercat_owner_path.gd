extends SceneTree

# El Mercat (#153): left to himself, your human walks the whole hall without
# wedging. Nobody touches the dog; the walk is stepped frame by frame, and
# while he is walking (not on the phone, not waiting, not fallen) he must
# never stand still for long. He used to wedge in the slot between a stall
# block and its corner column, and against a block's end face when he met
# it still crossing over to its side.

const STEP := 1.0 / 60.0
# a walking human who covers less than this in WINDOW seconds is stuck
const WINDOW := 4.0
const MIN_MOVE := 20.0
const SEEDS: Array[int] = [1, 2, 3]
const MAX_T := 400.0

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.level_id = "market"
	for sd: int in SEEDS:
		seed(sd)
		var m: Node2D = load("res://main.tscn").instantiate()
		root.add_child(m)
		if not m.is_node_ready():
			await m.ready
		var t := 0.0
		# (time, position) samples while he is walking; cleared by anything else
		var walk_hist: Array = []
		var worst := 0.0
		var worst_at := Vector2.ZERO
		while t < MAX_T and m.phase == "out":
			m._physics_process(STEP)
			t += STEP
			var hp: Vector2 = m.human.global_position
			var walking: bool = m.human.state == m.human.HState.WALK or m.human.state == m.human.HState.DRIFT
			# a dog squatting is waited for, on purpose
			# held by the leash is not wedged: nobody steers the dog here, so a
			# rope caught round a stall can hold him, which a player would fix
			var held: bool = m.leash.taut_amount(m.leash.used_length() / m.leash.rest_len) > 0.5
			if not walking or held or m.dog.squat_t > 0.0 or m.dog.peeing or m.human.halt_t > 0.0:
				walk_hist.clear()
				continue
			walk_hist.append([t, hp])
			while walk_hist.size() > 1 and t - float(walk_hist[0][0]) > WINDOW:
				var first: Array = walk_hist.pop_front()
				var moved: float = (first[1] as Vector2).distance_to(hp)
				if moved < MIN_MOVE and t - float(first[0]) > worst:
					worst = t - float(first[0])
					worst_at = hp
		_check(m.phase != "out", "seed %d: he walks the hall to the gate in %.0f s (at y=%.0f)" % [
			sd, t, m.human.global_position.y])
		_check(worst == 0.0, "seed %d: never stuck while walking (%.1f s at %s)" % [sd, worst, worst_at])
		print("seed %d: %.0f s to the gate" % [sd, t])
		m.queue_free()
		await process_frame
	# Pulled into the other aisle: level with a block on the side its route
	# does not take, he walks on up that aisle instead of pressing into the
	# block's flank (seed 2 on Linux CI pinned him there, at x 530)
	for start: Vector2 in [Vector2(515, -3020), Vector2(515, -3280), Vector2(515, -1350), Vector2(765, -2150)]:
		seed(1)
		var mb: Node2D = load("res://main.tscn").instantiate()
		root.add_child(mb)
		if not mb.is_node_ready():
			await mb.ready
		mb._skip_title()
		mb.human.global_position = start
		mb.dog.global_position = start + Vector2(0, -30)
		mb.leash.resnap()
		mb.human.event_timer = 999.0
		for i in range(360):
			# the dog at his heel, the leash slack, no call or selfie
			mb.dog.global_position = mb.human.global_position + Vector2(0, -30)
			mb.dog.velocity = Vector2.ZERO
			mb.human.event_timer = 999.0
			mb._physics_process(STEP)
		var up: float = start.y - mb.human.global_position.y
		_check(up > 300.0, "from %s, the wrong side of a block, he walks on up the aisle (%.0f px)" % [start, up])
		mb.queue_free()
		await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_mercat_owner_path: OK")
		quit(0)
	else:
		quit(1)
