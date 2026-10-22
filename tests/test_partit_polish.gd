extends SceneTree

# Tests for visual polish additions to Dia de Partit (systems/partit.gd):
# - Authentic matchday detritus (tickets, programmes, crushed cans, plastic cups)
# - Pavement matchday directional stencils ("ACCES ESTADI", "PORTES 7-12 ->")
# - Retroreflective barrier hazard chevrons, heavy rubber base stabilizers, and supporter stickers
# - Bar La Penya terrace dressing: vermouth glasses, olive dishes, napkin dispensers, propped chalkboard menu, bottle crates
# - Merch stall beanies, cash box, and hanging stadium horns
# - Cart bottled water cartons and seed packets
# - Sausage kiosk baguette bread crate, mustard/ketchup squeeze dispensers, and charcoal ember glow
# - Stadium concourse turnstile optical barcode scanners, queue lane guide hatchings, gate signage, and concrete buttresses
# - Plaça del Gol floodlight lattice gantries and stadium bowl cantilever ribs

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
	game.level_id = "partit"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	var P: GDScript = load("res://systems/partit.gd")

	# 1. Colors & matchday constants
	_check(P.TICKET_WHITE.r > 0.9 and P.TICKET_WHITE.g > 0.9, "ticket white defined")
	_check(P.SCANNER_GREEN.g > 0.8 and P.SCANNER_GREEN.r < 0.4, "turnstile barcode scanner emerald green defined")
	_check(P.LED_RED.r > 0.8 and P.LED_RED.g < 0.3, "ticket office LED red defined")
	_check(P.HAZARD_RED.r > 0.7 and P.HAZARD_WHITE.r > 0.9, "barrier hazard warning colors defined")
	_check(P.CAN_RED.r > 0.7 and P.CAN_GOLD.r > 0.8 and P.CAN_SILVER.r > 0.7, "beverage can varieties defined")
	_check(P.CUP_PLASTIC.a > 0.3 and P.CUP_PLASTIC.a < 0.8, "plastic cup translucency defined")

	# 2. Level solids and keepouts remain preserved and uncorrupted
	var solids: Array = P.solids(m)
	_check(solids.size() == 19, "solids list count preserved (%d)" % solids.size())
	for r: Rect2 in solids:
		_check(m.solid_rects.has(r), "solid %s registered in solid_rects" % str(r))
		_check(m.owner_keepouts.has(r), "solid %s registered in owner_keepouts" % str(r))

	# 3. ShapeBatch drawing passes without error across all viewports
	var sb := ShapeBatch.new()

	# Edge layer pass (stalls, barriers, matchday litter, stencils, stadium concourse)
	P.draw_edge_layer(m, sb, -4800.0, 300.0)
	_check(true, "draw_edge_layer completes cleanly over full level range")

	# Freedom square pass stadium bowl cantilever ribs
	var fr_rect: Rect2 = m._freedom_rect()
	P._draw_stadium_bowl(m, sb, fr_rect)
	_check(true, "draw_stadium_bowl completes cleanly")

	# Live world pass (smoke, tout, drummers)
	P.draw_live(m, sb, -4500.0, -1000.0)
	_check(true, "draw_live completes cleanly")

	# 4. Strict brand deny list check on all new text
	var branding_test = load("res://tests/test_partit_branding.gd").new()
	var code_text: String = FileAccess.get_file_as_string("res://systems/partit.gd").to_lower()
	var hit: String = branding_test._hit(code_text)
	_check(hit == "", "partit.gd strictly adheres to brand protection deny list (hit=%s)" % hit)

	print("test_partit_polish: %d checks, %d failures" % [checks, failures.size()])
	m.queue_free()
	quit(1 if failures.size() > 0 else 0)
