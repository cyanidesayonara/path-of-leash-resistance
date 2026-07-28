extends Node2D

const DogAppearanceScript := preload("res://dog_appearance.gd")

# BRUTUS. The dog at the park who is having a lovely time at your expense.
#
# He is not a hazard and he cannot hurt you - he is a THIEF. He waits for you
# to earn something (a ball you have gone and fetched, a bone you have dug
# up), takes it, and legs it looking extremely pleased with himself. You get
# it back by barking him out of it or by catching him, which is why he makes
# the fetch and dig systems better: they now have something pushing back.
#
# Design rules he obeys, so he stays funny rather than infuriating:
#  - he never steals out of your mouth, only things sitting on the ground
#  - a bark at close range ALWAYS makes him drop it (no dice rolls)
#  - he gives up after a while and leaves the loot behind
#  - he is faster in a straight line but turns like a bus, so a dog who
#    cuts corners beats him

enum S { PROWL, STALK, FLEE, SULK, GONE }

const PROWL_SPEED := 96.0
const STALK_SPEED := 176.0
const FLEE_SPEED := 232.0
const TURN_RATE := 3.4       # deliberately sluggish: this is how you beat him
const SNATCH_R := 26.0
const BARK_R := 132.0
const FLEE_TIME := 9.0

var main: Node2D
var my_dog: Node2D
var bounds := Rect2()
var state: S = S.PROWL
var vel := Vector2.ZERO
var face := Vector2.DOWN
var target_pos := Vector2(INF, INF)
var target_ref = null        # the prop dictionary he is going for, if any
var loot := ""               # "" | "ball" | "bone"
var t := 0.0
var sulk_t := 0.0
var seed_o := 0.0
var appearance: Dictionary = {}


func setup(m: Node2D, mine: Node2D, area: Rect2) -> void:
	add_to_group("rivals")
	main = m
	my_dog = mine
	bounds = area
	# a big scruffy one, picked deterministically so Brutus is always Brutus
	appearance = DogAppearanceScript.profile_for_key(0x8B2705)
	seed_o = fmod(absf(position.x) * 0.017, TAU)
	_pick_wander()


func _pick_wander() -> void:
	target_pos = Vector2(
		randf_range(bounds.position.x + 40.0, bounds.end.x - 40.0),
		randf_range(bounds.position.y + 40.0, bounds.end.y - 40.0)
	)


func _physics_process(delta: float) -> void:
	if main.frozen or state == S.GONE:
		return
	t += delta
	match state:
		S.PROWL:
			# trotting about, keeping half an eye out for something to nick
			if global_position.distance_to(target_pos) < 40.0:
				_pick_wander()
			_move_toward(target_pos, PROWL_SPEED, delta)
			var mark = _find_loot()
			if mark != null:
				target_ref = mark
				target_pos = mark["pos"]
				state = S.STALK
				main.float_text(global_position + Vector2(0, -26), "oh, is that FREE?", Color(1, 0.85, 0.7))
		S.STALK:
			# is it still there? if you picked it up he loses interest
			if target_ref == null or not _loot_still_there(target_ref):
				target_ref = null
				state = S.PROWL
				_pick_wander()
				return
			target_pos = target_ref["pos"]
			_move_toward(target_pos, STALK_SPEED, delta)
			if global_position.distance_to(target_pos) < SNATCH_R:
				_snatch()
		S.FLEE:
			sulk_t -= delta
			# a bark in his ear and he drops it every time - no dice rolls
			# (the player is being punished enough by having to chase him)
			if my_dog.global_position.distance_to(global_position) < SNATCH_R:
				_drop("caught him!", true)
				return
			if sulk_t <= 0.0:
				# he loses interest and wanders off with it. NOT a win for
				# you - you did nothing - so this pays nothing.
				_drop("...he got away with it", false)
				return
			# he runs for a corner, but he turns like a bus
			_move_toward(target_pos, FLEE_SPEED, delta)
			if global_position.distance_to(target_pos) < 50.0:
				_pick_corner()
		S.SULK:
			sulk_t -= delta
			vel = vel.move_toward(Vector2.ZERO, 400.0 * delta)
			position += vel * delta
			if sulk_t <= 0.0:
				state = S.PROWL
				_pick_wander()
	position.x = clampf(position.x, bounds.position.x, bounds.end.x)
	position.y = clampf(position.y, bounds.position.y, bounds.end.y)
	if Engine.get_physics_frames() % 2 == 0:
		queue_redraw()


func _move_toward(to: Vector2, speed: float, delta: float) -> void:
	var want := (to - global_position)
	if want.length() < 0.001:
		return
	want = want.normalized() * speed
	# the sluggish turn is the whole counterplay: cut the corner and you have
	# him, chase him in a straight line and you never will
	vel = vel.move_toward(want, speed * TURN_RATE * delta)
	position += vel * delta
	if vel.length() > 8.0:
		face = vel.normalized()


func _find_loot():
	# only things sitting on the ground, never out of your mouth
	if is_instance_valid(main.ball) and main.ball.has_method("is_carried") and not main.ball.is_carried():
		if bounds.has_point(main.ball.global_position):
			return {"kind": "ball", "pos": main.ball.global_position}
	for pp in main.park_props:
		if String(pp.kind) == "dig" and pp.done and not pp.get("looted", false):
			return {"kind": "bone", "pos": pp.pos, "prop": pp}
	return null


func _loot_still_there(mark) -> bool:
	if String(mark.kind) == "ball":
		return is_instance_valid(main.ball) and not main.ball.is_carried()
	return not mark["prop"].get("looted", false)


func _snatch() -> void:
	loot = String(target_ref.kind)
	if loot == "bone":
		target_ref["prop"]["looted"] = true
	elif is_instance_valid(main.ball):
		main.ball.queue_free()  # he has it now; the owner will throw another
	state = S.FLEE
	sulk_t = FLEE_TIME
	_pick_corner()
	main.on_rival_snatch(global_position, loot)


func _pick_corner() -> void:
	# away from the dog, roughly, so fleeing reads as fleeing
	var away := (global_position - my_dog.global_position).normalized()
	target_pos = Vector2(
		clampf(global_position.x + away.x * 420.0, bounds.position.x + 30.0, bounds.end.x - 30.0),
		clampf(global_position.y + away.y * 420.0, bounds.position.y + 30.0, bounds.end.y - 30.0)
	)


func _drop(msg: String, earned: bool) -> void:
	# `earned` is the difference between you taking it back off him and him
	# simply getting bored. Only the former is worth anything.
	var had := loot
	loot = ""
	state = S.SULK
	sulk_t = 2.2
	main.on_rival_drop(global_position, had, msg, earned)


func scare() -> void:
	# a bark: if he has your things, he drops them. Always.
	if state == S.FLEE:
		_drop("HA! dropped it", true)
	elif state == S.STALK:
		state = S.SULK
		sulk_t = 1.6
		target_ref = null


func _draw() -> void:
	var tt := Time.get_ticks_msec() / 1000.0
	# contact shadow, same light as everything else
	draw_set_transform(Vector2(4.0, 7.0), 0.0, Vector2(1.2, 0.5))
	draw_circle(Vector2.ZERO, 13.0, Color(0.06, 0.05, 0.08, 0.26))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var bob := sin(tt * 9.0 + seed_o) * (2.0 if state == S.FLEE else 1.0)
	DogAppearanceScript.draw_dog(self, appearance, Vector2.ZERO, face, bob, tt * 12.0 + seed_o)
	# what he is carrying, plainly visible so you know what you are chasing
	if loot == "ball":
		draw_circle(face * 17.0, 6.0, Color(0.82, 0.86, 0.3))
	elif loot == "bone":
		var bp := face * 17.0
		draw_rect(Rect2(bp.x - 7.0, bp.y - 2.0, 14.0, 4.0), Color(0.92, 0.89, 0.80))
		draw_circle(bp + Vector2(-7.0, 0.0), 3.2, Color(0.92, 0.89, 0.80))
		draw_circle(bp + Vector2(7.0, 0.0), 3.2, Color(0.92, 0.89, 0.80))
	if state == S.SULK:
		draw_string(ThemeDB.fallback_font, Vector2(-8, -26), "...", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.85, 0.85, 0.9))
	elif state == S.FLEE:
		# smug speed lines
		for i in range(2):
			var o := -face * (12.0 + float(i) * 7.0)
			draw_line(o, o - face * 8.0, Color(1, 1, 1, 0.35 - float(i) * 0.12), 2.0)
