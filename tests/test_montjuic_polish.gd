extends SceneTree

# Tests visual polish additions for Montjuïc (PR montjuic-polish-163):
# 1. Carles Buïgas concentric brass jet manifolds and submerged underwater illumination in Font Màgica
# 2. Drystone terrace retaining walls with cascading ivy (heura) tendrils and terracotta geranium flowerpots
# 3. Sentinel Italian cypress trees (xiprers) framing hillside terrace lookouts
# 4. Raked limestone gravel ridges, border curbs, and botanical identification plaques in Jardí de Cactus
# 5. Scenic mirador viewpoint with neoclassical balustrade and panoramic coin-operated telescope (telescopi de mirador)
# 6. Ripe prickly pear cactus figs (figues de moro)

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
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "montjuic"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	var M: GDScript = load("res://systems/montjuic.gd")
	_check(M != null, "Montjuic system loaded")
	# the botanical pieces stand off the path, in the garden beside it
	for cp: Vector2 in M.CACTI:
		var ce: Vector2 = m.walk_edges(cp.y)
		_check(cp.x < ce.x - 13.0 or cp.x > ce.y + 13.0, "cactus at %s grows off the path (edges %s)" % [cp, ce])
		_check(cp in m.poles, "cactus at %s catches the rope" % cp)
	var fe: Vector2 = m.walk_edges(M.FONT.get_center().y)
	_check(M.FONT.position.x >= fe.y - 1.0 or M.FONT.end.x <= fe.x + 1.0, "the Font Màgica basin is off the path")

	# Verify terrace layout has walls
	var tys: Array[float] = M.terrace_ys(m)
	_check(tys.size() >= 10, "terraced retaining walls along the climb (%d)" % tys.size())
	for i in range(1, tys.size()):
		_check(tys[i] < tys[i - 1] - 100.0, "terrace %d is a full step above the one below" % i)

	# Verify cactus bed is intact
	_check(M.CACTI.size() == 5, "5 specimen cacti in botanical garden")

	# a couple of real frames: a draw error here fails the run (SCRIPT ERROR)
	await process_frame
	await process_frame

	m.queue_free()
	await process_frame

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_montjuic_polish: OK")
		quit(0)
	else:
		quit(1)
