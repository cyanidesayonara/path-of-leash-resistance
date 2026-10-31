extends SceneTree

# BOSS SHOTS: photograph each beat of El Gat de Botero (systems/boss_gat.gd)
# without playing up to it: the wake, the enrage, a charge and its lane, a
# stun, the last stand on the plinth, the teeter, the topple and the
# fireworks. Each beat puts the pair beside him and forces his state, then
# lets the real walk run for a moment before the photograph.
#
#   godot --path . --rendering-method gl_compatibility --script res://tools/boss_shots.gd -- --out=C:/tmp/boss

var m: Node2D
var out_dir := "user://boss_shots"
var n := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var game: Node = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "raval"
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	m.auto_walk = false
	var BG: GDScript = load("res://systems/boss_gat.gd")
	var gat = m.boss_gat

	# the wake
	_place(Vector2(640, -300), Vector2(640, -180))
	await _frames(4)
	await _shot("wake_eyes", 0.45)
	await _shot("wake_roar", 0.9)
	await _shot("wake_hop", 0.7)

	# the enrage, out on the rambla
	gat.pos = Vector2(640, -1500)
	gat.update_leg_positions()
	gat.hp = BG.MAX_HP * 0.5
	gat.phase = 2
	_place(Vector2(560, -1300), Vector2(620, -1150))
	gat.transition_to(BG.State.PROWL)
	await _shot("enrage", 0.6)

	# a charge: the lane, then the run
	gat.charge_cooldown = 99.0
	gat.swat_cooldown = 99.0
	_place(Vector2(640, -1220), Vector2(560, -1100))
	gat.transition_to(BG.State.CHARGE_WARN)
	await _shot("charge_lane", 0.5)
	await _shot("charge_run", 0.55)
	gat.transition_to(BG.State.STUNNED)
	await _shot("stunned", 0.25)

	# the last stand on his plinth
	gat.hp = 0.0
	gat.transition_to(BG.State.ROAR)
	_place(BG.PEDESTAL_POS + Vector2(110, 40), Vector2(640, BG.HOLD_Y))
	gat.ls_swat_cd = 0.0
	await _shot("last_stand", 0.5)
	gat.transition_to(BG.State.WRAPPED)
	await _shot("teeter", 0.7)
	await _shot("toppled", 0.6)
	m.dog.global_position = gat.snout_pos + Vector2(30, 0)
	gat.on_bark_action(gat.snout_pos)
	await _shot("fireworks", 1.2)
	await _shot("fireworks_late", 1.0)
	print("BOSS SHOTS done: %d in %s" % [n, out_dir])
	quit(0)


func _place(dog_at: Vector2, human_at: Vector2) -> void:
	m.dog.global_position = dog_at
	m.dog.velocity = Vector2.ZERO
	m.human.global_position = human_at
	m.human.velocity = Vector2.ZERO
	m.leash.resnap()


func _frames(k: int) -> void:
	for i in range(k):
		await process_frame


func _shot(label: String, secs: float) -> void:
	var stop := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < stop:
		await process_frame
	await RenderingServer.frame_post_draw
	n += 1
	var path := "%s/%02d_%s.png" % [out_dir, n, label]
	root.get_viewport().get_texture().get_image().save_png(path)
	print("BOSS SHOTS %s" % path)
