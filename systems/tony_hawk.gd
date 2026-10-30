extends RefCounted

# Tony Hawk quests:
# 1. Spell a word of at least five letters tied to the place (G-O-O-O-L on match day)
# 2. Hidden secret tape per walk
# 3. Optional beat-the-clock completion under par time (no failure timer; walk has its own clock)

const UiIcons := preload("res://hud/ui_icons.gd")
const AnimClock := preload("res://systems/anim_clock.gd")

const WORDS := {
	"barri": "BARRI",
	"street": "RAMBLA",
	"park": "CIUTAT",
	"beach": "PLATJA",
	"rain": "DILUVI",
	"market": "MERCAT",
	"oldtown": "GOTIC",
	"trail": "BOSCS",
	"station": "ESTACIO",
	"besos": "BESOS",
	"site": "OBRES",
	"spook": "CASTANYA",
	"scrap": "FERRO",
	"guell": "MOSAIC",
	"neteja": "NETEJA",
	"montjuic": "CASTELL",
	"partit": "GOOOL",
	"port": "MARINA",
	"reial": "REIAL",
	"vet": "CLINIC",
	"tibidabo": "TIBIDABO",
	"aigues": "AIGUES",
	"horta": "LABERINT",
	"llevant": "LLEVANT",
}

const CLOCK_TARGETS := {
	"barri": 75,
	"street": 85,
	"park": 75,
	"beach": 85,
	"rain": 80,
	"market": 75,
	"oldtown": 75,
	"trail": 85,
	"station": 75,
	"besos": 80,
	"site": 75,
	"spook": 80,
	"scrap": 80,
	"guell": 85,
	"neteja": 75,
	"montjuic": 90,
	"partit": 80,
	"port": 80,
	"reial": 75,
	"vet": 75,
	"tibidabo": 85,
	"aigues": 85,
	"horta": 85,
	"llevant": 85,
}

const SECRET_TAPES := {
	"barri": Vector2(330.0, -1850.0),
	"street": Vector2(880.0, -1650.0),
	"park": Vector2(400.0, -2200.0),
	"beach": Vector2(980.0, -2250.0),
	"rain": Vector2(430.0, -2100.0),
	"market": Vector2(420.0, -2500.0),
	"oldtown": Vector2(860.0, -2300.0),
	"trail": Vector2(420.0, -2100.0),
	"station": Vector2(400.0, -2300.0),
	"besos": Vector2(700.0, -2200.0),
	"site": Vector2(420.0, -2200.0),
	"spook": Vector2(840.0, -2100.0),
	"scrap": Vector2(430.0, -2500.0),
	"guell": Vector2(870.0, -2400.0),
	"neteja": Vector2(430.0, -2000.0),
	"montjuic": Vector2(840.0, -2600.0),
	"partit": Vector2(430.0, -2000.0),
	"port": Vector2(870.0, -2300.0),
	"reial": Vector2(860.0, -2000.0),
	"vet": Vector2(430.0, -2100.0),
	"tibidabo": Vector2(860.0, -2400.0),
	"aigues": Vector2(860.0, -2200.0),
	"horta": Vector2(430.0, -2400.0),
	"llevant": Vector2(860.0, -2200.0),
}


static func word_for(lvl: String) -> String:
	return String(WORDS.get(lvl, "BARRI"))


static func clock_target_for(lvl: String) -> int:
	return int(CLOCK_TARGETS.get(lvl, 75))


static func secret_tape_pos_for(lvl: String) -> Vector2:
	return Vector2(SECRET_TAPES.get(lvl, Vector2(640.0, -2200.0)))


static func _resolve_clear_pos(m: Node2D, base: Vector2) -> Vector2:
	var pos := base
	var edges: Vector2 = m.walk_edges(pos.y)
	var cx := (edges.x + edges.y) * 0.5
	for attempt in range(8):
		var clear := true
		for r: Rect2 in m.solid_rects:
			if r.grow(16.0).has_point(pos):
				clear = false
				break
		if clear:
			for p: Vector2 in m.poles:
				if pos.distance_to(p) < 22.0:
					clear = false
					break
		if clear:
			return pos
		pos.x = lerpf(pos.x, cx, 0.35)
		pos.y += 20.0
	return pos


static func setup_walk(m: Node2D) -> void:
	if m.tutorial_mode:
		m.spell_word = ""
		m.word_letters.clear()
		m.word_letters_collected = 0
		m.secret_tape_pos = Vector2(INF, INF)
		m.secret_tape_found = false
		m.clock_target = 75
		return

	m.spell_word = word_for(m.lvl)
	m.clock_target = clock_target_for(m.lvl)
	m.secret_tape_found = false
	m.word_letters_collected = 0
	m.word_letters.clear()

	var tape_base := secret_tape_pos_for(m.lvl)
	m.secret_tape_pos = _resolve_clear_pos(m, tape_base)

	var w: String = String(m.spell_word)
	var n: int = w.length()
	var y_start: float = float(m.START_Y) - 450.0
	var y_end: float = float(m.GATE_Y) + 450.0
	var y_span: float = y_end - y_start

	var x_patterns: Array[float] = [0.35, 0.65, 0.45, 0.75, 0.25, 0.55, 0.30, 0.70]

	for i in range(n):
		var frac: float = float(i + 0.5) / float(n)
		var y: float = y_start + y_span * frac
		var edges: Vector2 = m.walk_edges(y)
		var pw: float = maxf(edges.y - edges.x, 80.0)
		var x_frac: float = x_patterns[i % x_patterns.size()]
		var x: float = edges.x + pw * x_frac
		var pos: Vector2 = _resolve_clear_pos(m, Vector2(x, y))
		m.word_letters.append({
			"letter": w.substr(i, 1),
			"index": i,
			"pos": pos,
			"collected": false,
		})


static func tick(m: Node2D, _delta: float) -> void:
	if m.tutorial_mode or m.finished:
		return

	var dog_pos: Vector2 = m.dog.global_position

	# 1. Letter collection
	for i in range(m.word_letters.size()):
		var l: Dictionary = m.word_letters[i]
		if not bool(l.collected) and dog_pos.distance_to(l.pos) < 24.0:
			l.collected = true
			m.word_letters_collected += 1
			m.float_text(l.pos, String(l.letter), Color(1.0, 0.88, 0.2))
			Sfx.play("pickup")
			var progress := ""
			for item: Dictionary in m.word_letters:
				progress += (String(item.letter) if bool(item.collected) else "_") + " "
			progress = progress.strip_edges()
			if m.word_letters_collected >= m.word_letters.size():
				m.feed.say("SPELLED %s!" % m.spell_word)
				Sfx.play("dare_won")
			else:
				m.feed.say("%s: %s" % [m.spell_word, progress])
			m._check_goals()
			m._peek_goals()

	# 2. Secret tape collection
	if not m.secret_tape_found and m.secret_tape_pos.x < INF:
		if dog_pos.distance_to(m.secret_tape_pos) < 26.0:
			m.secret_tape_found = true
			m.float_text(m.secret_tape_pos, "secret tape! +5", Color(1.0, 0.85, 0.3))
			m.feed.toast("goal", "SECRET TAPE FOUND!  +5", "You found the hidden cassette tape", Color(1.0, 0.85, 0.3))
			Sfx.play("star")
			m.bones += 5
			m._check_goals()
			m._peek_goals()


static func draw_world(m: Node2D, wc: Object, font: Font, vt: float, vb: float) -> void:
	if m.tutorial_mode:
		return

	# Draw uncollected letters
	for l: Dictionary in m.word_letters:
		if bool(l.collected):
			continue
		var lpos: Vector2 = l.pos
		if lpos.y < vt - 40.0 or lpos.y > vb + 40.0:
			continue
		var bob: float = sin(AnimClock.msec() * 0.005 + float(l.index) * 1.5) * 4.0
		var p := lpos + Vector2(0.0, bob)
		m.contact_shadow(wc, lpos, 10.0, 4.0, 0.22)
		wc.draw_circle(p, 12.0, Color(0.85, 0.68, 0.15))
		wc.draw_circle(p, 10.5, Color(1.0, 0.88, 0.28))
		wc.draw_circle(p + Vector2(-2.5, -2.5), 3.0, Color(1.0, 0.98, 0.65))
		wc.draw_string(font, p + Vector2(-20.0, 5.0), String(l.letter), HORIZONTAL_ALIGNMENT_CENTER, 40, 15, Color(0.24, 0.16, 0.05))

	# Draw secret tape
	if not m.secret_tape_found and m.secret_tape_pos.x < INF:
		var tp: Vector2 = m.secret_tape_pos
		if tp.y >= vt - 40.0 and tp.y <= vb + 40.0:
			var bob_tape: float = sin(AnimClock.msec() * 0.004) * 3.5
			var cp := tp + Vector2(0.0, bob_tape)
			m.contact_shadow(wc, tp, 14.0, 5.0, 0.25)
			var glow: float = 0.5 + 0.5 * sin(AnimClock.msec() * 0.006)
			wc.draw_arc(cp, 17.0 + glow * 3.0, 0.0, TAU, 16, Color(1.0, 0.85, 0.3, 0.3 + glow * 0.3), 1.5)
			# Cassette body
			wc.draw_rect(Rect2(cp.x - 12.0, cp.y - 7.5, 24.0, 15.0), Color(0.18, 0.18, 0.22))
			# Cream label
			wc.draw_rect(Rect2(cp.x - 9.0, cp.y - 6.0, 18.0, 6.0), Color(0.92, 0.90, 0.82))
			wc.draw_line(cp + Vector2(-8.0, -1.5), cp + Vector2(8.0, -1.5), Color(0.85, 0.25, 0.2), 1.0)
			# Tape spools window
			wc.draw_rect(Rect2(cp.x - 7.0, cp.y + 1.0, 14.0, 5.0), Color(0.08, 0.08, 0.10))
			wc.draw_circle(cp + Vector2(-3.5, 3.5), 1.5, Color(0.95, 0.95, 0.95))
			wc.draw_circle(cp + Vector2(3.5, 3.5), 1.5, Color(0.95, 0.95, 0.95))
