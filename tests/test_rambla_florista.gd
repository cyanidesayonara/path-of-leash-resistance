extends SceneTree

const Florista := preload("res://systems/florista.gd")

# Regression test for La Rambla (street, Walk 2) Flower Seller ("La Florista") live event.
# Tests 0.8s warning telegraph ("Flors fresques de la Rambla!"), eastward crossing walk across
# the central promenade at y = -2980.0, cut red rose drop and dog snatch trick,
# distracted human bump hazard, florista boop trick, startle bark trick,
# near-miss dodge save ("rambla dodge! +2"), autowalk safety clearance, and clean reset.

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
	var game: Node = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "street"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.florista != null, "florista instantiated for street walk")
	var f: Florista = m.florista

	# 1. Initial idle state
	_check(f.state == Florista.State.IDLE, "starts in IDLE state")
	_check(not f.triggered, "starts untriggered")
	_check(f.pos == Florista.START_POS, "positioned at START_POS")

	# 2. Distant approach does not trigger
	var far_dog := Vector2(640.0, -2500.0)
	var far_human := Vector2(640.0, -2450.0)
	var out1: Dictionary = f.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(not bool(out1["warn"]), "does not trigger when south of trigger line")
	_check(f.state == Florista.State.IDLE, "remains IDLE when south of trigger line")

	# 3. Crossing trigger line triggers 0.8s warning telegraph
	var near_dog := Vector2(640.0, -2680.0)
	var near_human := Vector2(640.0, -2665.0)
	var out2: Dictionary = f.tick(0.016, near_dog, Vector2.ZERO, near_human)
	_check(bool(out2["warn"]), "triggers 0.8s warning telegraph")
	_check(f.state == Florista.State.TELEGRAPH, "transitions to TELEGRAPH state")
	_check(f.timer < 0.1, "timer initialized at 0.0s")

	# 4. Remains in TELEGRAPH during warning window
	f.tick(0.4, near_dog, Vector2.ZERO, near_human)
	_check(f.state == Florista.State.TELEGRAPH, "remains in TELEGRAPH at t=0.4s")
	_check(f.pos == Florista.START_POS, "florista remains at start during telegraph")

	# 5. Warning completes -> transitions to WALKING
	f.tick(0.45, near_dog, Vector2.ZERO, near_human)
	_check(f.state == Florista.State.WALKING, "transitions to WALKING state after 0.8s")
	f.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(f.pos.x > Florista.START_POS.x, "florista begins walking east across promenade")

	# 6. Walks across promenade and drops a red rose
	for step in range(35):
		f.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(f.rose_dropped, "rose dropped as florista crosses center promenade")
	# Florist walks further ahead so dog can interact with rose and florist separately
	for step in range(5):
		f.tick(0.05, near_dog, Vector2.ZERO, near_human)

	# 7. Dog snatch trick on dropped rose
	var dog_at_rose := f.rose_pos + Vector2(2.0, 2.0)
	var out5: Dictionary = f.tick(0.02, dog_at_rose, Vector2.ZERO, far_human)
	_check(bool(out5["snatch"]), "dog snatching rose awards rose snatch trick")
	_check(f.rose_snatched, "rose_snatched flag set")
	var out5b: Dictionary = f.tick(0.02, dog_at_rose, Vector2.ZERO, far_human)
	_check(not bool(out5b["snatch"]), "rose snatch does not award twice")

	# 8. Bark trick on florist
	_check(not f.barked, "barked starts false")
	var bark_dog := f.pos + Vector2(40.0, 0.0)
	var bark_ok := f.on_bark(bark_dog)
	_check(bark_ok, "barking near florist triggers bark trick")
	_check(f.barked, "barked flag set")
	_check(f.wobble_t > 0.0, "wobble_t set upon bark")
	_check(not f.on_bark(bark_dog), "bark trick does not trigger twice")

	# 9. Direct boop trick
	_check(not f.booped, "booped starts false")
	var boop_dog := f.pos + Vector2(10.0, 0.0)
	var out_boop: Dictionary = f.tick(0.016, boop_dog, Vector2.ZERO, far_human)
	_check(bool(out_boop["boop"]), "dog booping florist awards boop trick")
	_check(f.booped, "booped flag set")

	# 10. Distracted human collision triggers bump hazard
	var hazard_f := Florista.new()
	hazard_f.triggered = true
	hazard_f.state = Florista.State.WALKING
	hazard_f.pos = Vector2(640.0, Florista.CROSSING_Y)
	var bump_human := hazard_f.pos + Vector2(15.0, 0.0)
	var out_hit: Dictionary = hazard_f.tick(0.016, Vector2.ZERO, Vector2.ZERO, bump_human)
	_check(bool(out_hit["bump"]), "distracted human collision triggers bump hazard")
	_check(hazard_f.human_hit, "human_hit flag set")

	# 11. Near-miss dodge: stepping close and clearing without getting hit
	var dodge_f := Florista.new()
	dodge_f.triggered = true
	dodge_f.state = Florista.State.WALKING
	dodge_f.pos = Vector2(640.0, Florista.CROSSING_Y)
	# Standing far away is not a save
	var far_line := Vector2(640.0, Florista.CROSSING_Y - 120.0)
	var out_far: Dictionary = dodge_f.tick(0.016, Vector2.ZERO, Vector2.ZERO, far_line)
	_check(not bool(out_far["dodge"]), "ordinary line clear of threat is not a save")
	# Moving inside threat radius
	var near_dodge_human := dodge_f.pos + Vector2(45.0, 0.0)
	var out_threat: Dictionary = dodge_f.tick(0.016, Vector2.ZERO, Vector2.ZERO, near_dodge_human)
	_check(not bool(out_threat["dodge"]), "inside threat is not yet a save")
	_check(dodge_f.threatened, "threatened flag armed")
	# Moving clear safely
	var clear_human := dodge_f.pos + Vector2(90.0, 0.0)
	var out_dodge: Dictionary = dodge_f.tick(0.016, Vector2.ZERO, Vector2.ZERO, clear_human)
	_check(bool(out_dodge["dodge"]), "clearing threat safely awards rambla dodge save")
	_check(dodge_f.dodged, "dodged flag set")

	# 12. Runs to END_POS and settles
	for i in range(120):
		dodge_f.tick(0.05, Vector2.ZERO, Vector2.ZERO, clear_human)
	_check(dodge_f.state == Florista.State.SETTLED, "settles after crossing promenade")
	_check(dodge_f.pos == Florista.END_POS, "positioned at END_POS when settled")

	# 13. Autowalk safety: autowalk pair clears crossing safely
	var sim_f := Florista.new()
	var auto_human := Vector2(640.0, -2650.0)
	var auto_dog := Vector2(640.0, -2680.0)
	var auto_hit := false
	for frame in range(400):
		auto_human.y -= 125.0 * 0.016
		auto_dog.y -= 125.0 * 0.016
		var out_auto: Dictionary = sim_f.tick(0.016, auto_dog, Vector2.UP * 125.0, auto_human)
		if bool(out_auto["bump"]):
			auto_hit = true
			break
		if auto_human.y < Florista.CROSSING_Y - 50.0:
			break
	_check(not auto_hit, "autowalk completes crossing safely without bump")

	# 14. Reset cleans up
	f.reset()
	_check(f.state == Florista.State.IDLE, "reset restores IDLE state")
	_check(not f.rose_dropped, "reset clears rose_dropped")
	_check(not f.dodged, "reset clears dodged")

	m.queue_free()
	await process_frame
	print("test_rambla_florista: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
