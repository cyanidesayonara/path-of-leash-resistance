extends SceneTree

# A chase machine as a cartoon vehicle (systems/chase_vehicle.gd), run as La
# Neteja's street sweeper (entities/sweeper.gd) the length of the street:
# - it swerves round heavy things in its lane: its body rarely overlaps one
#   (only where there was no room, or at a jam, which holds it anyway)
# - it bonks straight over light ones, each once, slowing as it judders
# - the jams still hold it, and both are saves (systems/home_chase.gd)
# And on its own: dodge_sway picks the roomier side, and gives up (NAN) when
# there is no room either side.

const DT := 1.0 / 60.0

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		printerr("FAIL: ", what)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "neteja"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame
	m.set_physics_process(false)
	m.set_process(false)
	m.auto_walk = true

	var Sweeper: GDScript = load("res://entities/sweeper.gd")
	var Vehicle: GDScript = load("res://systems/chase_vehicle.gd")
	var s = Sweeper.new()
	root.add_child(s)
	s.setup(m, m.GATE_Y + 200.0, m.walk_cx, m.walk_half, 140.0)
	for j: Vector2 in m.chase_jams:
		s.jams.append(j)

	# --- the length of the street ---
	var bonks := 0
	var slowest := 1.0
	var heavy_frames := 0
	var frames := 0
	var jammed_frames := 0
	while s.front_y < m.START_Y - 200.0 and frames < 60 * 120:
		var was: float = s.drive.bonk_t
		s.advance(DT, 300.0, 0.0)
		s.global_position = Vector2(m.walk_cx, s.front_y)
		if s.drive.bonk_t > was + 0.01:
			bonks += 1
		slowest = minf(slowest, s.drive.pace())
		if s.jammed():
			jammed_frames += 1
		var body := Rect2(s.cx + s.sway - s.BODY_HALF, s.front_y + s.BODY_Y - s.BODY_HALF_LEN, s.BODY_HALF * 2.0, s.BODY_HALF_LEN * 2.0)
		for bl: Dictionary in m.bypasser_blockers:
			var id := String(bl.get("id", ""))
			if Vehicle._is(id, Vehicle.LIGHT) or Vehicle._is(id, Vehicle.FLAT):
				continue
			if body.grow(-24.0).intersects(Vehicle._rect(bl)) and not s.jammed():
				heavy_frames += 1
				break
		frames += 1
	_check(s.front_y >= m.START_Y - 200.0, "it gets the length of the street (%.0f after %.0f s)" % [s.front_y, float(frames) * DT])
	_check(bonks >= 3, "it bonks over light things on the way (%d)" % bonks)
	_check(slowest < 1.0, "and slows as it judders over them (%.2f)" % slowest)
	_check(jammed_frames > 0, "the jams still hold it")
	_check(float(heavy_frames) / float(maxi(frames, 1)) < 0.06,
		"its body is rarely on anything heavy (%.1f%% of the run)" % (100.0 * float(heavy_frames) / float(maxi(frames, 1))))

	# --- dodge_sway on its own ---
	var d = Vehicle.new()
	var keep: Array = m.bypasser_blockers.duplicate()
	m.bypasser_blockers.clear()
	m.bypasser_blockers.append({"id": "van_test", "rect": Rect2(600.0, -1000.0, 140.0, 60.0)})
	var go: float = d.dodge_sway(m, 640.0, 0.0, -1200.0, 80.0, 180.0)
	_check(not is_nan(go) and absf(go) >= 50.0, "a van in its lane: it swerves round (%.0f)" % go)
	d = Vehicle.new()
	_check(is_nan(d.dodge_sway(m, 640.0, 0.0, -2000.0, 80.0, 180.0)), "nothing ahead: no swerve")
	d = Vehicle.new()
	m.bypasser_blockers[0] = {"id": "van_test", "rect": Rect2(400.0, -1000.0, 480.0, 60.0)}
	_check(is_nan(d.dodge_sway(m, 640.0, 0.0, -1200.0, 80.0, 180.0)), "no room either side: it does not try")
	d = Vehicle.new()
	m.bypasser_blockers[0] = {"id": "bench_test", "rect": Rect2(620.0, -1000.0, 40.0, 40.0)}
	_check(is_nan(d.dodge_sway(m, 640.0, 0.0, -1200.0, 80.0, 180.0)), "a bench it does not swerve for")
	_check(d.bonk(m, Rect2(560.0, -1100.0, 160.0, 160.0), DT) and not d.bonk(m, Rect2(560.0, -1100.0, 160.0, 160.0), DT),
		"it bonks over the bench, once")
	m.bypasser_blockers.assign(keep)

	if failures.is_empty():
		print("test_chase_vehicle: %d checks, OK" % checks)
	else:
		print("test_chase_vehicle: %d checks, %d FAILED" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)
