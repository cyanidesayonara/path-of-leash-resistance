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
#   DOG STUCK      a direction held, she stayed within 4 px for a second, and
#                  for most of it nothing explains it: not dug in or squatting,
#                  tumbling, at a brink, dragged, or held straight into a face
#                  or a corner she is touching (or into your human), which is a
#                  player pressing into a wall. Held along a face and not
#                  sliding is still reported. The line says what she meant,
#                  her velocity, what she is against, the leash and your human
#   HUMAN STUCK    your human moved under 6 px in 1.5 s while plainly walking
#                  on a slack leash (taut_amount under 0.5) for every frame
#                  of it: a human held by a dog pushing into something, or
#                  one who stopped for an event or a squat in that time, is
#                  not stuck, the same rule as tests/test_mercat_owner_path.gd.
#                  The line says what he meant and what he is against
#   NPC IN SOLID   a walker, their dog or a tourist inside a solid rect
#                  (main.solid_rects, shrunk by 4 px); the line names which
#                  and the rect's index
# Headless it plays and logs but takes no photographs.

# under this much of the held direction left once the faces she touches have
# taken theirs, she is pressed into them, not stuck
const PRESSED_FREE := 0.25
const NORMAL_FRAMES := 6
# a stall is reported only when, for this many of its 60 frames, she was held
# toward open ground with nothing (a squat, a plant, a tumble, the leash) on her
const FREE_FRAMES := 30
const MOVE := {"up": "move_up", "down": "move_down", "left": "move_left", "right": "move_right"}

var m: Node2D
var out_dir := ""
var shots := 0
var log_lines: Array[String] = []
var reported := {}
var dog_hist: Array[Vector2] = []
var human_hist: Array[Vector2] = []
# per frame of human_hist: was he excused from walking (an event, a wait, a
# leash holding him)
var human_excused: Array[bool] = []
var held: Array[String] = []
# the faces she touched, frame by frame, for the last NORMAL_FRAMES frames
var dog_normals: Array = []
# per frame of dog_hist: held toward somewhere she could go, and free to
var dog_free: Array[bool] = []


func _initialize() -> void:
	call_deferred("_run")


func _arg(name: String, def: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + name + "="):
			return a.substr(name.length() + 3)
	return def


func _note(kind: String, at: Vector2, detail := "") -> void:
	# once per kind per 60 px cell, so a jam is one line, not a thousand
	var key := "%s:%d:%d" % [kind, int(at.x / 60.0), int(at.y / 60.0)]
	if reported.has(key):
		return
	reported[key] = true
	var line := "%s at (%d, %d) t=%.1f" % [kind, int(at.x), int(at.y), float(m.elapsed)]
	if detail != "":
		line += " " + detail
	log_lines.append(line)
	print("PLAYTEST " + line)


func _watch() -> void:
	var touching: Array[Vector2] = []
	for i in range(m.dog.get_slide_collision_count()):
		touching.append(m.dog.get_slide_collision(i).get_normal())
	# your human's body is a face too (main._part_bodies holds her off it)
	var off: Vector2 = m.dog.global_position - m.human.global_position
	if off.length() < m.BODY_REACH + 1.0 and off.length() > 0.01:
		touching.append(off.normalized())
	dog_normals.append(touching)
	if dog_normals.size() > NORMAL_FRAMES:
		dog_normals.pop_front()
	dog_hist.append(m.dog.global_position)
	human_hist.append(m.human.global_position)
	if dog_hist.size() > 60:
		dog_hist.pop_front()
	human_excused.append(_human_excused())
	if human_hist.size() > 90:
		human_hist.pop_front()
		human_excused.pop_front()
	if m.phase == "freedom" or m.finished or m.frozen:
		return
	var steering := false
	for a in held:
		if a.begins_with("move_"):
			steering = true
	# held toward somewhere she could go, and nothing else holding her, this
	# frame: not dug in or squatting, tumbling, at a brink or dragged
	var held_back: bool = m.dog.planted or m.dog.is_tumbling() or m.teeter.active or m.dog.dragged
	dog_free.append(steering and not held_back and not _pressed_flat())
	if dog_free.size() > 60:
		dog_free.pop_front()
	# a stall is a second spent within 4 px of where it began, not a second
	# that happens to end where it began (a yank back and a run up again)
	if steering and dog_hist.size() == 60 and _dog_stayed(4.0) and dog_free.count(true) >= FREE_FRAMES:
		_note("DOG STUCK", m.dog.global_position, _dog_detail())
	if human_hist.size() == 90 and human_hist[0].distance_to(human_hist[89]) < 6.0 and not human_excused.has(true):
		_note("HUMAN STUCK", m.human.global_position, _human_detail())
	for g in ["pairs", "tourists"]:
		for n: Node in get_nodes_in_group(g):
			var bodies: Array = [n]
			var names: Array[String] = ["tourist"]
			if g == "pairs":
				bodies = [n.get("npc_owner"), n.get("npc_dog")]
				names = ["pair owner", "pair dog"]
			for i in range(bodies.size()):
				var b = bodies[i]
				if b is Node2D and is_instance_valid(b):
					var p: Vector2 = (b as Node2D).global_position
					for ri in range(m.solid_rects.size()):
						var r: Rect2 = m.solid_rects[ri]
						if r.grow(-4.0).has_point(p):
							_note("NPC IN SOLID", p, "(%s in rect %d %s)" % [names[i], ri, str(r)])


# Not plainly walking this frame, so a stop is no wedge. Every frame of the
# window counts: a leash that held him until a moment ago, a selfie he shuffled
# back for and then walked off, or a dog he waited for left him where he
# started without his being stuck.
func _human_excused() -> bool:
	var h: CharacterBody2D = m.human
	if m.phase == "freedom" or m.finished or m.frozen:
		return true
	# an owner event, a telegraph or a HEY! winding up, a halt
	var walking: bool = h.state == h.HState.WALK or h.state == h.HState.DRIFT
	if not walking or float(h.get("halt_t")) > 0.0 or h.walk_intent.length() <= 30.0:
		return true
	# waiting at a tutorial lesson, standing still on purpose
	if float(h.get("tut_hold_y")) > -INF:
		return true
	# waiting while she does her business
	if m.dog.squat_t > 0.0 or m.dog.peeing:
		return true
	# held by the leash: a dog pushing into an obstacle pins her human, which
	# is the dog's doing, not his being stuck
	return m.leash.taut_amount(m.leash.used_length() / m.leash.rest_len) >= 0.5


func _dog_stayed(within: float) -> bool:
	for p in dog_hist:
		if p.distance_to(dog_hist[0]) >= within:
			return false
	return true


# Held straight into what she is touching: a face head on, or into a corner
# (a block and the column out of its corner, a bin by a wall). Nothing is left
# of the held direction once every face she touched has taken its share, so a
# player expects no movement. Sliding along a face leaves the part along it,
# and a stall there is still reported.
func _pressed_flat() -> bool:
	var normals: Array[Vector2] = []
	for frame: Array in dog_normals:
		for n: Vector2 in frame:
			normals.append(n)
	if normals.is_empty():
		return false
	# the nearest direction to the held one that no touched face refuses:
	# the held one itself, its slide along one face, or nothing
	var want: Vector2 = m.dog.input_dir.normalized()
	var best := Vector2.ZERO
	var candidates: Array[Vector2] = [want]
	for n in normals:
		candidates.append(want - n * want.dot(n))
	for c in candidates:
		var ok := true
		for n in normals:
			if c.dot(n) < -0.001:
				ok = false
				break
		if ok and c.distance_to(want) < best.distance_to(want):
			best = c
	return best.length() < PRESSED_FREE


# what she meant and what she is against
func _dog_detail() -> String:
	var d: CharacterBody2D = m.dog
	var parts: Array[String] = []
	for i in range(d.get_slide_collision_count()):
		var c := d.get_slide_collision(i)
		var who: Object = c.get_collider()
		parts.append("%s n(%.2f, %.2f)" % [who.name if who is Node else str(who), c.get_normal().x, c.get_normal().y])
	return "(input (%.2f, %.2f), vel (%d, %d), against [%s], taut %.2f, drag %.2f, human at (%d, %d))" % [
		d.input_dir.x, d.input_dir.y, int(d.velocity.x), int(d.velocity.y), ", ".join(parts),
		m.leash.taut_amount(m.leash.used_length() / m.leash.rest_len), float(d.drag_amt),
		int(m.human.global_position.x), int(m.human.global_position.y)]


# what he meant and what he is against, so a stuck line says why
func _human_detail() -> String:
	var h: CharacterBody2D = m.human
	var against := "nothing"
	if h.get_slide_collision_count() > 0:
		var c := h.get_slide_collision(0)
		var who: Object = c.get_collider()
		against = "%s normal (%.2f, %.2f)" % [who.name if who is Node else str(who), c.get_normal().x, c.get_normal().y]
	return "(meant (%d, %d), against %s, dog at (%d, %d))" % [int(h.walk_intent.x), int(h.walk_intent.y),
		against, int(m.dog.global_position.x), int(m.dog.global_position.y)]


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
	var clock := ""
	if m.match_day != null:
		var fans := -1
		if m.match_crowd != null:
			fans = m.match_crowd.active_count()
		clock = " clock %s t=%.0f fans %d banner [%s]" % [MatchDay.Ph.keys()[m.match_day.phase], m.match_day.walk_t, fans, m.hud_status]
	print("PLAYTEST done: %d problem(s), %d shot(s), dog at (%d, %d), human at (%d, %d), phase %s%s" % [
		log_lines.size(), shots, int(m.dog.global_position.x), int(m.dog.global_position.y),
		int(m.human.global_position.x), int(m.human.global_position.y), m.phase, clock])
	m.free()
	quit(0)
