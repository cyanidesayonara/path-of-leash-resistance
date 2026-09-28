extends SceneTree

# La Rambla's own layout (docs/LEVEL_DESIGN.md): no lawn (a traffic lane
# west of the promenade instead), stalls of every kind, sellers' blankets
# that get you shouted at, human statues that bow if you stand and watch,
# the square opening out round the pavement mosaic. The First Walk no longer
# shares the boulevard (it is El Barri's stations) and has none of this.

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
	var LevelBuild: GDScript = load("res://world/level_build.gd")
	var game: Node = root.get_node("Game")
	game.level_id = "street"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m.frozen = false
	_check(m.rambla(), "the street walk is La Rambla")
	_check(m.strip_kind_l == "road", "west of the promenade is a traffic lane, not a lawn")
	_check(m.verge_items.is_empty(), "no picnics without a lawn")
	var kinds := {}
	for k: String in m.stall_kinds:
		kinds[k] = true
	for want: String in ["kiosk", "flowers", "souvenir", "icecream", "caricature"]:
		_check(kinds.has(want), "there is a %s stall" % want)
	_check(m.stalls.size() == m.stall_kinds.size(), "every stall has a kind")
	_check(m.blankets.size() >= 3 and m.statues.size() >= 2, "blankets and statues are laid out")
	# the square opens out round the mosaic
	var mc: Vector2 = LevelBuild.RAMBLA_MOSAIC
	var at_square: Vector2 = m.walk_edges(mc.y)
	var before: Vector2 = m.walk_edges(mc.y + 600.0)
	_check(at_square.y - at_square.x > before.y - before.x + 60.0, "the promenade widens at the square")

	var dog: CharacterBody2D = m.dog
	# a blanket: step on it and the seller shouts, once until the cooldown
	var bl: Dictionary = m.blankets[0]
	dog.global_position = (bl["rect"] as Rect2).get_center()
	m._tick_rambla(0.016)
	_check(float(bl["cd"]) > 0.0, "walking across a blanket gets a shout")
	var cd0 := float(bl["cd"])
	m._tick_rambla(0.016)
	_check(float(bl["cd"]) < cd0, "and only one shout until it cools down")
	# a statue: stand and watch, and it bows (once, and it pays)
	var sp: Vector2 = m.statues[0]
	dog.global_position = sp + Vector2(0, 50)
	dog.velocity = Vector2.ZERO
	var bones0: int = m.bones
	for i in range(int(m.STATUE_WATCH * 60.0) + 5):
		m._tick_rambla(1.0 / 60.0)
	_check(float(m.statue_bow.get(0, 0.0)) > 0.0 and m.bones > bones0, "a statue bows to a dog who stands and watches")
	var bones1: int = m.bones
	for i in range(60):
		m._tick_rambla(1.0 / 60.0)
	_check(m.bones == bones1, "and not again straight away")
	# walking past does not count
	dog.global_position = m.statues[1] + Vector2(0, 50)
	dog.velocity = Vector2(0, -200)
	for i in range(120):
		m._tick_rambla(1.0 / 60.0)
	_check(float(m.statue_bow.get(1, 0.0)) <= 0.0, "a statue does not bow to a dog trotting past")
	# the whistle: the sellers near the camera bundle up, carry it off
	# (snagging the rope on the way), wait, and come back and lay it out again
	var nb: Dictionary = m.blankets[0]
	m.cam.position = Vector2(640.0, (nb["rect"] as Rect2).get_center().y)
	dog.global_position = Vector2(-3000, 0)
	m.whistle_t = 0.0
	m._tick_whistle(1.0 / 60.0)
	_check(String(nb["state"]) == "pack", "at the whistle the seller packs up")
	var saw_moving := false
	var saw_snag := false
	for i in range(int((0.6 + 3.0) * 60.0)):
		m._tick_whistle(1.0 / 60.0)
		if m.bundle_moving(nb):
			saw_moving = true
			m._refresh_pair_obstacles()
			saw_snag = saw_snag or m.leash.dynamic_obstacles.has(m.seller_at(nb))
	_check(saw_moving and saw_snag, "and carries the bundle off, a moving snag for the rope")
	dog.global_position = (nb["rect"] as Rect2).get_center()
	nb["cd"] = 0.0
	m._tick_rambla(0.0)
	_check(float(nb["cd"]) == 0.0, "no shout for walking where the blanket was")
	for i in range(int((m.BUNDLE_AWAY + 6.0) * 60.0)):
		m._tick_whistle(1.0 / 60.0)
	_check(String(nb["state"]) == "laid", "then he comes back and lays it out again")
	# the shell game: plough through it at a run and it is busted, once
	var sg: Dictionary = m.shell_game
	_check(not sg.is_empty() and not bool(sg["done"]), "there is a shell game running")
	var b0: int = m.bones
	dog.global_position = sg["pos"]
	dog.velocity = Vector2(0, -300)
	m._tick_shells(0.016)
	_check(bool(sg["done"]) and m.bones > b0, "ploughing through the shell game busts it")
	# the dropped ice cream is sticky underfoot, not ground that slows you
	var ice_ok := false
	for pt: Dictionary in m.patches:
		if String(pt["kind"]) == "icecream":
			ice_ok = m.surface_at(m.patch_centre(pt)) == m.Surfaces.S.PAVEMENT
	_check(ice_ok, "the dropped ice cream is a mess on the paving, not a surface")
	m.queue_free()
	await process_frame

	# the First Walk keeps its lawn and stays calm
	game.level_id = "tutorial"
	var t: Node2D = load("res://main.tscn").instantiate()
	root.add_child(t)
	if not t.is_node_ready():
		await t.ready
	_check(not t.rambla() and t.lvl == "barri", "the First Walk is not La Rambla (it is El Barri's stations)")
	_check(t.blankets.is_empty() and t.statues.is_empty() and t.stall_kinds.is_empty(), "and none of La Rambla's clutter")
	t.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_rambla: OK")
		quit(0)
	else:
		quit(1)
