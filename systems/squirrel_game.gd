class_name SquirrelGame
extends RefCounted

const Clay := preload("res://entities/clay.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")

# The woodland clearing's own off-leash game: tree a squirrel. One forages
# out on the grass. Come near and it bolts for a trunk, the one furthest from
# her side, and up it goes: never catchable. Stand under the tree and bark:
# it peeks over the rim of the crown and scolds her ("treed! +N", less for
# each bark at the same squirrel up the same tree). Soon it rustles its crown
# (the telegraph, LEAP_WARN) and leaps to a neighbouring tree; be under that
# one to bark again before it settles and the streak grows. After LEAPS
# leaps it goes off over the canopy, and the next comes down. Three
# squirrels. The autowalk never plays it.
#
# The squirrel is drawn by its own layer above the crowns (z 14), so it can
# peek out of one and arc over to the next; main.on_bark asks here first.

enum S { WAIT, FORAGE, BOLT, CLIMB, TREED, RUSTLE, LEAP, GONE }

const ROUNDS := 3
const ALERT := 170.0          # she comes this close and it bolts
const RUN := 300.0            # a squirrel's sprint, faster than her walk
const JINK := 46.0            # it never lets her nearer than this
const CLIMB_S := 0.5
const TRUNK_R := 80.0         # under the tree: a bark here counts
const TREED_S := 4.5          # up one tree this long, then it rustles
const BARKS_UP := 3           # or after this many barks at it
const LEAP_WARN := 0.8        # the crown rustles this long before the leap
const LEAP_S := 0.6
const LEAP_REACH := 420.0     # it leaps to a tree this near
const LEAPS := 2              # leaps before it goes off over the canopy
const PAY_FIRST := 3          # the first bark up a tree...
const PAY_MORE := 1           # ...the rest at the same tree
const STREAK_PAY := 2         # a bark at the next tree before it settles, per streak
const PAUSE_S := 2.2
const PEEK := 18.0            # how far out of the crown it peeks, toward her

var state: S = S.WAIT
var t := 1.2
var round := 0
var pos := Vector2(INF, INF)
var tree := Vector2(INF, INF)
var next_tree := Vector2(INF, INF)
var from := Vector2.ZERO
var leaps := 0
var barks := 0                # at this tree
var streak := 0
var settle_t := 0.0           # since it landed in this tree
var done := false
var treed_total := 0          # trees she has barked it up, for a goal or a test
var rng := RandomNumberGenerator.new()
var layer: Node2D = null
var _m: Node2D = null


func _init(seed_v: int) -> void:
	rng.seed = seed_v


func attach(m: Node2D) -> void:
	_m = m
	layer = Node2D.new()
	layer.z_index = 14
	layer.draw.connect(_on_draw)
	m.add_child(layer)


func clear() -> void:
	if is_instance_valid(layer):
		layer.queue_free()
	layer = null
	done = true


func active() -> bool:
	return not done and state != S.WAIT and state != S.GONE


func up_a_tree() -> bool:
	return state == S.TREED or state == S.RUSTLE


func _trees(m: Node2D) -> Array:
	var r: Rect2 = m._freedom_rect().grow(-10.0)
	var out: Array = []
	for tp: Vector2 in m.trees:
		if r.has_point(tp):
			out.append(tp)
	return out


# down on the grass, well away from her and from the trunks
func _forage_spot(m: Node2D) -> Vector2:
	var r: Rect2 = m._freedom_rect().grow(-170.0)
	var best := r.get_center()
	var best_d := -1.0
	for i in range(10):
		var p := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))
		var d: float = p.distance_to(m.dog.global_position)
		if d > best_d:
			best = p
			best_d = d
		if d > 380.0:
			return p
	return best


# the trunk to run for: away from her side, not too far
func _bolt_tree(m: Node2D, at: Vector2) -> Vector2:
	var away: Vector2 = (at - m.dog.global_position).normalized()
	var best := Vector2(INF, INF)
	var best_s := -INF
	for tp: Vector2 in _trees(m):
		var d := at.distance_to(tp)
		var s := away.dot((tp - at).normalized()) * 300.0 - d
		if s > best_s:
			best_s = s
			best = tp
	return best


func _leap_tree(m: Node2D) -> Vector2:
	var best := Vector2(INF, INF)
	var best_s := -INF
	for tp: Vector2 in _trees(m):
		var d := tp.distance_to(tree)
		if d < 60.0 or d > LEAP_REACH:
			continue
		# away from her if it can
		var s: float = tp.distance_to(m.dog.global_position) + rng.randf_range(0.0, 80.0)
		if s > best_s:
			best_s = s
			best = tp
	return best


func tick(m: Node2D, delta: float) -> void:
	if done:
		return
	t -= delta
	settle_t += delta
	var dog: Vector2 = m.dog.global_position
	match state:
		S.WAIT:
			if t <= 0.0:
				pos = _forage_spot(m)
				tree = Vector2(INF, INF)
				next_tree = Vector2(INF, INF)
				state = S.FORAGE
				Sfx.play("rustle", 1.6, -10.0)
				if round == 0:
					m.feed.say(Prompts.fill(I18n.t("w_a_squirrel_chase_it_up_a_tree_then")), EventFeed.Tone.PLAIN)
		S.FORAGE:
			if dog.distance_to(pos) < ALERT:
				tree = _bolt_tree(m, pos)
				if tree.x >= INF:
					_gone(m)
					return
				state = S.BOLT
				Sfx.play("squawk", 1.8, -8.0)
		S.BOLT:
			var to := tree - pos
			var step := RUN * delta
			var dir := to.normalized()
			# never caught: a dog this close and it jinks off sideways
			if dog.distance_to(pos + dir * step) < JINK:
				var side := dir.orthogonal()
				if side.dot(pos - dog) < 0.0:
					side = -side
				dir = (dir + side * 1.4).normalized()
			if to.length() <= step:
				pos = tree
				state = S.CLIMB
				t = CLIMB_S
			else:
				pos += dir * step
		S.CLIMB:
			if t <= 0.0:
				_treed()
		S.TREED:
			if t <= 0.0 or barks >= BARKS_UP:
				var next := _leap_tree(m)
				if leaps >= LEAPS or next.x >= INF:
					_gone(m)
				else:
					next_tree = next
					state = S.RUSTLE
					t = LEAP_WARN
					Sfx.play("rustle", 1.0, -6.0)
		S.RUSTLE:
			if t <= 0.0:
				from = tree
				tree = next_tree
				next_tree = Vector2(INF, INF)
				state = S.LEAP
				t = LEAP_S
		S.LEAP:
			pos = from.lerp(tree, 1.0 - clampf(t / LEAP_S, 0.0, 1.0))
			if t <= 0.0:
				leaps += 1
				_treed()
		S.GONE:
			if t <= 0.0:
				round += 1
				if round >= ROUNDS:
					done = true
					m.feed.say(I18n.t("w_not_a_squirrel_left_on_the_ground"), EventFeed.Tone.GOOD)
				else:
					state = S.WAIT
					t = PAUSE_S
	if is_instance_valid(layer):
		layer.queue_redraw()


func _treed() -> void:
	pos = tree
	state = S.TREED
	t = TREED_S
	barks = 0
	settle_t = 0.0


func _gone(m: Node2D) -> void:
	state = S.GONE
	t = PAUSE_S
	next_tree = Vector2(INF, INF)
	streak = 0
	leaps = 0
	if round + 1 < ROUNDS:
		m.feed.say(I18n.t("w_it_s_off_over_the_trees"), EventFeed.Tone.PLAIN)


# main.on_bark asks first: a bark from under its tree, while it is up there
func on_bark(m: Node2D, at: Vector2) -> void:
	if not up_a_tree() or at.distance_to(tree) > TRUNK_R:
		return
	var pay := PAY_FIRST if barks == 0 else PAY_MORE
	# barked at in the tree it just leapt to, before it settled: the streak
	if barks == 0 and leaps > 0 and settle_t < TREED_S * 0.5:
		streak += 1
		pay += STREAK_PAY * streak
	elif barks == 0:
		streak = 0
	if barks == 0:
		treed_total += 1
	barks += 1
	m.bones += pay
	m.combo.add("TREED", pay)
	var word := I18n.t("w_treed_again") if (barks == 1 and streak > 0) else I18n.t("w_treed")
	m.float_text(tree + Vector2(0.0, -40.0), "%s +%d" % [word, pay], Color(0.85, 1.0, 0.85))
	if barks == 1:
		m.feed.say(I18n.t("w_treed_it_s_scolding_you") if streak == 0 else I18n.t("w_after_it_treed_again_x") % (streak + 1), EventFeed.Tone.GOOD)
	Sfx.play("squawk", 2.2, -6.0)


# what the banner says while the game is on and she is near it
func banner(m: Node2D) -> String:
	if not active():
		return ""
	if m.dog.global_position.distance_to(pos) > 520.0:
		return ""
	match state:
		S.FORAGE, S.BOLT:
			return I18n.t("sq_chase")
		S.RUSTLE, S.LEAP:
			return I18n.t("sq_jump")
		_:
			return Prompts.fill(I18n.t("sq_bark"))


# --- drawing: the squirrel, above the crowns ----------------------------------------

const FUR := Color(0.66, 0.36, 0.17)
const FUR_DARK := Color(0.42, 0.22, 0.10)
const BELLY := Color(0.93, 0.82, 0.64)


func _on_draw() -> void:
	if _m == null or done or pos.x >= INF or state == S.WAIT or state == S.GONE:
		return
	var b := ShapeBatch.new(layer)
	var now := AnimClock.msec() / 1000.0
	var dog: Vector2 = _m.dog.global_position
	match state:
		S.FORAGE:
			# nibbling, tail up, a little hop now and then
			var hop := maxf(0.0, sin(now * 3.1)) * 3.0
			_body(b, pos + Vector2(0.0, -hop), Vector2.UP.rotated(sin(now * 0.7) * 0.6), 1.0, now, true, false)
		S.BOLT:
			var dir := (tree - pos).normalized()
			_body(b, pos, dir, 1.0, now, true, false)
		S.CLIMB:
			# up the trunk, getting smaller as it goes up into the crown
			var k := 1.0 - clampf(t / CLIMB_S, 0.0, 1.0)
			_body(b, pos + Vector2(0.0, -14.0 * k), Vector2.UP, lerpf(1.0, 0.85, k), now, false, false)
		S.TREED:
			# perched at the rim of the crown on her side, tail curled back over the leaves
			var side := (dog - tree).normalized() if dog.distance_to(tree) > 1.0 else Vector2.DOWN
			var bob := 2.0 * sin(now * (9.0 if barks > 0 else 3.0))
			var perch := tree + side * (PEEK + bob)
			_body(b, perch - side * 4.0, side, 0.95, now, false, false)
			if barks > 0:
				var snout := perch + side * 6.0
				var lat := side.orthogonal()
				var chatter := Color(1.0, 0.95, 0.78, 0.85)
				var pulse := 1.5 * sin(now * 16.0)
				for sgn: float in [-1.0, 1.0]:
					var p0 := snout + side * 4.0 + lat * (sgn * (6.0 + pulse * 0.4))
					b.line(p0, p0 + side * 4.0 + lat * (sgn * 3.5), chatter, 1.8)
		S.RUSTLE:
			# crown shakes on this tree while leaves drift toward next_tree
			var aim := (next_tree - tree).normalized() if next_tree.x < INF else Vector2.UP
			var k := 1.0 - clampf(t / LEAP_WARN, 0.0, 1.0)
			var shake := sin(now * 38.0) * 4.0
			var leaf_a := Color(0.58, 0.78, 0.30, 0.92)
			var leaf_b := Color(0.86, 0.70, 0.26, 0.90)
			for i in range(8):
				var a := float(i) * TAU / 8.0 + now * 2.4
				var lp := tree + Vector2.from_angle(a) * (24.0 + shake * (1.0 if i % 2 == 0 else -1.0))
				Clay.patch(b, lp, Vector2(3.6, 2.0), Vector2.from_angle(a + 0.7), leaf_a if i % 2 == 0 else leaf_b)
			for i in range(3):
				var fi := float(i) - 1.0
				var drift := aim * (18.0 + 26.0 * k + float(i) * 4.0) + aim.orthogonal() * (fi * 10.0)
				Clay.patch(b, tree + drift, Vector2(3.2, 1.8), aim.rotated(fi * 0.3), leaf_b if i == 1 else leaf_a)
			_body(b, tree + aim * (PEEK * 0.6), aim, 0.92, now, false, false)
		S.LEAP:
			# an arc over the gap: ground shadow below, trailing leaves, outstretched limbs
			var k := 1.0 - clampf(t / LEAP_S, 0.0, 1.0)
			var arc := sin(k * PI)
			var lift := arc * 62.0
			var dir := (tree - from).normalized()
			Clay.ground_shadow(b, pos, 7.0, 4.5, 4.0, 0.24 * (1.0 - arc * 0.45))
			var air_pos := pos + Vector2(0.0, -lift)
			for i in range(3):
				var lag := -dir * (16.0 + float(i) * 9.0) + Vector2(0.0, float(i) * 3.0)
				var alpha := 0.8 - float(i) * 0.18
				var col := Color(0.58, 0.78, 0.30, alpha) if i % 2 == 0 else Color(0.86, 0.70, 0.26, alpha)
				Clay.patch(b, air_pos + lag, Vector2(3.0, 1.7), dir.rotated(float(i - 1) * 0.4), col)
			_body(b, air_pos, dir, 1.12, now, false, true)
	b.flush()


# a squirrel from above, facing dir: shaded body, head, optional ground
# shadow, and a three-puff plume tail with a pale tip
func _body(b: ShapeBatch, at: Vector2, dir: Vector2, s: float, now: float, grounded := true, leaping := false) -> void:
	var side := dir.orthogonal()
	if grounded:
		Clay.ground_shadow(b, at, 9.5 * s, 6.2 * s, 4.0 * s, 0.22)
	var flick := sin(now * (14.0 if not grounded else 7.0)) * (0.18 if leaping else 0.35)
	var curl := 0.25 if leaping else 1.0
	var tail_root := at - dir * 5.0 * s
	var d1 := (-dir).rotated((0.45 * curl + flick) * 0.6)
	var d2 := (-dir).rotated(1.05 * curl + flick)
	var plume := FUR.lightened(0.10)
	Clay.blob(b, tail_root + d1 * 6.5 * s, Vector2(7.0 * s, 4.6 * s), d1, plume)
	Clay.ball(b, tail_root + d1 * 8.0 * s + d2 * 6.0 * s, 5.4 * s, FUR_DARK)
	Clay.ball(b, tail_root + d1 * 8.5 * s + d2 * 9.5 * s, 3.6 * s, BELLY)
	for e: float in [-1.0, 1.0]:
		b.circle(at - dir * (4.0 if leaping else 3.0) * s + side * e * (4.8 if leaping else 4.2) * s, 2.0 * s, FUR_DARK)
		if leaping:
			b.circle(at + dir * 7.5 * s + side * e * 4.5 * s, 1.8 * s, FUR_DARK)
	Clay.blob(b, at, Vector2((8.2 if leaping else 7.2) * s, 5.2 * s), dir, FUR)
	Clay.patch(b, at + dir * 3.8 * s, Vector2(3.2 * s, 2.2 * s), dir, BELLY)
	var hc := at + dir * (8.5 if leaping else 7.5) * s
	Clay.ball(b, hc, 4.8 * s, FUR)
	for e: float in [-1.0, 1.0]:
		b.circle(hc - dir * 1.4 * s + side * e * 3.8 * s, 1.8 * s, FUR_DARK)
		b.circle(hc + dir * 1.6 * s + side * e * 2.4 * s, 1.2 * s, Color(0.08, 0.06, 0.05))
		b.circle(hc + dir * 1.3 * s + side * e * 2.2 * s - Vector2(0.3, 0.3) * s, 0.45 * s, Color(1.0, 0.98, 0.92, 0.85))
	b.circle(hc + dir * 4.4 * s, 1.1 * s, Color(0.18, 0.10, 0.08))
