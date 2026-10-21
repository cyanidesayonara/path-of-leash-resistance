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

const SHALLOW_LEAD := 110.0
const PUSH := 220.0
const PLANT_PUSH := 28.0
# standing in the shallow the whole way home fails "less than half soaked"
const SOAK_SECS := 36.0
const SWELL_MAX := 90.0
const JAM_SECS := 3.0
const DEBRIS_SPAN := 560.0

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
	return jam_t > 0.0 and apron.has_point(p)


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
		_shove(dog, delta, bool(dog.planted))
		_shove(human, delta, false)
		_branch(dog, human)


func _shove(body: CharacterBody2D, delta: float, planted: bool) -> void:
	if not in_shallow(body.global_position):
		return
	var rate := PLANT_PUSH if planted else PUSH
	var extra := maxf(rate - maxf(body.velocity.y, 0.0), 0.0)
	if extra > 0.0:
		body.move_and_collide(Vector2(0.0, extra * delta))


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


func _branch(dog: CharacterBody2D, human: CharacterBody2D) -> void:
	var at := _branch_pos()
	if dog.global_position.distance_to(at) < 22.0:
		dog.stumble()
	elif human.global_position.distance_to(at) < 22.0 and int(human.state) != HumanScript.HState.STUMBLE:
		human.bumped(Vector2(0.0, 1.0))


func _draw() -> void:
	var b := ShapeBatch.new(self)
	var left := -half
	var right := LevelBuild.BESOS_DEEP_X + LevelBuild.BESOS_DEEP_W - cx
	var deep := Color(0.08, 0.20, 0.28, 0.94)
	var pale := Color(0.62, 0.80, 0.78, 0.50)
	var foam := Color(0.92, 0.96, 0.94, 0.75)
	b.rect(Rect2(left, -340.0, right - left, 340.0), deep)
	b.rect(Rect2(left, 0.0, right - left, SHALLOW_LEAD), pale)
	b.rect(Rect2(left, SHALLOW_LEAD - 7.0, right - left, 8.0), foam)
	var reach := swell()
	if reach > 8.0:
		var edge := half - reach
		b.rect(Rect2(edge, 0.0, right - edge, SHALLOW_LEAD), Color(0.10, 0.22, 0.30, 0.90))
	for i in range(4):
		var along := fmod(heading + float(i) * 140.0, DEBRIS_SPAN)
		var dx := sin(heading * 0.02 + float(i) * 1.7) * half * 0.45
		b.rect(Rect2(dx, SHALLOW_LEAD * 0.2 + along * 0.55, 16.0, 5.0), Color(0.40, 0.30, 0.16, 0.9))
	var branch := _branch_pos() - global_position
	b.rect(Rect2(branch.x - 14.0, branch.y - 3.0, 28.0, 6.0), Color(0.32, 0.22, 0.12))
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
