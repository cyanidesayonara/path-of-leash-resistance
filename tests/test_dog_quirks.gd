extends SceneTree

# Each dog's own idle quirk and bark (entities/dog.gd, autoload/sfx.gd): every
# dog has a quirk and a bark of her own, the barks as loud as each other; a
# quirk starts only once she has stood still a while, and moving or any input
# ends it at once; and a quirk is drawing only, so a walk played with quirks
# and without them puts her in the same place at the same speed every frame.

const FRAMES := 420

# loaded once the autoloads are up: the dog reads Game
var DogScript: GDScript

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _rms(s: AudioStreamWAV) -> float:
	var n := s.data.size() / 2
	var sum := 0.0
	for i in range(n):
		var v := float(s.data.decode_s16(i * 2)) / 32767.0
		sum += v * v
	return sqrt(sum / maxf(1.0, float(n)))


func _load(game: Node, lv: String) -> Node2D:
	game.level_id = lv
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	return m


# her drawing recorded rather than drawn, posed at u through quirk q: the
# canvas calls it would make (everything not joined into one triangle batch)
func _canvas_calls(d: CharacterBody2D, q: String, u: float) -> int:
	d.quirk = q
	d.quirk_u = u
	d._quirk_n = 0
	d._b = ShapeBatch.new(null)
	d._quirk_pose(1.0)
	d._draw_xf()
	d._draw_shapes()
	d._b.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return d._b._ops.size() + (1 if not d._b._points.is_empty() else 0)


# a walk's frames with the dog left standing, quirks on or off: where she was
# and how fast, every physics frame, and how many frames a quirk played
func _walk(game: Node, quirks: bool) -> Dictionary:
	seed(4242)
	var m := await _load(game, "street")
	m.dog.quirks = quirks
	# a second short of her first quirk, so the run sees several of them
	m.dog._still_since = AnimClock.msec() - int((DogScript.QUIRK_FIRST - 1.0) * 1000.0)
	m.dog._still_known = true
	var pos := PackedVector2Array()
	var vel := PackedVector2Array()
	var quirked := 0
	for i in range(FRAMES):
		await physics_frame
		pos.append(m.dog.global_position)
		vel.append(m.dog.velocity)
		if m.dog.quirk != "":
			quirked += 1
		if i % 60 == 0 and quirks:
			# keep her quirking whatever the walk does to her: the stillness
			# clock is the only thing set from outside
			if m.dog.quirk == "" and m.dog._quirk_idle():
				m.dog._still_since = AnimClock.msec() - int(DogScript.QUIRK_FIRST * 1000.0)
				m.dog._still_known = true
	m.queue_free()
	await process_frame
	return {"pos": pos, "vel": vel, "quirked": quirked}


func _run() -> void:
	DogScript = load("res://entities/dog.gd")
	var game: Node = root.get_node("Game")
	var sfx: Node = root.get_node("Sfx")
	game.persist = false

	# her own quirk and bark, each dog
	var quirks := {}
	var barks := {}
	var ref := _rms(sfx.lib["bark"])
	for k: String in game.DOG_KEYS:
		var q: String = game.dog_quirk(k)
		var b: String = game.dog_bark(k)
		_check(q != "" and not quirks.has(q), "%s has a quirk of her own (%s)" % [k, q])
		_check(b != "" and not barks.has(b), "%s has a bark of her own (%s)" % [k, b])
		quirks[q] = k
		barks[b] = k
		_check(sfx.lib.has(b), "%s's bark %s is in the sound library" % [k, b])
		if sfx.lib.has(b):
			var db := linear_to_db(_rms(sfx.lib[b]) / ref)
			_check(absf(db) < 1.0, "%s barks as loud as Millie (%.2f dB)" % [k, db])
	_check(game.dog_bark("millie") == "bark", "Millie keeps the bark she had")
	for q: String in ["sniff", "stretch", "sit", "lie", "tremble"]:
		_check(quirks.has(q), "someone does the %s" % q)
	game.dog = "tito"
	_check(sfx.bark_name() == "bark_tito", "the bark played is the walking dog's")
	game.dog = "millie"

	# when they come: not before she has stood still a while, then now and then
	_check(DogScript.quirk_phase(0.0).x < 0.0, "no quirk the moment she stops")
	_check(DogScript.quirk_phase(DogScript.QUIRK_FIRST - 0.05).x < 0.0, "no quirk before she has stood still a few seconds")
	_check(int(DogScript.quirk_phase(DogScript.QUIRK_FIRST + 0.5).x) == 0, "the first quirk after a few seconds still")
	var starts: Array[float] = []
	var s := 0.0
	var last := -1
	while s < 120.0:
		var ph: Vector2 = DogScript.quirk_phase(s)
		if int(ph.x) >= 0 and int(ph.x) != last:
			last = int(ph.x)
			starts.append(s)
		s += 0.05
	_check(starts.size() >= 8, "a dog left standing two minutes quirks again and again (%d)" % starts.size())
	for i in range(1, starts.size()):
		var gap := starts[i] - starts[i - 1]
		_check(gap >= DogScript.QUIRK_GAP_MIN - 0.1 and gap <= DogScript.QUIRK_GAP_MAX + 0.1,
			"quirks come eight to fifteen seconds apart (%.2f)" % gap)

	# on a walk: stood still she quirks; moving or any input ends it at once
	for k: String in game.DOG_KEYS:
		game.dog = k
		var m := await _load(game, "street")
		await physics_frame
		var d: CharacterBody2D = m.dog
		d.velocity = Vector2.ZERO
		d._tick_quirk()
		_check(d.quirk == "", "%s: no quirk on a walk's first frame" % k)
		d._still_since = AnimClock.msec() - int((DogScript.QUIRK_FIRST + 0.5) * 1000.0)
		d._still_known = true
		d._tick_quirk()
		_check(d.quirk == game.dog_quirk(k), "%s does her %s once stood still (%s)" % [k, game.dog_quirk(k), d.quirk])
		_check(d.quirk_u > 0.0 and d.quirk_u < 1.0, "%s's quirk is under way" % k)
		d.velocity = Vector2(220.0, 0.0)
		d._tick_quirk()
		_check(d.quirk == "", "%s: moving ends it at once" % k)
		d.velocity = Vector2.ZERO
		d._still_since = AnimClock.msec() - int((DogScript.QUIRK_FIRST + 0.5) * 1000.0)
		d._still_known = true
		d._tick_quirk()
		Input.action_press("bark")
		d._tick_quirk()
		_check(d.quirk == "", "%s: any input ends it at once" % k)
		Input.action_release("bark")
		d._tick_quirk()
		_check(d.quirk == "", "%s: and she starts counting from still again" % k)
		m.queue_free()
		await process_frame
	game.dog = "millie"

	# in the wardrobe: the preview dog quirks too
	var pv: CharacterBody2D = CharacterBody2D.new()
	pv.set_script(DogScript)
	pv.preview_mode = true
	root.add_child(pv)
	await process_frame
	pv._still_since = AnimClock.msec() - int((DogScript.QUIRK_FIRST + 0.5) * 1000.0)
	pv._still_known = true
	pv._tick_quirk()
	_check(pv.quirk == "sniff", "the wardrobe's dog quirks too (%s)" % pv.quirk)

	# drawn with the rest of her: no canvas call a quirk adds, every dog, all
	# the way through it
	pv.quirks = false
	for k: String in game.DOG_KEYS:
		game.dog = k
		var rest := _canvas_calls(pv, "", 0.0)
		for u: float in [0.05, 0.2, 0.4, 0.6, 0.7, 0.8, 0.95]:
			var n := _canvas_calls(pv, game.dog_quirk(k), u)
			_check(n == rest, "%s's %s at %.2f draws in %d canvas calls, as at rest (%d)" % [k, game.dog_quirk(k), u, n, rest])
	game.dog = "millie"
	pv.queue_free()
	await process_frame

	# drawing only: the same walk with and without them, frame for frame
	for k: String in ["millie", "mochi", "tito"]:
		game.dog = k
		var off := await _walk(game, false)
		var on := await _walk(game, true)
		_check(int(on.quirked) > 0, "%s quirked during the walk (%d frames)" % [k, int(on.quirked)])
		_check(int(off.quirked) == 0, "%s never quirks with quirks off" % k)
		var same := true
		var first_diff := -1
		for i in range(FRAMES):
			if (off.pos as PackedVector2Array)[i] != (on.pos as PackedVector2Array)[i] \
					or (off.vel as PackedVector2Array)[i] != (on.vel as PackedVector2Array)[i]:
				same = false
				first_diff = i
				break
		_check(same, "%s is where she was and as fast, with quirks and without (first difference at frame %d)" % [k, first_diff])
	game.dog = "millie"

	if failures.is_empty():
		print("PASS: dog quirks (%d checks)" % checks)
		quit(0)
	else:
		print("FAILED: %d of %d checks" % [failures.size(), checks])
		quit(1)
