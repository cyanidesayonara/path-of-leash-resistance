extends SceneTree

# Rope drawing micro-benchmark: the same three scenarios as bench_leash.gd,
# but the timed part is the per-frame draw preparation, not the solver.
#
#   godot --headless --path . --script res://tools/bench_leash_draw.gd
#
# Each frame ticks the rope (untimed), then times leash._draw_shapes() handed
# a sink in place of the canvas, so everything the script does to turn the
# solved rope into strap geometry is measured and nothing needs a renderer.
# visible_path() is also timed on its own where the leash has it. The hash
# covers every polyline, circle and width the draw hands over, so a speed-up
# meant to change no pixel must leave it as it was.
# Timings are wall clock on this machine; compare runs from one machine only.

const TICKS := 3000
const REPEATS := 5
const DT := 1.0 / 60.0

const Leash := preload("res://entities/leash.gd")


# takes the draw calls instead of a canvas; holds them only until hashed
class Sink:
	extends ShapeBatch

	var calls: Array = []

	func draw_polyline(...args: Array) -> void:
		calls.append(args)

	func draw_circle(...args: Array) -> void:
		calls.append(args)

	func flush(_canvas: Object = null) -> void:
		pass


func _initialize() -> void:
	for scen in ["free", "poles", "tangle"]:
		var best_draw := INF
		var best_path := INF
		var digest := ""
		for _r in range(REPEATS):
			var res := _run(scen)
			best_draw = minf(best_draw, res[0])
			best_path = minf(best_path, res[1])
			if digest == "":
				digest = res[2]
			elif digest != res[2]:
				push_error("bench_leash_draw: %s is not deterministic between repeats" % scen)
		var path_text := "    n/a" if best_path >= INF else "%7.2f" % best_path
		print("BENCH leash-draw %-6s draw %7.2f us  path %s us  hash=%s" % [
			scen, best_draw, path_text, digest.substr(0, 16)])
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
	var has_path := leash.has_method("visible_path")
	var sink := Sink.new()
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	var t_draw := 0
	var t_path := 0
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
		leash.tick(DT)
		if has_path:
			var t1 := Time.get_ticks_usec()
			leash.visible_path()
			t_path += Time.get_ticks_usec() - t1
		leash._b = sink
		var t0 := Time.get_ticks_usec()
		leash._draw_shapes()
		t_draw += Time.get_ticks_usec() - t0
		ctx.update(var_to_bytes(sink.calls))
		# released before the next frame, so the leash's buffers are never
		# shared when it next writes them
		sink.calls.clear()
	leash.free()
	dog.free()
	human.free()
	var path_us := float(t_path) / TICKS if has_path else INF
	return [float(t_draw) / TICKS, path_us, ctx.finish().hex_encode()]
