extends SceneTree

# El Mercat (#153): left to himself, your human walks the whole hall without
# wedging. Nobody touches the dog; the walk is stepped frame by frame, and
# while he is walking (not on the phone, not waiting, not fallen) he must
# never stand still for long. He used to wedge in the slot between a stall
# block and its corner column, and against a block's end face when he met
# it still crossing over to its side.

const STEP := 1.0 / 60.0
# Stepping by hand must happen inside an engine physics step: outside one,
# move_and_slide moves the dog and your human by the process delta (the wall
# time of the last frame) instead of the physics step, so every walk after
# the first `await process_frame` ran several times too fast.
# a walking human who covers less than this in WINDOW seconds is stuck
const WINDOW := 4.0
const MIN_MOVE := 20.0
const SEEDS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const MAX_T := 400.0
# LevelBuild.MERCAT_DOOR_Y (class names do not resolve in a SceneTree script)
const MERCAT_DOOR_Y := -4650.0

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
	# With the dog left to herself the rope can snag round a stall and hold him
	# for minutes, so the seeded walks check only that he never wedges on a
	# slack leash. Whether he reaches the gate depends on where she wanders.
	# (Other seeds still find wedges against block end faces and the wall
	# stalls: tracked separately; these three must stay clean.)
	for sd: int in SEEDS:
		seed(sd)
		var m: Node2D = load("res://main.tscn").instantiate()
		root.add_child(m)
		if not m.is_node_ready():
			await m.ready
		await physics_frame
		_check(Engine.is_in_physics_frame(), "seed %d: stepped inside a physics step" % sd)
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
		_check(worst == 0.0, "seed %d: never stuck while walking (%.1f s at %s)" % [sd, worst, worst_at])
		print("seed %d: %.0f s, %s" % [sd, t, "reached the gate" if m.phase != "out" else "still in the hall"])
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
		await physics_frame
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
	# The wedges a wider seed sweep found. The dog keeps near him by her own
	# movement (never placed: put past a wall, she drags him through it).
	# Just short of a block's end face, across it on the wrong side for its
	# aisle: he crosses before he walks on, and does not meet the end face and
	# then its corner column sliding along it (he wedged in that corner).
	# Just below a wall stall at the mouth of a block's aisle, or what stands
	# by the wall between stalls, with his weave and the dog both drawing him
	# to the wall: he steers out round it instead of walking into its end.
	# [start, what, weave toward (-1 west, +1 east), dog's offset from him at first]
	var scenarios: Array = [
		[Vector2(700, -3835), "below block 3's end, east of its west aisle", -1.0, Vector2(0, -36)],
		[Vector2(700, -1935), "below block 1's end, east of its west aisle", -1.0, Vector2(0, -36)],
		[Vector2(580, -2935), "below block 2's end, west of its east aisle", 1.0, Vector2(0, -36)],
		[Vector2(262, -3790), "below the west wall's jamon stall", -1.0, Vector2(-30, -36)],
		[Vector2(262, -1990), "below the west wall's fish stall", -1.0, Vector2(-30, -36)],
		[Vector2(1018, -1320), "below the crates on the east wall", 1.0, Vector2(30, -36)],
	]
	for sc: Array in scenarios:
		var start: Vector2 = sc[0]
		var heel_off: Vector2 = sc[3]
		seed(1)
		var ms: Node2D = load("res://main.tscn").instantiate()
		root.add_child(ms)
		if not ms.is_node_ready():
			await ms.ready
		ms._skip_title()
		ms.human.global_position = start
		# behind him, where he came from: always open floor
		ms.dog.global_position = start + Vector2(0, 24)
		ms.leash.resnap()
		ms.dog.auto = true
		await physics_frame
		_check(Engine.is_in_physics_frame(), "%s: stepped inside a physics step" % sc[1])
		# his weave held at one end throughout
		ms.human.wobble_seed = PI * 0.5 * float(sc[2]) - ms.elapsed * 0.35
		# where he was over the last two seconds: covering under 20 px in that
		# time, short of the far door, is a wedge
		var trail: Array[Vector2] = []
		var stuck_at := Vector2.INF
		for i in range(480):
			ms.human.event_timer = 999.0
			ms.human.patience = 1.0
			# drawing him to the wall only at the start: kept up, she snags the
			# leash on a bin by the wall and holds him there
			var off: Vector2 = heel_off if i < 40 else Vector2(0, -36)
			var ahead: Vector2 = ms.human.global_position + off - ms.dog.global_position
			ms.dog.auto_move = ahead.limit_length(40.0) / 40.0
			ms._physics_process(STEP)
			var hp_s: Vector2 = ms.human.global_position
			trail.append(hp_s)
			if trail.size() > 120:
				var then: Vector2 = trail.pop_front()
				if then.distance_to(hp_s) < 20.0 and hp_s.y > MERCAT_DOOR_Y and stuck_at == Vector2.INF:
					stuck_at = hp_s
		var up_s: float = start.y - ms.human.global_position.y
		_check(up_s > 300.0 and stuck_at == Vector2.INF, "%s: he goes round and on up (%.0f px; wedged at %s)" % [
			sc[1], up_s, stuck_at])
		ms.queue_free()
		await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_mercat_owner_path: OK")
		quit(0)
	else:
		quit(1)
