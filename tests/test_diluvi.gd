extends SceneTree

# El Diluvi is its own rainy shopping street (docs/LEVEL_DESIGN.md): the
# arcade down one side and the awnings are dry (no slick paws there, and the
# owner dries off under them), the owner soaks through out in the open, and
# splashing through a puddle at speed is a trick. No terrace, no lawn.

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
	game.level_id = "rain"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	_check(m.tables.is_empty() and m.benches.is_empty(), "no terrace, no benches out in the rain")
	_check(m.shelters.size() >= 5, "the arcade and the awnings are shelter")
	var arcade: Rect2 = m.shelters[0]
	var under := arcade.get_center()
	var open_p := Vector2(arcade.end.x + 120.0, under.y)
	_check(m.sheltered(under) and not m.sheltered(open_p), "under the arcade is dry, the street is not")
	# the owner soaks in the open and dries under cover
	var human: CharacterBody2D = m.human
	human.global_position = open_p
	m.human_soak = 0.0
	for i in range(600):
		m._tick_wet(1.0 / 60.0)
	var wet: float = m.human_soak
	_check(wet > 0.05, "out in it, the owner gets wetter (%.2f)" % wet)
	human.global_position = under
	for i in range(600):
		m._tick_wet(1.0 / 60.0)
	_check(m.human_soak < wet, "under the arcade, the owner dries off")
	# a splash at speed through a puddle
	var pd: Dictionary = {}
	for pt: Dictionary in m.patches:
		if String(pt["kind"]) == "puddle":
			pd = pt
			break
	_check(not pd.is_empty(), "there are puddles")
	var dog: CharacterBody2D = m.dog
	dog.global_position = m.patch_centre(pd)
	dog.velocity = Vector2(0, -320)
	m.splash_cd = 0.0
	var s0: int = m.splashes
	m._tick_wet(1.0 / 60.0)
	_check(m.splashes == s0 + 1, "splashing through a puddle at speed counts")
	dog.velocity = Vector2(0, -60)
	m.splash_cd = 0.0
	m._tick_wet(1.0 / 60.0)
	_check(m.splashes == s0 + 1, "walking through one does not")
	_check(m.surface_at(m.patch_centre(pd)) == m.Surfaces.S.PAVEMENT, "a puddle is wet paving, not ground that slows you")
	var ids: Array = []
	for q: Dictionary in m.active_quests:
		ids.append(q.id)
	_check("dry" in ids and "splash" in ids, "El Diluvi has its dry and splash goals")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_diluvi: OK")
		quit(0)
	else:
		quit(1)
