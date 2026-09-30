extends SceneTree

# Over the gate into the off-leash area, a walk with a material spells where
# it goes and OFF LEASH in the same loose pieces as its name (main.build_signs),
# on the far side of the gate, inside the gate's width; a walk without one
# keeps the gate's painted name.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _gate_signs(lvl: String) -> Array:
	root.get_node("Game").level_id = lvl
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	var out := []
	for sg: Dictionary in m.signs:
		if float(sg.bottom) < m.GATE_Y:
			out.append({"txt": String(sg.txt), "sign": sg, "gate_text": m.gate_text,
				"l": m.gate_l, "r": m.gate_r, "mat": String(sg.mat)})
	m.queue_free()
	await process_frame
	return out


func _run() -> void:
	for lvl: String in ["street", "site", "guell", "beach"]:
		var gs: Array = await _gate_signs(lvl)
		var txts: Array = gs.map(func(g: Dictionary) -> String: return g.txt)
		_check(gs.size() == 2, "%s: two signs over the gate (%s)" % [lvl, txts])
		if gs.size() != 2:
			continue
		_check(txts.has("OFF LEASH") and txts.has(gs[0].gate_text), "%s: where it goes, and OFF LEASH" % lvl)
		var inside := true
		for g: Dictionary in gs:
			for ln: Array in g.sign.lines:
				for p: Vector2 in ln:
					inside = inside and p.x > float(g.l) - 20.0 and p.x < float(g.r) + 20.0
		_check(inside, "%s: within the gate's width" % lvl)
	var none: Array = await _gate_signs("oldtown")
	_check(none.is_empty(), "a walk without a material keeps the gate's painted name")
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_gate_sign: OK")
		quit(0)
	else:
		quit(1)
