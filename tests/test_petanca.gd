extends SceneTree

# Regression tests for El Barri signature petanca event (systems/petanca.gd,
# systems/barri.gd, main._tick_petanca):
#  1. Starts WAITING; nears pitch -> WARN for 0.8 s (telegraph contract)
#  2. Bowls along court towards jack -> SETTLED near target, clink sound
#  3. Dog boop -> BOOPED state, deflects boule, awards bones/combo
#  4. Barri has petanca; tutorial mode does not

const DT := 1.0 / 60.0

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
	var PetancaClass: GDScript = load("res://systems/petanca.gd")

	# 1. State lifecycle: WAITING -> WARN -> BOWLING -> SETTLED
	var p = PetancaClass.new()
	_check(p.state == PetancaClass.St.WAITING, "starts in WAITING state")
	_check(p.pos == PetancaClass.THROWER, "starts at thrower position")

	# Dog far away -> stays waiting
	var cue1: Dictionary = p.tick(DT, Vector2(640.0, -1000.0), Vector2.UP, Vector2(600.0, -950.0))
	_check(p.state == PetancaClass.St.WAITING and not bool(cue1["warn"]), "dog far away does not trigger warn")

	# Dog nears thrower -> triggers WARN (0.8s telegraph)
	var dog_near: Vector2 = PetancaClass.THROWER + Vector2(100.0, 150.0)
	var cue2: Dictionary = p.tick(DT, dog_near, Vector2.UP, dog_near + Vector2(0, 40))
	_check(p.state == PetancaClass.St.WARN and bool(cue2["warn"]), "nearing pitch triggers WARN with cue")

	# 0.4s into telegraph -> still WARN
	for i in range(24):
		p.tick(DT, dog_near, Vector2.UP, dog_near)
	_check(p.state == PetancaClass.St.WARN, "still in WARN at 0.4s")

	# Past 0.8s -> transitions to BOWLING
	for i in range(30):
		p.tick(DT, dog_near, Vector2.UP, dog_near)
	_check(p.state == PetancaClass.St.BOWLING, "transitions to BOWLING after 0.8s")
	_check(p.vel.length() > 50.0 and p.vel.y < 0.0, "boule moves toward jack (up/north)")

	# Rolls until settled
	var clinked := false
	for i in range(200):
		var cue: Dictionary = p.tick(DT, Vector2(640.0, -1800.0), Vector2.UP, Vector2(600.0, -1800.0))
		if bool(cue["clink"]):
			clinked = true
		if p.state == PetancaClass.St.SETTLED:
			break
	_check(p.state == PetancaClass.St.SETTLED, "boule settles near jack")
	_check(clinked, "clink cue fired when reaching jack cluster")
	_check(p.pos.distance_to(PetancaClass.TARGET_POS) < 15.0, "settles near target boule position")

	# 2. Dog boop interaction
	var p2 = PetancaClass.new()
	p2.tick(DT, dog_near, Vector2.UP, dog_near)
	# advance past warn
	for i in range(50):
		p2.tick(DT, dog_near, Vector2.UP, dog_near)
	_check(p2.state == PetancaClass.St.BOWLING, "p2 is bowling")

	# Dog runs onto pitch and collides with rolling boule
	var boop_cue: Dictionary = p2.tick(DT, p2.pos + Vector2(4.0, 4.0), Vector2.RIGHT, dog_near)
	_check(p2.state == PetancaClass.St.BOOPED and bool(boop_cue["boop"]), "dog collision triggers BOOPED state")
	_check(p2.booped, "booped flag set")

	# 3. Main scene integration
	var game: Node = root.get_node("Game")
	game.persist = false
	var sfx: Node = root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.muted = true

	game.level_id = "barri"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.petanca != null, "El Barri has petanca instance")
	m.queue_free()
	await process_frame

	# Tutorial mode has no petanca
	var m_tut: Node2D = load("res://main.tscn").instantiate()
	m_tut.tutorial_mode = true
	root.add_child(m_tut)
	if not m_tut.is_node_ready():
		await m_tut.ready
	_check(m_tut.petanca == null, "tutorial mode does not have petanca instance")
	m_tut.queue_free()
	await process_frame

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_petanca: OK")
		quit(0)
	else:
		quit(1)
