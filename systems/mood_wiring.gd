extends RefCounted

# How the walk feeds the dog's moods, and how her mood reaches the handling and
# the picture. mood.gd is the mood itself (pure logic, tested headless); this is
# the wiring between it and the world: which events and conditions bump or
# soothe which mood, and where the result goes (dog handling, colour grade,
# event feed).
#
# Static functions over main's state, called from main.gd's _tick_mood. All the
# state stays on main, so nothing here changes what the walk does.

const Mood := preload("res://mood.gd")
const EventFeed := preload("res://event_feed.gd")


static func tick(m: Node2D, delta: float) -> void:
	# A mood belongs to the walk. The menu has nothing to react to, and the
	# tutorial teaches one thing at a time - a re-graded screen mid-lesson
	# would read as a fault rather than a feeling.
	if not m.started or m.tutorial_mode:
		m.dog.mood_speed = 1.0
		m.dog.mood_accel = 1.0
		m.dog.mood_wobble = 0.0
		return
	_ambient(m, delta)
	m.mood.tick(delta)
	if m._soak_t0 >= 0.0 and m.mood.active != m._soak_last_mood:
		m._soak_last_mood = m.mood.active
		if m.mood.active != Mood.M.HAPPY:
			var mname: String = Mood.M.keys()[m.mood.active]
			m._soak_moods[mname] = int(m._soak_moods.get(mname, 0)) + 1
			print("SOAK mood t=%.2f %s" % [m.elapsed - m._soak_t0, mname])
	# the handling first, the picture second - a mood should reach your hands
	# before it reaches your eyes
	m.dog.mood_speed = m.mood.speed_mult()
	m.dog.mood_accel = m.mood.accel_mult()
	m.dog.mood_wobble = m.mood.wobble()
	if m.grade_rect != null:
		var gm: ShaderMaterial = m.grade_rect.material
		var g: Dictionary = m.mood.grade()
		gm.set_shader_parameter("saturation", g["sat"])
		gm.set_shader_parameter("contrast", g["con"])
		gm.set_shader_parameter("vignette", g["vig"])
		gm.set_shader_parameter("vignette_tight", g["tight"])
		gm.set_shader_parameter("exposure", g["exp"])
		gm.set_shader_parameter("tint", g["tint"])
		gm.set_shader_parameter("lift", g["lift"])
		gm.set_shader_parameter("cool_shadows", g["cool"])
		gm.set_shader_parameter("warm_light", g["warm"])
	var line: String = m.mood.take_onset()
	if line != "":
		# an announcement about her, not about a place: it goes in the feed
		m.feed.say(line, EventFeed.Tone.LOUD)


static func _ambient(m: Node2D, delta: float) -> void:
	# The two moods a walk GROWS into, as opposed to the ones it gets startled
	# into. Both are fed a little every frame the condition holds rather than
	# landed in one go, so they arrive at the pace the walk does.
	# --mood=scared|barky|zoomies|tired pins one on, so a look can be
	# photographed and tuned without having to provoke it in play. Barky in
	# particular needs a cat and a chase to arrive honestly.
	if m.mood_forced >= 0:
		m.mood.bump(m.mood_forced, delta * 3.0)
	var spd: float = m.dog.velocity.length()
	# Running yourself empty makes the legs go heavy - but as a one-off
	# reaction to the moment you run out, not a tax on being tired. Fed every
	# frame the tank was low it pinned TIRED on for the whole home leg, and
	# since TIRED is slow AND gives the human an easier tow, a walk could get
	# genuinely stuck in it. An edge trigger with hysteresis: it fires when you
	# hit empty, and cannot fire again until you have got your breath back.
	if m.dog.energy < 0.16 and not m.mood_worn:
		m.mood_worn = true
		m.mood.bump(Mood.M.TIRED, 0.70)
	elif m.dog.energy > 0.35:
		m.mood_worn = false
	# a rested dog let off the leash is a dog with the zoomies
	if m.phase == "freedom" and m.dog.energy > 0.80 and spd > 250.0:
		m.mood.bump(Mood.M.ZOOMIES, delta * 0.65)
	# Acting into a mood feeds it, and this is the whole of the player's
	# influence over their own moods: keep running and the zoomies keep going.
	# Only moods that reward DOING something get this. Feeding TIRED for being
	# slow was the same idea run backwards and it made a trap - standing still
	# is also what being stuck looks like, so it deepened the one mood you
	# most need to be able to come out of.
	if m.mood.active == Mood.M.ZOOMIES and spd > 240.0:
		m.mood.bump(Mood.M.ZOOMIES, delta * 0.30)
	# ...and the other half of the model: the things that genuinely ANSWER a
	# mood shorten it. Being tired is the mood a dog can actually do something
	# about, and all three answers are real ones rather than a button - stop
	# and get your breath back, get out of the sun, or find something to eat
	# (the eating is handled where the kebab is, since that is a moment).
	if m.mood.active == Mood.M.TIRED:
		if spd < 50.0:
			m.mood.soothe(Mood.M.TIRED, delta * 0.30)
		if in_shade(m, m.dog.global_position):
			# shade is worth more when there is actually a sun to get out of
			m.mood.soothe(Mood.M.TIRED, delta * (0.34 if sunny() else 0.12))
	# Something eating the pavement behind you is not a thing you get used to -
	# and it gets worse the closer it is. A flat rate made the far end of a
	# chase feel exactly like the near end, which wasted the one moment the
	# whole sequence is built around. Squared, so dread is a slow background
	# hum at a corridor's distance and climbs hard over the last stretch.
	# Suppressed under --shot-sweeper only, so the machine's paint can be
	# reviewed in daylight rather than through a frightened dog's eyes.
	if m.chase_active and not "--shot-sweeper" in OS.get_cmdline_user_args():
		var near := 0.0
		if m.chase_sweeper != null:
			near = clampf(1.0 - m.chase_sweeper.gap_to(m.dog.global_position) / 900.0, 0.0, 1.0)
		m.mood.bump(Mood.M.SCARED, delta * (0.16 + 0.90 * near * near))


static func sunny() -> bool:
	return Game.weather == "clear" and not Game.night


static func in_shade(m: Node2D, p: Vector2) -> bool:
	# Shade is where the SHADOW is, not where the tree is. Everything in this
	# game throws its shadow along one light (LIGHT), so the cool patch under a
	# plane tree sits clear of the trunk on the far side - standing on the tree
	# does nothing, standing in its shadow is the thing. Costs nothing to agree
	# with the picture, and it is the kind of detail a dog owner would notice.
	var light: Vector2 = m.LIGHT
	for t: Vector2 in m.trees:
		var d := p - (t + light * 46.0)
		# the same squashed ellipse _draw_broadleaf lays its crown shadow on
		if (d.x * d.x) / 1450.0 + (d.y * d.y) / 365.0 <= 1.0:
			return true
	for u: Vector2 in m.parasols:
		var q := p - (u + light * 30.0)
		if (q.x * q.x) / 900.0 + (q.y * q.y) / 230.0 <= 1.0:
			return true
	# the terrace awnings are proper roofs: under one is simply under it
	for cn: Rect2 in m.canopies:
		if cn.has_point(p):
			return true
	return false
