extends SceneTree

# Every chase that is a line on foot (systems/chase_squad.gd), run the length
# of its own walk: L'Aeroport's security, El Veterinari's staff, Els
# Senglars' boars, Festa de Gràcia's devils and their dragon.
# - nobody in the line is ever inside a solid (the walk's bypasser blockers),
#   except clambering over one after a long hold-up, and that is rare
# - the line still gets the length of the walk
# - the walk's jams hold it, and every jam is a save (home_chase bands)
# - the boars run through what she left; the others skid in it

const DT := 1.0 / 60.0
const WALKS := [
	["aeroport", "res://entities/aeroport_threat.gd", true],
	["vet", "res://entities/vet_threat.gd", true],
	["boars", "res://entities/boar_threat.gd", false],
	["gracia", "res://entities/correfoc_threat.gd", true],
]

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		printerr("FAIL: ", what)


func _initialize() -> void:
	call_deferred("_run")


func _inside(m: Node2D, p: Vector2, slack: float) -> String:
	for bl: Dictionary in m.bypasser_blockers:
		if bl.has("rect"):
			if (bl["rect"] as Rect2).grow(-slack).has_point(p):
				return String(bl["id"])
		elif p.distance_to(bl["center"]) < float(bl["radius"]) - slack:
			return String(bl["id"])
	return ""


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	var HC: GDScript = load("res://systems/home_chase.gd")
	for w: Array in WALKS:
		var lv: String = w[0]
		game.level_id = lv
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

		var bands: Array = HC.profile_for(lv).get("bands", [])
		var saves := 0
		for bd: Dictionary in bands:
			if bool(bd.get("checkpoint", false)):
				saves += 1
		_check(bands.size() >= 2 and saves == bands.size(), "%s: every respite is a save (%d of %d)" % [lv, saves, bands.size()])
		_check(m.chase_jams.size() == bands.size(), "%s: a jam placed for every respite (%d for %d)" % [lv, m.chase_jams.size(), bands.size()])

		var t: Node2D = load(String(w[1])).new()
		root.add_child(t)
		t.setup(m, m.GATE_Y + 200.0, m.walk_cx, m.walk_half, 136.0)
		for j: Vector2 in m.chase_jams:
			t.jams.append(j)
		var worst := ""
		var jammed := 0
		var frames := 0
		var climbs := 0
		while t.front_y < m.START_Y - 200.0 and frames < 60 * 120:
			t.advance(DT, 300.0, 0.0)
			t.global_position = Vector2(m.walk_cx, t.front_y)
			if t.jammed():
				jammed += 1
			for i in range(t.squad.members.size()):
				if t.squad.clambering(i):
					climbs += 1
					continue
				var p: Vector2 = t.squad.members[i]["pos"]
				var hit := _inside(m, p, 2.0)
				if hit != "" and worst == "":
					worst = "%s at %s" % [hit, p]
			frames += 1
		_check(worst == "", "%s: nobody in the line inside a solid (%s)" % [lv, worst])
		_check(t.front_y >= m.START_Y - 200.0, "%s: the line gets the length of the walk (%.0f after %.0f s)" % [lv, t.front_y, float(frames) * DT])
		_check(jammed > 0, "%s: the jams hold it" % lv)
		_check(float(climbs) / 60.0 / 0.5 <= 3.0, "%s: clambering over things is rare (%d climbs)" % [lv, int(float(climbs) / 30.0)])

		# what she left lying, in the middle of the line's way
		t.setup(m, -2600.0, m.walk_cx, m.walk_half, 136.0)
		t.jams.clear()
		m.poop_state = 2
		m.bag_pending = true
		m.business_spot = Vector2(t.squad.members[t.squad.members.size() / 2]["slot"] + m.walk_cx, -2500.0)
		var slipped := false
		for k in range(150):
			t.advance(DT, 300.0, 0.0)
			for i in range(t.squad.members.size()):
				if t.squad.slipping(i):
					slipped = true
		_check(slipped == bool(w[2]), "%s: %s" % [lv, "they skid in what she left" if w[2] else "boars run through what she left"])
		m.bag_pending = false

		t.queue_free()
		m.queue_free()
		await physics_frame

	if failures.is_empty():
		print("test_chase_squad_walks: %d checks, OK" % checks)
	else:
		print("test_chase_squad_walks: %d checks, %d FAILED" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)
