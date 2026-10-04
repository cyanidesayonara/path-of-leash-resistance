extends SceneTree

# The off-leash space, fixed: a ball Brutus takes is replaced, a bone taken
# back off him stays hers, he goes when the walk turns for home, nobody spawns
# in the dog beach's sea, the bottom fence holds either side of the gate, the
# trough says when she has had a proper drink, logs can be sniffed, and the
# banner says what else there is to do once fetch is over.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _open(lvl: String) -> Node2D:
	root.get_node("Game").level_id = lvl
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	m.dog.global_position = Vector2(640.0, m.GATE_Y - 300.0)
	m.human.global_position = Vector2(640.0, m.GATE_Y - 60.0)
	m.leash.resnap()
	m._enter_freedom()
	await physics_frame
	return m


func _close(m: Node2D) -> void:
	m.queue_free()
	await process_frame


func _run() -> void:
	# --- Brutus and the ball, and the bone
	var m: Node2D = await _open("park")
	var rv := Node2D.new()
	rv.set_script(load("res://entities/rival.gd"))
	rv.position = Vector2(300.0, m.GATE_Y - 300.0)
	m.add_child(rv)
	rv.setup(m, m.dog, m._pair_park_bounds())
	m.rival = rv
	m.ball.queue_free()
	await process_frame
	m.on_rival_drop(rv.position, "ball", "he dropped it", false)
	_check(is_instance_valid(m.ball), "a ball Brutus made off with is replaced")
	var dig: Dictionary = {}
	for pp in m.park_props:
		if String(pp.kind) == "dig":
			dig = pp
			break
	dig.done = true
	dig["looted"] = true
	m.on_rival_drop(rv.position, "bone", "got it back", true)
	_check(not bool(dig.get("looted", false)) and bool(dig.get("kept", false)), "a bone taken back is kept")
	m.ball.queue_free()
	await process_frame
	var found = rv._find_loot()
	_check(found == null or String(found.kind) != "bone" or found["prop"] != dig, "Brutus cannot take a kept bone again")
	m.dog.global_position = Vector2(640.0, m.GATE_Y + 60.0)
	m._enter_home()
	await process_frame
	_check(not is_instance_valid(rv) or rv.is_queued_for_deletion(), "Brutus goes when the walk turns for home")

	# --- logs sniff, the trough speaks, the banner hints
	var lg := {"pos": Vector2(400.0, m.GATE_Y - 400.0), "kind": "log", "done": false, "prog": 0.0}
	var tr := {"pos": Vector2(800.0, m.GATE_Y - 400.0), "kind": "trough", "done": false, "prog": 0.0}
	await _close(m)
	m = await _open("park")
	m.park_props.append(lg)
	m.park_props.append(tr)
	m.dog.auto = true
	m.dog.auto_move = Vector2.ZERO
	m.dog.global_position = lg.pos
	for f in range(60):
		m.dog.global_position = lg.pos
		m.dog.velocity = Vector2.ZERO
		await physics_frame
	_check(bool(lg.done), "a log can be sniffed")
	var b0: int = m.bones
	for f in range(150):
		m.dog.global_position = tr.pos
		m.dog.velocity = Vector2.ZERO
		await physics_frame
	_check(m.drink_praised and m.drunk_amount >= m.DRINK_ENOUGH, "a long drink at the trough is noticed")
	_check(m.bones >= b0 + 2, "and rewarded")
	m.romp_done = true
	var seen := {}
	for t in range(8):
		m.elapsed = float(t) * 4.0
		seen[m._freedom_hint()] = true
	_check(seen.has("BACK OUT THROUGH THE GATE, THEN HOME") and seen.size() >= 2, "after fetch the banner suggests other things to do")
	m.romp_done = false
	m.dog.global_position = Vector2(640.0, m.GATE_Y - 40.0)
	m.dog.velocity = Vector2(0.0, 120.0)
	m.freedom_at = m.elapsed
	m._update_hud()
	_check(not String(m.hud_status).begins_with("LEAVING ALREADY"), "no leaving warning the moment she arrives")
	m.freedom_at = m.elapsed - 5.0
	m._update_hud()
	_check(String(m.hud_status).begins_with("LEAVING ALREADY"), "heading out mid-fetch is flagged")
	m.dog.velocity = Vector2.ZERO
	m._update_hud()
	_check(not String(m.hud_status).begins_with("LEAVING ALREADY"), "standing by the gate is not leaving")

	# --- the bottom fence holds either side of the gate
	m.dog.auto_move = Vector2.DOWN
	m.dog.global_position = Vector2(200.0, m.GATE_Y - 120.0)
	for f in range(120):
		await physics_frame
	_check(m.dog.global_position.y < m.GATE_Y - 10.0, "the bottom fence holds beside the gate (%d)" % int(m.dog.global_position.y))
	m.dog.auto = false
	await _close(m)

	# --- the dog beach: nobody in the sea
	m = await _open("beach")
	var dry: float = m.BEACH_SEA_R
	var dry_ok := true
	for fd in m.get_tree().get_nodes_in_group("freedogs"):
		dry_ok = dry_ok and (fd as Node2D).global_position.x > dry
	for i in range(m.PAIR_PARK_SPOTS.size()):
		dry_ok = dry_ok and m.pair_park_spot(i).x > dry
	_check(dry_ok, "free dogs and parked pairs start on the sand")
	await _close(m)

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_freedom_fixes: OK")
		quit(0)
	else:
		quit(1)
