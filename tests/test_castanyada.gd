extends SceneTree

# La Castanyada is its own night festival (docs/LEVEL_DESIGN.md): an
# old-town street opening into a plaça; the chestnut roaster in the middle of
# it, solid, with the owner walking round it; a stage with the band on it;
# festival stalls (chestnuts, panellets, sweet potatoes, sweets); lantern
# strings drawn over everyone; chocolate underfoot; always after dark.

var LevelBuild: GDScript
var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	LevelBuild = load("res://world/level_build.gd")
	var game: Node = root.get_node("Game")
	game.level_id = "spook"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	var pc: Vector2 = LevelBuild.CAST_PLACA
	var street: Vector2 = m.walk_edges(-900.0)
	var placa: Vector2 = m.walk_edges(pc.y)
	_check(placa.y - placa.x > (street.y - street.x) + 250.0, "the street opens into the plaça")
	_check(game.night, "the festival is after dark")
	var kinds := {}
	for k: String in m.stall_kinds:
		kinds[k] = true
	_check(kinds.has("castanyes") and kinds.has("panellets") and kinds.has("moniatos"), "chestnut, panellet and sweet potato stalls")
	_check(m.candy.size() >= 8, "chocolate underfoot to steer past (%d)" % m.candy.size())
	_check(m.islands.size() == 1, "the owner walks round the roaster")
	_check(m.performers.size() >= 2, "the band on the stage")
	var over: Array = m.get_children().filter(func(c: Node) -> bool: return c.get_script() == load("res://world/overheadlayer.gd"))
	_check(over.size() == 1 and (over[0] as Node2D).z_index > m.dog.z_index, "the lantern strings hang over everyone")
	# the roaster is solid
	var dog: CharacterBody2D = m.dog
	dog.collision_mask = 1
	var rc: Vector2 = LevelBuild.CAST_ROASTER_AT
	dog.global_position = rc + Vector2(0.0, 90.0)
	for i in range(40):
		dog.velocity = Vector2(0, -400)
		dog.move_and_slide()
	var rr := Rect2(rc - LevelBuild.CAST_ROASTER * 0.5, LevelBuild.CAST_ROASTER)
	_check(not rr.grow(-4.0).has_point(dog.global_position), "the roaster stops the dog")
	# so is the stage
	var st: Rect2 = LevelBuild.castanyada_stage(m)
	dog.global_position = Vector2(st.end.x + 60.0, st.get_center().y)
	for i in range(40):
		dog.velocity = Vector2(-400, 0)
		dog.move_and_slide()
	_check(not st.grow(-4.0).has_point(dog.global_position), "the stage stops the dog")
	_check(m.hydrants.size() >= 4, "enough chestnut sacks to mark")
	# the festival yard past the gate is paved wall to wall, soft only in its
	# tree pits, and its trees stand there without forest roots
	var S: Dictionary = m.Surfaces.S
	var fr: Rect2 = m._freedom_rect()
	var flags := Vector2(fr.position.x + 90.0, m.GATE_Y - 260.0)
	for pp: Dictionary in m.park_props:
		if flags.distance_to(pp.pos) < 40.0:
			flags += Vector2(0.0, -90.0)
	_check(m.surface_at(flags) == S.PAVEMENT, "the yard's flags off the dance floor handle as paving (%s)" % flags)
	var pits: Array[Vector2] = m.trees
	_check(not pits.is_empty() and m.surface_at(pits[0] + Vector2(8.0, 0.0)) == S.GRASS, "a tree pit there is soft")
	_check(m.walk_mod.has_method("draw_grove"), "the yard's trees stand in their pits without forest roots")
	var street_l: Array[Vector3] = m.street_night_lights()
	var lights: Array[Vector3] = m.night_lights()
	_check(lights.size() == street_l.size() + m.walk_mod.YARD_LAMPS.size() * 2,
		"the street's %d lamps and the yard's wall lamps (%d in all)" % [street_l.size(), lights.size()])
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_castanyada: OK")
		quit(0)
	else:
		quit(1)
