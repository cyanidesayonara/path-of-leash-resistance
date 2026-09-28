extends Node2D

# A pickpocket working La Rambla's crowd (docs/LEVEL_DESIGN.md, Pickpockets).
#
# Readable before he strikes, by contract: he picks a mark and sidles in
# behind them for at least STALK_MIN, cap pulled low, glancing about, before
# the lift. His marks are the tourists and, above all, the owner, who never
# looks up. He takes wallets, never the phone.
#
# With a wallet he runs for the nearest side street. Every way of stopping
# him is slapstick: the leash across his legs, the dog bowling him over at a
# run, a slip on something on the paving, tripping over a seller's blanket,
# the owner flung into him. He goes down, the wallet pops out, and he slinks
# off. Unless he goes down beside an open manhole: then the wallet drops in
# and nobody gets it back. A bark while he is stalking scares him off before
# the lift.
#
# Self-managing and order-independent, like the other critters.

enum S { LURK, STALK, LIFT, RUN, DOWN, SLINK, GONE }

const LURK_SPEED := 50.0
const STALK_SPEED := 130.0      # faster than the owner walks, so he can close in
const STALK_MIN := 1.6          # the tell is on screen at least this long
const LIFT_T := 0.6
const RUN_SPEED := 190.0        # well under her sprint, so a chase is fair
const DOWN_T := 1.4
const SLINK_SPEED := 70.0
const BUMP_R := 26.0
const BUMP_SPEED := 200.0       # she has to be going properly to bowl him
const ROPE_R := 9.0             # the leash this close to his legs trips him
const MANHOLE_R := 44.0
const BARK_R := 170.0

var main: Node2D
var state := S.LURK
var state_t := 0.0
var mark: Node2D = null
var mark_is_owner := false
var stalked := 0.0
var run_to := Vector2.ZERO
var run_dir := Vector2.UP
var down_why := ""
var slink_dir := 1.0
var wallet_pos := Vector2.ZERO     # the wallet in flight after he goes down
var wallet_t := -1.0
var wallet_lost := false
var weave_seed := 0.0


func setup(m: Node2D, at: Vector2, target: Node2D, is_owner: bool, seed_f: float) -> void:
	add_to_group("pickpockets")
	main = m
	global_position = at
	mark = target
	mark_is_owner = is_owner
	weave_seed = seed_f
	state = S.STALK
	stalked = 0.0


func has_wallet() -> bool:
	return state == S.RUN


func scare() -> void:
	# a bark before the lift: he thinks better of it and slips away
	if state == S.STALK or state == S.LURK:
		main.on_pickpocket_busted(global_position)
		_start_slink()


func _start_slink() -> void:
	state = S.SLINK
	var e: Vector2 = main.walk_edges(global_position.y)
	slink_dir = -1.0 if global_position.x < (e.x + e.y) * 0.5 else 1.0


func _behind(target: Node2D) -> Vector2:
	# behind the mark, relative to the way they are facing
	var d := 1.0
	if target == main.human:
		d = -1.0 if main.human.homeward else 1.0
	elif "dir" in target:
		d = -float(target.dir)
	return target.global_position + Vector2(8.0, 24.0 * d)


func _physics_process(delta: float) -> void:
	if main.frozen:
		return
	state_t += delta
	match state:
		S.STALK:
			if mark == null or not is_instance_valid(mark):
				_start_slink()
				return
			var to := _behind(mark) - global_position
			var sp: float = STALK_SPEED
			global_position += to.limit_length(sp * delta)
			stalked += delta
			# charged before the lift: he thinks better of it
			if main.dog.global_position.distance_to(global_position) < BUMP_R and main.dog.velocity.length() > BUMP_SPEED:
				scare()
				return
			if stalked >= STALK_MIN and to.length() < 14.0:
				state = S.LIFT
				state_t = 0.0
		S.LIFT:
			global_position = _behind(mark)
			if state_t >= LIFT_T:
				if mark_is_owner:
					main.owner_wallet_taken = true
				elif mark.has_method("robbed"):
					mark.robbed()
				main.on_pickpocket_lift(mark.global_position, mark_is_owner)
				_pick_exit()
				state = S.RUN
				state_t = 0.0
		S.RUN:
			var to := run_to - global_position
			var weave := Vector2(sin(main.elapsed * 5.0 + weave_seed) * 60.0, 0.0)
			global_position += (to.normalized() * RUN_SPEED + weave) * delta
			run_dir = to.normalized()
			if _stopped_by():
				return
			if to.length() < 20.0 or absf(global_position.x - 640.0) > 700.0:
				main.on_pickpocket_escaped(mark_is_owner)
				state = S.GONE
				queue_free()
		S.DOWN:
			if wallet_t >= 0.0:
				wallet_t += delta
			if state_t >= DOWN_T:
				_start_slink()
		S.SLINK:
			global_position.x += slink_dir * SLINK_SPEED * delta
			if absf(global_position.x - 640.0) > 700.0 or state_t > 12.0:
				queue_free()


func _pick_exit() -> void:
	# the nearest side street ahead of him or behind, out along the crossing;
	# with none near, off the end of the screen up the promenade
	var best := INF
	run_to = global_position + Vector2(0.0, -900.0)
	for ly: float in main.lane_ys:
		var d := absf(ly - global_position.y)
		if d < best and d < 700.0:
			best = d
			var side := -1.0 if global_position.x < 640.0 else 1.0
			run_to = Vector2(640.0 + side * 760.0, ly)


func _stopped_by() -> bool:
	var p := global_position
	var dog: Node2D = main.dog
	# the dog bowling him over at a run
	if dog.global_position.distance_to(p) < BUMP_R and dog.velocity.length() > BUMP_SPEED:
		_go_down("bump", (p - dog.global_position).normalized())
		return true
	# the rope and the owner are right beside him at the lift: give him a
	# moment to get clear before either can trip him
	if state_t < 0.4:
		return false
	# the leash across his legs
	var pts: Array = main.leash.pts
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var ab := b - a
		var f := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
		if p.distance_to(a + ab * f) < ROPE_R:
			_go_down("tangle", run_dir)
			return true
	# the owner, flung or stumbling into him
	var h: Node2D = main.human
	if h.global_position.distance_to(p) < 30.0 and (h.is_whirling() or h.velocity.length() > 150.0):
		_go_down("owner", (p - h.global_position).normalized())
		return true
	# a seller's blanket underfoot, or a seller running past with the bundle
	for bl: Dictionary in main.blankets:
		var laid := String(bl.get("state", "laid")) == "laid"
		if (laid and (bl["rect"] as Rect2).has_point(p)) or (main.bundle_moving(bl) and main.seller_at(bl).distance_to(p) < 20.0):
			_go_down("blanket", run_dir)
			return true
	# something slippery on the paving
	for pt: Dictionary in main.patches:
		if String(pt["kind"]) in ["oil", "fish", "paint", "mud", "cement", "icecream"] and main.patch_has_point(pt, p):
			_go_down("slip", run_dir)
			return true
	return false


func _go_down(why: String, fling: Vector2) -> void:
	state = S.DOWN
	state_t = 0.0
	down_why = why
	global_position += fling * 14.0
	# the wallet pops out, unless he went down by an open manhole
	for mh: Vector2 in main.manholes:
		if mh.distance_to(global_position) < MANHOLE_R:
			wallet_lost = true
			wallet_pos = mh
			break
	if not wallet_lost:
		wallet_pos = global_position + fling * 30.0
	wallet_t = 0.0
	main.on_pickpocket_stopped(global_position, why, wallet_lost, mark, mark_is_owner)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := AnimClock.msec() / 1000.0
	var b := ShapeBatch.new()
	var down := state == S.DOWN
	var body := Color(0.22, 0.22, 0.26)
	b.circle(Vector2(3, 4), 11.0, Color(0, 0, 0, 0.2))
	if down:
		# flat on his back, legs in the air
		b.circle(Vector2(0, 0), 11.0, body)
		b.line(Vector2(-4, 8), Vector2(-10, 18), body.darkened(0.2), 4.0)
		b.line(Vector2(4, 8), Vector2(12, 16), body.darkened(0.2), 4.0)
		b.circle(Vector2(0, -8), 6.5, Color(0.80, 0.64, 0.50))
		# stars going round his head
		for k in range(3):
			var a := t * 4.0 + TAU * float(k) / 3.0
			b.circle(Vector2(0, -10) + Vector2(cos(a) * 12.0, sin(a) * 5.0), 2.2, Color(1, 0.9, 0.4))
	else:
		b.circle(Vector2.ZERO, 11.0, body)
		b.circle(Vector2(0, -4), 6.5, Color(0.80, 0.64, 0.50))
		# the cap pulled low, peak forward; the glance side to side
		var glance := sin(t * 3.0 + weave_seed) * 3.0 if state == S.STALK else 0.0
		b.circle(Vector2(glance, -5), 6.8, Color(0.14, 0.14, 0.16))
		b.rect(Rect2(glance - 5.0, -14.0, 10.0, 4.0), Color(0.10, 0.10, 0.12))
		if state == S.LIFT:
			# the hand going in
			var hand := (_behind(mark) - global_position) * 0.0 + Vector2(-2, -18)
			b.line(Vector2(4, -4), hand, body.lightened(0.1), 3.0)
		if state == S.RUN:
			# the wallet, held up where the player can follow it
			b.rect(Rect2(8.0, -10.0, 9.0, 7.0), Color(0.45, 0.28, 0.16))
	b.flush(self)
	if state == S.STALK and stalked > 0.4 and fmod(t, 0.8) < 0.5:
		draw_string(ThemeDB.fallback_font, Vector2(-8, -20), "...", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.85, 0.5))
	if wallet_t >= 0.0 and wallet_t < 0.6 and not wallet_lost:
		# the wallet arcing out of his hand
		var f := wallet_t / 0.6
		var wp: Vector2 = (wallet_pos - global_position) * f + Vector2(0, -40.0 * sin(f * PI))
		draw_rect(Rect2(wp.x - 5.0, wp.y - 4.0, 10.0, 8.0), Color(0.45, 0.28, 0.16))
