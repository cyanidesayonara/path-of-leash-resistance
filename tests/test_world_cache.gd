extends SceneTree

# The world pass's cached sections (main._draw_section) and what they lean
# on: a batch with no canvas records its shapes and, in their place, the
# calls only a canvas can make, and a replay makes them again in order; the
# animation clock counts its reads; a cached section replays exactly what a
# live draw of the same band makes, is recorded again once the camera has
# travelled SECTION_BAND or the weather or its own key changes, and a walk
# whose cross-section reads the clock draws it live.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	create_timer(120.0).timeout.connect(func():
		print("FAIL: test watchdog timeout")
		quit(1)
	)
	call_deferred("_run")


func _load(lvl: String) -> Node2D:
	var game = root.get_node("Game")
	game.level_id = lvl
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	return m


# the cached path, run outside a draw: everything goes to a recording batch
func _cached(m: Node2D) -> ShapeBatch:
	var out := ShapeBatch.new()
	m._wc = out
	var y: float = m.cam.position.y
	var top: float = m.GATE_Y - 800.0
	var bottom: float = m.START_Y + 560.0
	var ctop: float = m.GATE_Y - 40.0
	m._draw_section("cross", [], y - 440.0, y + 440.0, func(t: float, b: float) -> void: m._draw_cross_section(top, bottom, ctop, t, b))
	return out



func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true

	# recording
	var rec := ShapeBatch.new()
	rec.circle(Vector2(1, 2), 4.0, Color.RED)
	rec.flush()
	_check(rec._points.size() == ShapeBatch.SEGMENTS * 3, "a recording keeps its shapes through a flush")
	var buf := PackedVector2Array([Vector2(1, 1)])
	rec.draw_arc(Vector2.ZERO, 5.0, 0.0, TAU, 8, Color.RED, 1.0)
	rec.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(4, 0), Vector2(0, 4)]), Color.BLUE, buf)
	buf[0] = Vector2(9, 9)
	rec.rect(Rect2(0, 0, 2, 2), Color.GREEN)
	_check(rec._ops.size() == 2 and rec._ops[0][0] == ShapeBatch.SEGMENTS * 3 and rec._ops[0][1] == "draw_arc", "an arc is recorded in its place among the shapes")
	_check((rec._ops[1][2][2] as PackedVector2Array)[0] == Vector2(1, 1), "a recorded call keeps its arguments as they were, not a refilled buffer")
	var into := ShapeBatch.new()
	rec.append_to(into)
	_check(into._ops.size() == 2 and into._points.size() == rec._points.size(), "a replay into another recording makes the same calls and shapes")
	_check(into._ops[1][0] == ShapeBatch.SEGMENTS * 3, "and keeps the calls in their place")
	var r0 := AnimClock.reads
	AnimClock.msec()
	_check(AnimClock.reads == r0 + 1, "the clock counts a read")

	# a cached walk
	var m := await _load("park")
	var first := _cached(m)
	var sc = m._sections["cross"]
	_check(not sc.live and sc.rec != null, "park's cross-section is cached")
	var live := ShapeBatch.new()
	m._wc = live
	var y: float = sc.cam
	m._draw_cross_section(m.GATE_Y - 800.0, m.START_Y + 560.0, m.GATE_Y - 40.0, y - 440.0 - m.SECTION_BAND, y + 440.0 + m.SECTION_BAND)
	_check(first._points == live._points and first._colors == live._colors, "the replay is exactly a live draw of the recorded band")
	var kept: ShapeBatch = sc.rec
	m.cam.position.y -= m.SECTION_BAND * 0.5
	_cached(m)
	_check(sc.rec == kept, "a short scroll replays the recording")
	m.cam.position.y -= m.SECTION_BAND
	_cached(m)
	_check(sc.rec != kept, "past XS_BAND it records again")
	kept = sc.rec
	var w: String = game.weather
	game.weather = "snow" if w != "snow" else "clear"
	_cached(m)
	_check(sc.rec != kept, "a change of weather records again")
	game.weather = w
	# a section's own key: furniture records again when it changes
	var fsc = m._sections.get("furniture")
	m._wc = ShapeBatch.new()
	m._draw_section("furniture", [0.0], m.cam.position.y - 440.0, m.cam.position.y + 440.0, m._draw_furniture)
	fsc = m._sections["furniture"]
	kept = fsc.rec
	m._draw_section("furniture", [0.5], m.cam.position.y - 440.0, m.cam.position.y + 440.0, m._draw_furniture)
	_check(fsc.rec != kept and not fsc.live, "furniture records again when its key changes")
	m.queue_free()
	await process_frame

	# a walk whose cross-section animates
	m = await _load("llevant")
	_cached(m)
	_check(m._sections["cross"].live and m._sections["cross"].rec == null, "Llevant's cross-section reads the clock, so it is drawn live")
	m.queue_free()
	await process_frame

	if failures.is_empty():
		print("test_world_cache: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_world_cache: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)
