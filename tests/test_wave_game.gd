extends SceneTree

# The dog beach's wave game (systems/wave_game.gd), its rules alone: staying
# up the beach earns nothing and stays dry; daring out as the wave drains and
# running back before the next one pays, more the further out; staying out
# when it comes soaks her and ends the streak; dry escapes in a row add up;
# every surge is telegraphed by a crest building first; six waves and done.

var checks := 0
var failures: Array[String] = []
const WaveGameScript := preload("res://systems/wave_game.gd")
const DT := 1.0 / 60.0


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


# run one whole wave cycle with her position chosen per phase by `where`
func _cycle(wg, where: Callable) -> Array:
	var ev: Array = []
	var w0: int = wg.wave
	var n := 0
	while wg.wave == w0 and not wg.done and n < 60 * 20:
		ev.append_array(wg.step(where.call(wg), DT))
		n += 1
	# and on through its drain into the next lull
	while wg.phase == wg.P.DRAIN and not wg.done and n < 60 * 30:
		ev.append_array(wg.step(where.call(wg), DT))
		n += 1
	return ev


func _count(ev: Array, kind: String) -> int:
	var n := 0
	for e: Array in ev:
		if String(e[0]) == kind:
			n += 1
	return n


func _first(ev: Array, kind: String) -> Array:
	for e: Array in ev:
		if String(e[0]) == kind:
			return e
	return []


func _initialize() -> void:
	# up the beach the whole time: nothing, and dry
	var wg = WaveGameScript.new()
	var ev := _cycle(wg, func(_w) -> float: return 300.0)
	_check(_count(ev, "outran") == 0 and _count(ev, "soaked") == 0, "staying up the beach earns nothing and stays dry")
	# every surge comes after a crest has built (the telegraph)
	var wt = WaveGameScript.new()
	var last: int = wt.phase
	var told := true
	var built := 0.0
	for i in range(60 * 30):
		wt.step(300.0, DT)
		built = maxf(built, wt.crest())
		if wt.phase != last:
			if wt.phase == wt.P.SURGE:
				told = told and last == wt.P.BUILD and built > 0.9
				built = 0.0
			last = wt.phase
	_check(told, "every surge is telegraphed by a crest built out at sea")
	# out as it drains, back up before it comes: paid
	var wd = WaveGameScript.new()
	var dare := func(w) -> float:
		return 5.0 if w.phase == w.P.LULL else 300.0
	var ev2 := _cycle(wd, dare)
	var out2 := _first(ev2, "outran")
	_check(not out2.is_empty() and _count(ev2, "soaked") == 0, "daring out and running back pays and stays dry")
	# further out pays more
	_check(WaveGameScript.pay_for(-60.0, 1) > WaveGameScript.pay_for(30.0, 1), "further out pays more")
	# a second dry escape in a row adds to it
	var ev3 := _cycle(wd, dare)
	var out3 := _first(ev3, "outran")
	_check(not out3.is_empty() and int(out3[2]) == 2 and int(out3[1]) > int(out2[1]), "dry escapes in a row add up (%s, %s)" % [out2, out3])
	# staying out when it comes: soaked, no pay, the streak gone
	var ev4 := _cycle(wd, func(_w) -> float: return 5.0)
	_check(_count(ev4, "soaked") == 1 and _count(ev4, "outran") == 0 and wd.streak == 0, "staying out when it comes soaks her and ends the streak")
	# six waves and done
	var wf = WaveGameScript.new()
	var n := 0
	while not wf.done and n < 60 * 120:
		wf.step(300.0, DT)
		n += 1
	_check(wf.done and wf.wave == wf.WAVES, "six waves and the game is over")
	print("%d checks, %d failures" % [checks, failures.size()])
	print("test_wave_game: " + ("OK" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)
