extends SceneTree

# The walk's signs live on their own canvas (world/sign_layer.gd), redrawn
# only when the picture can differ. These checks pin when it must redraw (a
# piece moved, a sign came into or left view, the signs were rebuilt, the
# signs hid, a puddle shimmers) and when it must not (nothing changed, or a
# body was near without touching anything), and that the canvas sits where
# the signs were drawn before: straight after main's world pass.

const WorldSign := preload("res://world/world_sign.gd")

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
	_check_rev()
	await _check_layer()
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_sign_layer: OK")
		quit(0)
	else:
		quit(1)


# a sign's rev moves on when, and only when, something drawn changed
func _check_rev() -> void:
	var sg := WorldSign.build("LA RAMBLA", Vector2(640, 0), 44.0, "carnations", 4.0, 900.0)
	var rev0 := int(sg.get("rev", 0))
	var dt := 1.0 / 60.0
	# near enough to wake the sign, but nowhere near a piece
	var far := [[Vector2(-4000, 0), Vector2(200, 0), 15.0]]
	for i in range(30):
		WorldSign.tick(sg, far, [], dt, float(i) * dt)
	_check(int(sg.get("rev", 0)) == rev0, "a body near the sign but touching nothing leaves it as drawn")
	# straight through the letters
	var moved := false
	for i in range(60):
		var p := Vector2(300.0 + float(i) * 12.0, -20.0)
		WorldSign.tick(sg, [[p, Vector2(720, 0), 15.0]], [], dt, float(i) * dt)
		moved = moved or int(sg.get("rev", 0)) != rev0
	_check(moved, "a body running through the letters moves the sign on")
	# left alone, the pieces come to rest and the sign stops changing
	for i in range(600):
		WorldSign.tick(sg, far, [], dt, float(i) * dt)
	var settled := int(sg.get("rev", 0))
	for i in range(30):
		WorldSign.tick(sg, far, [], dt, float(i) * dt)
	_check(int(sg.get("rev", 0)) == settled, "settled pieces stop moving the sign on (%d)" % settled)
	# what animates on its own
	var puddle := WorldSign.build("HOME", Vector2.ZERO, 26.0, "puddle", 9.0, 300.0)
	_check(WorldSign.animated(puddle, 0.0), "a puddle sign shimmers, so it is always redrawn")
	_check(not WorldSign.animated(sg, 0.0), "carnations without rings look the same until moved")


func _check_layer() -> void:
	root.get_node("Game").level_id = "street"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	var layer: Node2D = m.sign_layer
	_check(layer != null, "street has a sign layer")
	if layer == null:
		m.queue_free()
		return
	_check(layer.get_index() == 0, "the sign layer is main's first child, drawn straight after the world pass")
	_check(layer.z_index == 0 and layer.z_as_relative, "the sign layer sits at main's own z")
	_check(layer.transform == Transform2D.IDENTITY, "the sign layer draws in world space")
	_check(not m.signs.is_empty(), "street lays its name in carnations")
	if m.signs.is_empty():
		m.queue_free()
		return
	var sg: Dictionary = m.signs[0]
	var vt := float(sg.top)
	var vb := float(sg.bottom)
	# a name just laid out is still falling into place: every pass redraws
	_check(layer.refresh(vt, vb, true) and layer.refresh(vt, vb, true), "a sign falling into place redraws every pass")
	for s2: Dictionary in m.signs:
		s2.born = -100.0
	# whatever the main pass already did, this settles the layer's key
	layer.refresh(vt, vb, true)
	_check(not layer.refresh(vt, vb, true), "an unchanged sign is not redrawn")
	_check(not layer.refresh(vt + 2.0, vb + 2.0, true), "a scroll that shows the same signs is not redrawn")
	sg.rev = int(sg.get("rev", 0)) + 1
	_check(layer.refresh(vt, vb, true), "a moved piece redraws the sign")
	_check(layer.refresh(vt - 100000.0, vt - 90000.0, true), "a sign leaving view redraws the layer")
	_check(layer.refresh(vt, vb, true), "a sign coming into view redraws the layer")
	_check(layer.refresh(vt, vb, false), "hiding the signs redraws the layer")
	_check(not layer.refresh(vt, vb, false), "hidden signs stay hidden without redrawing")
	_check(layer.refresh(vt, vb, true), "showing them again redraws the layer")
	m.signs_built += 1
	_check(layer.refresh(vt, vb, true), "rebuilt signs redraw the layer")
	sg.rings.append({"p": Vector2(float(sg.top), 0.0), "t": 0.0, "big": false})
	_check(layer.refresh(vt, vb, true) and layer.refresh(vt, vb, true), "a ring fading redraws every pass")
	sg.rings.clear()
	_check(layer.refresh(vt, vb, true), "the pass after the last ring clears it")
	_check(not layer.refresh(vt, vb, true), "and then the layer rests again")
	_check(m.signs.size() >= 2, "street has multiple signs to test selective repaints")
	if m.signs.size() >= 2 and not (sg.pieces as Array).is_empty():
		var sg1: Dictionary = m.signs[1]
		var vt2 := minf(vt, float(sg1.top))
		var vb2 := maxf(vb, float(sg1.bottom))
		layer.refresh(vt2, vb2, true)
		var e0: Dictionary = layer._paint[0]
		var e1: Dictionary = layer._paint[1]
		var vp0: SubViewport = e0.vp
		var vp1: SubViewport = e1.vp
		_check(vp0.size.x < layer.MAX_SIDE and vp0.size.x % layer.ALLOC_STEP == 0, "sign SubViewport width is bucketed to ALLOC_STEP")
		_check((e0.src as Rect2).size.x <= float(vp0.size.x) and (e0.src as Rect2).size.y <= float(vp0.size.y), "sign src rect fits inside its SubViewport")
		vp0.render_target_update_mode = SubViewport.UPDATE_DISABLED
		vp1.render_target_update_mode = SubViewport.UPDATE_DISABLED
		var kept_sz := vp0.size
		sg.pieces[0].p = (sg.pieces[0].p as Vector2) + Vector2(2.0, 0.0)
		sg.rev = int(sg.get("rev", 0)) + 1
		_check(layer.refresh(vt2, vb2, true), "moving one piece refreshes the layer")
		_check(vp0.render_target_update_mode == SubViewport.UPDATE_ONCE, "the changed sign repaints")
		_check(vp1.render_target_update_mode == SubViewport.UPDATE_DISABLED, "an unchanged sign in view is not repainted")
		_check(vp0.size == kept_sz, "a small move inside ALLOC_STEP headroom keeps the SubViewport size")
		sg.pieces[0].p = (sg.pieces[0].p as Vector2) + Vector2(float(kept_sz.x), 0.0)
		sg.rev = int(sg.get("rev", 0)) + 1
		layer.refresh(vt2, vb2, true)
		_check(vp0.size.x > kept_sz.x and (e0.src as Rect2).size.x <= float(vp0.size.x), "growing past headroom expands the SubViewport")
	m.queue_free()
	await process_frame
