extends SceneTree

# The chase profile (systems/home_chase.gd) and what La Neteja is built from
# it: ordinary walks have no profile; La Neteja always selects its fixed
# street-sweeper profile and an oblivious human, whatever the dice drew; the
# developer hooks (--chase, --bolt, --rescue) still force their named
# behaviour; HomeChase.begin instantiates the profile's threat script; every
# walk draws exactly the random numbers it always did; and La Neteja's lane
# carries only content authored for it (no manholes, no market bins).
#
# Checkpoints and respites are the next layer (tests/test_chase_checkpoint.gd
# once it exists); this test only pins the data boundary they will read.

var HomeChase: GDScript
var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	# deferred so the autoloads are registered before main.gd is compiled
	call_deferred("_run")


func _fresh_main(level: String) -> Node2D:
	root.get_node("Game").level_id = level
	var main: Node2D = load("res://main.tscn").instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		await main.ready
	main.auto_walk = false
	main.tutorial_mode = false
	return main


func _drop(main: Node2D) -> void:
	main.queue_free()
	await process_frame


# What follows `draws` draws from this seed.
func _next_after(sd: int, draws: int) -> float:
	seed(sd)
	for i in range(draws):
		randf()
	return randf()


# A seed whose second draw (the kind selection) would have been this kind
# under the legacy table: 0.4 sweeper, 0.35 bolt, 0.25 both.
func _seed_for_kind(kind: String) -> int:
	for sd in range(2000):
		seed(sd)
		randf()
		var r := randf()
		var k := "sweeper" if r < 0.4 else ("bolt" if r < 0.75 else "both")
		if k == kind:
			return sd
	return -1


func _run() -> void:
	HomeChase = load("res://systems/home_chase.gd")
	var no_args := PackedStringArray()

	# --- the profile table ---
	_check(HomeChase.profile_for("street").is_empty(), "an ordinary walk has no chase profile")
	_check(HomeChase.profile_for("market").is_empty(), "the market has no chase profile")
	var prof: Dictionary = HomeChase.profile_for("neteja")
	_check(not prof.is_empty(), "La Neteja has a chase profile")
	_check(String(prof.get("kind", "")) == "sweeper", "its behaviour is fixed to the sweeper")
	_check(is_equal_approx(float(prof.get("speed", 0.0)), HomeChase.CHASE_SPEED), "its speed is the slow sweeper's")
	var script_ok := false
	if prof.has("script"):
		var sc: Script = prof["script"] if prof["script"] is Script else load(String(prof["script"]))
		script_ok = sc != null and sc.resource_path == "res://entities/sweeper.gd"
	_check(script_ok, "its threat script is the street sweeper")
	for key: String in ["warning", "caught_human", "caught_dog"]:
		_check(String(prof.get(key, "")).length() > 4, "its %s copy is written" % key)
	_check(prof.get("bands") is Array, "it leaves an ordered-bands list for respites and checkpoints")

	# --- ordinary play on La Neteja: always the sweeper, same draws ---
	var nm := await _fresh_main("neteja")
	_check(String(nm.lvl) == "neteja", "the test walk is La Neteja")
	var fixed := true
	var same_draws := true
	for kind: String in ["sweeper", "bolt", "both"]:
		var sd := _seed_for_kind(kind)
		_check(sd >= 0, "a seed exists whose legacy kind draw is %s" % kind)
		nm.chase_kind = "both"
		nm.chase_active = false
		nm.tofu_quest_active = true
		var expect_next := _next_after(sd, 2)
		seed(sd)
		HomeChase.roll(nm, no_args)
		fixed = fixed and bool(nm.chase_active) and String(nm.chase_kind) == "sweeper" and not bool(nm.tofu_quest_active)
		same_draws = same_draws and is_equal_approx(randf(), expect_next)
	_check(fixed, "La Neteja is always the sweeper whatever the legacy kind draw was")
	_check(same_draws, "La Neteja still draws the roll and the ignored kind selection, no more")

	# --- other walks keep the legacy draws exactly, hooks included ---
	nm.lvl = "street"
	var plain := true
	var plain_draws := true
	for sd in range(60):
		seed(sd)
		var first := randf()
		var expect_next := _next_after(sd, 1) if first >= 0.25 else _next_after(sd, 2)
		seed(sd)
		HomeChase.roll(nm, no_args)
		plain = plain and not bool(nm.chase_active)
		plain_draws = plain_draws and is_equal_approx(randf(), expect_next)
	_check(plain, "no chase rolls on another walk")
	_check(plain_draws, "another walk draws one number, and a second only when the old 25% roll did")
	var legacy_kinds := {}
	nm.chase_kind = "unset"
	for sd in range(200):
		seed(sd)
		HomeChase.roll(nm, no_args)
		legacy_kinds[String(nm.chase_kind)] = true
	_check(legacy_kinds.size() == 3, "the ignored kind draw on other walks is unchanged (%s)" % str(legacy_kinds.keys()))

	# --- the developer hooks still force their named behaviour ---
	for pair: Array in [["--chase", "sweeper"], ["--bolt", "bolt"], ["--rescue", "both"]]:
		for lv: String in ["neteja", "street"]:
			nm.lvl = lv
			nm.chase_active = false
			seed(7)
			HomeChase.roll(nm, PackedStringArray([pair[0]]))
			_check(bool(nm.chase_active) and String(nm.chase_kind) == pair[1],
				"%s forces %s on %s (got %s)" % [pair[0], pair[1], lv, nm.chase_kind])
	nm.lvl = "neteja"
	nm.auto_walk = false
	nm.tutorial_mode = true
	nm.chase_active = true
	HomeChase.roll(nm, no_args)
	_check(not nm.chase_active, "the tutorial never chases, even on La Neteja's id")
	nm.tutorial_mode = false
	await _drop(nm)

	# --- begin uses the profile's script and data ---
	var bm := await _fresh_main("neteja")
	bm.chase_active = true
	bm.chase_kind = "sweeper"
	# from the far end of the street, where the home leg starts
	bm.dog.global_position.y = -4600.0
	bm.human.global_position.y = -4600.0
	HomeChase.begin(bm)
	var sw: Node2D = bm.chase_sweeper
	_check(sw != null and sw.get_script().resource_path == "res://entities/sweeper.gd", "begin builds the profile's sweeper")
	_check(sw != null and String(sw.kind) == "sweeper" and is_equal_approx(float(sw.speed), HomeChase.CHASE_SPEED),
		"La Neteja's machine is the slow sweeper")
	_check(not bool(bm.human.panic), "your human stays oblivious")
	_check(bm.chase_jams.size() == 2 and sw.jams.size() == 2, "both dumpster respites are still wired to the machine (%d)" % sw.jams.size())
	# its catch copy is the profile's
	bm.frozen = false
	bm.msg_label.text = ""
	bm.chase_catch_t = 0.0
	sw.front_y = bm.human.global_position.y + 5.0
	bm.dog.global_position.y = bm.human.global_position.y + 400.0
	HomeChase.tick(bm, 0.0)
	HomeChase.tick(bm, HomeChase.CATCH_BEAT * 2.0)
	_check(bm.msg_label.text.get_slice("\n", 0) == String(prof.get("caught_human", "?")).get_slice("\n", 0),
		"a caught human reads the profile's copy (got '%s')" % bm.msg_label.text.get_slice("\n", 0))
	await _drop(bm)

	# a profile that names another script gets that script
	var pm := await _fresh_main("street")
	var probe := GDScript.new()
	probe.source_code = "extends \"res://entities/sweeper.gd\"\nvar probe_marker := true\n"
	probe.reload()
	var custom := {"id": "probe", "script": probe, "kind": "sweeper", "speed": 77.0,
		"warning": "PROBE", "caught_human": "PROBE HUMAN", "caught_dog": "PROBE DOG", "bands": []}
	pm.chase_active = true
	pm.chase_kind = "sweeper"
	HomeChase.begin(pm, custom)
	var psw: Node2D = pm.chase_sweeper
	_check(psw != null and "probe_marker" in psw, "begin instantiates whatever threat script the profile names")
	_check(psw != null and is_equal_approx(float(psw.speed), 77.0), "and takes the profile's speed")
	await _drop(pm)

	# forced behaviour on La Neteja still runs the named machine
	for pair: Array in [["bolt", HomeChase.CHASE_SPEED_BOLT, true], ["both", HomeChase.CHASE_SPEED_BOTH, true]]:
		var fm := await _fresh_main("neteja")
		fm.chase_active = true
		fm.chase_kind = pair[0]
		HomeChase.begin(fm)
		_check(fm.chase_sweeper != null and is_equal_approx(float(fm.chase_sweeper.speed), float(pair[1])),
			"a forced %s on La Neteja runs at its own speed" % pair[0])
		_check(bool(fm.human.panic) == bool(pair[2]), "a forced %s on La Neteja panics the owner" % pair[0])
		await _drop(fm)

	# --- content purity: La Neteja's lane holds only what it authored ---
	var lm := await _fresh_main("neteja")
	var LevelBuild: GDScript = load("res://world/level_build.gd")
	_check(lm.manholes.is_empty(), "no manhole anywhere on La Neteja")
	_check(lm.cellars.is_empty(), "no open cellar hatch on La Neteja")
	_check(lm.vans.is_empty() and lm.stalls.is_empty() and lm.tables.is_empty(), "no van, stall or terrace table on La Neteja")
	_check(lm.bins.size() >= 1, "the bag chore still has a bin to walk to")
	# the market skeleton La Neteja was cut from left bins at these depths
	var inherited := 0
	for b: Vector2 in lm.bins:
		for old_y: float in [-1400.0, -2700.0, -3300.0, -4400.0]:
			if absf(b.y - old_y) < 1.0:
				inherited += 1
	_check(inherited == 0, "no bin is left where the market skeleton put one (%d)" % inherited)
	_check(lm.bins.size() == 2, "two bins, authored for the street (%d)" % lm.bins.size())
	var dumps: Array[Vector2] = LevelBuild.neteja_dumpsters(lm)
	var clear := true
	for b: Vector2 in lm.bins:
		var e: Vector2 = lm.walk_edges(b.y)
		clear = clear and b.x > e.x - 1.0 and b.x < e.y + 1.0
		for d: Vector2 in dumps:
			clear = clear and b.distance_to(d) > 120.0
		for sp: Vector2 in lm.scooters:
			clear = clear and b.distance_to(sp) > 80.0
		for hy: Dictionary in lm.hydrants:
			clear = clear and b.distance_to(hy.pos) > 80.0
		for i in range(lm.deco_pole_count):
			clear = clear and b.distance_to(lm.poles[i]) > 80.0
	_check(clear, "every bin stands at the kerb, clear of the dumpsters, scooters, hydrants and lampposts")
	_check(lm.nearest_bin(Vector2(640.0, -300.0)) in lm.bins, "the owner can find a bin to bag at")
	await _drop(lm)

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("CHASE WALK OK")
		quit(0)
	else:
		print("CHASE WALK FAIL")
		quit(1)
