extends SceneTree

# Can she leave the off-leash space? For every walk: start the walk, open the
# gate, then drive the dog flat out in eight directions from the middle of the
# space and record how far she gets, and where the free dogs wander. Prints a
# line per walk; a walk where anyone ends up off the space's ground is marked.
#   godot --headless --path . --script res://tools/freedom_bounds.gd

const LEVELS := ["street", "park", "beach", "rain", "market", "oldtown", "trail", "station",
	"site", "spook", "scrap", "guell", "barri", "neteja", "montjuic"]
const RUN_FRAMES := 240
const SLACK := 40.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var bad := 0
	for lvl: String in LEVELS:
		root.get_node("Game").level_id = lvl
		var m: Node2D = load("res://main.tscn").instantiate()
		root.add_child(m)
		if not m.is_node_ready():
			await m.ready
		for k in range(5):
			await physics_frame
		m._skip_title()
		var mid := Vector2(640.0, (m.freedom_lo + m.GATE_Y) * 0.5)
		m.dog.global_position = mid
		m.human.global_position = Vector2(640.0, m.GATE_Y - 60.0)
		m.leash.resnap()
		m._enter_freedom()
		var fr: Rect2 = m._freedom_rect()
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		var out: Array[String] = []
		# down through the gate last: that turns the walk for home
		for d: int in [6, 5, 7, 4, 0, 2]:
			var dir := Vector2.from_angle(TAU * float(d) / 8.0)
			m.dog.global_position = mid
			m.dog.velocity = Vector2.ZERO
			m.dog.auto = true
			m.dog.auto_move = dir
			for f in range(RUN_FRAMES):
				await physics_frame
			var p: Vector2 = m.dog.global_position
			# and can she still be seen? (the camera follows off the leash)
			var vs: Vector2 = m.get_viewport_rect().size / m.cam.zoom
			var view := Rect2(m.cam.get_screen_center_position() - vs * 0.5, vs)
			if p.y < m.GATE_Y and not view.grow(-8.0).has_point(p):
				out.append("off screen at (%d,%d) view %s phase %s cam %s" % [int(p.x), int(p.y), str(view), m.phase, str(m.cam.position)])
			lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
			hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
			# going back down through the gate onto the walk is allowed
			if p.y < m.GATE_Y and not fr.grow(SLACK).has_point(p) and not (m.lvl == "beach" and p.x < fr.position.x):
				out.append("dog %s -> (%d,%d)" % [str(dir.snapped(Vector2(0.01, 0.01))), int(p.x), int(p.y)])
		m.dog.auto = false
		for fd in m.get_tree().get_nodes_in_group("freedogs"):
			var q: Vector2 = (fd as Node2D).global_position
			if not fr.grow(SLACK).has_point(q):
				out.append("free dog at (%d,%d)" % [int(q.x), int(q.y)])
		var tag := "OK " if out.is_empty() else "OUT"
		if not out.is_empty():
			bad += 1
		print("%s %-8s space x %d..%d y %d..%d | dog reached x %d..%d y %d..%d %s" % [tag, lvl,
			int(fr.position.x), int(fr.end.x), int(fr.position.y), int(fr.end.y),
			int(lo.x), int(hi.x), int(lo.y), int(hi.y), "; ".join(out)])
		m.queue_free()
		await process_frame
	print("freedom_bounds: %d walks with escapes" % bad)
	quit(0)
