extends SceneTree

# Another walker's dog walks like a dog on a leash (entities/otherpair.gd):
# mostly a little ahead of its owner, or level, dropping behind only on a
# sniff; and the leash runs from the owner's fist to the collar with a gentle
# droop, never a heap of slack trailing behind the pair.

const PAIR_SCRIPT := "res://entities/otherpair.gd"
const DT := 1.0 / 60.0
const SECONDS := 30.0
const SETTLE_FRAMES := 30
# ahead of or level with the owner: no more than this far behind along the walk
const LEVEL_TOL := 8.0
const AHEAD_SHARE_MIN := 0.75
# slack: rope used beyond the straight fist-to-collar line (or beyond the
# shortest the owner takes it in to, when the dog is right by them)
const SLACK_MAX := 18.0
# and no part of the rope bulges further than this off that line
const BULGE_MAX := 24.0

var failures := 0


class FakeMain:
	extends Node2D

	func contact_shadow(_c: Object, _at: Vector2, _r: float, _h: float, _a := 0.24) -> void:
		pass

	func cast_shadow(_c: Object, _at: Vector2, _w: float, _h: float, _a := 0.20) -> void:
		pass

	var phase := "out"
	var frozen := false
	var cam := Node2D.new()
	var bypasser_blockers: Array[Dictionary] = []

	func _init() -> void:
		add_child(cam)

	const POP_SAY := 0

	func float_text(_position: Vector2, _text: String, _color: Color, _kind := -1) -> void:
		pass


func _check(condition: bool, message: String) -> void:
	if not condition:
		print("FAIL: " + message)
		failures += 1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := FakeMain.new()
	main.visible = false
	root.add_child(main)
	var player_dog := Node2D.new()
	player_dog.position = Vector2(-10000, -10000)
	root.add_child(player_dog)
	for direction in [-1.0, 1.0]:
		for walk_seed in [3, 11, 29, 47]:
			_walk(main, player_dog, direction, walk_seed)
	main.queue_free()
	player_dog.queue_free()
	await process_frame
	if failures == 0:
		print("test_pair_walk: OK")
		quit(0)
	else:
		print("test_pair_walk: %d FAILURES" % failures)
		quit(1)


func _walk(main: Node2D, player_dog: Node2D, direction: float, walk_seed: int) -> void:
	var label := "pair walking %s (seed %d)" % ["up" if direction < 0.0 else "down", walk_seed]
	seed(walk_seed)
	var pair := Node2D.new()
	pair.set_script(load(PAIR_SCRIPT))
	pair.visible = false
	pair.set_physics_process(false)
	var no_poles: Array[Vector2] = []
	pair.setup(main, player_dog, no_poles, Vector2(300, 0), Vector2(0, direction))
	var no_blockers: Array[Dictionary] = []
	_check(bool(pair.configure_route(300.0, 0.0, 600.0, no_blockers)), label + " route configures")
	root.add_child(pair)
	pair.set_physics_process(false)
	var frames := int(SECONDS / DT)
	var ahead_frames := 0
	var counted := 0
	var worst_slack := 0.0
	var worst_bulge := 0.0
	var worst_span := 0.0
	for frame in range(frames):
		main.cam.position = pair.npc_owner.position
		pair._physics_process(DT)
		var owner: Vector2 = pair.npc_owner.position
		var dog: Vector2 = pair.npc_dog.position
		worst_span = maxf(worst_span, owner.distance_to(dog))
		if frame < SETTLE_FRAMES:
			continue
		counted += 1
		if (dog.y - owner.y) * direction >= -LEVEL_TOL:
			ahead_frames += 1
		var hand: Vector2 = pair.leash.call("_hand_pos")
		var collar: Vector2 = pair.leash.pts[0]
		var straight := hand.distance_to(collar)
		# a fist can only gather so much: up to LEASH_MIN of strap is in hand
		var gathered := maxf(straight, float(pair.LEASH_MIN))
		worst_slack = maxf(worst_slack, float(pair.leash.used_length()) - gathered)
		for p: Vector2 in pair.leash.pts:
			worst_bulge = maxf(worst_bulge, _distance_to_segment(p, collar, hand))
	var share := float(ahead_frames) / float(maxi(counted, 1))
	print("%s: ahead or level %.0f%%, worst slack %.1f px, worst bulge %.1f px, widest span %.1f px" % [
		label, share * 100.0, worst_slack, worst_bulge, worst_span])
	_check(share >= AHEAD_SHARE_MIN, label + " keeps the dog ahead of or level with its owner most of the time")
	_check(worst_slack <= SLACK_MAX, label + " never carries a heap of slack")
	_check(worst_bulge <= BULGE_MAX, label + " never lets the leash trail off the fist-to-collar line")
	_check(worst_span <= float(pair.LEASH_CAP) + 0.5, label + " keeps the dog on its leash")
	pair.queue_free()


func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 0.0001:
		return p.distance_to(a)
	return p.distance_to(a + ab * clampf((p - a).dot(ab) / l2, 0.0, 1.0))
