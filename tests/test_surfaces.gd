extends SceneTree

# The surface registry (surfaces.gd) and the one function that decides which
# surface you are on (main.surface_at).
#
# Two things worth guarding. First, that the registry is a TRADE and not a
# list of debuffs: a surface that is worse in every column is a wall with
# extra steps, and the verge only earns its place if going there buys you
# something. Second, that surface_at agrees with the geometry the level was
# actually built from - the old code re-derived "am I on sand" from a bare
# x threshold in one place and a Rect2 list in another, and this is the file
# that stops that drifting apart again.
#
#   godot --headless --path . --script res://tests/test_surfaces.gd

const Surfaces := preload("res://surfaces.gd")

var failures: Array[String] = []
var checks := 0


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures.append(msg)
		print("  FAIL  %s" % msg)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_registry()
	await _test_resolution()
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("SURFACES OK")
		quit(0)
	else:
		print("SURFACES FAIL")
		quit(1)


func _test_registry() -> void:
	print("\n--- the table itself ---")
	var kinds := [Surfaces.S.PAVEMENT, Surfaces.S.GRASS, Surfaces.S.SAND,
		Surfaces.S.MUD, Surfaces.S.WATER]
	for s: int in kinds:
		var f: Dictionary = Surfaces.feel(s)
		var n: String = String(f["name"])
		for key: String in ["top", "grip", "scent", "marks", "name"]:
			_check(f.has(key), "%s declares %s" % [n, key])
		# nothing may be so slow or so slippery that the walk stops working
		_check(float(f["top"]) >= 0.5 and float(f["top"]) <= 1.2,
			"%s top stays sane (%.2f)" % [n, float(f["top"])])
		_check(float(f["grip"]) >= 0.6 and float(f["grip"]) <= 1.3,
			"%s grip stays sane (%.2f)" % [n, float(f["grip"])])
		_check(float(f["scent"]) >= 0.3, "%s never fully blinds the nose" % n)

	# pavement is the baseline everything else is expressed against, so it
	# has to be exactly 1 or the numbers above stop meaning anything
	var pave: Dictionary = Surfaces.feel(Surfaces.S.PAVEMENT)
	_check(is_equal_approx(float(pave["top"]), 1.0), "pavement top is the 1.0 baseline")
	_check(is_equal_approx(float(pave["grip"]), 1.0), "pavement grip is the 1.0 baseline")
	_check(is_equal_approx(float(pave["scent"]), 1.0), "pavement scent is the 1.0 baseline")

	# THE TRADE, and it applies to DETOURS specifically: somewhere you choose
	# to step off the main way has to pay for what it costs, or it is just a
	# worse pavement and nobody will ever go there - which was the whole
	# complaint about the sides of the path. Terrain the level simply IS
	# (beach sand, the sea) is exempt, because the beach is not a detour from
	# itself; those only have to stay playable, checked above.
	for s: int in kinds:
		var f: Dictionary = Surfaces.feel(s)
		if not bool(f["detour"]):
			continue
		var pays := (float(f["top"]) > 1.0 or float(f["grip"]) > 1.0
			or float(f["scent"]) > 1.0 or bool(f["washes"]))
		_check(pays, "%s pays for what it costs (top %.2f grip %.2f scent %.2f)" % [
			String(f["name"]), float(f["top"]), float(f["grip"]), float(f["scent"])])
	# and every surface that is worse in every single column must at least be
	# giving something back that is not a number, or it is a trap
	for s: int in kinds:
		var f2: Dictionary = Surfaces.feel(s)
		if float(f2["top"]) < 1.0 and float(f2["grip"]) < 1.0 and float(f2["scent"]) < 1.0:
			_check(bool(f2["washes"]) or not bool(f2["detour"]),
				"%s is all cost, so it had better not be an optional detour" % String(f2["name"]))
	# water is the case that forced the distinction: it is worse at everything,
	# and what it pays is getting the mud back off her
	_check(bool(Surfaces.feel(Surfaces.S.WATER)["washes"]), "a swim cleans her paws")

	# grass is the worked example and the reason this registry exists: the
	# verge should be somewhere you go on purpose
	var g: Dictionary = Surfaces.feel(Surfaces.S.GRASS)
	_check(float(g["top"]) < 1.0, "grass is slower than pavement")
	_check(float(g["grip"]) > 1.0, "...but grips better")
	_check(float(g["scent"]) > 1.15, "...and holds a lot more smell")
	# water is the one place a nose genuinely stops working
	_check(float(Surfaces.feel(Surfaces.S.WATER)["scent"]) < 0.6, "smell does not survive water")


func _test_resolution() -> void:
	print("\n--- what the ground actually is, per level ---")
	var game = root.get_node("Game")
	game.menu_step = 2

	# the beach: sand to the west, sea beyond it, pavement on the walk
	game.level_id = "beach"
	var beach = load("res://main.tscn").instantiate()
	root.add_child(beach)
	if not beach.is_node_ready():
		await beach.ready
	beach.frozen = true
	_check(beach.surface_at(Vector2(beach.walk_cx, -900.0)) == Surfaces.S.PAVEMENT,
		"the middle of the walk is pavement")
	_check(beach.surface_at(Vector2(300.0, -900.0)) == Surfaces.S.SAND,
		"west of the promenade is sand")
	# every water rect really reads as water, however it was built
	var wet := 0
	for w: Rect2 in beach.water:
		if beach.surface_at(w.get_center()) == Surfaces.S.WATER:
			wet += 1
	_check(wet == beach.water.size(),
		"all %d water rects read as water (%d did)" % [beach.water.size(), wet])
	beach.queue_free()
	await process_frame

	# the boulevard: the green either side of the walk is grass now, which is
	# the whole point of the exercise
	game.level_id = "street"
	var street = load("res://main.tscn").instantiate()
	root.add_child(street)
	if not street.is_node_ready():
		await street.ready
	street.frozen = true
	_check(street.surface_at(Vector2(street.walk_cx, -1200.0)) == Surfaces.S.PAVEMENT,
		"the walk itself is pavement")
	_check(street.surface_at(Vector2(street.sw_l - 60.0, -1200.0)) == Surfaces.S.GRASS,
		"the verge west of the walk is grass")
	# the carriageway is hard ground, not verge - a road is not a lawn
	_check(street.surface_at(Vector2((street.BLANE_L + street.BLANE_R) * 0.5, -1200.0))
		== Surfaces.S.PAVEMENT, "the bike lane is hard ground, not grass")

	# and the dog is actually told about it, rather than the registry sitting
	# there unread
	street.dog.global_position = Vector2(street.sw_l - 60.0, -1200.0)
	street._offpath(0.016)
	_check(street.dog.surface == Surfaces.S.GRASS, "the dog is told it is on grass")
	street.dog.global_position = Vector2(street.walk_cx, -1200.0)
	street._offpath(0.016)
	_check(street.dog.surface == Surfaces.S.PAVEMENT, "...and told when it is back on the walk")
	street.queue_free()
	await process_frame
