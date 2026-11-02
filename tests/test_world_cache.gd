extends SceneTree

# The cached cross-section (main._draw_cross_section_cached) and what it
# leans on: a batch with no canvas records instead of drawing, and notes
# anything it cannot hold; the animation clock counts its reads; a cached
# walk replays exactly what a live draw of the same band makes, re-records
# once the camera has travelled XS_BAND or the weather changes, and a walk
# whose cross-section reads the clock is drawn live.

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
	m._draw_cross_section_cached(m.GATE_Y - 800.0, m.START_Y + 560.0, m.GATE_Y - 40.0, y - 440.0, y + 440.0)
	return out


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true

	# recording
	var rec := ShapeBatch.new()
	rec.circle(Vector2(1, 2), 4.0, Color.RED)
	rec.flush()
	_check(rec._points.size() == ShapeBatch.SEGMENTS * 3 and not rec.missed, "a recording keeps its shapes through a flush")
	rec.draw_arc(Vector2.ZERO, 5.0, 0.0, TAU, 8, Color.RED, 1.0)
	_check(rec.missed, "an arc, which a batch cannot hold, is noted, not drawn")
	var r0 := AnimClock.reads
	AnimClock.msec()
	_check(AnimClock.reads == r0 + 1, "the clock counts a read")

	# a cached walk
	var m := await _load("park")
	var first := _cached(m)
	_check(not m._xs_live and m._xs_rec != null, "park's cross-section is cached")
	var live := ShapeBatch.new()
	m._wc = live
	var y: float = m._xs_cam
	m._draw_cross_section(m.GATE_Y - 800.0, m.START_Y + 560.0, m.GATE_Y - 40.0, y - 440.0 - m.XS_BAND, y + 440.0 + m.XS_BAND)
	_check(first._points == live._points and first._colors == live._colors, "the replay is exactly a live draw of the recorded band")
	var kept: ShapeBatch = m._xs_rec
	m.cam.position.y -= m.XS_BAND * 0.5
	_cached(m)
	_check(m._xs_rec == kept, "a short scroll replays the recording")
	m.cam.position.y -= m.XS_BAND
	_cached(m)
	_check(m._xs_rec != kept, "past XS_BAND it records again")
	kept = m._xs_rec
	var w: String = game.weather
	game.weather = "snow" if w != "snow" else "clear"
	_cached(m)
	_check(m._xs_rec != kept, "a change of weather records again")
	game.weather = w
	m.queue_free()
	await process_frame

	# a walk whose cross-section animates
	m = await _load("llevant")
	_cached(m)
	_check(m._xs_live and m._xs_rec == null, "Llevant's cross-section reads the clock, so it is drawn live")
	m.queue_free()
	await process_frame

	if failures.is_empty():
		print("test_world_cache: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_world_cache: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)
