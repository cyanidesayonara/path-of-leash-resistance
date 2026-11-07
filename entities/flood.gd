extends Node2D

# The river, on the way home from El Besos. The same threat interface as the
# sweeper (setup, advance, caught, gap_to, the jam fields the checkpoint
# copies) so the chase, the camera and the continue all stay one system.
# front_y is the deep front, the loss. The shallow edge is a fixed lead
# south of it: it pushes, wets and loosens the dog's steering, and it is
# not a loss. The swell is the river reaching sideways into the path. It
# narrows the lane; it does not close it.

const LevelBuild := preload("res://world/level_build.gd")
const HumanScript := preload("res://entities/human.gd")
const CurrentFlow := preload("res://systems/current_flow.gd")

const SHALLOW_LEAD := 110.0
const PUSH := 220.0
const PLANT_PUSH := 28.0
# standing in the shallow the whole way home fails "mostly dry"
const SOAK_SECS := 36.0
const SWELL_MAX := 90.0
const JAM_SECS := 3.0
const DEBRIS_SPAN := 560.0
# the same beat as every other owner event: the bubble, then the stumble
const BRANCH_WARN := 0.8
const BRANCH_HIT := 22.0
# the look, as in the film (intro/film_flood.gd): the front is a wall of
# water WALL_H tall seen from above, its lit face toward you and a curling
# foam lip along the top. It is drawn back over the deep; the loss line is
# its foot, front_y.
const WALL_H := 100.0
const DEEP := Color(0.08, 0.20, 0.28, 0.96)
const FACE := Color(0.16, 0.34, 0.40)
const PALE := Color(0.62, 0.80, 0.78)
const PALE_DEEP := Color(0.62, 0.80, 0.78, 0.35)
const SHALLOW := Color(0.62, 0.80, 0.78, 0.55)
const FOAM := Color(0.93, 0.97, 0.96)
const CONE_ORANGE := Color(0.98, 0.50, 0.10)
const DUCK_BODY := Color(0.50, 0.40, 0.30)
const DUCK_HEAD := Color(0.16, 0.36, 0.22)
const DUCK_BILL := Color(0.96, 0.74, 0.20)
const BRANCH_BROWN := Color(0.32, 0.22, 0.12)
const LEAF := Color(0.36, 0.50, 0.24)

var main: Node2D
var speed := 128.0
var cur_speed := 128.0
var front_y := 0.0
var cx := 400.0
var half := 200.0
var rumble := 0.0
var kind := "flood"
var sway := 0.0
var sway_v := 0.0
var heading := 0.0
var jams: Array[Vector2] = []
var jam_t := 0.0
var jam_side := 0.0
var jam_at := Vector2(INF, INF)
var kerb_blocks: Array[Rect2] = []
var jammed_now := false
var freed_now := false
var apron := Rect2()
# a branch already committed to a body. Empty until the warning beat ends.
var branch_who := ""
var branch_warn := 0.0


func setup(m: Node2D, start_front_y: float, corridor_cx: float, corridor_half: float, flood_speed: float) -> void:
	main = m
	front_y = start_front_y
	cx = corridor_cx
	half = corridor_half
	speed = flood_speed
	cur_speed = flood_speed
	apron = LevelBuild.BESOS_APRON


func advance(delta: float, _gap := -1.0, _aim := 0.0) -> void:
	rumble += delta
	jammed_now = false
	freed_now = false
	sway = swell()
	if jam_t > 0.0:
		jam_t -= delta
		cur_speed = 0.0
		if jam_t <= 0.0:
			freed_now = true
		return
	var lurch := sin(rumble * 0.7) * 0.12
	cur_speed = speed * (1.0 + lurch)
	front_y += cur_speed * delta
	heading = fmod(heading + cur_speed * delta, DEBRIS_SPAN)
	for i in range(jams.size()):
		if front_y >= jams[i].y:
			jam_side = signf(jams[i].x - cx)
			jam_at = jams[i]
			jams.remove_at(i)
			jam_t = JAM_SECS
			jammed_now = true
			break


func jammed() -> bool:
	return jam_t > 0.0


# How far the river has reached in from the path's river edge. Zero on the
# ebb, SWELL_MAX at most, so the lane always keeps a gap.
func swell() -> float:
	return maxf(0.0, sin(rumble * 0.55)) * SWELL_MAX


func threat_boundary() -> float:
	return front_y + SHALLOW_LEAD


func _on_apron(p: Vector2) -> bool:
	var is_held: bool = jam_t > 0.0 or (main != null and String(main.chase_phase) == "hold")
	return is_held and apron.has_point(p)


func in_deep(p: Vector2) -> bool:
	if _on_apron(p):
		return false
	var deep_end := LevelBuild.BESOS_DEEP_X + LevelBuild.BESOS_DEEP_W
	if p.y <= front_y and p.x >= cx - half - 30.0 and p.x <= deep_end:
		return true
	var reach := swell()
	if reach < 8.0:
		return false
	var edge := cx + half - reach
	return p.x >= edge and p.y > front_y and p.y <= front_y + SHALLOW_LEAD


func in_shallow(p: Vector2) -> bool:
	if _on_apron(p) or in_deep(p):
		return false
	if p.y > front_y + SHALLOW_LEAD or p.y <= front_y:
		return false
	return p.x >= cx - half - 30.0 and p.x < LevelBuild.BESOS_DEEP_X


func caught(p: Vector2) -> bool:
	return in_deep(p)


func gap_to(p: Vector2) -> float:
	return p.y - front_y


func sweep_junk(_junk: Array) -> int:
	return 0


# Wet anyone in the shallow. Push only while the flood is actually running:
# a warning, a head start and a countdown hold the water where it is.
func touch(m: Node2D, delta: float, do_push: bool) -> void:
	var dog: CharacterBody2D = m.dog
	var human: CharacterBody2D = m.human
	if in_shallow(human.global_position):
		m.human_soak = minf(1.0, float(m.human_soak) + delta / SOAK_SECS)
	if do_push:
		push_bodies(m, delta)


# The shove and the branch, without the soaking. Main calls this after the
# bodies tick and before the leash, so the rope constrains the push the
# same frame. touch() still soaks on the later chase pass.
func push_bodies(m: Node2D, delta: float) -> void:
	var dog: CharacterBody2D = m.dog
	var human: CharacterBody2D = m.human
	_shove(dog, delta, bool(dog.planted))
	_shove(human, delta, false)
	_branch(dog, human, delta)


func _shove(body: CharacterBody2D, delta: float, planted: bool) -> void:
	CurrentFlow.shove_body(body, in_shallow(body.global_position), Vector2.DOWN,
		PUSH, PLANT_PUSH, planted, delta)


func _branch_pos() -> Vector2:
	var along := fmod(maxf(heading, 0.0), DEBRIS_SPAN)
	var p := Vector2(cx - half * 0.2, front_y + SHALLOW_LEAD + 24.0 + along * 0.45)
	if main == null:
		return p
	var dog_p: Vector2 = main.dog.global_position
	var hum_p: Vector2 = main.human.global_position
	if along < 24.0 and (p.distance_to(dog_p) < 56.0 or p.distance_to(hum_p) < 56.0):
		p.x += half * 0.7
	return p


func _branch(dog: CharacterBody2D, human: CharacterBody2D, delta: float) -> void:
	var at := _branch_pos()
	if branch_warn > 0.0:
		branch_warn = maxf(0.0, branch_warn - delta)
		if branch_warn > 0.0:
			return
		# the beat was the warning. It lands once, the way a correction does,
		# and it is not armed again until this one has finished.
		if branch_who == "dog":
			dog.stumble()
		elif branch_who == "human":
			# Release the reservation even if an orbit or fall refuses the
			# stumble. Otherwise every later owner event stays suppressed.
			human.clear_external_warning("Watch out!")
			if int(human.state) != HumanScript.HState.STUMBLE:
				human.bumped(Vector2(0.0, 1.0))
		branch_who = ""
		return
	var who := ""
	if dog.global_position.distance_to(at) < BRANCH_HIT:
		who = "dog"
	elif human.global_position.distance_to(at) < BRANCH_HIT \
			and int(human.state) != HumanScript.HState.STUMBLE \
			and human.warn_external("Watch out!", BRANCH_WARN):
		who = "human"
	if who == "":
		return
	branch_who = who
	branch_warn = BRANCH_WARN


func cancel_branch_warning() -> void:
	branch_who = ""
	branch_warn = 0.0
	if main != null:
		main.human.clear_external_warning("Watch out!")


func _draw() -> void:
	var b := ShapeBatch.new(self)
	var left := -half
	var right := LevelBuild.BESOS_DEEP_X + LevelBuild.BESOS_DEEP_W - cx
	var w := right - left
	b.rect(Rect2(left, -340.0, w, 340.0), DEEP)
	# rollers on the deep behind the wall, coming on with it
	for r in range(4):
		var ry := -WALL_H - 40.0 - fposmod(heading * 0.6 + float(r) * 60.0, 220.0)
		_wavy(b, left, right, ry, 5.0, PALE_DEEP, 3.0)
	b.rect(Rect2(left, 0.0, w, SHALLOW_LEAD), SHALLOW)
	# the wash out ahead of the wall: a scalloped foam edge that runs and draws back
	var run := sin(rumble * 3.0) * 6.0
	b.rect(Rect2(left, SHALLOW_LEAD - 8.0 + run, w, 6.0), FOAM)
	var n_sc := int(w / 26.0) + 1
	for i in range(n_sc):
		var fx := left + float(i) * 26.0
		b.circle(Vector2(fx, SHALLOW_LEAD - 4.0 + run + sin(rumble * 5.0 + float(i) * 1.3) * 3.0), 9.0, FOAM)
	for r in range(2):
		_wavy(b, left, right, SHALLOW_LEAD * (0.3 + 0.35 * float(r)) + run * 0.5, 4.0, Color(1, 1, 1, 0.35), 2.0)
	var reach := swell()
	if reach > 8.0:
		var edge := half - reach
		b.rect(Rect2(edge, 0.0, right - edge, SHALLOW_LEAD), DEEP)
		for k in range(int(SHALLOW_LEAD / 18.0) + 1):
			b.circle(Vector2(edge + sin(rumble * 6.0 + float(k)) * 3.0, float(k) * 18.0), 8.0, FOAM)
	_wall(b, left, right)
	# the hold keeps the apron dry. This batch is drawn after the world's
	# concrete, so paint that slab back over whatever water landed on it.
	if (jam_t > 0.0 or (main != null and String(main.chase_phase) == "hold")) and apron.size.x > 1.0:
		var local := Rect2(apron.position - global_position, apron.size)
		var painted := Rect2(left, -340.0, right - left, 340.0 + SHALLOW_LEAD)
		var cover := local.intersection(painted)
		if cover.size.x > 1.0 and cover.size.y > 1.0:
			b.rect(cover.grow(6.0), Color(0.62, 0.60, 0.56))
			b.rect(cover, Color(0.78, 0.74, 0.66))
	# while held at the inflatable weir, render churning foam and water pressure
	if jam_t > 0.0 and absf(jam_at.y - LevelBuild.BESOS_WEIR_JAM_Y) < 60.0:
		b.rect(Rect2(left, -14.0, right - left, 26.0), Color(0.94, 0.97, 0.98, 0.75))
		for k in range(10):
			var fx := left + float(k) * (right - left) / 9.0 + sin(rumble * 10.0 + float(k) * 1.5) * 12.0
			b.circle(Vector2(fx, 2.0), 8.0 + sin(rumble * 7.0 + float(k)) * 3.0, Color(1.0, 1.0, 1.0, 0.85))
	# what the river carries, as in the film: a traffic cone, a duck, sticks
	for i in range(4):
		var along := fmod(heading + float(i) * 140.0, DEBRIS_SPAN)
		var dx := sin(heading * 0.02 + float(i) * 1.7) * half * 0.45
		var at := Vector2(dx, SHALLOW_LEAD * 0.2 + along * 0.55)
		match i % 4:
			0:
				b.polygon(PackedVector2Array([at + Vector2(-12, -6), at + Vector2(12, 0), at + Vector2(-12, 6)]), CONE_ORANGE)
				b.rect(Rect2(at.x - 5.0, at.y - 4.0, 3.0, 8.0), FOAM)
			1:
				b.circle(at, 7.0, DUCK_BODY)
				b.circle(at - Vector2(5, 0), 5.5, DUCK_BODY)
				b.circle(at + Vector2(7, -3), 4.5, DUCK_HEAD)
				b.polygon(PackedVector2Array([at + Vector2(10, -4), at + Vector2(15, -3), at + Vector2(10, -1)]), DUCK_BILL)
			_:
				b.line(at - Vector2(9, 2), at + Vector2(9, 2), BRANCH_BROWN, 4.0)
	# the branch that can trip either of them, leaves and all
	var branch := _branch_pos() - global_position
	b.line(branch + Vector2(-16, 4), branch + Vector2(16, -4), BRANCH_BROWN, 6.0)
	b.line(branch + Vector2(2, -1), branch + Vector2(10, -12), BRANCH_BROWN, 3.0)
	b.circle(branch + Vector2(11, -14), 6.0, LEAF)
	b.circle(branch + Vector2(-12, 0), 4.0, LEAF)
	if main != null and String(main.chase_phase) in ["warning", "head_start"]:
		var pulse := 0.35 + 0.65 * absf(sin(rumble * 10.0))
		var n: int = mini(main.poles.size(), int(main.deco_pole_count))
		for i in range(n):
			var wp: Vector2 = main.poles[i]
			if wp.y < float(main.GATE_Y):
				continue
			b.circle(wp - global_position, 8.0, Color(1.0, 0.82, 0.28, pulse))
		var ride := clampf(1.0 - float(main.chase_phase_t) / 1.2, 0.0, 1.0)
		b.rect(Rect2(-18.0, 220.0 - ride * 180.0, 22.0, 10.0), Color(0.95, 0.78, 0.15))
	b.flush()


# the wall: its face from the foot up to a lumpy, rolling crest, streaked as
# it falls, the dark barrel under the curl, and the lip itself a row of foam
# heaps rolling over toward you, spray thrown off ahead
func _wall(b: ShapeBatch, left: float, right: float) -> void:
	var face := PackedVector2Array([Vector2(right, 0.0), Vector2(left, 0.0)])
	var x := left
	while x <= right + 0.1:
		face.append(Vector2(x, _crest(x)))
		x += 20.0
	b.polygon(face, FACE)
	var n := int((right - left) / 34.0) + 1
	for i in range(n):
		var sx := left + float(i) * 34.0 + fposmod(heading * 0.3, 34.0)
		var top := _crest(sx) + 22.0
		var drop := fposmod(rumble * 1.6 + float(i) * 0.37, 1.0)
		b.line(Vector2(sx, top), Vector2(sx - 6.0, top + (-top) * (0.4 + 0.6 * drop)), Color(PALE, 0.55), 2.5)
	x = left
	while x < right:
		var x2 := minf(x + 20.0, right)
		b.polygon(PackedVector2Array([Vector2(x, _crest(x) + 10.0), Vector2(x2, _crest(x2) + 10.0),
			Vector2(x2, _crest(x2) + 26.0), Vector2(x, _crest(x) + 26.0)]), Color(0.04, 0.10, 0.14, 0.85))
		x = x2
	for i in range(n * 2):
		var fx := left + float(i) * 17.0
		var bob := sin(rumble * 7.0 + float(i) * 0.9) * 3.0
		b.circle(Vector2(fx, _crest(fx) + 6.0 + bob), 13.0 + 4.0 * sin(float(i) * 2.3), FOAM)
		b.circle(Vector2(fx + 6.0, _crest(fx) - 4.0 + bob), 8.0, FOAM)
	for p in range(n):
		var f := fposmod(rumble * 1.4 + float(p) * 0.29, 1.0)
		var px := left + float(p) * 34.0 + sin(float(p) * 2.7) * 10.0
		var at := Vector2(px, _crest(px) + 12.0 + f * (-_crest(px) + 30.0))
		b.circle(at, 4.0 * (1.0 - f) + 1.5, Color(FOAM, 1.0 - f))
	# foam boiling at the foot, where it meets the wash
	for i in range(n):
		var fx := left + float(i) * 34.0 + 17.0
		b.circle(Vector2(fx, sin(rumble * 6.0 + float(i)) * 3.0), 11.0, Color(FOAM, 0.85))


# the crest's height over the foot at x: lumps that roll along as it comes
func _crest(x: float) -> float:
	return -WALL_H + sin(x * 0.011 + rumble * 0.9) * 18.0 + sin(x * 0.033 - rumble * 1.7) * 7.0


# a wavy stroke across the water at y
func _wavy(b: ShapeBatch, left: float, right: float, y: float, amp: float, col: Color, width: float) -> void:
	var x := left
	while x < right:
		var x2 := minf(x + 24.0, right)
		b.line(Vector2(x, y + sin(x * 0.05 + rumble * 2.0) * amp), Vector2(x2, y + sin(x2 * 0.05 + rumble * 2.0) * amp),
			col, width)
		x = x2
