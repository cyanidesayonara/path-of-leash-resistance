extends SceneTree

# Looks for what is solid and never drawn: every post the leash winds round
# and every solid rect of a walk, photographed with the interface off and held
# against the ground about it. One whose picture is as flat as bare ground is
# printed, with a crop of it saved to look at:
#   godot --path . --rendering-method gl_compatibility --fixed-fps 60
#     --script res://tools/ghost_check.gd -- --level=vet --out=C:/tmp/ghost
# A guess, not a verdict: look at the crops.

const FLAT := 0.030              # a picture that varies no more than this is bare
const BOX := 46                  # half the crop, px of world

var m: Node2D


func _arg(key: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="):
			return a.substr(key.length() + 3)
	return fallback


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var out := _arg("out", "user://ghost")
	DirAccess.make_dir_recursive_absolute(out)
	var game = root.get_node("Game")
	game.persist = false
	game.level_id = _arg("level", "street")
	game.weather = "clear"
	root.get_node("Sfx").muted = true
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame
	for layer in root.find_children("*", "CanvasLayer", true, false):
		if not String(layer.name).to_lower().contains("grade") and layer.layer > 0:
			layer.visible = false
	m.shot_zoom_set = true
	m.cam.zoom = Vector2.ONE
	var spots: Array = []
	for i in range(m.poles.size()):
		spots.append(["pole %d" % i, Rect2(m.poles[i], Vector2.ZERO).grow(9.0)])
	for i in range(m.solid_rects.size()):
		var r: Rect2 = m.solid_rects[i]
		# walls round the walk are not things
		if r.size.x < 700.0 and r.size.y < 500.0:
			spots.append(["solid %d" % i, r])
	spots.sort_custom(func(a, b): return a[1].position.y > b[1].position.y)
	var img: Image = null
	var top_left := Vector2.ZERO
	var at_y := INF
	var view: Vector2 = m.get_viewport_rect().size
	var ghosts := 0
	for s: Array in spots:
		var r: Rect2 = s[1]
		var c := r.get_center()
		if c.x < 0.0 or c.x > 1280.0 or c.y > m.START_Y + 60.0 or c.y < m.freedom_lo:
			continue
		if absf(c.y - at_y) > view.y * 0.5 - 90.0 - r.size.y * 0.5 or img == null:
			at_y = c.y - view.y * 0.25
			m.shot_cam = Vector2(640.0, at_y)
			m._edge_drawn_y = 1.0e9
			m._verge_drawn_y = 1.0e9
			for k in range(6):
				await process_frame
			img = root.get_viewport().get_texture().get_image()
			top_left = Vector2(640.0, at_y) - view * 0.5
		var p := r.position - top_left
		var lo := Vector2i(maxi(0, int(p.x)), maxi(0, int(p.y)))
		var hi := Vector2i(mini(img.get_width() - 1, int(p.x + r.size.x)), mini(img.get_height() - 1, int(p.y + r.size.y)))
		var n := 0
		var sum := 0.0
		var sq := 0.0
		var step := maxi(1, mini(hi.x - lo.x, hi.y - lo.y) / 14)
		for y in range(lo.y, hi.y, step):
			for x in range(lo.x, hi.x, step):
				var v := img.get_pixel(x, y).get_luminance()
				sum += v
				sq += v * v
				n += 1
		if n < 8:
			continue
		var dev := sqrt(maxf(0.0, sq / float(n) - (sum / float(n)) * (sum / float(n))))
		if dev < FLAT:
			ghosts += 1
			var crop := Rect2i(Vector2i(p + r.size * 0.5) - Vector2i(BOX, BOX), Vector2i(BOX, BOX) * 2).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
			if crop.has_area():
				img.get_region(crop).save_png("%s/%s_%s_%d_%d.png" % [out, game.level_id, s[0].replace(" ", ""), int(c.x), int(c.y)])
			print("GHOST %s %s at (%d, %d) size (%d, %d) dev %.3f" % [game.level_id, s[0], int(c.x), int(c.y), int(r.size.x), int(r.size.y), dev])
	print("GHOSTS %s: %d of %d" % [game.level_id, ghosts, spots.size()])
	m.free()
	quit(0)
