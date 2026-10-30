extends RefCounted

# Tony Hawk quests:
# 1. Spell L-E-A-S-H on every walk (S-K-A-T-E homage)
# 2. Hidden secret jamón leg per walk (replaces secret tape with Catalan/dog holy grail)
# 3. Optional beat-the-clock completion under par time (no failure timer; walk has its own clock)

const UiIcons := preload("res://hud/ui_icons.gd")
const AnimClock := preload("res://systems/anim_clock.gd")

const WORD := "LEASH"

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

const JAMON_POS := {
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


static func word_for(_lvl: String) -> String:
	return WORD


static func clock_target_for(lvl: String) -> int:
	return int(CLOCK_TARGETS.get(lvl, 75))


static func jamon_pos_for(lvl: String) -> Vector2:
	return Vector2(JAMON_POS.get(lvl, Vector2(640.0, -2200.0)))


static func _resolve_clear_pos(m: Node2D, base: Vector2) -> Vector2:
	var pos: Vector2 = base
	var edges: Vector2 = m.walk_edges(pos.y)
	var cx: float = (edges.x + edges.y) * 0.5
	for attempt in range(8):
		var clear: bool = true
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
		m.jamon_pos = Vector2(INF, INF)
		m.jamon_found = false
		m.clock_target = 75
		return

	m.spell_word = WORD
	m.clock_target = clock_target_for(m.lvl)
	m.jamon_found = false
	m.word_letters_collected = 0
	m.word_letters.clear()

	var jamon_base: Vector2 = jamon_pos_for(m.lvl)
	m.jamon_pos = _resolve_clear_pos(m, jamon_base)

	var w: String = WORD
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

	# 1. Letter collection (L-E-A-S-H)
	for i in range(m.word_letters.size()):
		var l: Dictionary = m.word_letters[i]
		if not bool(l.collected) and dog_pos.distance_to(l.pos) < 24.0:
			l.collected = true
			m.word_letters_collected += 1
			m.float_text(l.pos, String(l.letter), Color(1.0, 0.88, 0.2))
			Sfx.play("pickup")
			var progress: String = ""
			for item: Dictionary in m.word_letters:
				progress += (String(item.letter) if bool(item.collected) else "_") + " "
			progress = progress.strip_edges()
			if m.word_letters_collected >= m.word_letters.size():
				m.feed.say("SPELLED LEASH!")
				Sfx.play("dare_won")
			else:
				m.feed.say("LEASH: %s" % progress)
			m._check_goals()
			m._peek_goals()

	# 2. Secret jamón collection
	if not m.jamon_found and m.jamon_pos.x < INF:
		if dog_pos.distance_to(m.jamon_pos) < 26.0:
			m.jamon_found = true
			m.float_text(m.jamon_pos, "jamón! +5", Color(1.0, 0.78, 0.28))
			m.feed.toast("goal", "HIDDEN JAMÓN FOUND!  +5", "You found the hidden jamón leg", Color(1.0, 0.78, 0.28))
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
		var p: Vector2 = lpos + Vector2(0.0, bob)
		m.contact_shadow(wc, lpos, 10.0, 4.0, 0.22)
		wc.draw_circle(p, 12.0, Color(0.85, 0.68, 0.15))
		wc.draw_circle(p, 10.5, Color(1.0, 0.88, 0.28))
		wc.draw_circle(p + Vector2(-2.5, -2.5), 3.0, Color(1.0, 0.98, 0.65))
		wc.draw_string(font, p + Vector2(-20.0, 5.0), String(l.letter), HORIZONTAL_ALIGNMENT_CENTER, 40, 15, Color(0.24, 0.16, 0.05))

	# Draw secret jamón leg
	if not m.jamon_found and m.jamon_pos.x < INF:
		var jp: Vector2 = m.jamon_pos
		if jp.y >= vt - 40.0 and jp.y <= vb + 40.0:
			var bob_jamon: float = sin(AnimClock.msec() * 0.004) * 3.5
			var cp: Vector2 = jp + Vector2(0.0, bob_jamon)
			m.contact_shadow(wc, jp, 15.0, 6.0, 0.26)
			var glow: float = 0.5 + 0.5 * sin(AnimClock.msec() * 0.006)
			wc.draw_arc(cp, 18.0 + glow * 3.0, 0.0, TAU, 16, Color(1.0, 0.78, 0.25, 0.25 + glow * 0.28), 1.5)

			# Jamón leg: shank tilted at ~30 degrees (hoof up-left, ham bulb down-right)
			var angle: float = -0.52
			var u: Vector2 = Vector2.from_angle(angle)
			var v: Vector2 = Vector2(-u.y, u.x)

			# Bone shank extending to the hoof
			var shank_start: Vector2 = cp - u * 2.0
			var shank_end: Vector2 = cp - u * 13.0
			wc.draw_line(shank_start, shank_end, Color(0.92, 0.90, 0.82), 3.5)

			# Black trotter (pezuña negra)
			var hoof_pos: Vector2 = shank_end - u * 2.0
			wc.draw_circle(hoof_pos, 2.5, Color(0.12, 0.12, 0.14))

			# Red butcher ribbon tied around the shank
			var ribbon_pos: Vector2 = cp - u * 7.0
			wc.draw_line(ribbon_pos - v * 2.5, ribbon_pos + v * 2.5, Color(0.85, 0.20, 0.18), 2.0)
			wc.draw_line(ribbon_pos - v * 1.5, ribbon_pos + v * 1.5, Color(0.95, 0.85, 0.25), 1.0)

			# Cured ham meat bulb (teardrop silhouette)
			var bulb_center: Vector2 = cp + u * 4.0
			# Outer cured ham rind (rich deep mahogany)
			var outer_pts: PackedVector2Array = PackedVector2Array([
				shank_start - v * 2.0,
				bulb_center - v * 6.5,
				bulb_center + u * 8.0 - v * 4.0,
				bulb_center + u * 10.0,
				bulb_center + u * 8.0 + v * 4.0,
				bulb_center + v * 6.5,
				shank_start + v * 2.0,
			])
			wc.draw_colored_polygon(outer_pts, Color(0.46, 0.18, 0.12))

			# Inner cured meat slice (ruby red jamón with marbled fat edge)
			var inner_meat: PackedVector2Array = PackedVector2Array([
				bulb_center - u * 2.0 - v * 1.0,
				bulb_center - v * 4.5,
				bulb_center + u * 6.0 - v * 2.5,
				bulb_center + u * 8.0,
				bulb_center + u * 6.0 + v * 2.5,
				bulb_center + v * 4.5,
				bulb_center - u * 2.0 + v * 1.0,
			])
			# Fat layer
			wc.draw_colored_polygon(inner_meat, Color(0.95, 0.92, 0.84))
			# Red meat center
			var meat_pts: PackedVector2Array = PackedVector2Array([
				bulb_center - u * 1.0 - v * 0.8,
				bulb_center - v * 3.5,
				bulb_center + u * 5.0 - v * 1.8,
				bulb_center + u * 6.5,
				bulb_center + u * 5.0 + v * 1.8,
				bulb_center + v * 3.5,
				bulb_center - u * 1.0 + v * 0.8,
			])
			wc.draw_colored_polygon(meat_pts, Color(0.78, 0.22, 0.18))
			# Subtle glossy fat streaks
			wc.draw_line(bulb_center + u * 1.0 - v * 2.0, bulb_center + u * 4.0 - v * 1.0, Color(1.0, 0.96, 0.90, 0.8), 1.0)
			wc.draw_line(bulb_center + u * 2.0 + v * 1.5, bulb_center + u * 5.0 + v * 0.8, Color(1.0, 0.96, 0.90, 0.8), 1.0)
