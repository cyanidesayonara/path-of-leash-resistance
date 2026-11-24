extends SceneTree

# Photographs a whole walk, start line to past the far fence, one overlapping
# frame after another with the interface off, for going over it square by
# square:
#   godot --path . --rendering-method gl_compatibility --fixed-fps 60
#     --script res://tools/walk_strip.gd -- --level=street --out=C:/tmp/strip [--zoom=0.9]
# The walk is not played: nobody has touched anything. tools/walk_strip.sh
# lays the frames out on a sheet.

var m: Node2D


func _arg(key: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="):
			return a.substr(key.length() + 3)
	return fallback


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var out := _arg("out", "user://strip")
	DirAccess.make_dir_recursive_absolute(out)
	var game = root.get_node("Game")
	game.persist = false
	game.level_id = _arg("level", "street")
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
	if m.hud is CanvasItem or m.hud is CanvasLayer:
		m.hud.visible = false
	var zoom := float(_arg("zoom", "0.9"))
	m.shot_zoom_set = true
	m.cam.zoom = Vector2(zoom, zoom)
	var view: Vector2 = m.get_viewport_rect().size / zoom
	var y: float = m.START_Y + 200.0
	var end: float = m.freedom_lo - 60.0
	var i := 0
	while true:
		m.shot_cam = Vector2(640.0, y)
		m._edge_drawn_y = 1.0e9
		m._verge_drawn_y = 1.0e9
		for k in range(8):
			await process_frame
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("%s/%02d.png" % [out, i])
		print("STRIP %02d y=%.0f..%.0f" % [i, y - view.y * 0.5, y + view.y * 0.5])
		i += 1
		if y - view.y * 0.5 <= end or i > 30:
			break
		y -= view.y * 0.94
	m.free()
	quit(0)
