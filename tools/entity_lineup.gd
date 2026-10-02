extends SceneTree

# A lineup of every character and loose prop, drawn big on a plain backdrop,
# so their looks can be judged side by side (a walk's zoom is too far out to
# tell a bald head from a haircut). Writes user://lineup.png, or the path
# after the script's user args:
#   godot --rendering-method gl_compatibility --path . --script res://tools/entity_lineup.gd -- out.png
# Each entity is the real one, set up as a walk would and frozen.

const ORIGIN := Vector2(-3200.0, -2000.0)   # off the walk: nothing else draws here
const CELL := Vector2(120.0, 110.0)
const COLS := 9
const ZOOM := 2.0

var labels: Array = []


class Backdrop:
	extends Node2D
	var rect := Rect2()
	var labels: Array = []

	func _draw() -> void:
		draw_rect(rect, Color(0.80, 0.78, 0.72))
		var f := ThemeDB.fallback_font
		for l: Array in labels:
			draw_string(f, l[0] + Vector2(-50.0, 44.0), String(l[1]), HORIZONTAL_ALIGNMENT_CENTER, 100.0, 10,
				Color(0.20, 0.18, 0.16))


func _initialize() -> void:
	call_deferred("_run")


func _cell(i: int) -> Vector2:
	return ORIGIN + Vector2(float(i % COLS) * CELL.x, float(i / COLS) * CELL.y)


func _place(m: Node2D, script: String, label: String, i: int) -> Node2D:
	var n := Node2D.new()
	n.set_script(load(script))
	n.position = _cell(i)
	n.z_index = 10
	m.add_child(n)
	labels.append([_cell(i), label])
	return n


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.level_id = "street"
	# weather=rain|snow|wind and level=<id> dress the lineup for that walk
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("weather="):
			game.weather = arg.substr(8)
		elif arg.begins_with("level="):
			game.level_id = arg.substr(6)
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(10):
		await process_frame
	m.frozen = true
	# the game's own frame (camera follow, spawning) stops here; entities
	# still draw themselves
	m.set_process(false)
	m.set_physics_process(false)
	var i := 0
	# the player's pair
	m.dog.global_position = _cell(i)
	m.dog.facing = Vector2.DOWN
	labels.append([_cell(i), "Millie"])
	i += 1
	m.human.global_position = _cell(i)
	m.human.face_dir = Vector2.DOWN
	labels.append([_cell(i), "your human"])
	m.leash.visible = false
	i += 1
	# other walkers: one of each owner look
	var ha: GDScript = load("res://entities/human_appearance.gd")
	for pid: String in ha.profile_ids():
		var pair := Node2D.new()
		pair.set_script(load("res://entities/otherpair.gd"))
		pair.set_physics_process(false)
		m.add_child(pair)
		pair.setup(m, m.dog, m.poles, _cell(i) + Vector2(-14.0, -8.0), Vector2(0.0, 1.0))
		pair.owner_appearance_profile = ha.get_profile(pid)
		pair.npc_dog.position = _cell(i) + Vector2(22.0, 18.0)
		pair.leash.visible = false
		labels.append([_cell(i), pid.substr(0, 14)])
		i += 1
	# the crowd and the people who want things from you
	var cr := RandomNumberGenerator.new()
	cr.seed = 3
	for look: String in ["map", "camera", "stick"]:
		var tw := _place(m, "res://entities/tourist.gd", "tourist " + look, i)
		tw.setup(m, cr, _cell(i), 1.0)
		tw.look = look
		i += 1
	var pp := _place(m, "res://entities/pickpocket.gd", "pickpocket", i)
	pp.setup(m, _cell(i), m.human, false, 1.0)
	i += 1
	var ch := _place(m, "res://entities/challenger.gd", "bet you can't", i)
	ch.setup(m, m.dog, 5, 30.0)
	i += 1
	var rv := _place(m, "res://entities/rival.gd", "Brutus", i)
	rv.setup(m, m.dog, Rect2(_cell(i) - Vector2(40, 40), Vector2(80, 80)))
	i += 1
	for k: String in ["bike", "kid"]:
		var bk := _place(m, "res://entities/bike.gd", k, i)
		bk.setup(m, m.dog, m.human, Vector2(0.0, 0.0), k)
		i += 1
	# animals
	var fd := _place(m, "res://entities/freedog.gd", "free dog", i)
	fd.setup(m, m.dog, ORIGIN.y - 200.0, ORIGIN.y + 400.0)
	i += 1
	var gd := _place(m, "res://entities/guarddog.gd", "guard dog", i)
	gd.setup(m, m.dog)
	i += 1
	for k: String in ["squirrel", "cat"]:
		var sq := _place(m, "res://entities/squirrel.gd", k, i)
		sq.setup(m, m.dog, k)
		i += 1
	var bo := _place(m, "res://entities/boar.gd", "boar", i)
	bo.setup(m, m.dog, m.human, _cell(i).y, _cell(i).x, _cell(i).x)
	i += 1
	var du := _place(m, "res://entities/duckling.gd", "duck", i)
	du.setup(m, m.dog, 1.0, true)
	i += 1
	var hide: Array[Vector2] = [_cell(i)]
	var tf := _place(m, "res://entities/tofu.gd", "Tofu", i)
	tf.setup(m, m.dog, hide)
	i += 1
	var wc := _place(m, "res://entities/wallcat.gd", "wall cat", i)
	wc.setup(m, m.dog, 1.0)
	i += 1
	for k: String in ["pigeon", "gull", "parakeet"]:
		var pg := _place(m, "res://entities/pigeon.gd", k, i)
		pg.setup(m, m.dog, m.human, k == "gull")
		if k == "parakeet":
			pg.make_parakeet(1.0)
		i += 1
	# loose things to kick
	for k: String in ["cone", "can", "bottle", "ball", "sack", "crate", "wetfloor"]:
		var cn := _place(m, "res://entities/cone.gd", k, i)
		cn.setup(m, m.dog, m.human, k)
		cn.rotation = 0.0
		i += 1
	var rows := int(ceil(float(i) / float(COLS)))
	var bd := Backdrop.new()
	bd.z_index = -40
	bd.rect = Rect2(ORIGIN - CELL * 0.5, Vector2(CELL.x * COLS, CELL.y * rows))
	bd.labels = labels
	m.add_child(bd)
	# hide the HUD and frame the lineup
	for c in m.get_children():
		if c is CanvasLayer:
			c.visible = false
	m.cam.position_smoothing_enabled = false
	m.cam.zoom = Vector2(ZOOM, ZOOM) * minf(1280.0 / (CELL.x * COLS * ZOOM), 720.0 / (CELL.y * rows * ZOOM))
	m.cam.position = bd.rect.get_center()
	# a second user arg, cells=K,N, frames N cells from cell K, close up
	var args0 := OS.get_cmdline_user_args()
	var cells_arg := ""
	for arg in args0:
		if arg.begins_with("cells="):
			cells_arg = arg
	if cells_arg != "":
		var kn := cells_arg.substr(6).split(",")
		var k0 := int(kn[0])
		var n := int(kn[1])
		var a := _cell(k0) - CELL * 0.5
		var r := Rect2(a, Vector2(CELL.x * n, CELL.y))
		m.cam.zoom = Vector2.ONE * minf(1280.0 / r.size.x, 720.0 / r.size.y)
		m.cam.position = r.get_center()
	for k in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	var out := "user://lineup.png" if args.is_empty() else args[0]
	var img := root.get_texture().get_image()
	img.save_png(out)
	print("lineup: %s (%d entities)" % [out, i])
	quit(0)
