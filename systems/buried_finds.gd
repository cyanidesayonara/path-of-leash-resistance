extends RefCounted

# Buried finds: PER_WALK things buried in the soft ground just off every
# walk's path (grass, sand or mud, never paving; on a paved walk, a street
# tree's pit by the path, or a stash tucked by a bench or a bin), the same
# spots on every run. Each gives off a faint scent that only reaches her up close, further
# with a better nose (Game.dog_nose_mult); stand still over one and she digs
# it up. The first time a dog digs up a find it is a training point for her
# (Game.record_find), spent on her stats in the wardrobe; a find she has had
# before is only a hole. Finds are her own: each dog has every walk's to dig.
#
# Placed from a hash of the walk, never the RNG, so a seeded walk replays.

const Surfaces := preload("res://world/surfaces.gd")
const EventFeed := preload("res://hud/event_feed.gd")

const PER_WALK := 3
# how far from the path's edge a find may lie, nearest first
const OFFSETS: Array[float] = [36.0, 60.0, 90.0, 125.0]
const TRIES := 6                   # rows tried, down and up, for each find
const ROW_STEP := 70.0
const SCENT_REACH := 105.0         # how near a plain nose must be to smell one
const DIG_R := 28.0
const DIG_SPEED := 70.0            # she digs only when nearly still
const DIG_TIME := 1.3
const BONUS := 3                   # bones for digging one up
const COL := Color(0.94, 0.90, 0.76)  # the pale bone of something buried
const SOFT := [Surfaces.S.GRASS, Surfaces.S.SAND, Surfaces.S.MUD]


static func _hash(s: String, i: int, salt: int) -> float:
	var h := hash("%s/%d/%d" % [s, i, salt])
	return float(h & 0xffff) / 65535.0


# Soft ground she can reach near about y: inside the walls first, nearest a
# wall (a verge, a planter, a tree pit), then just outside the path where a
# walk has open ground past its edges, then a street tree's pit. None, or
# Vector2.INF.
const SCAN_STEP := 20.0
const WALL_KEEP := 18.0             # clear of the wall itself


static func _soft(m: Node2D, p: Vector2) -> bool:
	return int(m.surface_at(p)) in SOFT and not _blocked(m, p) and not _taken(m, p)


# whether a find already lies too near this spot
static func _taken(m: Node2D, p: Vector2) -> bool:
	for f: Dictionary in m.finds:
		if (f.pos as Vector2).distance_to(p) < APART:
			return true
	return false


static func _spot(m: Node2D, y: float, first_side: float) -> Vector2:
	for k in range(TRIES):
		var yy := y + ROW_STEP * float((k + 1) / 2) * (1.0 if k % 2 == 0 else -1.0)
		var e: Vector2 = m.walk_edges(yy)
		# inside the walls, from the first side's wall inward, then the other's
		var half := (e.y - e.x) * 0.5
		var d := WALL_KEEP
		while d < half:
			for side: float in [first_side, -first_side]:
				var x := (e.x + d) if side < 0.0 else (e.y - d)
				var p := Vector2(x, yy)
				if _soft(m, p):
					return p
			d += SCAN_STEP
		for side: float in [first_side, -first_side]:
			for off: float in OFFSETS:
				var p := Vector2((e.x - off) if side < 0.0 else (e.y + off), yy)
				if _soft(m, p):
					return p
	var pit := _tree_pit(m, y)
	if pit != Vector2.INF:
		return pit
	return _stash(m, y)


# On a walk paved wall to wall there is nothing to dig: a find is a stash
# tucked by a bench or a bin, nosed out the same way.
const STASH_OFF := 30.0


static func _stash(m: Node2D, y: float) -> Vector2:
	var best := Vector2.INF
	var best_d := PIT_REACH
	var spots: Array[Vector2] = []
	spots.append_array(m.benches)
	spots.append_array(m.bins)
	for q: Vector2 in spots:
		var dy := absf(q.y - y)
		if dy >= best_d:
			continue
		var e: Vector2 = m.walk_edges(q.y)
		var mid := (e.x + e.y) * 0.5
		for off: Vector2 in [Vector2(signf(mid - q.x) * STASH_OFF, 0.0), Vector2(0.0, STASH_OFF), Vector2(0.0, -STASH_OFF)]:
			var p := q + off
			if p.x < e.x + WALL_KEEP or p.x > e.y - WALL_KEEP or _blocked(m, p) or _taken(m, p):
				continue
			best = p
			best_d = dy
			break
	return best


# on a paved walk, the earth at the foot of the nearest street tree by the path
const PIT_OFF := 24.0              # off the trunk, still in the pit
const PIT_REACH := 1100.0          # how far along the walk to look for one
const APART := 260.0               # no two finds nearer each other than this


static func _tree_pit(m: Node2D, y: float) -> Vector2:
	var best := Vector2.INF
	var best_d := PIT_REACH
	for t: Vector2 in m.trees:
		var dy := absf(t.y - y)
		if dy >= best_d:
			continue
		var e: Vector2 = m.walk_edges(t.y)
		if t.x < e.x - 70.0 or t.x > e.y + 70.0:
			continue
		# the side of the trunk toward the path's middle
		var p := t + Vector2(PIT_OFF * signf((e.x + e.y) * 0.5 - t.x), PIT_OFF * 0.4)
		if _blocked(m, p) or _taken(m, p):
			continue
		best = p
		best_d = dy
	return best


static func _blocked(m: Node2D, p: Vector2) -> bool:
	for r: Rect2 in m.solid_rects:
		if r.grow(DIG_R).has_point(p):
			return true
	return false


# where this walk's finds are, laid out once when the walk is built
static func build(m: Node2D) -> void:
	m.finds = []
	var lv := String(m.lvl)
	if lv == "tutorial" or bool(m.get("tutorial_mode")):
		return
	var top := float(m.GATE_Y) + 300.0
	var bottom := float(m.START_Y) - 500.0
	if bottom <= top:
		return
	for i in range(PER_WALK):
		var u := (float(i) + 0.25 + 0.5 * _hash(lv, i, 1)) / float(PER_WALK)
		var y := lerpf(bottom, top, u)
		var p := _spot(m, y, -1.0 if _hash(lv, i, 2) < 0.5 else 1.0)
		if p == Vector2.INF:
			continue
		m.finds.append({"i": i, "pos": p, "prog": 0.0, "dug": Game.find_found(lv, i), "had": Game.find_found(lv, i)})


# Digging, called with the walk's other diggings. Says whether she is digging
# one up this frame.
static func tick(m: Node2D, delta: float) -> bool:
	var digging := false
	var dp: Vector2 = m.dog.global_position
	var still: bool = (m.dog.velocity as Vector2).length() < DIG_SPEED
	for f: Dictionary in m.finds:
		if bool(f.dug):
			continue
		if still and dp.distance_to(f.pos) < DIG_R:
			digging = true
			f.prog = float(f.prog) + delta
			if float(f.prog) >= DIG_TIME:
				_dug(m, f)
		else:
			f.prog = maxf(0.0, float(f.prog) - delta * 0.6)
	return digging


static func _dug(m: Node2D, f: Dictionary) -> void:
	f.dug = true
	var new := Game.record_find(String(m.lvl), int(f.i))
	m.bones += BONUS
	Sfx.play("star", 0.85)
	m.combo.add("DIG", 4)
	if new:
		m.feed.say(I18n.t("find_dug"), EventFeed.Tone.GOOD)
		m.float_text(f.pos, I18n.t("find_score"), Color(0.55, 0.95, 0.9))
	else:
		m.float_text(f.pos, I18n.t("find_again") % BONUS, Color(1, 0.9, 0.55))
	m._update_hud()


# the finds she can smell: faint, and only within her nose's reach of them
static func scents(m: Node2D) -> Array:
	var out: Array = []
	var reach := SCENT_REACH * Game.dog_nose_mult()
	for f: Dictionary in m.finds:
		if not bool(f.dug):
			out.append({"pos": f.pos, "col": COL, "reach": reach})
	return out


# a dug find: the hole, its thrown earth, and while she digs the spray of it
static func draw(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var soil := Color(0.34, 0.26, 0.18)
	for f: Dictionary in m.finds:
		var p: Vector2 = f.pos
		if p.y < vt - 40.0 or p.y > vb + 40.0:
			continue
		var prog := clampf(float(f.prog) / DIG_TIME, 0.0, 1.0)
		if bool(f.dug):
			prog = 1.0
		elif prog <= 0.0:
			continue
		var lt: Vector2 = Shade.light
		b.circle(p + lt * 6.0, 9.0 + 3.0 * prog, soil.lightened(0.12))
		b.circle(p, 7.0 + 4.0 * prog, soil.darkened(0.15))
		b.circle(p - lt * 1.5, 4.5 + 3.5 * prog, soil.darkened(0.55))
		for k in range(4):
			var a := TAU * float(k) / 4.0 + p.x * 0.03
			b.circle(p + Vector2.from_angle(a) * (10.0 + 4.0 * prog), 2.2, soil)
