extends SceneTree

# Moods (mood.gd) are "weather": they arrive from events and fade on their own,
# and there is deliberately no button to cancel one. That design choice is only
# safe if the fading is guaranteed, so most of this file is about the promise
# rather than the feature:
#
#   - a mood never starts by itself, only from something that happened
#   - one small event is not a mood; it takes real provocation
#   - EVERY mood ends on its own, within its own advertised fade
#   - when it ends, the picture lands back exactly on the authored grade, not
#     approximately near it
#   - no effect is ever bigger than the table says, so a mood cannot quietly
#     grow into something that plays the game for you
#
# Also checks the steering wobble is reproducible. It has to be: the CI leans
# on --autowalk being deterministic, so the zoomies veer on layered sines
# rather than on a random number.
#
#   godot --headless --path . --script res://tests/test_mood.gd

const Mood := preload("res://mood.gd")
const DT := 1.0 / 60.0
const EPS := 0.0001

var failures: Array[String] = []
var checks := 0


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures.append(msg)
		print("  FAIL  %s" % msg)


func _initialize() -> void:
	call_deferred("_run")


func _fresh() -> Node:
	var m: Node = Mood.new()
	m.reset()
	return m


func _run() -> void:
	_test_starts_neutral()
	_test_needs_provocation()
	_test_every_mood_ends()
	_test_grade_returns_home()
	_test_strongest_wins()
	_test_effects_bounded()
	_test_wobble()
	_test_soothing()
	_test_voice()

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("MOOD OK")
		quit(0)
	else:
		print("MOOD FAIL")
		quit(1)


func _test_starts_neutral() -> void:
	print("\n--- a walk starts in no mood at all ---")
	var m := _fresh()
	_check(m.active == Mood.M.HAPPY, "starts HAPPY")
	_check(is_equal_approx(m.intensity, 0.0), "starts at zero intensity")
	# and stays there: a mood must never appear out of nowhere
	for i in range(60 * 30):
		m.tick(DT)
	_check(m.active == Mood.M.HAPPY, "thirty quiet seconds produce no mood on their own")
	_check(is_equal_approx(m.speed_mult(), 1.0), "no mood, no speed change")
	_check(is_equal_approx(m.accel_mult(), 1.0), "no mood, no accel change")
	_check(is_equal_approx(m.scent_mult(), 1.0), "no mood, no scent change")
	_check(is_equal_approx(m.pull_mult(), 1.0), "no mood, no pull change")
	_check(is_equal_approx(m.wobble(), 0.0), "no mood, no wobble")
	m.free()


func _test_needs_provocation() -> void:
	print("\n--- one startled pigeon is not a mood ---")
	var m := _fresh()
	# a single nudge below the onset threshold must not re-grade the screen
	m.bump(Mood.M.BARKY, Mood.ONSET * 0.5)
	m.tick(DT)
	_check(m.active == Mood.M.HAPPY, "a nudge under the threshold stays HAPPY")
	_check(is_equal_approx(m.speed_mult(), 1.0), "...and changes nothing")
	# but provocation that keeps coming does land
	m.bump(Mood.M.BARKY, 0.5)
	m.tick(DT)
	_check(m.active == Mood.M.BARKY, "enough provocation lands the mood")
	# intensity is rescaled across the part of the charge that counts, so a
	# mood that has only just landed is a WEAK mood, not a third of one
	m.reset()
	m.bump(Mood.M.BARKY, Mood.ONSET + 0.01)
	m.tick(DT)
	_check(m.intensity < 0.1, "a mood that just landed is weak (%.3f)" % m.intensity)
	m.reset()
	m.bump(Mood.M.BARKY, 1.0)
	m.tick(DT)
	_check(m.intensity > 0.95, "a mood provoked in full is strong (%.3f)" % m.intensity)
	m.free()


func _test_every_mood_ends() -> void:
	print("\n--- every mood ends on its own (there is no cancel button) ---")
	for mk: int in [Mood.M.SCARED, Mood.M.BARKY, Mood.M.ZOOMIES, Mood.M.TIRED]:
		var m := _fresh()
		m.bump(mk, 1.0)
		m.tick(DT)
		_check(m.active == mk, "%s lands when provoked in full" % m.badge())
		var fade: float = float(Mood.FADE[mk])
		var name: String = m.badge()
		var elapsed := 0.0
		# generous ceiling: if it has not ended in twice its own fade, the
		# promise this design rests on is broken
		while m.active != Mood.M.HAPPY and elapsed < fade * 2.0:
			m.tick(DT)
			elapsed += DT
		_check(m.active == Mood.M.HAPPY,
			"%s ends by itself (took %.1fs, fade %.1fs)" % [name, elapsed, fade])
		# FADE is meant to be readable as "how long this mood lasts", so hold
		# it to that in both directions rather than just as a ceiling
		_check(absf(elapsed - fade) < 0.2,
			"%s lasts the fade it advertises (%.2fs vs %.1fs)" % [name, elapsed, fade])
		m.free()


func _test_grade_returns_home() -> void:
	print("\n--- the picture lands back exactly where it started ---")
	var m := _fresh()
	var home: Dictionary = Mood.GRADE[Mood.M.HAPPY]
	m.bump(Mood.M.SCARED, 1.0)
	for i in range(60 * 2):
		m.tick(DT)
	# mid-mood the grade must actually have moved, or none of this is doing
	# anything at all
	_check(m.active == Mood.M.SCARED, "still mid-mood two seconds in")
	_check(absf(float(m.grade()["sat"]) - float(home["sat"])) > 0.05,
		"the grade really moves while a mood is on (sat %.3f vs %.3f)" % [
			float(m.grade()["sat"]), float(home["sat"])])
	# ...and then come all the way back
	for i in range(60 * 40):
		m.tick(DT)
	_check(m.active == Mood.M.HAPPY, "mood is over")
	for key: String in home:
		var now: Variant = m.grade()[key]
		var want: Variant = home[key]
		if want is Vector3:
			_check((now as Vector3).distance_to(want as Vector3) < 0.002,
				"grade.%s returns home (%s vs %s)" % [key, now, want])
		else:
			_check(absf(float(now) - float(want)) < 0.002,
				"grade.%s returns home (%.4f vs %.4f)" % [key, float(now), float(want)])
	m.free()


func _test_strongest_wins() -> void:
	print("\n--- a real fright interrupts anything ---")
	var m := _fresh()
	m.bump(Mood.M.ZOOMIES, 0.6)
	m.tick(DT)
	_check(m.active == Mood.M.ZOOMIES, "zoomies running")
	# a bigger fright mid-zoomies takes over, because charges compete on merit
	# rather than on whichever fired most recently
	m.bump(Mood.M.SCARED, 0.9)
	m.tick(DT)
	_check(m.active == Mood.M.SCARED, "a bigger fright takes over")
	# and a smaller one does not
	m.reset()
	m.bump(Mood.M.ZOOMIES, 0.9)
	m.tick(DT)
	m.bump(Mood.M.BARKY, 0.45)
	m.tick(DT)
	_check(m.active == Mood.M.ZOOMIES, "a smaller provocation does not interrupt")
	m.free()


func _test_effects_bounded() -> void:
	print("\n--- no mood ever plays the game for you ---")
	# the table itself is the contract: nothing in it may exceed these, so a
	# later tuning pass cannot quietly turn a mood into an autopilot
	for mk: int in Mood.EFFECT:
		var e: Dictionary = Mood.EFFECT[mk]
		_check(float(e["speed"]) >= 0.75 and float(e["speed"]) <= 1.25,
			"speed effect stays within a quarter (%s -> %.2f)" % [Mood.BADGE[mk], float(e["speed"])])
		_check(float(e["accel"]) >= 0.5 and float(e["accel"]) <= 1.5,
			"accel effect stays reasonable (%s -> %.2f)" % [Mood.BADGE[mk], float(e["accel"])])
		# the nose may be dulled but never switched off: a mood makes the walk
		# harder to read, never impossible to finish
		_check(float(e["scent"]) >= 0.3,
			"scent is never fully blinded (%s -> %.2f)" % [Mood.BADGE[mk], float(e["scent"])])
		_check(float(e["pull"]) >= 0.7 and float(e["pull"]) <= 1.35,
			"pull effect stays within reason (%s -> %.2f)" % [Mood.BADGE[mk], float(e["pull"])])
	# THE FRAME YOU PLAY IN. SCARED and BARKY are meant to genuinely shorten
	# how far you can see, so a flat cap on the vignette is the wrong test -
	# what matters is that closing the world in never reaches the middle, where
	# the dog and the leash are. This is the shader's own arithmetic:
	#
	#   brightness = exposure * (1 - vig * dot(d, d) * tight),  d = uv - 0.5
	#
	# checked at 20% of the screen out from the centre, which comfortably holds
	# the dog, the human and the rope between them.
	var d2 := 0.2 * 0.2
	for mk: int in Mood.GRADE:
		var g: Dictionary = Mood.GRADE[mk]
		var centre_lit: float = float(g["exp"]) * (1.0 - float(g["vig"]) * d2 * float(g["tight"]))
		# Half brightness is the floor, and it is a legibility floor rather
		# than a taste one: fright is SUPPOSED to make the street dark, so the
		# test may not be tuned tighter than the design just to stay green.
		# SCARED sits at 0.54 by intent and was eyeballed at that value.
		_check(centre_lit >= 0.50,
			"%s keeps the middle of the screen playable (%.2f of full)" % [
				String(Mood.BADGE.get(mk, "HAPPY")), centre_lit])
		# and the corners may go dark but the maths must not go negative and
		# start brightening again
		var corner: float = 1.0 - float(g["vig"]) * 0.5 * float(g["tight"])
		_check(corner <= 1.0, "%s never brightens the corners" % String(Mood.BADGE.get(mk, "HAPPY")))
	# fright really must be dark and narrow, or the mood is not doing its job
	var scared: Dictionary = Mood.GRADE[Mood.M.SCARED]
	_check(float(scared["exp"]) < 0.8, "SCARED genuinely darkens the street")
	_check(float(scared["vig"]) * float(scared["tight"])
		> float((Mood.GRADE[Mood.M.HAPPY] as Dictionary)["vig"]) * 3.0,
		"SCARED genuinely shortens how far you can see")
	# and barky really must be red
	var barky_tint: Vector3 = (Mood.GRADE[Mood.M.BARKY] as Dictionary)["tint"]
	_check(barky_tint.x > barky_tint.y * 1.3 and barky_tint.x > barky_tint.z * 1.3,
		"BARKY sees red (%s)" % barky_tint)
	# and the multipliers actually interpolate rather than snapping on
	var m := _fresh()
	m.bump(Mood.M.TIRED, 1.0)
	m.tick(DT)
	var full: float = m.speed_mult()
	_check(absf(full - float((Mood.EFFECT[Mood.M.TIRED] as Dictionary)["speed"])) < 0.02,
		"a full mood applies its full effect (%.3f)" % full)
	m.free()


func _test_wobble() -> void:
	print("\n--- the zoomies veer, reproducibly ---")
	var a := _fresh()
	var b := _fresh()
	a.bump(Mood.M.ZOOMIES, 1.0)
	b.bump(Mood.M.ZOOMIES, 1.0)
	var maxw := 0.0
	var same := true
	for i in range(60 * 5):
		a.tick(DT)
		b.tick(DT)
		if absf(a.wobble() - b.wobble()) > EPS:
			same = false
		maxw = maxf(maxw, absf(a.wobble()))
	_check(same, "two identical runs wobble identically (no RNG in the path)")
	_check(maxw > 0.05, "the wobble is actually doing something (%.3f rad)" % maxw)
	_check(maxw <= deg_to_rad(Mood.WOBBLE_DEG) + EPS,
		"the wobble stays inside its cap (%.3f rad <= %.3f)" % [maxw, deg_to_rad(Mood.WOBBLE_DEG)])
	# no other mood steers for you
	var c := _fresh()
	c.bump(Mood.M.SCARED, 1.0)
	for i in range(60):
		c.tick(DT)
	_check(is_equal_approx(c.wobble(), 0.0), "only the zoomies veer")
	a.free()
	b.free()
	c.free()


func _test_soothing() -> void:
	print("\n--- being tired is answered by things a dog would actually do ---")
	# soothing has to genuinely shorten a mood, or resting in the shade is just
	# a nice idea that does nothing
	var slow := _fresh()
	var helped := _fresh()
	slow.bump(Mood.M.TIRED, 1.0)
	helped.bump(Mood.M.TIRED, 1.0)
	# one tick to actually land the mood - active only moves inside tick()
	slow.tick(DT)
	helped.tick(DT)
	_check(slow.active == Mood.M.TIRED and helped.active == Mood.M.TIRED,
		"both runs start out tired")
	var t_slow := 0.0
	var t_helped := 0.0
	while slow.active != Mood.M.HAPPY and t_slow < 40.0:
		slow.tick(DT)
		t_slow += DT
	while helped.active != Mood.M.HAPPY and t_helped < 40.0:
		# a breather plus shade, the way main.gd feeds it
		helped.soothe(Mood.M.TIRED, DT * 0.30)
		helped.soothe(Mood.M.TIRED, DT * 0.34)
		helped.tick(DT)
		t_helped += DT
	_check(t_helped < t_slow * 0.75,
		"resting in the shade really shortens it (%.1fs vs %.1fs)" % [t_helped, t_slow])
	slow.free()
	helped.free()

	# a kebab is most of the way out of it in one go
	var fed := _fresh()
	fed.bump(Mood.M.TIRED, 1.0)
	fed.tick(DT)
	var before: float = fed.intensity
	fed.soothe(Mood.M.TIRED, 0.55)
	fed.tick(DT)
	_check(fed.intensity < before - 0.4, "eating takes most of it away in one go")

	# but soothing is not a cancel button, and it cannot go below nothing or
	# leave a mood owing charge that would suppress the next one
	fed.soothe(Mood.M.TIRED, 99.0)
	fed.tick(DT)
	_check(fed.active == Mood.M.HAPPY, "soothed all the way out")
	_check(float(fed.charge[Mood.M.TIRED]) >= 0.0, "charge never goes negative")
	fed.bump(Mood.M.TIRED, 1.0)
	fed.tick(DT)
	_check(fed.intensity > 0.95, "and the next tiring thing still lands in full")
	fed.free()

	# soothing one mood must not touch another - they are separate weathers
	var mixed := _fresh()
	mixed.bump(Mood.M.SCARED, 0.9)
	mixed.bump(Mood.M.TIRED, 0.8)
	mixed.soothe(Mood.M.TIRED, 0.8)
	mixed.tick(DT)
	_check(mixed.active == Mood.M.SCARED, "soothing tiredness leaves a fright alone")
	_check(float(mixed.charge[Mood.M.SCARED]) > 0.8, "...at full strength")
	mixed.free()


func _test_voice() -> void:
	print("\n--- the dog says it once ---")
	var m := _fresh()
	_check(m.badge() == "", "HAPPY wears no badge")
	m.bump(Mood.M.TIRED, 1.0)
	m.tick(DT)
	var first: String = m.take_onset()
	_check(first != "", "a mood arriving says its line: %s" % first)
	_check(m.take_onset() == "", "...and does not repeat it every frame")
	_check(m.badge() == "TIRED", "the badge names the mood")
	# every mood has both, or the HUD shows a blank
	for mk: int in [Mood.M.SCARED, Mood.M.BARKY, Mood.M.ZOOMIES, Mood.M.TIRED]:
		_check(String(Mood.SAID.get(mk, "")) != "", "mood %d has a line" % mk)
		_check(String(Mood.BADGE.get(mk, "")) != "", "mood %d has a badge" % mk)
		_check(Mood.FADE.has(mk) and Mood.EFFECT.has(mk) and Mood.GRADE.has(mk),
			"mood %d is fully described" % mk)
	m.free()
