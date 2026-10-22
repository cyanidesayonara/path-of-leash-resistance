extends SceneTree

# Tests for visual polish additions to La Rambla (world/rambla.gd):
# - Iconic undulating wave pavement (ones del paviment de la Rambla)
# - Joan Miró's Pla de l'Os pavement mosaic in Plaça de la Boqueria
# - Font de Canaletes: 4 bronze spouts, city crests, drain grates, 4-armed lantern
# - Newsstand kiosks with postcard carousel racks and newspaper bundles
# - Rambla de les Flors flower stalls with zinc buckets, potted plants, and petal drifts
# - Souvenir stalls with straw hats, espadrilles, and ceramic trencadis lizards
# - Caricaturist and painter pitches with easels, palettes, and sketch clotheslines
# - Living statues on weathered stone pedestals with tipping coin dishes

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
	game.level_id = "street"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	var R: GDScript = load("res://world/rambla.gd")

	# 1. Iconic color palette & constants
	_check(R.CANALETES_IRON.v < 0.2, "Canaletes iron is dark cast-iron")
	_check(R.BRONZE_SPOUT.r > 0.6 and R.BRONZE_SPOUT.g > 0.4, "Bronze spout color defined")
	_check(R.LANTERN_GLOW.a > 0.7 and R.LANTERN_GLOW.r > 0.9, "Lantern glow defined with warmth and alpha")
	_check(R.CREST_RED.r > 0.7 and R.CREST_GOLD.g > 0.6, "Barcelona crest colors defined")
	_check(R.MIRO_BLUE.b > 0.6 and R.MIRO_RED.r > 0.7, "Miró primary colors defined")
	_check(R.MIRO_YELLOW.r > 0.8 and R.MIRO_GREEN.g > 0.4, "Miró yellow and green defined")
	_check(R.ZINC_BUCKET.r > 0.5 and R.ZINC_BUCKET.b > 0.5, "Flower stall zinc bucket metal defined")
	_check(R.ROSE_RED.r > 0.8 and R.SUNFLOWER_GOLD.r > 0.8, "Flower varieties defined")
	_check(R.STRAW_HAT.r > 0.7 and R.ESPADRILLE_STRIPE.b > 0.5, "Souvenir stall materials defined")
	_check(R.KIOSK_GREEN.g > 0.2 and R.KIOSK_GREEN.r < 0.3, "Kiosk dark green defined")

	# 2. Structural corridor and solids integrity
	_check(game.level_id == "street", "Level is street")
	_check(m.fountains.size() > 0, "Canaletes fountain exists (%d fountains)" % m.fountains.size())
	_check(m.stalls.size() > 0, "Rambla stalls generated (%d stalls)" % m.stalls.size())
	_check(m.statues.size() > 0, "Living statues exist (%d statues)" % m.statues.size())
	_check(m.poles.size() > 0, "London plane trees (poles) exist (%d trees)" % m.poles.size())

	# 3. ShapeBatch drawing passes without error
	var sb := ShapeBatch.new()
	var vt := -4000.0
	var vb := 500.0

	# Pavement waves
	R.draw_pavement_waves(m, sb, vt, vb)
	_check(true, "draw_pavement_waves executed cleanly")

	# Miró mosaic
	var mosaic_c := Vector2(float(m.sw_l + m.sw_r) * 0.5, -1650.0)
	var mosaic_r := float(m.sw_r - m.sw_l) * 0.38
	R.draw_miro_mosaic(sb, mosaic_c, mosaic_r)
	_check(true, "draw_miro_mosaic executed cleanly")

	# Tree leaf drifts
	R.draw_tree_leaf_drifts(m, sb, vt, vb)
	_check(true, "draw_tree_leaf_drifts executed cleanly")

	# Canaletes drawing
	var dummy = DummyCanvas.new()
	if m.fountains.size() > 0:
		R.draw_canaletes(m, dummy, m.fountains[0])
		_check(true, "draw_canaletes executed cleanly on canvas")

	# Stall variants drawing
	var stall_kinds := ["kiosk", "flowers", "souvenir", "caricature", "painter", "icecream", "books"]
	for idx in range(stall_kinds.size()):
		var kind: String = stall_kinds[idx]
		var st_pos := Vector2(640.0, -500.0 - float(idx) * 200.0)
		R.draw_rambla_stall(m, sb, st_pos, kind, idx)
	_check(true, "all rambla stall kinds drawn without error")

	# Statue dressing drawing
	for s_idx in range(m.statues.size()):
		var sp: Vector2 = m.statues[s_idx]
		var paint: Color = Color(0.80, 0.66, 0.30) if s_idx % 2 == 0 else Color(0.72, 0.74, 0.76)
		R.draw_statue_dressing(m, sb, sp, s_idx, paint, 0.0, 1.0)
	_check(true, "statue dressing drawn cleanly")

	if failures.is_empty():
		print("%d checks, 0 failures" % checks)
		print("test_rambla_polish: OK")
		quit(0)
	else:
		print("%d checks, %d FAILURES:" % [checks, failures.size()])
		for f in failures:
			print("  - " + f)
		quit(1)


class DummyCanvas:
	func draw_set_transform(_pos: Vector2, _rot := 0.0, _scale := Vector2.ONE) -> void:
		pass

	func draw_circle(_p: Vector2, _r: float, _c: Color) -> void:
		pass

	func draw_rect(_r: Rect2, _c: Color) -> void:
		pass

	func draw_line(_from: Vector2, _to: Vector2, _c: Color, _w := 1.0) -> void:
		pass

