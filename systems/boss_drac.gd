class_name BossDrac
extends RefCounted

# EL DRAC, El Mosaic's salamander boss: asleep on the fountain stair until
# she wakes him. Task 1 is registration, goals and an IDLE scaffold only.

const LevelBuild := preload("res://world/level_build.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")

const PLINTH := LevelBuild.MOSAIC_SALAMANDER
const HOLD_Y := -780.0
const WAKE_Y := -860.0
const MAX_HP := 100.0
const FILM := "res://intro/film_drac.gd"
const FILM_WIN := "res://intro/film_drac_win.gd"
const LEG_OFFSETS: Array[Vector2] = [
	Vector2(-28.0, -36.0), Vector2(28.0, -36.0),
	Vector2(-28.0, 36.0), Vector2(28.0, 36.0),
]
const LEG_RADIUS := 16.0
const LEG_MEMORY := 1.5
const LEGS_TO_TIE := 3
const AWAKEN_TIME := 2.6
const CARD_TIME := 3.4
const CARD_FROM := 0.3

enum State {
	IDLE, AWAKEN, ENRAGE, PROWL, TAIL_WHIP, JET, SLITHER,
	STUNNED, RETREAT, STAND, WRAPPED, SLIDE, CONTENT,
}

var state: State = State.IDLE
var state_t := 0.0
var hp := MAX_HP
var max_hp := MAX_HP
var phase := 1
var main: Node2D = null
var pos := PLINTH
var face_dir := Vector2.DOWN
var leg_poles: Array[Vector2] = []
var leg_indices: Array[int] = []
var leg_soft_indices: Array[int] = []
var leg_furniture_indices: Array[int] = []
var leg_touch_t: Array[float] = [-INF, -INF, -INF, -INF]
var legs_tied := 0
var lean := 0.0
var card_t := -1.0
var film_shown := false
var win_film_shown := false
var enraged := false
# puddles / chips: [{ "rect": Rect2, "kind": int, "until": float }]
var surface_zones: Array[Dictionary] = []


func setup(m: Node2D) -> void:
	main = m
	state = State.IDLE
	state_t = 0.0
	hp = MAX_HP
	max_hp = MAX_HP
	phase = 1
	pos = PLINTH
	face_dir = Vector2.DOWN
	enraged = false
	card_t = -1.0
	lean = 0.0
	film_shown = false
	win_film_shown = false
	legs_tied = 0
	surface_zones.clear()
	leg_poles.clear()
	for off: Vector2 in LEG_OFFSETS:
		leg_poles.append(pos + off)


# Called by LevelBuild after the rope radii are filled: the legs are rope
# points with furniture slip, kept out of the static bodies.
func register_legs(m: Node2D) -> void:
	leg_indices.clear()
	leg_soft_indices.clear()
	leg_furniture_indices.clear()
	leg_poles.clear()
	for k in range(LEG_OFFSETS.size()):
		var lp: Vector2 = _leg_at(k)
		leg_indices.append(m.poles.size())
		leg_soft_indices.append(m.rope_soft.size())
		m.poles.append(lp)
		m.rope_radii.append(LEG_RADIUS + 2.0)
		m.rope_soft.append(lp)
		leg_poles.append(lp)


func is_leg_index(i: int) -> bool:
	return not leg_indices.is_empty() and i >= leg_indices[0] and i <= leg_indices[leg_indices.size() - 1]


# his legs turn with him: offsets are in his frame, face pointing down
func _leg_at(k: int) -> Vector2:
	var ang := face_dir.angle() - PI * 0.5
	return pos + LEG_OFFSETS[k].rotated(ang)


func update_leg_positions() -> void:
	if leg_poles.size() != 4:
		return
	var leash_furn: Array = main.leash.furniture_poles if main.leash != null else []
	if leg_furniture_indices.size() != leg_indices.size():
		leg_furniture_indices.clear()
		for k in range(leg_indices.size()):
			leg_furniture_indices.append(leash_furn.find(leg_poles[k]))
	for k in range(4):
		var target := _leg_at(k)
		leg_poles[k] = target
		if k < leg_indices.size():
			var idx: int = leg_indices[k]
			if idx >= 0 and idx < main.poles.size():
				main.poles[idx] = target
			var si: int = leg_soft_indices[k]
			if si >= 0 and si < main.rope_soft.size():
				main.rope_soft[si] = target
			var fi: int = leg_furniture_indices[k]
			if fi >= 0 and fi < leash_furn.size():
				leash_furn[fi] = target


func beaten() -> bool:
	return state == State.CONTENT


func in_fight() -> bool:
	return state != State.IDLE and not beaten()


func status() -> String:
	return ""


func hush_banner() -> bool:
	return card_t >= 0.0 and card_t < CARD_FROM + CARD_TIME


func tick_state(_delta: float) -> void:
	pass


func on_bark_action(_pos: Vector2) -> bool:
	return false


func surface_at(_p: Vector2) -> int:
	return -1  # -1 = no override


func awake_for_draw() -> bool:
	return state != State.IDLE
