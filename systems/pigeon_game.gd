class_name PigeonGame
extends RefCounted

const EventFeed := preload("res://hud/event_feed.gd")

# The plaça's own off-leash game: the pigeons. A flock lands on some
# scattered crumbs. Run at them and the ones she gets near take off one by
# one, lost (sprinting, they see her coming from much further off). Creep up
# without sprinting, stop close, and bark: every pigeon still down goes up at
# once. A bone a pigeon in that burst, double when she was right in among
# them, five more for the whole flock. Three flocks, each landing somewhere
# new after a pause. The autowalk never plays it.
#
# Its pigeons are ordinary pigeons (entities/pigeon.gd) told how wary to be
# (`wary`); the bark that bursts them is main.on_bark's, which asks here
# first (on_bark) what the burst was worth.

const ROUNDS := 3
const FLOCK_N := 9
const SPREAD := 34.0          # crumbs, and the flock pecking at them, this far out
const WARY_WALK := 44.0       # a pigeon takes off when she comes this close at a walk
const WARY_SPRINT := 150.0    # ...or this close at a sprint
const CLOSE := 90.0           # a bark this close to the flock's middle counts double
const BARK_REACH := 200.0     # main.on_bark scares pigeons out to here
const PAUSE_S := 2.5          # between one flock going and the next landing
const FULL_BONUS := 5

var round := 0
var wait_t := 1.5
var at := Vector2(INF, INF)   # the crumbs
var flock: Array = []         # this round's pigeons
var landed_n := 0
var flushed := 0
var done := false
var rng := RandomNumberGenerator.new()


func _init(seed_v: int) -> void:
	rng.seed = seed_v


func active() -> bool:
	return not done and at.x < INF and not flock.is_empty()


# where to put the crumbs: on the open paving, well away from her
func _pick_spot(m: Node2D) -> Vector2:
	var r: Rect2 = m._freedom_rect().grow(-120.0)
	var best := r.get_center()
	var best_d := -1.0
	for i in range(8):
		var p := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))
		var d: float = p.distance_to(m.dog.global_position)
		if d > best_d:
			best = p
			best_d = d
		if d > 300.0:
			return p
	return best


func tick(m: Node2D, delta: float) -> void:
	if done:
		return
	if flock.is_empty():
		wait_t -= delta
		if wait_t > 0.0:
			return
		_land(m)
		return
	# the ones she flushed by running at them, before any bark
	var down := 0
	for p in flock:
		if is_instance_valid(p) and not p.flying:
			down += 1
			p.wary = WARY_SPRINT if m.dog.turbo_active else WARY_WALK
	if down == 0:
		_round_over(m)


func _land(m: Node2D) -> void:
	at = _pick_spot(m)
	landed_n = FLOCK_N
	flushed = 0
	for i in range(FLOCK_N):
		var pg: Node2D = Node2D.new()
		pg.set_script(load("res://entities/pigeon.gd"))
		pg.z_index = 6
		var a := TAU * float(i) / float(FLOCK_N) + rng.randf_range(-0.3, 0.3)
		pg.position = at + Vector2.from_angle(a) * rng.randf_range(6.0, SPREAD)
		m.add_child(pg)
		pg.setup(m, m.dog, m.dog)
		pg.wary = WARY_WALK
		flock.append(pg)
	Sfx.play("rustle", 1.3, -10.0)
	if round == 0:
		m.feed.say(Prompts.fill("PIGEONS! CREEP UP, THEN {bark} BARK"), EventFeed.Tone.PLAIN)


# main.on_bark asks first: how many of the flock are still down within the
# bark's reach, and how close she is. Returns nothing; pays and says it.
func on_bark(m: Node2D, pos: Vector2) -> void:
	if not active():
		return
	var n := 0
	for p in flock:
		if is_instance_valid(p) and not p.flying and p.global_position.distance_to(pos) < BARK_REACH:
			n += 1
	if n == 0:
		return
	var close := pos.distance_to(at) < CLOSE
	var pay := n * (2 if close else 1)
	var whole := n == FLOCK_N
	if whole:
		pay += FULL_BONUS
	m.bones += pay
	m.combo.add("PIGEONS", pay)
	var shout := "WHOOSH! ALL %d" % n if whole else "WHOOSH! %d PIGEONS" % n
	if close:
		shout += ", RIGHT AMONG THEM"
	m.feed.say(shout, EventFeed.Tone.GOOD)
	m.float_text(pos, "pigeons! +%d" % pay, Color(0.85, 1.0, 0.85))
	Sfx.play("whoop", 1.2, -8.0)


func _round_over(m: Node2D) -> void:
	for p in flock:
		if is_instance_valid(p) and not p.flying:
			p.queue_free()
	flock.clear()
	at = Vector2(INF, INF)
	round += 1
	if round >= ROUNDS:
		done = true
		m.feed.say("NOT A PIGEON LEFT IN THE PLAÇA", EventFeed.Tone.GOOD)
		return
	wait_t = PAUSE_S


func clear() -> void:
	for p in flock:
		if is_instance_valid(p):
			p.queue_free()
	flock.clear()
	done = true


# the crumbs and dropped bakery paper bag under the flock (games layer, ground)
func draw_ground(b: ShapeBatch) -> void:
	if at.x >= INF:
		return
	# crumpled paper bakery bag + napkin beside the crumbs so the spot reads from afar
	var bag_c := at + Vector2(-12.0, 7.0)
	b.polygon(PackedVector2Array([
		bag_c + Vector2(-7.0, -4.0), bag_c + Vector2(6.0, -6.0),
		bag_c + Vector2(8.0, 5.0), bag_c + Vector2(-5.0, 7.0),
	]), Color(0.05, 0.05, 0.08, 0.18))
	var bag_pts := PackedVector2Array([
		bag_c + Vector2(-8.0, -5.0), bag_c + Vector2(5.0, -7.0),
		bag_c + Vector2(7.0, 3.0), bag_c + Vector2(-6.0, 5.0),
	])
	b.polygon(bag_pts, Color(0.86, 0.78, 0.64))
	b.line(bag_pts[0], bag_pts[1], Color(0.68, 0.56, 0.42), 1.6)
	b.line(bag_pts[1], bag_pts[2], Color(0.74, 0.62, 0.46), 1.4)
	b.line(bag_c + Vector2(-3.0, -2.0), bag_c + Vector2(3.0, 1.0), Color(0.64, 0.50, 0.36, 0.7), 1.2)
	var nap := at + Vector2(10.0, -8.0)
	b.polygon(PackedVector2Array([
		nap + Vector2(-5.0, -2.0), nap + Vector2(4.0, -5.0),
		nap + Vector2(7.0, 3.0), nap + Vector2(-2.0, 5.0),
	]), Color(0.95, 0.93, 0.88, 0.88))
	var crumb := Color(0.86, 0.74, 0.52)
	for i in range(14):
		var a := float(i) * 2.39996
		var r := SPREAD * sqrt(float(i) / 14.0)
		var p := at + Vector2(cos(a), sin(a)) * r
		b.circle(p, 1.8 + float(i % 3) * 0.5, crumb)
