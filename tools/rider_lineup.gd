extends SceneTree

# Every rider style, drawn big on a strip of pavement, so their looks can be
# judged side by side: the top row riding straight, the second leaning into a
# turn with the pedals round, the third braking. Writes user://riders.png, or
# the first user arg:
#   godot --rendering-method gl_compatibility --path . --script res://tools/rider_lineup.gd -- out.png [hour=night] [weather=rain] [only=city,courier]
# only= draws just those styles, closer up.
# Each rider is the real entities/bike.gd, set up as a walk would and frozen.

const ORIGIN := Vector2(-3200.0, -2000.0)   # off the walk: nothing else draws here
const CELL := Vector2(78.0, 84.0)
const STYLES: Array = [["bike", "city"], ["bike", "bicing"], ["bike", "courier"], ["bike", "road"],
	["bike", "mtb"], ["bike", "escooter"], ["kid", "kick"], ["kid", "kidbike"], ["roller", "roller"],
	["roller", "skate"], ["kid", "pram"]]
const ROWS := ["riding", "leaning", "braking"]


class Backdrop:
	extends Node2D
	var rect := Rect2()
	var labels: Array = []

	func _draw() -> void:
		draw_rect(rect, Color(0.70, 0.68, 0.64))
		var f := ThemeDB.fallback_font
		for l: Array in labels:
			draw_string(f, l[0], String(l[1]), HORIZONTAL_ALIGNMENT_CENTER, CELL.x, 8,
				Color(0.16, 0.14, 0.12))


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.level_id = "street"
	var out := "user://riders.png"
	var styles: Array = STYLES.duplicate()
	var weather := ""
	var hour := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("weather="):
			weather = arg.substr(8)
		elif arg.begins_with("hour="):
			hour = arg.substr(5)
		elif arg.begins_with("only="):
			var keep := arg.substr(5).split(",")
			styles = STYLES.filter(func(e: Array) -> bool: return String(e[1]) in keep)
		elif not arg.contains("="):
			out = arg
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(10):
		await process_frame
	m.frozen = true
	# the walk sets its own sky as it loads; this one is for the riders
	if weather != "":
		game.weather = weather
	if hour != "":
		game.hour = hour
	m.set_process(false)
	m.set_physics_process(false)
	for b in m.get_tree().get_nodes_in_group("bikes"):
		b.queue_free()
	m.leash.visible = false
	m.dog.global_position = ORIGIN + Vector2(0, 2000)
	m.human.global_position = ORIGIN + Vector2(0, 2100)
	var labels: Array = []
	for r in range(ROWS.size()):
		for i in range(styles.size()):
			var at := ORIGIN + Vector2(float(i) * CELL.x, float(r) * CELL.y)
			var n := Node2D.new()
			n.set_script(load("res://entities/bike.gd"))
			n.position = at
			n.z_index = 12
			m.add_child(n)
			seed(41 + i * 7)
			n.setup(m, m.dog, m.human, Vector2(0.0, -300.0), String(styles[i][0]))
			n.set("style", String(styles[i][1]))
			n.rotation = -PI * 0.5
			n.set("heading", -PI * 0.5)
			n.set("crank", 0.0 if r == 0 else 1.9)
			n.set("lean", 0.0 if r != 1 else 0.85)
			n.set("braking", r == 2)
			n.queue_redraw()
			if r == 0:
				labels.append([ORIGIN + Vector2(float(i) * CELL.x - CELL.x * 0.5, -CELL.y * 0.5 + 10.0),
					String(styles[i][1])])
	var bd := Backdrop.new()
	bd.z_index = -40
	bd.rect = Rect2(ORIGIN - CELL * 0.5, Vector2(CELL.x * styles.size(), CELL.y * ROWS.size()))
	bd.labels = labels
	m.add_child(bd)
	for c in m.get_children():
		if c is CanvasLayer:
			c.visible = false
	m.cam.position_smoothing_enabled = false
	m.cam.rotation = 0.0
	m.cam.zoom = Vector2.ONE * minf(1280.0 / bd.rect.size.x, 720.0 / bd.rect.size.y)
	m.cam.position = bd.rect.get_center()
	for k in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out)
	print("riders: %s" % out)
	quit(0)
