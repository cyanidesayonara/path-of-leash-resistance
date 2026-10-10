extends SceneTree

# PLAYTEST: play a walk through the real input actions, the way a player's
# keys do, from a script of steps; photograph it as it goes; and log what a
# player would notice going wrong. Tests check rules; this checks the walk as
# it is played.
#
#   godot --path . --rendering-method gl_compatibility --script res://tools/playtest.gd -- \
#     --level=market --steps="up:4;shot;turbo+up:2;shot;plant:1.5;left:1;shot" --out=C:/tmp/pt
#
# Steps, separated by ';':
#   up / down / left / right / plant / bark / pee / turbo / ...  any input
#     action (up = move_up), joined with '+', held for ':SECONDS'
#   wait:SECONDS   nothing held
#   tap:ACTION     one press of an action (share is the tutorial's skip)
#   shot           a screenshot, NN_shot.png in --out
#   at:X,Y         put the pair there (the dog, the human 60 px behind)
# --y=N starts the pair N px down the walk, like --shot-y.
#
# The watch, every frame, each reported once per place:
#   DOG STUCK      a direction held, she moved under 4 px in a second, and
#                  nothing explains it (dug in, tumbling, at a brink, dragged)
#   HUMAN STUCK    your human meant to walk and moved under 6 px in 1.5 s
#   NPC IN SOLID   a walker, their dog or a tourist inside a solid rect
# Headless it plays and logs but takes no photographs.

const MOVE := {"up": "move_up", "down": "move_down", "left": "move_left", "right": "move_right"}

var m: Node2D
var out_dir := ""
var shots := 0
var log_lines: Array[String] = []
var reported := {}
var dog_hist: Array[Vector2] = []
var human_hist: Array[Vector2] = []
var held: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _arg(name: String, def: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + name + "="):
			return a.substr(name.length() + 3)
	return def


func _note(kind: String, at: Vector2) -> void:
	# once per kind per 60 px cell, so a jam is one line, not a thousand
	var key := "%s:%d:%d" % [kind, int(at.x / 60.0), int(at.y / 60.0)]
	if reported.has(key):
		return
	reported[key] = true
	var line := "%s at (%d, %d) t=%.1f" % [kind, int(at.x), int(at.y), float(m.elapsed)]
	log_lines.append(line)
	print("PLAYTEST " + line)


func _watch() -> void:
	dog_hist.append(m.dog.global_position)
	human_hist.append(m.human.global_position)
	if dog_hist.size() > 60:
		dog_hist.pop_front()
	if human_hist.size() > 90:
		human_hist.pop_front()
	if m.phase == "freedom" or m.finished or m.frozen:
		return
	var steering := false
	for a in held:
		if a.begins_with("move_"):
			steering = true
	if steering and dog_hist.size() == 60 and dog_hist[0].distance_to(dog_hist[59]) < 4.0:
		var why: bool = m.dog.planted or m.dog.is_tumbling() or m.teeter.active or m.dog.dragged
		if not why:
			_note("DOG STUCK", m.dog.global_position)
	if human_hist.size() == 90 and human_hist[0].distance_to(human_hist[89]) < 6.0:
		# only while plainly walking: a stop for a selfie or lost signal is
		# the owner's own event, not being stuck
		if m.human.state == 0 and m.human.walk_intent.length() > 30.0 and float(m.human.get("halt_t")) <= 0.0:
			_note("HUMAN STUCK", m.human.global_position)
	for g in ["pairs", "tourists"]:
		for n: Node in get_nodes_in_group(g):
			var bodies: Array = [n]
			if g == "pairs":
				bodies = [n.get("npc_owner"), n.get("npc_dog")]
			for b in bodies:
				if b is Node2D and is_instance_valid(b):
					var p: Vector2 = (b as Node2D).global_position
					for r: Rect2 in m.solid_rects:
						if r.grow(-4.0).has_point(p):
							_note("NPC IN SOLID", p)


func _frames(seconds: float) -> void:
	for k in range(int(round(seconds * 60.0))):
		await physics_frame
		_watch()


func _shot() -> void:
	shots += 1
	if DisplayServer.get_name() == "headless" or out_dir == "":
		return
	await process_frame
	await process_frame
	var path := "%s/%02d_shot.png" % [out_dir, shots]
	root.get_viewport().get_texture().get_image().save_png(path)
	print("PLAYTEST shot " + path)


func _run() -> void:
	out_dir = _arg("out", "")
	if out_dir != "":
		DirAccess.make_dir_recursive_absolute(out_dir)
	var game = root.get_node("Game")
	game.persist = false
	game.level_id = _arg("level", "street")
	var m_scene: PackedScene = load("res://main.tscn")
	m = m_scene.instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame
	var y0 := float(_arg("y", "0"))
	if y0 != 0.0:
		var p: Vector2 = m.dog.global_position + Vector2(0, y0)
		m.dog.global_position = p
		m.human.global_position = p + Vector2(0, 60)
		m.leash.resnap()
	for step: String in _arg("steps", "up:3;shot").split(";", false):
		step = step.strip_edges()
		if step == "shot":
			await _shot()
			continue
		var parts := step.split(":")
		var head := parts[0]
		var arg := parts[1] if parts.size() > 1 else ""
		if head == "wait":
			await _frames(float(arg))
		elif head == "tap":
			Input.action_press(arg)
			await physics_frame
			Input.action_release(arg)
			await _frames(0.1)
		elif head == "at":
			var xy := arg.split(",")
			var at := Vector2(float(xy[0]), float(xy[1]))
			m.dog.global_position = at
			m.human.global_position = at + Vector2(0, 60)
			m.leash.resnap()
			await _frames(0.2)
		else:
			held.clear()
			for a in head.split("+"):
				held.append(String(MOVE.get(a, a)))
			for a in held:
				Input.action_press(a)
			await _frames(float(arg) if arg != "" else 1.0)
			for a in held:
				Input.action_release(a)
			held.clear()
	print("PLAYTEST done: %d problem(s), %d shot(s), dog at (%d, %d), human at (%d, %d), phase %s" % [
		log_lines.size(), shots, int(m.dog.global_position.x), int(m.dog.global_position.y),
		int(m.human.global_position.x), int(m.human.global_position.y), m.phase])
	m.free()
	quit(0)
