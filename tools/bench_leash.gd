extends SceneTree

# Rope solver micro-benchmark: runs entities/leash.gd through fixed scenarios
# and prints the time per tick plus a hash of everything the solver outputs.
# A speed-up that is meant to change nothing must leave every hash identical.
#
#   godot --headless --path . --script res://tools/bench_leash.gd
#
# Scenarios: "free" (slack and taut, no obstacles - most NPC walker ropes),
# "poles" (the dog circles a pole among others, so the rope wraps and slips),
# "tangle" (another leash's sampled points drape across this one).
# Timings are wall clock on this machine; compare runs from one machine only.

const TICKS := 3000
const REPEATS := 5
const DT := 1.0 / 60.0

const Leash := preload("res://entities/leash.gd")


func _initialize() -> void:
	for scen in ["free", "poles", "tangle"]:
		var best := INF
		var digest := ""
		for _r in range(REPEATS):
			var res := _run(scen)
			best = minf(best, res[0])
			if digest == "":
				digest = res[1]
			elif digest != res[1]:
				push_error("bench_leash: %s is not deterministic between repeats" % scen)
		print("BENCH leash %-6s %7.2f us/tick  hash=%s" % [scen, best, digest.substr(0, 16)])
	quit()


func _run(scen: String) -> Array:
	var dog := Node2D.new()
	var human := Node2D.new()
	var leash: Node2D = Leash.new()
	root.add_child(dog)
	root.add_child(human)
	root.add_child(leash)
	var poles: Array[Vector2] = []
	if scen == "poles":
		poles = Array([Vector2(0, -120), Vector2(90, -300), Vector2(-80, -520), Vector2(400, 0)], TYPE_VECTOR2, &"", null)
	var furn: Array[Vector2] = []
	if scen == "poles":
		furn = Array([Vector2(90, -300)], TYPE_VECTOR2, &"", null)
	leash.furniture_poles = furn
	dog.global_position = Vector2(0, -60)
	human.global_position = Vector2(0, 150)
	leash.setup(dog, human, poles, 220.0)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	var t_total := 0
	for f in range(TICKS):
		var t := f * DT
		match scen:
			"free":
				human.global_position = Vector2(20.0 * sin(t * 0.7), 150.0 - 40.0 * t)
				dog.global_position = human.global_position + Vector2(140.0 * sin(t * 1.3), -120.0 - 90.0 * sin(t * 0.45))
			"poles":
				human.global_position = Vector2(30.0 * sin(t * 0.5), 140.0 - 10.0 * sin(t * 0.2))
				dog.global_position = Vector2(0, -120) + Vector2.from_angle(t * 1.9) * (40.0 + 25.0 * sin(t * 0.8))
				human.rotation = 0.3 * sin(t)
			"tangle":
				human.global_position = Vector2(10.0 * sin(t * 0.6), 150.0)
				dog.global_position = Vector2(120.0 * sin(t * 0.9), -80.0)
				var other: Array[Vector2] = []
				for i in range(12):
					other.append(Vector2(-160.0 + i * 28.0, 30.0 * sin(t * 1.1 + i * 0.4)))
				leash.dynamic_obstacles = other
		leash.rest_len = 220.0 + 30.0 * sin(t * 0.33)
		var t0 := Time.get_ticks_usec()
		leash.tick(DT)
		t_total += Time.get_ticks_usec() - t0
		ctx.update(var_to_bytes([leash.pts, leash.prev, leash.contacts, leash.static_contacts,
			leash.dynamic_contacts, leash.contact_pole, leash.contact_kind, leash.contact_static,
			leash.contact_dynamic, leash.near_poles, leash.used_length()]))
	leash.free()
	dog.free()
	human.free()
	return [float(t_total) / TICKS, ctx.finish().hex_encode()]
