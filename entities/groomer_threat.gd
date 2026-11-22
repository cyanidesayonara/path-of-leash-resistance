extends Node2D

# The chase threat of La Molina: the piste basher. The big snow groomer was
# parked at the top of the run, and as they turn for home its brake lets go
# and it comes down the piste after them, nobody in the cab: the lamps on,
# the amber beacon going round, the blade down and pushing a wall of snow,
# the tiller behind it combing the piste into corduroy. Cartoonishly
# menacing to a dog: the two headlamps are its eyes, the visor over them a
# scowl, the blade's scraper a row of teeth.
#
# What sets it apart: it rolls snowballs. Every few seconds a lump of the
# snow it is pushing packs itself up on top of the blade, and a track shows
# on the piste ahead (SNOWBALL_WARN long, the telegraph) down the line it
# will roll. Then it drops off and rolls down that line, growing as it goes,
# faster than your human walks and slower than she runs. Whoever is in its
# way is knocked (the dog tumbles; your human is bumped, never a fall).
# Out of its way as it passes, close enough to feel the powder, is a dodge.
# The blade itself is the catch line, as every chase's.
#
# What is in its way (systems/chase_vehicle.gd): a machine this wide is a
# juggernaut: it flattens posts and rides up and over benches, and the
# heavy things stop it dead for a moment.
#
# Implements the standard chase threat interface (setup, advance, caught,
# gap_to, threat_boundary, sweep_junk) so systems/home_chase drives it. Only
# advance() moves it, and home_chase only calls that in the "chase" phase,
# so no snowball rolls during the warning, the head start or a hold.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const ChaseVehicleScript := preload("res://systems/chase_vehicle.gd")

# the machine: a red cab, rubber tracks, a steel blade
const CAB := Color(0.84, 0.16, 0.14)
const CAB_DARK := Color(0.54, 0.08, 0.08)
const CAB_LIT := Color(0.96, 0.38, 0.30)
const ROOF := Color(0.94, 0.93, 0.90)
const GLASS := Color(0.16, 0.20, 0.28)
const GLASS_LIT := Color(0.52, 0.68, 0.82)
const TRACK := Color(0.12, 0.12, 0.14)
const TRACK_LUG := Color(0.26, 0.26, 0.29)
const BLADE := Color(0.62, 0.64, 0.68)
const BLADE_LIT := Color(0.86, 0.88, 0.92)
const BLADE_DARK := Color(0.30, 0.31, 0.35)
const TOOTH := Color(0.94, 0.94, 0.96)
const TILLER := Color(0.30, 0.30, 0.33)
const LAMP := Color(1.0, 0.97, 0.80)
const LAMP_GLOW := Color(1.0, 0.95, 0.70, 0.30)
const BEACON := Color(1.0, 0.62, 0.10)
const EXHAUST := Color(0.20, 0.20, 0.22, 0.30)
const SNOW := Color(0.96, 0.97, 1.0)
const SNOW_SHADE := Color(0.74, 0.80, 0.92)
const SNOW_DEEP := Color(0.58, 0.66, 0.82)
# a snowball's outline and what it rolls up, film and walk alike: a dark blue
# rim so it never melts into the piste, fir twigs and grit packed into it
const SNOWBALL_RIM := Color(0.18, 0.24, 0.40)
const SNOWBALL_TWIG := Color(0.20, 0.34, 0.24)
const SNOWBALL_GRIT := Color(0.36, 0.32, 0.30)
const SHADOW := Color(0.10, 0.14, 0.26, 0.30)
const TRACK_MARK := Color(0.44, 0.56, 0.86, 0.55)

const SURGE := 0.16
const CATCH_UP := 1.35
const CATCH_UP_GAP := 660.0
const JAM_SECS := 3.0
# from the blade's edge back to the tiller
const DEPTH := 210.0
# the blade's half-width as a fraction of the corridor's
const CATCH_SPAN := 0.80

# the snowballs it rolls down the fall line
const SNOWBALL_FIRST := 1.4      # after the chase begins, the first one
const SNOWBALL_EVERY := 2.6      # between them, before the jitter
const SNOWBALL_JITTER := 0.5
const SNOWBALL_WARN := 1.0       # packing on the blade, its track showing
const SNOWBALL_SPEED := 250.0    # rolling: faster than your human, slower than her run
const SNOWBALL_RANGE := 760.0    # how far it rolls before it bursts
const SNOWBALL_R0 := 13.0        # its radius as it drops off the blade
const SNOWBALL_R1 := 30.0        # and when it bursts
const SNOWBALL_HIT := 12.0       # added to its radius: a body this close is hit
const SNOWBALL_DODGE := 90.0     # passing this close without a hit: a dodge
const MAX_SNOWBALLS := 3
const PUFF_TIME := 0.5
const DODGE_BONES := 1

var main: Node2D
var speed := 128.0
var cur_speed := 128.0
var front_y := 0.0
var cx := 640.0
var half := 270.0
var kind := "groomer"
var rumble := 0.0
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
# {"x": lane, "y": world y of its centre, "t": time since it was packed,
#  "rolling": bool, "dog_near", "hum_near", "hit": bool}
var snowballs: Array[Dictionary] = []
# {"at", "r", "t"}: a burst of powder
var puffs: Array[Dictionary] = []
var pack_t := SNOWBALL_FIRST
var rolled := 0
var hits := 0
var dodges := 0
var drive = ChaseVehicleScript.new()


func setup(m: Node2D, start_front_y: float, corridor_cx: float, corridor_half: float, groomer_speed: float) -> void:
	main = m
	front_y = start_front_y
	cx = corridor_cx
	half = corridor_half
	speed = groomer_speed
	cur_speed = groomer_speed
	snowballs.clear()
	puffs.clear()
	pack_t = SNOWBALL_FIRST
	position = Vector2(cx, front_y)


func advance(delta: float, gap := -1.0, aim := 0.0) -> void:
	rumble += delta
	jammed_now = false
	freed_now = false
	_tick_snowballs(delta)
	if jam_t > 0.0:
		jam_t -= delta
		cur_speed = 0.0
		if jam_t <= 0.0:
			freed_now = true
		if main != null:
			drive.bonk(main, Rect2(), delta)
		queue_redraw()
		return

	var lurch := sin(rumble * 1.1) * 0.6 + sin(rumble * 2.7) * 0.4
	var mult := 1.0 + SURGE * lurch
	if gap > CATCH_UP_GAP:
		mult = maxf(mult, CATCH_UP)
	cur_speed = speed * mult * drive.pace()
	front_y += cur_speed * delta

	for i in range(jams.size()):
		if front_y >= jams[i].y:
			jam_side = signf(jams[i].x - cx)
			jam_at = jams[i]
			jams.remove_at(i)
			jam_t = JAM_SECS
			jammed_now = true
			break

	# on snow it slews: a slow drift toward the dog's side, or a skid round
	# something heavy where there is room
	var target_sway: float = clampf(aim, -half * 0.30, half * 0.30)
	var steer := 1.4
	if main != null:
		var room := maxf(half - half * CATCH_SPAN, 0.0) + half * 0.30
		var dodge: float = drive.dodge_sway(main, cx, sway, front_y, half * CATCH_SPAN, room)
		if not is_nan(dodge):
			target_sway = dodge
			steer = 3.0
	sway_v += (target_sway - sway) * steer * delta
	sway_v *= exp(-2.6 * delta)
	sway += sway_v * delta
	heading = clampf(sway_v * 0.004, -0.12, 0.12)

	pack_t -= delta
	if pack_t <= 0.0 and snowballs.size() < MAX_SNOWBALLS:
		_pack()
		pack_t = SNOWBALL_EVERY + SNOWBALL_JITTER * sin(float(rolled) * 2.39)
	position = Vector2(cx + sway, front_y)
	_run_over(delta)
	queue_redraw()


# under its tracks: light things it rides over, heavy ones stop it dead
func _run_over(delta: float) -> void:
	if main == null:
		return
	var w := half * CATCH_SPAN
	var body := Rect2(cx + sway - w, front_y - DEPTH, w * 2.0, DEPTH)
	var sfx := main.get_node_or_null("/root/Sfx")
	var side: float = drive.slam(main, body, cx)
	if side != 0.0 and jam_t <= 0.0:
		jam_t = drive.SLAM_SECS
		jam_side = side
		jam_at = Vector2(INF, INF)
		jammed_now = true
		main.shake_t = maxf(float(main.shake_t), 0.6)
	if drive.bonk(main, body, delta):
		if sfx != null:
			sfx.play("crack", 0.9, -8.0)
		main.shake_t = maxf(float(main.shake_t), 0.3)
		if not bool(main.auto_walk):
			main.float_text(drive.bonk_at + Vector2(0.0, -24.0), I18n.t("w_crunch"), Color(0.86, 0.92, 1.0))


func jammed() -> bool:
	return jam_t > 0.0


func threat_boundary() -> float:
	return front_y


func caught(p: Vector2) -> bool:
	if p.y <= front_y and p.y >= front_y - DEPTH * 0.6:
		return absf(p.x - (cx + sway)) <= half * CATCH_SPAN
	# it came on past them: whoever slipped by at the side went under a track
	return p.y < front_y - DEPTH * 0.6


func gap_to(p: Vector2) -> float:
	return p.y - front_y


func sweep_junk(_junk: Array) -> int:
	return 0


# The lane the next snowball rolls down: the dog and your human in turn, led
# a little by how they are moving across the piste, kept on the corridor.
func lane_for(target: Vector2, vel: Vector2) -> float:
	var x := target.x + vel.x * 0.4
	var lim := half * CATCH_SPAN - SNOWBALL_R1
	return clampf(x, cx + sway - lim, cx + sway + lim)


func _pack() -> void:
	if main == null:
		return
	var x: float
	if rolled % 2 == 0:
		x = lane_for(main.dog.global_position, main.dog.velocity)
	else:
		x = lane_for(main.human.global_position, main.human.velocity)
	rolled += 1
	snowballs.append({"x": x, "y": front_y + 8.0, "t": 0.0, "rolling": false, "hit": false,
		"dog_near": false, "hum_near": false})
	Sfx.play("grit", 0.6, -14.0)


static func radius_at(rolled_px: float) -> float:
	return lerpf(SNOWBALL_R0, SNOWBALL_R1, clampf(rolled_px / SNOWBALL_RANGE, 0.0, 1.0))


func _tick_snowballs(delta: float) -> void:
	for i in range(puffs.size() - 1, -1, -1):
		puffs[i]["t"] = float(puffs[i]["t"]) - delta
		if float(puffs[i]["t"]) <= 0.0:
			puffs.remove_at(i)
	for i in range(snowballs.size() - 1, -1, -1):
		var s: Dictionary = snowballs[i]
		s["t"] = float(s["t"]) + delta
		if not bool(s["rolling"]):
			# packing on the blade: it rides along with it
			s["y"] = front_y + 8.0
			if float(s["t"]) >= SNOWBALL_WARN:
				s["rolling"] = true
				s["from"] = front_y + 8.0
				Sfx.play("diesel", 1.3, -16.0)
			continue
		s["y"] = float(s["y"]) + SNOWBALL_SPEED * delta
		var gone := float(s["y"]) - float(s["from"])
		if _roll_into(s) or gone >= SNOWBALL_RANGE:
			_burst(s)
			snowballs.remove_at(i)


# Whoever is in its way is knocked; whoever it passes close by is a dodge,
# paid once it bursts. The autowalk bot is never knocked (CI's selftest and
# the soak carry an unsweepable pair; home_chase does the same for the catch).
func _roll_into(s: Dictionary) -> bool:
	if main == null:
		return false
	var at := Vector2(float(s["x"]), float(s["y"]))
	var r := radius_at(float(s["y"]) - float(s["from"]))
	var dog_p: Vector2 = main.dog.global_position
	var hum_p: Vector2 = main.human.global_position
	var auto: bool = bool(main.auto_walk)
	var dd := dog_p.distance_to(at)
	var hd := hum_p.distance_to(at)
	if dd < SNOWBALL_DODGE:
		s["dog_near"] = true
	if hd < SNOWBALL_DODGE:
		s["hum_near"] = true
	if auto:
		return false
	var hit := false
	if dd <= r + SNOWBALL_HIT:
		hit = true
		main.dog.knocked((dog_p - at).normalized() if dd > 1.0 else Vector2.DOWN, "snowball")
	if hd <= r + SNOWBALL_HIT:
		hit = true
		main.human.bumped((hum_p - at).normalized() if hd > 1.0 else Vector2.DOWN)
		main.float_text(hum_p, I18n.t("w_brrr"), Color(0.86, 0.94, 1.0))
	if hit:
		s["hit"] = true
		hits += 1
		if "molina_snowball_hits" in main:
			main.molina_snowball_hits += 1
		main.float_text(at, I18n.t("w_splat"), SNOW)
		main.shake_t = maxf(float(main.shake_t), 0.25)
	return hit


func _burst(s: Dictionary) -> void:
	var at := Vector2(float(s["x"]), float(s["y"]))
	var r := radius_at(float(s["y"]) - float(s.get("from", s["y"])))
	puffs.append({"at": at, "r": r, "t": PUFF_TIME})
	if main == null:
		return
	Sfx.play("poof", 1.0, -6.0)
	if bool(s["hit"]) or not (bool(s["dog_near"]) or bool(s["hum_near"])):
		return
	dodges += 1
	if "molina_snowball_dodges" in main:
		main.molina_snowball_dodges += 1
	main.bones += DODGE_BONES
	main.float_text(main.dog.global_position + Vector2(0.0, -30.0), I18n.t("w_dodged") % DODGE_BONES, Color(0.75, 0.9, 1.0))


# The banner while a snowball is packing or rolling toward either of them:
# the one thing to do.
func snowball_warning() -> bool:
	if main == null:
		return false
	var dog_p: Vector2 = main.dog.global_position
	var hum_p: Vector2 = main.human.global_position
	for s: Dictionary in snowballs:
		var x := float(s["x"])
		var y := float(s["y"])
		for p: Vector2 in [dog_p, hum_p]:
			if p.y > y and p.y - y < SNOWBALL_RANGE * 0.7 and absf(p.x - x) < SNOWBALL_R1 + SNOWBALL_HIT + 20.0:
				return true
	return false


func _draw() -> void:
	var b := ShapeBatch.new(self)
	var o := -position
	# the tracks on the piste ahead of the packing snowballs, the lane each
	# will roll down: dashes marching away from the blade
	for s: Dictionary in snowballs:
		if bool(s["rolling"]):
			continue
		var k := clampf(float(s["t"]) / SNOWBALL_WARN, 0.0, 1.0)
		var x := float(s["x"]) + o.x
		var y0 := front_y + 30.0 + o.y
		var reach := SNOWBALL_RANGE * (0.35 + 0.65 * k)
		var step := 34.0
		var shift := fmod(rumble * 120.0, step)
		var d := shift
		while d < reach:
			var fade := 1.0 - d / reach
			b.line(Vector2(x, y0 + d), Vector2(x, y0 + d + 16.0), Color(TRACK_MARK, TRACK_MARK.a * (0.4 + 0.6 * fade) * k), 6.0)
			d += step
	# powder bursts
	for pf: Dictionary in puffs:
		var k := 1.0 - float(pf["t"]) / PUFF_TIME
		var at: Vector2 = Vector2(pf["at"]) + o
		var r := float(pf["r"])
		b.glow(at, r * (1.4 + k * 1.4), Color(SNOW, 0.8 * (1.0 - k)), 0.4)
		for j in range(8):
			var a := float(j) * TAU / 8.0 + 0.4
			b.circle(at + Vector2.from_angle(a) * r * (0.6 + k * 1.6), r * 0.32 * (1.0 - k) + 1.5, Color(SNOW, 1.0 - k))
	paint_groomer(b, Vector2(cx + sway, front_y) - global_position + drive.jolt(), half * CATCH_SPAN, rumble, heading, jam_t > 0.0)
	drive.draw_debris(b, global_position)
	# snowballs: packing on the blade's top, then rolling, growing, a spray
	# of powder off the back
	for s: Dictionary in snowballs:
		var at := Vector2(float(s["x"]), float(s["y"])) + o
		if not bool(s["rolling"]):
			var k := clampf(float(s["t"]) / SNOWBALL_WARN, 0.0, 1.0)
			_ball(b, at + Vector2(0.0, -6.0), SNOWBALL_R0 * (0.4 + 0.6 * k), rumble * 2.0)
			continue
		var gone := float(s["y"]) - float(s["from"])
		var r := radius_at(gone)
		for j in range(3):
			b.circle(at + Vector2(sin(rumble * 9.0 + float(j)) * r * 0.5, -r - 6.0 - float(j) * 9.0), r * 0.35 - float(j) * 1.5, Color(SNOW, 0.5 - float(j) * 0.14))
		_ball(b, at, r, gone / maxf(r, 1.0))
	b.flush()


# a snowball rolling: its shadow, a dark blue rim with lumps on it, the deep
# side down to the right and the lit top, a fir twig and grit rolled into it,
# and the ice catching the light
static func _ball(b: ShapeBatch, at: Vector2, r: float, spin: float) -> void:
	b.circle(at + Vector2(r * 0.25, r * 0.35), r * 1.06, SHADOW)
	for j in range(6):
		var a := spin * 0.6 + float(j) * TAU / 6.0
		b.circle(at + Vector2.from_angle(a) * r * 0.86, r * 0.30 + 2.0, SNOWBALL_RIM)
	b.circle(at, r + 2.0, SNOWBALL_RIM)
	b.circle(at, r, SNOW_DEEP)
	for j in range(6):
		var a := spin * 0.6 + float(j) * TAU / 6.0
		b.circle(at + Vector2.from_angle(a) * r * 0.86, r * 0.30, SNOW_DEEP if cos(a - 0.9) > 0.0 else SNOW_SHADE)
	b.circle(at - Vector2(r * 0.12, r * 0.14), r * 0.84, SNOW_SHADE)
	b.circle(at - Vector2(r * 0.24, r * 0.28), r * 0.60, SNOW)
	var tw := Vector2.from_angle(spin)
	b.line(at + tw * r * 0.1, at + tw * r * 0.7, SNOWBALL_TWIG, maxf(r * 0.10, 1.5))
	b.line(at + tw * r * 0.4, at + tw.rotated(0.6) * r * 0.65, SNOWBALL_TWIG, maxf(r * 0.07, 1.2))
	b.circle(at + Vector2.from_angle(spin + 2.4) * r * 0.5, r * 0.09 + 0.8, SNOWBALL_GRIT)
	b.circle(at - Vector2(r * 0.40, r * 0.44), r * 0.12 + 0.8, Color(1, 1, 1))


# The groomer with its blade's front edge at `c`, `w` either side, seen from
# above going down-screen: tracks either side, the cab between them, the
# blade and its berm of snow in front, the tiller and its corduroy behind.
# The walk's parked machine at the top and the chase's threat are the same
# drawing. `jammed`: wedged, it rocks on its tracks and the lamps flicker.
static func paint_groomer(b: ShapeBatch, c: Vector2, w: float, t: float, heading: float, jammed: bool) -> void:
	var rot := Transform2D(heading, c)
	var tw := w * 0.30              # each track's width
	var body_w := w * 0.62          # the cab's half-width plus the tracks' inner edge
	var rock := sin(t * 30.0) * 2.0 if jammed else 0.0
	# its shadow, cast down-right like everything's
	_quad(b, rot, Vector2(-w * 0.86 + 8.0, -DEPTH + 10.0), Vector2(w * 0.86 + 8.0, 12.0), SHADOW)
	# the corduroy it leaves behind it: fine ridges back up the piste
	for i in range(14):
		var x := -w * 0.84 + float(i) * (w * 1.68 / 13.0)
		b.line(rot * Vector2(x, -DEPTH - 4.0), rot * Vector2(x, -DEPTH - 120.0), Color(SNOW_SHADE, 0.55 * (1.0 - float(i % 2) * 0.4)), 3.0)
	# the tiller: a drum across the back, spinning snow off it
	_quad(b, rot, Vector2(-w * 0.86, -DEPTH - 6.0), Vector2(w * 0.86, -DEPTH + 18.0), TILLER)
	for i in range(9):
		var x := -w * 0.80 + float(i) * (w * 1.60 / 8.0)
		var f := fposmod(t * 3.0 + float(i) * 0.37, 1.0)
		b.circle(rot * Vector2(x, -DEPTH - 8.0 - f * 30.0), 5.0 * (1.0 - f) + 2.0, Color(SNOW, 0.8 * (1.0 - f)))
	# the tracks: rubber belts with their lugs running round
	for sd: float in [-1.0, 1.0]:
		var x0 := sd * body_w - (tw if sd < 0.0 else 0.0)
		_quad(b, rot, Vector2(x0, -DEPTH + 14.0 + rock), Vector2(x0 + tw, -34.0 + rock), TRACK)
		var lug := 18.0
		var off := fposmod(t * (0.0 if jammed else 160.0), lug)
		var y := -DEPTH + 18.0 + off
		while y < -38.0:
			_quad(b, rot, Vector2(x0 + 3.0, y + rock), Vector2(x0 + tw - 3.0, y + 6.0 + rock), TRACK_LUG)
			y += lug
	# the cab: a red body with a white roof, the windscreen to the front
	var cab_w := body_w - 6.0
	_quad(b, rot, Vector2(-cab_w, -DEPTH + 26.0), Vector2(cab_w, -44.0), CAB_DARK)
	_quad(b, rot, Vector2(-cab_w + 3.0, -DEPTH + 28.0), Vector2(cab_w - 3.0, -48.0), CAB)
	_quad(b, rot, Vector2(-cab_w * 0.70, -DEPTH + 40.0), Vector2(cab_w * 0.70, -96.0), ROOF)
	_quad(b, rot, Vector2(-cab_w * 0.70, -DEPTH + 40.0), Vector2(-cab_w * 0.55, -96.0), ROOF.darkened(0.12))
	# the windscreen: dark glass, nobody at the wheel, a glint
	_quad(b, rot, Vector2(-cab_w * 0.66, -92.0), Vector2(cab_w * 0.66, -62.0), GLASS)
	b.line(rot * Vector2(-cab_w * 0.4, -88.0), rot * Vector2(-cab_w * 0.1, -66.0), Color(GLASS_LIT, 0.6), 3.0)
	# the visor over the lamps, a scowl: lower in the middle
	b.quad(rot * Vector2(-cab_w, -60.0), rot * Vector2(0.0, -50.0), rot * Vector2(0.0, -44.0), rot * Vector2(-cab_w, -52.0), CAB_DARK.darkened(0.3))
	b.quad(rot * Vector2(cab_w, -60.0), rot * Vector2(0.0, -50.0), rot * Vector2(0.0, -44.0), rot * Vector2(cab_w, -52.0), CAB_DARK.darkened(0.3))
	# the headlamps, its eyes, under the scowl, and their beams ahead
	var on := not jammed or int(t * 14.0) % 3 != 0
	for sd: float in [-1.0, 1.0]:
		var lp := rot * Vector2(sd * cab_w * 0.55, -38.0)
		if on:
			b.glow(lp + (rot.basis_xform(Vector2(0.0, 70.0))), 64.0, LAMP_GLOW, 0.2)
		b.circle(lp, 10.0, CAB_DARK.darkened(0.4))
		b.circle(lp, 8.0, LAMP if on else LAMP.darkened(0.5))
		b.circle(lp + rot.basis_xform(Vector2(-sd * 2.0, 2.0)), 3.2, Color(0.2, 0.18, 0.12))
	# the beacon on the roof, going round
	var bp := rot * Vector2(0.0, -DEPTH + 70.0)
	var ba := t * 9.0
	b.glow(bp + Vector2.from_angle(ba) * 26.0, 34.0, Color(BEACON, 0.34), 0.2)
	b.circle(bp, 7.0, BEACON.darkened(0.3))
	b.circle(bp + Vector2.from_angle(ba) * 2.5, 4.5, BEACON.lightened(0.3))
	# its exhaust, puffing
	for j in range(3):
		var f := fposmod(t * 1.6 + float(j) * 0.33, 1.0)
		b.circle(rot * Vector2(cab_w * 0.6, -DEPTH + 40.0 - f * 50.0), 5.0 + f * 12.0, Color(EXHAUST, EXHAUST.a * (1.0 - f)))
	# the arms to the blade
	for sd: float in [-1.0, 1.0]:
		b.line(rot * Vector2(sd * cab_w * 0.8, -40.0), rot * Vector2(sd * w * 0.7, -6.0), BLADE_DARK, 7.0)
	# the berm of snow it pushes, heaped in front of the blade and spilling
	for i in range(11):
		var x := -w + float(i) * (w * 2.0 / 10.0)
		var hump := 14.0 + 7.0 * sin(t * 4.0 + float(i) * 1.3)
		b.circle(rot * Vector2(x, 6.0 + hump * 0.5), hump, SNOW_SHADE)
		b.circle(rot * Vector2(x - 3.0, 3.0 + hump * 0.4), hump * 0.8, SNOW)
	# the blade: a curved steel plate across the front, lit along its top,
	# its scraper's teeth along the bottom edge
	b.quad(rot * Vector2(-w, -14.0), rot * Vector2(w, -14.0), rot * Vector2(w * 0.94, 2.0), rot * Vector2(-w * 0.94, 2.0), BLADE)
	b.line(rot * Vector2(-w, -13.0), rot * Vector2(w, -13.0), BLADE_LIT, 3.0)
	b.line(rot * Vector2(-w * 0.94, 2.0), rot * Vector2(w * 0.94, 2.0), BLADE_DARK, 3.0)
	var nt := 12
	for i in range(nt):
		var x := -w * 0.90 + float(i) * (w * 1.80 / float(nt - 1))
		b.polygon(PackedVector2Array([rot * Vector2(x - 6.0, 2.0), rot * Vector2(x + 6.0, 2.0), rot * Vector2(x, 11.0)]), TOOTH)
	# the blade's wings, angled forward at each end
	for sd: float in [-1.0, 1.0]:
		b.quad(rot * Vector2(sd * w, -14.0), rot * Vector2(sd * (w + 16.0), -2.0), rot * Vector2(sd * (w + 14.0), 10.0), rot * Vector2(sd * w * 0.94, 2.0), BLADE_DARK)


static func _quad(b: ShapeBatch, xf: Transform2D, a: Vector2, z: Vector2, col: Color) -> void:
	b.quad(xf * a, xf * Vector2(z.x, a.y), xf * z, xf * Vector2(a.x, z.y), col)
