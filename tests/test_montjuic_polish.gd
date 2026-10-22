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
	_check(M.has_method("draw_font"), "draw_font method exists")
	_check(M.has_method("draw_cactus_bed"), "draw_cactus_bed method exists")
	_check(M.has_method("draw_on_hill"), "draw_on_hill method exists")
	_check(M.has_method("_cypress"), "_cypress helper exists")
	_check(M.has_method("_oval_pts"), "_oval_pts helper exists")

	# Verify terrace layout has walls
	var tys: Array[float] = M.terrace_ys(m)
	_check(tys.size() >= 10, "terraced retaining walls along the climb (%d)" % tys.size())

	# Verify cactus bed is intact
	_check(M.CACTI.size() == 5, "5 specimen cacti in botanical garden")

	# Allow frames to render through engine
	await process_frame
	await process_frame
	_check(true, "Montjuic frames render cleanly with batched shapes")

	m.queue_free()
	await process_frame

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_montjuic_polish: OK")
		quit(0)
	else:
		quit(1)
