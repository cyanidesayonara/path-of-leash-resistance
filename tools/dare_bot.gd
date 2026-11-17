extends SceneTree

# How many tricks a dare's clock really allows on each walk: the pair is put
# beside the walk's dare-giver, a dare is started, and a simple bot runs the
# one trick every walk has, POLE SWING (zoomies held, carve round a pole with
# the leash caught on it, then on to the next pole), for the dare's seconds.
# Prints one line per walk: DAREBOT level giver tricks swings poles_near.
# The bot drives straight at its pole and stalls against kiosks and stalls,
# so a cluttered walk reads low; on open ground it is a fair floor for what a
# player lands. The ladder in entities/challenger.gd is set against these.
# DAREBOT_TRACE=1 prints the dog, the leash and the swing twice a second.
#
#   godot --path . --rendering-method gl_compatibility --fixed-fps 60 \
#     --script res://tools/dare_bot.gd -- [--levels=a,b] [--secs=20]

const RADIUS := 70.0
const NEAR := 600.0

var m: Node2D
var target := Vector2(INF, INF)
var sense := 1.0
var used: Array[Vector2] = []


func _initialize() -> void:
	call_deferred("_run")


func _arg(name: String, def: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + name + "="):
			return a.substr(name.length() + 3)
	return def


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	var levels: Array = Array(_arg("levels", ",".join(game.LEVELS)).split(",", false))
	var secs := float(_arg("secs", "20"))
	for lvl: String in levels:
		await _one(game, lvl, secs)
	quit(0)


func _one(game: Node, lvl: String, secs: float) -> void:
	game.level_id = lvl
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame
	var givers := get_nodes_in_group("challengers")
	if givers.is_empty():
		print("DAREBOT %s none" % lvl)
		_free()
		return
	var g: Node2D = givers[0]
	var side := 1.0 if g.global_position.x < float(m.walk_cx) else -1.0
	var at: Vector2 = g.global_position + Vector2(140.0 * side, 0.0)
	m.dog.global_position = at
	m.human.global_position = at + Vector2(0, 60)
	m.leash.resnap()
	await _frames(0.3)
	var near := 0
	for p: Vector2 in m.poles:
		if p.distance_to(g.global_position) < NEAR:
			near += 1
	m.dog.energy = 1.0
	m.challenge.begin(99, secs)  # never won, so it counts to the bell
	m.challenge_giver = g
	var swings0: int = int(m.vaults_landed)
	var flings0: int = int(m.flings_done)
	target = Vector2(INF, INF)
	used.clear()
	Input.action_press("turbo")
	var frames := int(secs * 60.0)
	var best := 0
	for f in range(frames):
		_steer(g.global_position)
		await physics_frame
		best = maxi(best, int(m.challenge.count))
		if OS.get_environment("DAREBOT_TRACE") != "" and f % 30 == 0:
			print("  t=%.1f dog=%s v=%.0f en=%.2f taut=%s pole=%s tgt=%s vault_t=%.2f whirl=%s cnt=%d" % [f / 60.0,
				str(m.dog.global_position.round()), m.dog.velocity.length(), float(m.dog.energy), str(m.leash.taut),
				str(m.leash.contact_pole.round()) if m.leash.contact_pole.x < INF else "-", str(target.round()),
				float(m.vault_t), str(m.human.is_whirling()), int(m.challenge.count)])
		if not bool(m.challenge.active):
			break
	_release()
	print("DAREBOT %s %s tricks=%d swings=%d flings=%d poles_near=%d" % [lvl, g.who, best,
		int(m.vaults_landed) - swings0, int(m.flings_done) - flings0, near])
	_free()


func _free() -> void:
	m.queue_free()
	m = null
	await process_frame
	await process_frame


func _frames(s: float) -> void:
	for i in range(int(s * 60.0)):
		await physics_frame


func _release() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down", "turbo"]:
		Input.action_release(a)


func _pick(around: Vector2) -> void:
	var d: Vector2 = m.dog.global_position
	var best := INF
	target = Vector2(INF, INF)
	for p: Vector2 in m.poles:
		if p.distance_to(around) > NEAR:
			continue
		var skip := false
		for u in used:
			if u.distance_to(p) < 60.0:
				skip = true
		if skip:
			continue
		var k := p.distance_to(d)
		if k < best:
			best = k
			target = p
	if target.x == INF and not used.is_empty():
		# every pole near has had its swing: start the round again
		used = [used[used.size() - 1]]
		_pick(around)


func _steer(around: Vector2) -> void:
	var done: Vector2 = m.vault_done_pole
	if done.x != INF and (used.is_empty() or used[used.size() - 1].distance_to(done) > 1.0):
		used.append(done)
		if target.x != INF and done.distance_to(target) < 60.0:
			target = Vector2(INF, INF)
	if target.x == INF:
		_pick(around)
	if target.x == INF:
		_press(Vector2.ZERO)
		return
	var d: Vector2 = m.dog.global_position
	var h: Vector2 = m.human.global_position
	var r := d - target
	var dist := r.length()
	var want: Vector2
	if dist > RADIUS * 2.0:
		# run for the far side of the pole from your human, so the leash catches it
		var far := target + (target - h).normalized() * RADIUS
		want = (far - d).normalized()
		sense = 1.0 if r.cross(target - h) > 0.0 else -1.0
	else:
		var tan := r.orthogonal().normalized() * sense
		want = (tan + r.normalized() * clampf((RADIUS - dist) / 40.0, -1.0, 1.0)).normalized()
	_press(want)


func _press(v: Vector2) -> void:
	_hold("move_right", maxf(v.x, 0.0))
	_hold("move_left", maxf(-v.x, 0.0))
	_hold("move_down", maxf(v.y, 0.0))
	_hold("move_up", maxf(-v.y, 0.0))


func _hold(a: String, s: float) -> void:
	if s > 0.05:
		Input.action_press(a, s)
	else:
		Input.action_release(a)
