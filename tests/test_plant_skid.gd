extends SceneTree

# A planted dog the leash hauls anyway skids (main._skid): she braces facing
# the one hauling her, leaves paw furrows in whatever she is dug into (none
# in water), and a plant grips less on wet ground and less again on packed
# snow, so she is hauled further there by the same pull.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


# how far a planted dog is hauled in two seconds by a human walking away
func _haul(ice: bool, slick: bool) -> float:
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m.frozen = true
	m.dog.collision_mask = 0
	m.human.collision_mask = 0
	var d: CharacterBody2D = m.dog
	var h: CharacterBody2D = m.human
	d.global_position = Vector2(640, 0)
	h.global_position = Vector2(640, -m.leash_len - 60.0)
	m.leash.setup(d, h, m.poles, m.leash_len)
	# the same start every time, whatever the scene did before it was frozen
	h.velocity = Vector2.ZERO
	d.velocity = Vector2.ZERO
	var start := d.global_position
	var dt := 1.0 / 60.0
	for i in range(120):
		d.planted = true
		d.ice = ice
		d.slick = slick
		d.velocity = Vector2.ZERO
		# the human's own walking, which the leash then fights
		h.velocity = h.velocity.move_toward(Vector2(0, -110), 400.0 * dt)
		m._apply_leash(dt)
		h.move_and_slide()
		m.leash.tick(dt)
	var out := d.global_position.distance_to(start)
	m.queue_free()
	await process_frame
	return out


func _run() -> void:
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m.frozen = true
	var d: CharacterBody2D = m.dog
	d.collision_mask = 0
	m.human.collision_mask = 0
	# barely nudged: not a skid
	m._skid(Vector2.UP, 0.1)
	_check(d.skid == 0.0 and m.skids.is_empty(), "a nudge is not a skid")
	# hauled up the screen a pixel a frame on paving
	d.facing = Vector2.DOWN
	d.surface = m.Surfaces.S.PAVEMENT
	for i in range(30):
		d.global_position += Vector2(0, -1)
		m._skid(Vector2.UP, 1.0)
	_check(d.skid == 1.0, "hauled while planted is a skid")
	_check(m.skids.size() >= 4 and m.skids.size() % 2 == 0, "two paw furrows per stretch (%d)" % m.skids.size())
	_check(d.facing.dot(Vector2.UP) > 0.9, "she braces facing the one hauling her")
	var sand: Array = (func() -> Array: d.surface = m.Surfaces.S.SAND; return m._skid_look()).call()
	var pave: Array = (func() -> Array: d.surface = m.Surfaces.S.PAVEMENT; return m._skid_look()).call()
	_check(float(sand[1]) > float(pave[1]), "sand takes a deeper furrow than paving")
	d.surface = m.Surfaces.S.WATER
	var n: int = m.skids.size()
	for i in range(20):
		d.global_position += Vector2(0, -1)
		m._skid(Vector2.UP, 1.0)
	_check(m.skids.size() == n, "water takes no marks")
	# the same haul drags her further on wet ground, and further on snow
	m.queue_free()
	await process_frame
	var dry: float = await _haul(false, false)
	var wet: float = await _haul(false, true)
	var snow: float = await _haul(true, false)
	print("hauled: dry %.0f  wet %.0f  snow %.0f" % [dry, wet, snow])
	_check(dry > 5.0, "a planted dog still gives under a determined haul (%.0f)" % dry)
	# a margin, not a tuning check: the haul varies a pixel or two run to run
	_check(wet > dry * 1.1, "wet ground grips a plant less")
	_check(snow > wet * 1.2, "packed snow grips a plant least")
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_plant_skid: OK")
		quit(0)
	else:
		quit(1)
