extends Node2D

# Pull of Duty - leash physics prototype.
# You are the dog. Walk the phone-zombie human to the park with the phone intact.

const SIDEWALK_LEFT := 340.0
const SIDEWALK_RIGHT := 940.0
const START_Y := 260.0
const GATE_Y := -5000.0
const LEASH_LENGTH := 260.0
const LEASH_STRETCH_CAP := 1.15
const LEASH_K := 32.0
const DOG_MASS := 1.0
const HUMAN_MASS := 4.0
const POLE_RADIUS := 10.0

const LANE_YS: Array[float] = [-1200.0, -2600.0, -4000.0]
const LANE_HALF := 70.0

const COL_GRASS := Color(0.32, 0.42, 0.3)
const COL_GRASS_DARK := Color(0.28, 0.37, 0.26)
const COL_SIDEWALK := Color(0.68, 0.66, 0.61)
const COL_SEAM := Color(0.6, 0.58, 0.53)
const COL_ROAD := Color(0.24, 0.24, 0.27)
const COL_STRIPE := Color(0.75, 0.72, 0.63)

var dog: CharacterBody2D
var human: CharacterBody2D
var leash: Node2D
var cam: Camera2D

var poles: Array[Vector2] = []
var manholes: Array[Vector2] = []
var hydrants: Array = []
var kebabs: Array = []
var tufts: Array[Vector2] = []
var trees: Array[Vector2] = []
var benches: Array[Vector2] = []
var cellars: Array[Rect2] = []
var tables: Array[Vector2] = []
var deco_pole_count := 0
var lane_state: Array = []

var leash_len := LEASH_LENGTH
var leash_target := LEASH_LENGTH
var bones := 0
var streak := 0
var phone_hp := 3
var pee := 1.0
var marks: Array[Vector2] = []
var puddles: Array[Vector2] = []
var mark_progress := 0.0
var mark_target := Vector2(INF, INF)
var stray_t := 0.0
var poop_state := 0  # 0 not yet, 1 urge, 2 done, 3 forced telegraph, 4 forced squat
var urge_y := -2000.0
var urge_timer := 0.0
var squat_progress := 0.0
var business_spot := Vector2(INF, INF)
var elapsed := 0.0
var frozen := false
var shake_t := 0.0

var hud: CanvasLayer
var phone_label: Label
var bones_label: Label
var pee_label: Label
var tube: Control
var msg_label: Label
var dim: ColorRect
var font: Font


func _ready() -> void:
	Engine.time_scale = 1.0
	font = ThemeDB.fallback_font
	_setup_input()
	_build_level_data()
	_build_walls()
	_build_entities()
	_build_hud()


func _setup_input() -> void:
	if InputMap.has_action("plant"):
		return
	var moves := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
	}
	for action in moves:
		InputMap.add_action(action)
		for k in moves[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	var axes := {
		"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0],
	}
	for action in axes:
		var ev := InputEventJoypadMotion.new()
		ev.axis = axes[action][0]
		ev.axis_value = axes[action][1]
		InputMap.action_add_event(action, ev)
	var buttons := {
		"plant": [KEY_SPACE, JOY_BUTTON_A], "bark": [KEY_E, JOY_BUTTON_B],
		"restart": [KEY_R, JOY_BUTTON_START],
	}
	for action in buttons:
		InputMap.add_action(action)
		var evk := InputEventKey.new()
		evk.physical_keycode = buttons[action][0]
		InputMap.action_add_event(action, evk)
		var evb := InputEventJoypadButton.new()
		evb.button_index = buttons[action][1]
		InputMap.action_add_event(action, evb)


func _build_level_data() -> void:
	for i in range(7):
		var x := SIDEWALK_LEFT + 30.0 if i % 2 == 0 else SIDEWALK_RIGHT - 30.0
		var y := -350.0 - i * 640.0
		var near_lane := false
		for ly in LANE_YS:
			if absf(y - ly) < LANE_HALF + 60.0:
				near_lane = true
		if not near_lane:
			poles.append(Vector2(x, y))
	for mp in [Vector2(640, -1750), Vector2(700, -2900), Vector2(580, -4250)]:
		poles.append(mp)
	deco_pole_count = poles.size()
	# cafe terrace: tables join the poles array so they block bodies and
	# snag the leash, but they are drawn as tables
	tables = [Vector2(760, -3560), Vector2(840, -3660), Vector2(700, -3700), Vector2(790, -3780)]
	for tb in tables:
		poles.append(tb)
	benches = [Vector2(376, -1300), Vector2(904, -2450), Vector2(376, -3850)]
	cellars = [Rect2(340, -2750, 62, 88), Rect2(878, -750, 62, 82), Rect2(340, -4550, 62, 88)]
	urge_y = randf_range(-3200.0, -1500.0)
	manholes = [
		Vector2(560, -700), Vector2(760, -950), Vector2(480, -1700),
		Vector2(700, -2100), Vector2(600, -3100), Vector2(820, -3450),
		Vector2(520, -4400),
	]
	for hp in [
		Vector2(SIDEWALK_LEFT + 45, -500), Vector2(SIDEWALK_RIGHT - 45, -1500),
		Vector2(SIDEWALK_LEFT + 45, -2300), Vector2(SIDEWALK_RIGHT - 45, -3300),
		Vector2(SIDEWALK_LEFT + 45, -4600),
	]:
		hydrants.append({"pos": hp, "done": false, "progress": 0.0})
	for kp in [Vector2(620, -1900), Vector2(700, -4200)]:
		kebabs.append({"pos": kp, "eaten": false})
	for i in range(140):
		var side := -1.0 if randf() < 0.5 else 1.0
		var x := 640.0 + side * randf_range(340.0, 620.0)
		tufts.append(Vector2(x, randf_range(GATE_Y - 600.0, START_Y + 150.0)))
	for i in range(14):
		trees.append(Vector2(randf_range(200.0, 1080.0), GATE_Y - randf_range(120.0, 550.0)))
	for ly in LANE_YS:
		lane_state.append({"t": randf_range(1.0, 2.5), "phase": 0, "dir": 1})


func _build_walls() -> void:
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	var mid_y := (START_Y + GATE_Y) / 2.0
	var span := absf(START_Y - GATE_Y) + 1600.0
	var defs := [
		[Vector2(SIDEWALK_LEFT - 50.0, mid_y), Vector2(100, span)],
		[Vector2(SIDEWALK_RIGHT + 50.0, mid_y), Vector2(100, span)],
		[Vector2(640, START_Y + 160.0), Vector2(1400, 100)],
		[Vector2(640, GATE_Y - 700.0), Vector2(1400, 100)],
	]
	for d in defs:
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = d[1]
		cs.shape = sh
		cs.position = d[0]
		walls.add_child(cs)
	add_child(walls)
	for p in poles:
		var sb := StaticBody2D.new()
		sb.collision_layer = 1
		sb.position = p
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = POLE_RADIUS
		cs.shape = sh
		sb.add_child(cs)
		add_child(sb)


func _build_entities() -> void:
	leash = Node2D.new()
	leash.set_script(load("res://leash.gd"))
	leash.z_index = 5
	add_child(leash)

	dog = CharacterBody2D.new()
	dog.set_script(load("res://dog.gd"))
	dog.position = Vector2(700, START_Y)
	add_child(dog)
	dog.setup(self)

	human = CharacterBody2D.new()
	human.set_script(load("res://human.gd"))
	human.position = Vector2(600, START_Y - 70.0)
	add_child(human)
	human.setup(self)

	leash.setup(dog, human, poles, LEASH_LENGTH)

	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	cam.position = Vector2(640, START_Y - 120.0)
	add_child(cam)
	cam.make_current()


func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	phone_label = _hud_label(Vector2(24, 16), 22)
	bones_label = _hud_label(Vector2(24, 46), 22)
	tube = Control.new()
	tube.set_script(load("res://pee_tube.gd"))
	tube.position = Vector2(26, 82)
	tube.size = Vector2(16, 84)
	hud.add_child(tube)
	pee_label = _hud_label(Vector2(52, 112), 17)
	var hint := _hud_label(Vector2(24, 686), 15)
	hint.text = "WASD / left stick: move    hold SPACE / A: dig in, mark, squat    E / B: bark    R: restart"
	hint.modulate.a = 0.75
	var title := _hud_label(Vector2(0, 90), 30)
	title.size = Vector2(1280, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "TOUCH GRASS"
	var sub := _hud_label(Vector2(0, 128), 17)
	sub.size = Vector2(1280, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.text = "Take the Path of Leash Resistance"
	for l in [title, sub]:
		var tw := create_tween()
		tw.tween_interval(3.5)
		tw.tween_property(l, "modulate:a", 0.0, 1.0)
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = Vector2(1280, 720)
	dim.visible = false
	hud.add_child(dim)
	msg_label = _hud_label(Vector2(0, 290), 28)
	msg_label.size = Vector2(1280, 220)
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.visible = false
	_update_hud()


func _hud_label(pos: Vector2, size_px: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size_px)
	hud.add_child(l)
	return l


func _update_hud() -> void:
	phone_label.text = "PHONE  " + "#".repeat(phone_hp) + ".".repeat(3 - phone_hp)
	var streak_txt := "   STREAK x%d" % streak if streak > 1 else ""
	bones_label.text = "BONES  %d%s" % [bones, streak_txt]
	var status := ""
	if poop_state == 1:
		status = "GOTTA GO!  find a spot, hold SPACE"
	elif poop_state >= 3:
		status = "UH OH..."
	elif pee >= 0.999:
		status = "FULL!"
	pee_label.text = status


func _physics_process(delta: float) -> void:
	if frozen:
		return
	elapsed += delta
	dog.tick(delta)
	human.tick(delta)
	# the human owns the retractable leash: length changes on their whim
	# ("click!" event), never the dog's
	leash_len = move_toward(leash_len, leash_target, 150.0 * delta)
	leash.rest_len = leash_len
	_apply_leash(delta)
	_lanes(delta)
	_hazards(delta)
	_pickups(delta)
	_bodily(delta)
	_check_win()
	shake_t = maxf(0.0, shake_t - delta * 2.5)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return
	var target_y := (dog.global_position.y + human.global_position.y) / 2.0 - 60.0
	cam.position = Vector2(640, target_y)
	if shake_t > 0.0:
		cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 9.0 * shake_t
	else:
		cam.offset = Vector2.ZERO
	queue_redraw()


func _apply_leash(delta: float) -> void:
	# The rope itself (leash.gd) is the constraint. Here: run the rope
	# physics, then turn its stretch into tug-of-war forces. One tension,
	# applied to each end inversely to effective mass along the rope's end
	# tangent - so a wound-up human is pulled around the pole in an arc.
	# The human is ~4x the dog, so raw pulls yank the DOG around; the dog
	# wins by bracing (plant), winding poles (the coil grips and shields
	# both ends from raw tension while geometry still constrains), timing.
	human.strain = false
	dog.dragged = false
	leash.tick(delta)
	# the whirl manages its own release (aimed at the dog); no early exit,
	# or the launch direction would be random
	var whirling: bool = human.is_whirling()
	if whirling:
		# the choreographed unwind must never be arrested by rope grip
		leash.free_slip_t = 0.7
	var used: float = leash.used_length()
	var excess := used - leash_len
	leash.taut = excess > 0.0
	if excess <= 0.0:
		return
	var h_dir: Vector2 = leash.human_pull_dir()
	var d_dir: Vector2 = leash.dog_pull_dir()
	if h_dir == Vector2.ZERO or d_dir == Vector2.ZERO:
		return
	human.notify_strain()
	dog.dragged = not dog.planted
	var shield := 1.0 / (1.0 + 0.3 * float(leash.contacts))
	var dog_m := DOG_MASS
	if dog.planted:
		dog_m *= 14.0
	elif dog.input_active:
		dog_m *= 2.0
	var human_m := HUMAN_MASS * (2.0 if human.is_fallen() else 1.0)
	var tension := minf(LEASH_K * excess, 1600.0) * shield
	if whirling:
		# the dog's pulling feeds the whirl's spin-up (pulley)
		human.whirl_pull = maxf(float(human.whirl_pull), tension)
	if not whirling:
		human.velocity += h_dir * (tension / human_m) * delta
	if not dog.planted:
		dog.velocity += d_dir * (tension / dog_m) * delta
	# damp separating components so neither end bungees
	var sep_h := human.velocity.dot(-h_dir)
	if sep_h > 0.0 and not whirling:
		human.velocity += h_dir * sep_h * minf(5.0 * delta, 1.0)
	var sep_d := dog.velocity.dot(-d_dir)
	if sep_d > 0.0 and not dog.planted:
		dog.velocity += d_dir * sep_d * minf(3.0 * delta, 1.0)
	# hard cap: geometry always wins. Corrections follow the rope tangents
	# (unshielded), which is what whips a wound human along the arc.
	var cap := leash_len * (LEASH_STRETCH_CAP - 1.0)
	if excess > cap:
		var over := excess - cap
		var w_d := (1.0 / dog_m) / (1.0 / dog_m + 1.0 / human_m)
		var yank_speed := maxf(human.velocity.dot(-h_dir), 0.0)
		dog.move_and_collide(d_dir * over * w_d)
		if not whirling:
			human.move_and_collide(h_dir * over * (1.0 - w_d))
			var rel := human.velocity.dot(-h_dir)
			if rel > 0.0:
				human.velocity += h_dir * rel * 0.9
			var anchored: bool = dog.planted or leash.contacts > 0
			human.on_leash_yank(-h_dir, anchored, yank_speed)
	# cartoon tetherball: a human wound around a nearby pole who keeps
	# getting pulled starts to WHIRL - an accelerating orbit that unwinds
	# the rope and flings them when it runs out (Bugs Bunny physics)
	if not whirling and not human.is_fallen() and excess > 8.0:
		var end_wind: float = leash.human_end_winding()
		if absf(leash.winding()) > 0.7 and absf(end_wind) > 1.6:
			var wp := _nearest_pole_to(human.global_position, 70.0)
			if wp.x < INF:
				var spin_dir := -signf(end_wind)
				if spin_dir == 0.0:
					spin_dir = 1.0
				human.start_whirl(wp, spin_dir, absf(leash.winding()))


func _lanes(delta: float) -> void:
	for i in range(lane_state.size()):
		var ls: Dictionary = lane_state[i]
		if absf(LANE_YS[i] - cam.position.y) > 950.0:
			continue
		ls.t -= delta
		if ls.t <= 0.0:
			if ls.phase == 0:
				ls.phase = 1
				ls.dir = 1 if randf() < 0.5 else -1
				ls.t = 0.75
			else:
				ls.phase = 0
				ls.t = randf_range(1.7, 3.2)
				_spawn_bike(LANE_YS[i] + randf_range(-34.0, 34.0), ls.dir)


func _spawn_bike(y: float, dir: int) -> void:
	var b := Node2D.new()
	b.set_script(load("res://bike.gd"))
	b.position = Vector2(-250.0 if dir > 0 else 1530.0, y)
	b.z_index = 12
	add_child(b)
	b.setup(self, dog, human, dir)


func _hazards(_delta: float) -> void:
	for m in manholes:
		if human.global_position.distance_to(m) < 26.0:
			human.fall("manhole")
		if dog.hole_cd <= 0.0 and dog.global_position.distance_to(m) < 20.0:
			dog.fall_in(m)
	for c in cellars:
		if c.has_point(human.global_position):
			human.fall("cellar")
		if dog.hole_cd <= 0.0 and c.has_point(dog.global_position):
			dog.fall_in(c.get_center())


func _pickups(delta: float) -> void:
	for h in hydrants:
		if h.done:
			continue
		if dog.global_position.distance_to(h.pos) < 55.0 and dog.velocity.length() < 60.0:
			h.progress += delta
			if h.progress >= 0.8:
				h.done = true
				bones += 2
				float_text(h.pos, "good sniff +2", Color(1, 0.95, 0.7))
				_update_hud()
	for k in kebabs:
		if not k.eaten and dog.global_position.distance_to(k.pos) < 26.0:
			k.eaten = true
			bones += 1
			float_text(k.pos, "snack +1", Color(1, 0.95, 0.7))
			_update_hud()


func _bodily(delta: float) -> void:
	# the life of a dog: pee anywhere the leash allows (spots score),
	# and once per walk nature calls for a longer stop
	pee = minf(1.0, pee + 0.008 * delta)
	dog.bladder_slow = pee >= 0.999
	tube.level = pee
	# a casual plant with a slack leash means peeing; bracing against a
	# taut leash does not (the tank is a per-walk budget, ~9 breaks)
	var going: bool = dog.planted and not dog.is_tumbling() and not leash.taut and pee > 0.02
	if going:
		pee = maxf(0.0, pee - 0.16 * delta)
		var target := _nearest_markable(dog.global_position)
		if target.x < INF:
			if target != mark_target:
				mark_target = target
				mark_progress = 0.0
			mark_progress += delta
			stray_t = 0.0
			if mark_progress >= 0.7:
				bones += 3
				marks.append(target)
				float_text(target, "marked! +3", Color(1, 0.95, 0.7))
				mark_progress = 0.0
				mark_target = Vector2(INF, INF)
		else:
			mark_target = Vector2(INF, INF)
			mark_progress = 0.0
			stray_t += delta
	else:
		if stray_t >= 0.4:
			puddles.append(dog.global_position + Vector2(4, 8))
		stray_t = 0.0
		mark_progress = 0.0
		mark_target = Vector2(INF, INF)
	match poop_state:
		0:
			if dog.global_position.y < urge_y:
				poop_state = 1
				urge_timer = 35.0
				float_text(dog.global_position, "uh oh...", Color(1, 0.9, 0.6))
		1:
			urge_timer -= delta
			if dog.planted and not dog.is_tumbling():
				squat_progress += delta
				dog.squat_ui = squat_progress / 2.5
				if squat_progress >= 2.5:
					_finish_business(true)
			else:
				squat_progress = maxf(0.0, squat_progress - delta * 2.0)
				dog.squat_ui = squat_progress / 2.5
			if poop_state == 1 and urge_timer <= 0.0:
				poop_state = 3
				urge_timer = 1.2
				float_text(dog.global_position, "UH OH", Color(1, 0.6, 0.5))
		3:
			urge_timer -= delta
			if urge_timer <= 0.0:
				poop_state = 4
				dog.forced_squat(2.5)
		4:
			if dog.squat_t <= 0.0:
				_finish_business(false)
	_update_hud()


func _finish_business(voluntary: bool) -> void:
	poop_state = 2
	dog.squat_ui = 0.0
	squat_progress = 0.0
	business_spot = dog.global_position + Vector2(0, 8)
	if voluntary:
		bones += 5
		float_text(dog.global_position, "relief +5", Color(0.8, 1.0, 0.8))
	else:
		float_text(dog.global_position, "couldn't wait", Color(1, 0.8, 0.6))
	human.gross_out()


func _nearest_markable(pos: Vector2) -> Vector2:
	var best := Vector2(INF, INF)
	var best_d := 42.0
	for h in hydrants:
		var hp: Vector2 = h.pos
		if not marks.has(hp):
			var d := pos.distance_to(hp)
			if d < best_d:
				best_d = d
				best = hp
	for p in poles:
		if not marks.has(p):
			var d := pos.distance_to(p)
			if d < best_d:
				best_d = d
				best = p
	return best


func _check_win() -> void:
	if dog.global_position.y < GATE_Y and human.global_position.y < GATE_Y:
		frozen = true
		dim.visible = true
		msg_label.visible = true
		msg_label.text = "WALK COMPLETE\n\nBones: %d    Phone: %d/3    Time: %ds\n\nPress R for another walk" % [bones, phone_hp, int(elapsed)]


func on_bark(pos: Vector2) -> void:
	if human.global_position.distance_to(pos) < 170.0:
		human.halt(0.8)


func set_leash_target(v: float) -> void:
	leash_target = clampf(v, 120.0, 330.0)


func _nearest_pole_to(pos: Vector2, max_d: float) -> Vector2:
	var best := Vector2(INF, INF)
	var best_d := max_d
	for p in poles:
		var d := pos.distance_to(p)
		if d < best_d:
			best_d = d
			best = p
	return best


func nearest_bench(pos: Vector2):
	var best = null
	var best_d := 380.0
	for b in benches:
		var d := pos.distance_to(b)
		if d < best_d:
			best_d = d
			best = b
	return best


func on_stumble_save(pos: Vector2) -> void:
	for b in get_tree().get_nodes_in_group("bikes"):
		if b.global_position.distance_to(pos) < 170.0:
			streak += 1
			bones += streak
			float_text(pos + Vector2(0, -30), "NICE SAVE +%d" % streak, Color(0.7, 1.0, 0.75))
			_slowmo()
			_update_hud()
			return


func _slowmo() -> void:
	Engine.time_scale = 0.3
	var t := get_tree().create_timer(0.35, true, false, true)
	t.timeout.connect(func() -> void: Engine.time_scale = 1.0)


func crack_phone(pos: Vector2) -> void:
	phone_hp -= 1
	streak = 0
	shake_t = 1.0
	_update_hud()
	float_text(pos, "PHONE CRACKED", Color(1, 0.45, 0.4))
	if phone_hp <= 0:
		frozen = true
		dim.visible = true
		msg_label.visible = true
		msg_label.text = "THE PHONE IS SHATTERED\n\nThe human is inconsolable. The walk is over.\n\nPress R to try again"


func close_call(pos: Vector2) -> void:
	bones += 1
	float_text(pos, "close call +1", Color(0.75, 0.9, 1.0))
	_update_hud()


func float_text(pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	var l := Label.new()
	l.text = text
	l.z_index = 100
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", color)
	add_child(l)
	l.position = pos + Vector2(-40, -56)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - 44.0, 0.9)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.9)
	tw.tween_callback(l.queue_free)


func _draw() -> void:
	var top := GATE_Y - 800.0
	var bottom := START_Y + 320.0
	draw_rect(Rect2(-400, top, 2100, bottom - top), COL_GRASS)
	for t in tufts:
		draw_circle(t, 5.0, COL_GRASS_DARK)
	# park beyond the gate
	draw_rect(Rect2(-400, top, 2100, GATE_Y - top), Color(0.27, 0.4, 0.27))
	for t in trees:
		draw_circle(t, 26.0, Color(0.22, 0.34, 0.22))
		draw_circle(t + Vector2(8, 6), 18.0, Color(0.25, 0.38, 0.24))
	# sidewalk
	draw_rect(Rect2(SIDEWALK_LEFT, GATE_Y - 40.0, SIDEWALK_RIGHT - SIDEWALK_LEFT, bottom - GATE_Y), COL_SIDEWALK)
	var y := START_Y + 200.0
	while y > GATE_Y:
		draw_line(Vector2(SIDEWALK_LEFT, y), Vector2(SIDEWALK_RIGHT, y), COL_SEAM, 2.0)
		y -= 150.0
	draw_line(Vector2(SIDEWALK_LEFT, bottom), Vector2(SIDEWALK_LEFT, GATE_Y), COL_SEAM, 3.0)
	draw_line(Vector2(SIDEWALK_RIGHT, bottom), Vector2(SIDEWALK_RIGHT, GATE_Y), COL_SEAM, 3.0)
	# bike lanes crossing the sidewalk
	for i in range(LANE_YS.size()):
		var ly: float = LANE_YS[i]
		draw_rect(Rect2(-400, ly - LANE_HALF, 2100, LANE_HALF * 2.0), COL_ROAD)
		var x := -380.0
		while x < 1700.0:
			draw_line(Vector2(x, ly), Vector2(x + 30.0, ly), COL_STRIPE, 3.0)
			x += 70.0
		draw_line(Vector2(-400, ly - LANE_HALF), Vector2(1700, ly - LANE_HALF), COL_STRIPE, 2.0)
		draw_line(Vector2(-400, ly + LANE_HALF), Vector2(1700, ly + LANE_HALF), COL_STRIPE, 2.0)
		var ls: Dictionary = lane_state[i]
		if ls.phase == 1 and fmod(Time.get_ticks_msec() / 150.0, 2.0) < 1.0:
			var wx := 40.0 if ls.dir > 0 else 1240.0
			draw_circle(Vector2(wx, ly), 16.0, Color(0.95, 0.8, 0.25))
			draw_rect(Rect2(wx - 2.0, ly - 9.0, 4.0, 10.0), Color(0.15, 0.15, 0.15))
			draw_circle(Vector2(wx, ly + 6.0), 2.2, Color(0.15, 0.15, 0.15))
	# manholes
	for m in manholes:
		draw_circle(m, 24.0, Color(0.12, 0.12, 0.14))
		draw_arc(m, 19.0, 0, TAU, 24, Color(0.3, 0.3, 0.33), 2.0)
	# hydrants
	for h in hydrants:
		var c := Color(0.45, 0.4, 0.38) if h.done else Color(0.64, 0.26, 0.2)
		draw_circle(h.pos, 9.0, c)
		draw_circle(h.pos + Vector2(0, -8), 5.0, c.darkened(0.2))
		if not h.done and h.progress > 0.0:
			draw_arc(h.pos, 15.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)
	# kebabs
	for k in kebabs:
		if not k.eaten:
			draw_circle(k.pos, 7.0, Color(0.75, 0.55, 0.3))
			draw_line(k.pos + Vector2(-3, 5), k.pos + Vector2(4, -6), Color(0.5, 0.35, 0.2), 2.0)
	# lampposts (cafe tables share the poles array but are drawn below)
	for i in range(deco_pole_count):
		var p := poles[i]
		draw_circle(p, POLE_RADIUS + 3.0, Color(0.2, 0.2, 0.22, 0.35))
		draw_circle(p, POLE_RADIUS, Color(0.44, 0.44, 0.48))
		draw_circle(p, 4.0, Color(0.55, 0.55, 0.6))
	# cafe tables
	for tb in tables:
		draw_circle(tb, 14.0, Color(0.6, 0.55, 0.48))
		draw_arc(tb, 14.0, 0, TAU, 20, Color(0.45, 0.4, 0.34), 2.0)
		draw_circle(tb, 3.0, Color(0.4, 0.36, 0.3))
	# benches
	for b in benches:
		draw_rect(Rect2(b.x - 8, b.y - 24, 16, 48), Color(0.5, 0.38, 0.26))
		draw_line(Vector2(b.x, b.y - 22), Vector2(b.x, b.y + 22), Color(0.42, 0.32, 0.22), 2.0)
	# cellar doors
	for c in cellars:
		draw_rect(c, Color(0.1, 0.1, 0.12))
		draw_rect(Rect2(c.position.x, c.position.y, c.size.x, 6), Color(0.35, 0.28, 0.22))
		draw_line(c.position + Vector2(c.size.x / 2.0, 0), c.position + Vector2(c.size.x / 2.0, c.size.y), Color(0.3, 0.3, 0.33), 2.0)
	# marked spots, stray puddles and, discreetly, the business
	for mk in marks:
		draw_circle(mk + Vector2(7, 9), 3.0, Color(0.95, 0.88, 0.5, 0.55))
	for pd in puddles:
		draw_circle(pd, 4.0, Color(0.93, 0.85, 0.4, 0.35))
	if business_spot.x < INF:
		draw_circle(business_spot, 3.0, Color(0.35, 0.25, 0.15))
	if mark_target.x < INF and mark_progress > 0.0:
		draw_arc(mark_target, 17.0, -PI / 2.0, -PI / 2.0 + TAU * mark_progress / 0.7, 20, Color(1, 0.95, 0.6), 3.0)
	# park gate
	draw_rect(Rect2(SIDEWALK_LEFT - 14, GATE_Y - 46, 14, 60), Color(0.35, 0.3, 0.28))
	draw_rect(Rect2(SIDEWALK_RIGHT, GATE_Y - 46, 14, 60), Color(0.35, 0.3, 0.28))
	draw_rect(Rect2(SIDEWALK_LEFT - 14, GATE_Y - 58, SIDEWALK_RIGHT - SIDEWALK_LEFT + 28, 14), Color(0.35, 0.3, 0.28))
	draw_string(font, Vector2(600, GATE_Y - 66), "PARK", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.9, 0.88, 0.8))
	var gx := SIDEWALK_LEFT
	while gx < SIDEWALK_RIGHT:
		draw_line(Vector2(gx, GATE_Y), Vector2(gx + 16.0, GATE_Y), Color(0.9, 0.88, 0.8, 0.6), 3.0)
		gx += 32.0
	# start hint
	draw_string(font, Vector2(430, START_Y + 90), "The park is up ahead. Mind the bike lanes.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(1, 1, 1, 0.5))
