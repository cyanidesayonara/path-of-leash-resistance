extends Node2D

# While a dare is up (on offer or live), the trick spots near her are marked
# on the ground, so a player always knows what to try: a pulsing ring round
# every pole and tree she can swing round or fling your human off, and
# marching dashes along every ledge and rail she can grind. A pole she has
# just swung round loses its ring until she has left it, which is the rule
# for another swing there (main._tick_vault). Owned by the giver
# (entities/challenger.gd); drawn in world space over everything, tree crowns
# included (a ring under a crown is a ring nobody sees), in two calls (a soft
# wide pass and a bright thin one).

const REACH := 420.0
const MOST_POLES := 8
const RING_R := 22.0
# a tree's ring sits on its crown, wider than a lamppost's
const TREE_RING_R := 34.0
const RING_SEGS := 20
const DASH := 14.0
const GAP := 12.0
const COL := Color(1.0, 0.88, 0.45)

var main: Node2D
var _segs := PackedVector2Array()


func setup(m: Node2D) -> void:
	main = m
	top_level = true
	z_as_relative = false
	z_index = 14


func showing() -> bool:
	if main == null or main.challenge == null:
		return false
	var giver: Node2D = main.challenge_giver if is_instance_valid(main.challenge_giver) else null
	if giver != get_parent():
		return false
	var ph := String(main.challenge.phase)
	return ph == "live" or ph == "offer"


func _process(_delta: float) -> void:
	var up := showing()
	if up or visible:
		visible = up
		if up:
			queue_redraw()


func _draw() -> void:
	if not showing():
		return
	_segs.clear()
	_draw_into()
	if _segs.is_empty():
		return
	var live := String(main.challenge.phase) == "live"
	var a := 0.75 if live else 0.5
	draw_multiline(_segs, Color(COL.r, COL.g, COL.b, a * 0.28), 7.0)
	draw_multiline(_segs, Color(COL.r, COL.g, COL.b, a), 2.5)


# every ring and dash for this frame, as segment pairs in _segs
func _draw_into() -> void:
	var t := AnimClock.msec() / 1000.0
	var at: Vector2 = main.dog.global_position
	_poles(at, main.vault_done_pole, t)
	_rails(at, t)


# the nearest real poles (main.leash's kinds: no bench corners, no furniture)
func _poles(at: Vector2, done: Vector2, t: float) -> void:
	var lp: Array = main.leash.poles
	var kinds: PackedInt32Array = main.leash.kinds()
	var picked: Array[Vector2] = []
	var picked_i: Array[int] = []
	var dists: Array[float] = []
	var reach_sq := REACH * REACH
	for i in range(mini(lp.size(), kinds.size())):
		if kinds[i] != main.leash.K_POLE:
			continue
		var p: Vector2 = lp[i]
		var d := p.distance_squared_to(at)
		if d > reach_sq:
			continue
		if done.x < INF and p.distance_squared_to(done) < 576.0:
			continue
		# keep the MOST_POLES nearest, by insertion
		var k := dists.size()
		while k > 0 and dists[k - 1] > d:
			k -= 1
		if k >= MOST_POLES:
			continue
		dists.insert(k, d)
		picked.insert(k, p)
		picked_i.insert(k, i)
		if dists.size() > MOST_POLES:
			dists.pop_back()
			picked.pop_back()
			picked_i.pop_back()
	for j in range(picked.size()):
		var c := picked[j]
		var r0 := TREE_RING_R if _is_tree(picked_i[j], c) else RING_R
		var r := r0 + 3.0 * sin(t * 5.0 + c.x * 0.05)
		# a ring of dashes turning slowly, so it reads as "here", not a hole
		var spin := t * 1.2 + c.y * 0.01
		for s in range(RING_SEGS):
			if s % 2 == 1:
				continue
			var a0 := spin + TAU * float(s) / RING_SEGS
			var a1 := spin + TAU * float(s + 1) / RING_SEGS
			_segs.append(c + Vector2.from_angle(a0) * r)
			_segs.append(c + Vector2.from_angle(a1) * r)


func _is_tree(i: int, c: Vector2) -> bool:
	if i < int(main.deco_pole_count) and int(main.pole_tree(i)) != int(main.TREE_NONE):
		return true
	for tr: Vector2 in main.trees:
		if tr.distance_squared_to(c) < 1.0:
			return true
	return false


# dashes marching along each grindable near her
func _rails(at: Vector2, t: float) -> void:
	var off := fmod(t * 40.0, DASH + GAP)
	for r: Dictionary in main.rails:
		var pts: PackedVector2Array = r["pts"]
		for i in range(pts.size() - 1):
			var a := pts[i]
			var b := pts[i + 1]
			if Geometry2D.get_closest_point_to_segment(at, a, b).distance_to(at) > REACH:
				continue
			var l := a.distance_to(b)
			if l < 1.0:
				continue
			var dir := (b - a) / l
			var s := -off
			while s < l:
				var s0 := maxf(0.0, s)
				var s1 := minf(l, s + DASH)
				if s1 > s0:
					_segs.append(a + dir * s0)
					_segs.append(a + dir * s1)
				s += DASH + GAP
