extends Node2D

const CurrentFlow := preload("res://systems/current_flow.gd")

enum State { LOOSE, CARRIED, RETURNED, MISSED }

const FLOW_SPEED := 54.0
const GRAB_R := 22.0
const BANK_CLEAR := 12.0
const WAKE_DIST := 520.0

var main: Node2D
var kind := "branch"
var state := State.LOOSE
var footbridge_x := 0.0
var stream_y := 0.0
var stream_half := 0.0
var spin := 0.0
var armed := false


func setup(
	m: Node2D,
	item_kind: String,
	start: Vector2,
	under_footbridge_x: float,
	water_y: float,
	water_half: float,
) -> void:
	main = m
	kind = item_kind
	global_position = start
	footbridge_x = under_footbridge_x
	stream_y = water_y
	stream_half = water_half
	visible = false


func is_carried() -> bool:
	return state == State.CARRIED


func tick(delta: float) -> void:
	if main == null or main.frozen or state == State.RETURNED or state == State.MISSED:
		return
	if not armed:
		if absf(main.dog.global_position.y - stream_y) > WAKE_DIST:
			return
		armed = true
		visible = true
	if state == State.LOOSE:
		CurrentFlow.drift_loose(self, true, Vector2.RIGHT, FLOW_SPEED, delta, false)
		spin += delta * (2.4 if kind == "branch" else 5.2)
		if global_position.x >= footbridge_x:
			state = State.MISSED
			visible = false
			return
		if not bool(main.dog_carrying) \
				and global_position.distance_to(main.dog.global_position) < GRAB_R:
			state = State.CARRIED
			main.dog_carrying = true
			main.on_stream_find_grabbed(global_position)
	elif state == State.CARRIED:
		global_position = main.dog.global_position + main.dog.facing * 22.0
		if absf(global_position.y - stream_y) > stream_half + BANK_CLEAR:
			state = State.RETURNED
			main.dog_carrying = false
			main.on_stream_find_returned(kind, global_position)
			visible = false
	queue_redraw()


func _draw() -> void:
	if state == State.RETURNED or state == State.MISSED:
		return
	var b := ShapeBatch.new(self)
	for y: float in [-5.0, 5.0]:
		b.line(Vector2(-22.0, y), Vector2(-9.0, y * 0.55), Color(0.84, 0.92, 0.92, 0.55), 1.5)
	if kind == "ball":
		b.circle(Vector2.ZERO, 8.0, Color(0.90, 0.76, 0.24))
		for i in range(3):
			var a := spin + TAU * float(i) / 3.0
			b.line(Vector2.ZERO, Vector2.from_angle(a) * 7.0, Color(0.95, 0.94, 0.86), 1.5)
	else:
		var along := Vector2.RIGHT.rotated(spin) * 12.0
		var side := along.orthogonal().normalized() * 3.0
		b.polygon(PackedVector2Array([-along - side, along - side, along + side, -along + side]),
			Color(0.40, 0.27, 0.15))
		b.line(-along * 0.25, -along * 0.25 + side * 2.2, Color(0.30, 0.20, 0.12), 2.0)
	b.flush()
