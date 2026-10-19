class_name CrowdRiver
extends RefCounted

# A crowd as data. Dia de Partit's fans stream one way; El Diluvi's shoppers
# (setup_shuffle) stroll both ways under the cover. Nobody is a node or a rope
# contact: one packed-array step, binned by lane, drawn by world/crowd_layer.gd
# in a single ShapeBatch. The rope solver is never asked to know they exist.
# A taut leash laid across the flow shoves the pair along the flow through the
# push this step returns. A slack leash is stepped over. A taut leash that
# already runs with the flow does nothing.

const CAP := 150
const LANES := 8
const FLOW := -128.0          # north, px/s: quicker than the walk, so they stream past
const VENDOR_FLOW := 62.0     # south, back through the river
const LANE_GAP := 34.0
const BODY_R := 12.0
const PART_R := 32.0
const LEASH_HIT := 16.0
const NEAR_PAIR := 240.0
const PUSH_EACH := 18.0       # px/s added per fan held on a taut cross-leash
const PUSH_CAP := 70.0
const HOP_T := 0.32
const VIEW_N := 780.0         # how far past the pair the river is kept alive
const VIEW_S := 620.0
const PACE_WITH := 1.16       # packed crowd, walking their way
const PACE_AGAINST := 0.94    # packed crowd, walking home against it
const SHIFT := 22.0           # px of sideways drift at full density
const JUMP := 320.0          # a camera leap (a shot) rebuilds the window
# El Diluvi: a stroll, not a river. The shove is a jostle, not a carry.
const SHOPPERS := 28
const SHUFFLE_N := -42.0
const SHUFFLE_S := 36.0
const SHUFFLE_PUSH_EACH := 6.0
const SHUFFLE_PUSH_CAP := 22.0
# the clock (systems/match_day.gd) sets this. Walk is the river, jog is the
# rush, drain is the eight seconds into the gates, late is a handful running
# north after the streets have emptied.
const MODE_WALK := 0
const MODE_JOG := 1
const MODE_DRAIN := 2
const MODE_LATE := 3
const MODE_OUT := 4          # full time: the whole river pours south
const LATE_N := 6
const OUT_WIN := 150.0       # px/s south, faster than your human walks
const OUT_DRAW := 118.0
const OUT_LOSS := 64.0       # a grumbling crowd, the easy walk home
const DRAIN_SPEED := 170.0    # px/s east, off the street and into the gates
const DRAIN_GATES: Array[float] = [-3800.0, -4100.0, -4400.0]
var flow_mode := MODE_WALK
var _flow_was := MODE_WALK
var out_rate := OUT_DRAW
# fans of the outflow spawn north of this y, so one south of the dog has passed her
var out_wall := 0.0
# the same y cuts as Partit.STREET_Y1, AVENUE_Y0 and ROAD_END_Y. Kept here so
# this sim does not preload the level script (that script names the Game autoload).
const STREET_Y1 := -600.0
const AVENUE_Y0 := -1000.0
const ROAD_END_Y := -3420.0

var count := 0
var px := PackedFloat32Array()
var py := PackedFloat32Array()
var spd := PackedFloat32Array()
var hop := PackedFloat32Array()
var phase := PackedFloat32Array()
var lane := PackedByteArray()
var kind := PackedByteArray()   # 0 home, 1 away, 2 vendor
var on := PackedByteArray()

# false in tests that place fans by hand and want no window management
var manage := true
# shoppers on a shopping street: both directions, no stadium carry
var shuffle := false
# while the away column is on the east carriageway, the river keeps west of this x
var clear_east := 0.0
var anchored := false
var anchor_y := 0.0
var river_seed := 1
var hup_at := Vector2(INF, INF)
var hup_fresh := false
var hup_cd := 0.0
var _rng := RandomNumberGenerator.new()
var _bins_n: Array = []
var _bins_s: Array = []


func setup(s: int, n: int) -> void:
	river_seed = s
	count = mini(n, CAP)
	_rng.seed = s
	px.resize(count)
	py.resize(count)
	spd.resize(count)
	hop.resize(count)
	phase.resize(count)
	lane.resize(count)
	kind.resize(count)
	on.resize(count)
	_bins_n.clear()
	_bins_s.clear()
	for i in LANES:
		_bins_n.append([])
		_bins_s.append([])
	for i in count:
		lane[i] = i % LANES
		# vendors are the counterflow; a few away shirts so the river is not one color
		kind[i] = 2 if i % 11 == 0 else (1 if i % 7 == 0 else 0)
		spd[i] = 0.86 + float((i * 3) % 5) * 0.07
		phase[i] = float(i) * 0.37


# Both directions, every one of them in view, at a walking pace. The match
# river's density curve does not apply.
func setup_shuffle(s: int, n: int) -> void:
	shuffle = true
	setup(s, n)
	for i in count:
		kind[i] = 0 if i % 2 == 0 else 1
		lane[i] = i % LANES
		spd[i] = 0.82 + float((i * 5) % 7) * 0.05


# 0.24 on the side street, rising through the corner, 1 at the gates.
func density(y: float) -> float:
	if shuffle:
		return 1.0
	if y > STREET_Y1:
		return 0.24
	if y > AVENUE_Y0:
		var open_t := (STREET_Y1 - y) / (STREET_Y1 - AVENUE_Y0)
		return lerpf(0.24, 0.82, clampf(open_t, 0.0, 1.0))
	if y > ROAD_END_Y:
		var ave_t := (AVENUE_Y0 - y) / (AVENUE_Y0 - ROAD_END_Y)
		return lerpf(0.82, 1.0, clampf(ave_t, 0.0, 1.0))
	return 1.0


func target_at(y: float) -> int:
	if count <= 0 or flow_mode == MODE_DRAIN:
		return 0
	if flow_mode == MODE_LATE:
		return mini(LATE_N, count)
	if flow_mode == MODE_OUT:
		return count
	var n := clampi(int(round(float(count) * density(y))), mini(8, count), count)
	if flow_mode == MODE_JOG:
		n = mini(count, n + maxi(int(round(float(n) * 0.2)), 4))
	return n


# (sideways shift added to where they mean to go, pace multiplier).
# Pace only: the walk's acceleration is not this function's to change.
func carry(y: float, homeward: bool) -> Vector2:
	if shuffle:
		return Vector2(0.0, 1.0)
	var d := density(y)
	if flow_mode == MODE_DRAIN or flow_mode == MODE_LATE:
		return Vector2(0.0, 1.0)
	if flow_mode == MODE_OUT:
		var with := lerpf(1.0, PACE_WITH, d)
		return Vector2(sin(y * 0.013) * SHIFT * d, with)
	var pace := lerpf(1.0, PACE_AGAINST, d) if homeward else lerpf(1.0, PACE_WITH, d)
	return Vector2(sin(y * 0.013) * SHIFT * d, pace)


func active_count() -> int:
	var n := 0
	for i in count:
		if on[i] != 0:
			n += 1
	return n


func fingerprint() -> int:
	var h := 0
	for i in count:
		h = int((h * 33 + int(px[i] * 8.0) + int(py[i] * 8.0) * 17 + int(on[i])) & 0x7fffffff)
	return h


# step returns the shove to apply to the pair, in px/s along the flow
# (negative y is north). It does not move the dog or your human itself.
func step(dt: float, view_y: float, dog_p: Vector2, human_p: Vector2, leash: PackedVector2Array, taut: float, solids: Array, edges: Callable) -> Vector2:
	hup_fresh = false
	hup_cd = maxf(0.0, hup_cd - dt)
	if count <= 0:
		return Vector2.ZERO
	if manage and flow_mode != _flow_was:
		if flow_mode == MODE_LATE or flow_mode == MODE_OUT:
			anchored = false
		_flow_was = flow_mode
	if flow_mode == MODE_DRAIN:
		_drain(dt, edges)
		anchor_y = view_y
		return Vector2.ZERO
	if manage and (not anchored or absf(view_y - anchor_y) > JUMP):
		_relocate(view_y, edges)
		anchor_y = view_y
		anchored = true
		return Vector2.ZERO
	if manage:
		anchor_y = view_y
		_recycle(view_y, edges)
	for i in count:
		if on[i] == 0:
			continue
		var scale := 1.0 if shuffle else (1.7 if flow_mode == MODE_JOG else 1.0)
		var rate := FLOW
		if shuffle:
			rate = SHUFFLE_S if _southbound(i) else SHUFFLE_N
		elif flow_mode == MODE_LATE:
			rate = FLOW * 1.45
		elif flow_mode == MODE_OUT:
			rate = out_rate
		elif kind[i] == 2:
			rate = VENDOR_FLOW
		var vy := rate * spd[i] * scale * dt
		py[i] += vy
		phase[i] += absf(vy) * 0.08
		if hop[i] > 0.0:
			hop[i] = maxf(0.0, hop[i] - dt)
		var home_x := _lane_x(py[i], int(lane[i]), int(kind[i]), edges)
		if not _blocked(home_x, py[i], solids):
			px[i] = lerpf(px[i], home_x, minf(1.0, dt * 1.6))
	_space_lanes()
	for i in count:
		if on[i] == 0:
			continue
		_part_body(i, dog_p)
		_part_body(i, human_p)
		_out_of_solids(i, solids)
	var push_y := 0.0
	for i in count:
		if on[i] == 0:
			continue
		push_y += _leash_react(i, leash, taut, dog_p, human_p)
	for i in count:
		if on[i] == 0:
			continue
		var edge: Vector2 = edges.call(py[i])
		var lo := edge.x + 16.0
		var hi := edge.y - 16.0
		if hi > lo:
			px[i] = clampf(px[i], lo, hi)
	if shuffle:
		push_y *= SHUFFLE_PUSH_EACH / PUSH_EACH
	var cap := SHUFFLE_PUSH_CAP if shuffle else PUSH_CAP
	return Vector2(0.0, clampf(push_y, -cap, cap))


func _drain(dt: float, edges: Callable) -> void:
	for i in count:
		if on[i] == 0:
			continue
		var edge: Vector2 = edges.call(py[i])
		px[i] += DRAIN_SPEED * dt
		var gy := DRAIN_GATES[0]
		var best := absf(py[i] - gy)
		for g in DRAIN_GATES:
			var d := absf(py[i] - g)
			if d < best:
				best = d
				gy = g
		py[i] += clampf(gy - py[i], -90.0, 90.0) * dt
		if px[i] > edge.y + 24.0:
			on[i] = 0


func _relocate(view_y: float, edges: Callable) -> void:
	var want := target_at(view_y)
	var span := VIEW_N + VIEW_S
	for i in count:
		on[i] = 1 if i < want else 0
		hop[i] = 0.0
		if on[i] == 0:
			continue
		if flow_mode == MODE_OUT:
			var back := out_wall - 40.0
			py[i] = back - (float(i) + 0.5) / float(want) * VIEW_N
		else:
			py[i] = view_y - VIEW_N + (float(i) + 0.5) / float(want) * span
		px[i] = _lane_x(py[i], int(lane[i]), int(kind[i]), edges)


func _recycle(view_y: float, edges: Callable) -> void:
	var north := view_y - VIEW_N
	var south := view_y + VIEW_S
	var want := target_at(view_y)
	var alive := 0
	for i in count:
		if on[i] == 0:
			continue
		var y := py[i]
		var leaving := false
		if _southbound(i):
			leaving = y > south + 8.0 or y < north - 80.0
		else:
			leaving = y < north - 8.0 or y > south + 80.0
		if leaving:
			on[i] = 0
		else:
			alive += 1
	var room := maxi(want - alive, 0)
	if room <= 0:
		return
	# a few a frame, at the edge they walk in from, so a thickening street
	# does not pop a wall of people into view
	var spawned := 0
	for i in count:
		if spawned >= mini(room, 4):
			break
		if on[i] != 0:
			continue
		on[i] = 1
		spawned += 1
		if _southbound(i):
			py[i] = north + _rng.randf() * 36.0
		else:
			py[i] = south - _rng.randf() * 36.0
		px[i] = _lane_x(py[i], int(lane[i]), int(kind[i]), edges)


func _lane_x(y: float, lane_i: int, kind_i: int, edges: Callable) -> float:
	var edge: Vector2 = edges.call(y)
	var inset := 26.0
	var lo := edge.x + inset
	var hi := edge.y - inset
	if hi < lo + 30.0:
		return (edge.x + edge.y) * 0.5
	if shuffle:
		# two bands under the cover, and a gap down the middle of the street
		var mid := (lo + hi) * 0.5
		var span := (hi - lo) * 0.5
		var side := -1.0 if lane_i < 4 else 1.0
		var along := float(lane_i % 4) / 3.0
		var x := mid + side * lerpf(span * 0.42, span * 0.92, along)
		if kind_i != 0:
			x += 16.0 if lane_i % 2 == 0 else -16.0
		return clampf(x, lo, hi)
	var x := lo + (float(lane_i) + 0.5) / float(LANES) * (hi - lo)
	if kind_i == 2:
		x += 12.0 if lane_i % 2 == 0 else -12.0
	if clear_east > 0.0:
		x = minf(x, clear_east - 20.0)
	return clampf(x, lo, hi)


func _southbound(i: int) -> bool:
	if flow_mode == MODE_OUT:
		return true
	if shuffle:
		return kind[i] != 0
	return kind[i] == 2


func any_south_of(y: float) -> bool:
	for i in count:
		if on[i] != 0 and py[i] > y:
			return true
	return false


static func outflow_rate(which: String) -> float:
	if which == "home":
		return OUT_WIN
	if which == "away":
		return OUT_LOSS
	return OUT_DRAW


func _space_lanes() -> void:
	for L in LANES:
		(_bins_n[L] as Array).clear()
		(_bins_s[L] as Array).clear()
	for i in count:
		if on[i] == 0:
			continue
		var bin: Array = _bins_s[lane[i]] if _southbound(i) else _bins_n[lane[i]]
		_insert(bin, i)
	for L in LANES:
		var north: Array = _bins_n[L]
		for k in range(1, north.size()):
			var leader: int = north[k - 1]
			var follower: int = north[k]
			if py[follower] - py[leader] < LANE_GAP:
				py[follower] = py[leader] + LANE_GAP
		var south: Array = _bins_s[L]
		for k in range(south.size() - 2, -1, -1):
			var ahead: int = south[k + 1]
			var behind: int = south[k]
			if py[ahead] - py[behind] < LANE_GAP:
				py[behind] = py[ahead] - LANE_GAP


func _insert(bin: Array, i: int) -> void:
	var y := py[i]
	var at := bin.size()
	bin.append(i)
	while at > 0 and py[int(bin[at - 1])] > y:
		bin[at] = bin[at - 1]
		at -= 1
	bin[at] = i


func _part_body(i: int, body: Vector2) -> void:
	var dx := px[i] - body.x
	var dy := py[i] - body.y
	var d2 := dx * dx + dy * dy
	var r := PART_R
	if d2 >= r * r or d2 < 0.04:
		return
	var d := sqrt(d2)
	var push := (r - d) / d
	# sideways first; along the flow only a little, so a column is not shoved back
	px[i] += dx * push
	py[i] += dy * push * 0.35


func _blocked(x: float, y: float, solids: Array) -> bool:
	for r: Rect2 in solids:
		var g := r.grow(BODY_R)
		if g.has_point(Vector2(x, y)):
			return true
	return false


func _out_of_solids(i: int, solids: Array) -> void:
	var x := px[i]
	var y := py[i]
	for r: Rect2 in solids:
		var g := r.grow(BODY_R)
		if x < g.position.x or x > g.end.x or y < g.position.y or y > g.end.y:
			continue
		var to_w := x - g.position.x
		var to_e := g.end.x - x
		var to_n := y - g.position.y
		var to_s := g.end.y - y
		var vx := to_w if to_w < to_e else to_e
		var vy := to_n if to_n < to_s else to_s
		# along the flow when that exit is the short one, else out the side
		if vy <= vx:
			y = g.position.y if to_n <= to_s else g.end.y
		else:
			x = g.position.x if to_w <= to_e else g.end.x
	px[i] = x
	py[i] = y


# px/s along the flow from this fan, or 0. Also steps them over a slack leash.
func _leash_react(i: int, leash: PackedVector2Array, taut: float, dog_p: Vector2, human_p: Vector2) -> float:
	var mid := (dog_p + human_p) * 0.5
	if absf(px[i] - mid.x) > NEAR_PAIR or absf(py[i] - mid.y) > NEAR_PAIR:
		return 0.0
	var n := leash.size()
	if n < 2:
		return 0.0
	var best := NEAR_PAIR
	var ax := 0.0
	var ay := 0.0
	var bx := 0.0
	var by := 0.0
	var cx := 0.0
	var cy := 0.0
	for s in range(n - 1):
		var a: Vector2 = leash[s]
		var b: Vector2 = leash[s + 1]
		var hit := _closest(px[i], py[i], a, b)
		var d := Vector2(px[i] - hit.x, py[i] - hit.y).length()
		if d < best:
			best = d
			ax = a.x
			ay = a.y
			bx = b.x
			by = b.y
			cx = hit.x
			cy = hit.y
	if best > LEASH_HIT:
		return 0.0
	if taut < 0.45:
		hop[i] = HOP_T
		var off := _away(px[i], py[i], cx, cy, ax, ay, bx, by, LEASH_HIT + 8.0 - best)
		px[i] += off.x
		py[i] += off.y - 14.0
		_maybe_hup(i)
		return 0.0
	var chord := human_p - dog_p
	var across := absf(chord.x) > absf(chord.y) * 0.8
	if taut > 0.55 and across and kind[i] != 2:
		var slide := _away(px[i], py[i], cx, cy, ax, ay, bx, by, 6.0)
		px[i] += slide.x * 0.35
		return -PUSH_EACH
	return 0.0


func _maybe_hup(i: int) -> void:
	if hup_cd > 0.0:
		return
	if _rng.randi() % 3 != 0:
		return
	hup_at = Vector2(px[i], py[i])
	hup_fresh = true
	hup_cd = 1.6


func _closest(x: float, y: float, a: Vector2, b: Vector2) -> Vector2:
	var ab := b - a
	var l2 := ab.length_squared()
	var t := 0.0
	if l2 > 0.01:
		t = clampf(((x - a.x) * ab.x + (y - a.y) * ab.y) / l2, 0.0, 1.0)
	return a + ab * t


func _away(x: float, y: float, cx: float, cy: float, ax: float, ay: float, bx: float, by: float, dist: float) -> Vector2:
	var dx := x - cx
	var dy := y - cy
	var d := sqrt(dx * dx + dy * dy)
	if d > 0.5:
		return Vector2(dx / d * dist, dy / d * dist)
	# standing on the rope: step off to the side of the segment
	var sx := -(by - ay)
	var sy := bx - ax
	var sl := sqrt(sx * sx + sy * sy)
	if sl < 0.01:
		return Vector2(dist, 0.0)
	return Vector2(sx / sl * dist, sy / sl * dist)
