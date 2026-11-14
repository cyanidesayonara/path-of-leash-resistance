class_name GoticCastellers
extends RefCounted

# Castellers de Barcelona in El Gòtic's Plaça de Sant Felip Neri.
# Founded in 1969, the historic colla of Barcelona performs in the historic centre
# wearing their traditional vibrant red shirts, black faixas, and white trousers.
# Located in the open north-east quadrant of GOTIC_PLACA (y = -2850.0, x = 840.0),
# with two flanking Gothic stone stanchions serving as rope wrap points,
# accompanied by traditional colla musicians (graller and tabaler),
# a Diada banner, and a living 8-second dynamic crowning cycle with l'aleta.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const CastellCycle := preload("res://systems/castell_cycle.gd")
const LevelBuild := preload("res://world/level_build.gd")

const DIADA_POS := Vector2(840.0, -2850.0)
const STANCHION_L := Vector2(804.0, -2850.0)
const STANCHION_R := Vector2(876.0, -2850.0)

const COLLISION_SIZE := Vector2(56.0, 56.0)
const COLLISION_RECT := Rect2(DIADA_POS - COLLISION_SIZE * 0.5, COLLISION_SIZE)

# Colla identity: Castellers de Barcelona
const BARCELONA_RED := Color(0.85, 0.16, 0.18)
const FAIXA := Color(0.10, 0.10, 0.12)
const TROUSERS_WHITE := Color(0.96, 0.95, 0.92)
const SENYERA_GOLD := Color(0.94, 0.78, 0.22)
const SENYERA_RED := Color(0.85, 0.16, 0.18)
const STONE_PLINTH := Color(0.58, 0.54, 0.48)
const STONE_DARK := Color(0.42, 0.38, 0.34)
const IRON_RING := Color(0.22, 0.22, 0.24)
const CORDON_RED := Color(0.72, 0.18, 0.18)
const BANNER_RED := Color(0.82, 0.14, 0.16)
const BANNER_WHITE := Color(0.94, 0.92, 0.86)
const GOLD_GLINT := Color(1.0, 0.88, 0.32)
const SKIN_COL := Color(0.86, 0.70, 0.56)
const HAIR_COL := Color(0.24, 0.18, 0.14)

const WATCH_DIST := 130.0
const BARK_DIST := 150.0
const WATCH_TIME := 1.5


static func tick(m: Node2D, delta: float) -> void:
	if m.lvl != "oldtown" or m.gotic_castell_watched:
		return
	var dp: Vector2 = m.dog.global_position
	# Respectful watch: dog stands calmly near the colla without dragging
	if dp.distance_to(DIADA_POS) < WATCH_DIST and m.dog.velocity.length() < 30.0 and not m.dog.dragged:
		m.gotic_castell_t += delta
		if m.gotic_castell_t >= WATCH_TIME:
			m.gotic_castell_watched = true
			m.combo.add("EQUILIBRI", 2)
			m.award_points(2, "equilibri! +2")
			Sfx.play("combo", 1.1, -4.0)
			m.float_text(DIADA_POS + Vector2(0.0, -42.0), "Força, equilibri, valor i seny!", Color(0.96, 0.94, 0.88), m.POP_SAY)
	elif dp.distance_to(DIADA_POS) >= WATCH_DIST + 20.0:
		m.gotic_castell_t = 0.0


static func on_bark(m: Node2D, pos: Vector2 = Vector2.ZERO) -> void:
	if m.lvl != "oldtown" or m.gotic_aleta_cheered:
		return
	var bp: Vector2 = pos if pos != Vector2.ZERO else m.dog.global_position
	if bp.distance_to(DIADA_POS) <= BARK_DIST:
		if CastellCycle.cheer_window(m):
			m.gotic_aleta_cheered = true
			m.combo.add("ALETA", 2)
			m.award_points(2, "aleta cheer! +2")
			Sfx.play("save", 1.2, -4.0)
			m.float_text(DIADA_POS + Vector2(0.0, -42.0), "Visca els Castellers de Barcelona!", Color(0.96, 0.94, 0.88), m.POP_SAY)


static func draw(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if DIADA_POS.y < vt - 80.0 or DIADA_POS.y > vb + 80.0:
		return

	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.28)
	var t: float = AnimClock.msec() * 0.001
	var phase_t := CastellCycle.phase(m)
	var sway := Vector2(sin(t * 1.9 + 0.4) * 2.2, cos(t * 1.4) * 1.5)

	# 1. Diada cobblestone circle & chalk/ribbon perimeter
	b.circle(DIADA_POS + Vector2(2, 3), 36.0, sh)
	b.circle(DIADA_POS, 35.0, Color(0.50, 0.46, 0.40))
	b.circle(DIADA_POS, 33.5, Color(0.55, 0.51, 0.44))
	# Concentric sett ring
	for seg in range(16):
		var a0 := float(seg) * TAU / 16.0
		var a1 := float(seg + 1) * TAU / 16.0
		b.line(DIADA_POS + Vector2.from_angle(a0) * 33.0, DIADA_POS + Vector2.from_angle(a1) * 33.0, Color(0.24, 0.22, 0.20, 0.4), 1.5)
	# Senyera ribbon garland along outer perimeter
	for k in range(12):
		var ang := float(k) * TAU / 12.0
		var col: Color = SENYERA_GOLD if k % 2 == 0 else SENYERA_RED
		b.circle(DIADA_POS + Vector2.from_angle(ang) * 33.0, 2.2, col)

	# 2. Diada Banner hung behind the castell
	var banner_y := DIADA_POS.y - 36.0
	for px in [-28.0, 28.0]:
		var pole_p := Vector2(DIADA_POS.x + px, banner_y)
		b.circle(pole_p + Vector2(1, 2), 2.5, sh)
		b.line(pole_p + Vector2(0, 10.0), pole_p + Vector2(0, -10.0), Color(0.22, 0.20, 0.22), 2.0)
		b.circle(pole_p + Vector2(0, -10.0), 2.0, SENYERA_GOLD)
	var b_rect := Rect2(DIADA_POS.x - 26.0, banner_y - 8.0, 52.0, 12.0)
	b.rect(Rect2(b_rect.position + Vector2(2, 3), b_rect.size), sh)
	b.rect(b_rect, BANNER_RED.darkened(0.2))
	b.rect(b_rect.grow(-1.5), BANNER_RED)
	b.line(Vector2(b_rect.position.x + 2.0, b_rect.position.y + 2.0), Vector2(b_rect.end.x - 2.0, b_rect.position.y + 2.0), BANNER_WHITE, 1.2)
	b.line(Vector2(b_rect.position.x + 2.0, b_rect.end.y - 2.0), Vector2(b_rect.end.x - 2.0, b_rect.end.y - 2.0), BANNER_WHITE, 1.2)
	# Central Senyera shield badge
	var badge_cx := DIADA_POS.x
	b.rect(Rect2(badge_cx - 4.0, banner_y - 4.0, 8.0, 8.0), SENYERA_GOLD)
	for bar in range(4):
		b.line(Vector2(badge_cx - 3.0 + float(bar) * 2.0, banner_y - 4.0), Vector2(badge_cx - 3.0 + float(bar) * 2.0, banner_y + 4.0), SENYERA_RED, 1.0)

	# 3. Flanking Gothic Carved Stone Stanchions & Red Cordon (wrap poles)
	for sp: Vector2 in [STANCHION_L, STANCHION_R]:
		b.circle(sp + Shade.light * 3.0, 6.0, sh)
		b.circle(sp, 5.5, STONE_DARK)
		b.circle(sp - Shade.light * 0.8, 4.2, STONE_PLINTH)
		b.circle(sp - Shade.light * 1.5, 2.0, STONE_PLINTH.lightened(0.25))
		b.circle(sp, 2.4, IRON_RING)
		b.circle(sp, 1.0, STONE_DARK)
	# Red velvet cordon swags linking stanchions toward banner flanks
	b.line(STANCHION_L, Vector2(DIADA_POS.x - 26.0, banner_y), CORDON_RED, 2.0)
	b.line(STANCHION_R, Vector2(DIADA_POS.x + 26.0, banner_y), CORDON_RED, 2.0)

	# 4. Colla Musicians (Graller & Tabaler)
	var gp := DIADA_POS + Vector2(-28.0, 22.0)
	b.circle(gp + Vector2(2, 2), 6.5, sh)
	b.circle(gp, 6.0, BARCELONA_RED)
	b.circle(gp, 2.8, FAIXA)
	b.circle(gp + Vector2(0.0, 3.2), 3.0, TROUSERS_WHITE)
	b.circle(gp + Vector2(1.5, -2.5), 3.5, HAIR_COL)
	b.circle(gp + Vector2(1.5, -3.5), 4.0, FAIXA) # Catalan beret (boina)
	b.line(gp + Vector2(3.0, -1.0), gp + Vector2(9.0, -5.0), Color(0.48, 0.32, 0.18), 2.0) # woodwind gralla

	var tp := DIADA_POS + Vector2(28.0, 22.0)
	b.circle(tp + Vector2(2, 2), 6.5, sh)
	b.circle(tp, 6.0, BARCELONA_RED)
	b.circle(tp, 2.8, FAIXA)
	b.circle(tp + Vector2(0.0, 3.2), 3.0, TROUSERS_WHITE)
	b.circle(tp + Vector2(-1.5, -2.5), 3.5, HAIR_COL)
	b.circle(tp + Vector2(-4.0, 0.0), 4.2, Color(0.88, 0.84, 0.76)) # tabal snare drum
	b.line(tp + Vector2(-1.0, -2.0), tp + Vector2(-4.0, 0.0), Color(0.82, 0.72, 0.54), 1.5)

	# 5. Cap de Colla & Coaches flanking the pinya
	var coach_l := DIADA_POS + Vector2(-22.0, -12.0)
	var coach_r := DIADA_POS + Vector2(22.0, -12.0)
	for cp: Vector2 in [coach_l, coach_r]:
		b.circle(cp + Vector2(2, 2), 6.5, sh)
		b.circle(cp, 6.0, BARCELONA_RED)
		b.circle(cp, 2.8, FAIXA)
		b.circle(cp + Vector2(0.0, 3.0), 2.8, TROUSERS_WHITE)
		var face_dir := 1.0 if cp.x < DIADA_POS.x else -1.0
		b.circle(cp + Vector2(face_dir * 1.8, -1.2), 3.5, HAIR_COL)
		# Gesturing coaching arm toward the castell
		b.line(cp, cp + Vector2(face_dir * 5.0, 2.0), SKIN_COL, 1.8)

	var c := DIADA_POS + Vector2(0.0, -3.0)

	# 6. Pinya (base ring of 10 castellers in tight formation leaning inward)
	for k in range(10):
		var a := float(k) * (TAU / 10.0)
		var p := c + Vector2(cos(a) * 23.0, sin(a) * 16.0)
		b.circle(p + Vector2(2, 2), 7.5, sh)
		b.circle(p, 7.0, BARCELONA_RED)
		b.circle(p, 3.0, FAIXA)
		b.circle(p + Vector2(cos(a) * 2.5, sin(a) * 2.5), 3.2, TROUSERS_WHITE)
		# Head leaning inward toward the tower core
		b.circle(p - Vector2(cos(a), sin(a)) * 3.0, 3.8, HAIR_COL)

	# 7. Tronc / Quarts (second tier of 4 castellers, swaying gently)
	var c_quarts := c + sway * 0.4 + Vector2(0.0, -2.0)
	for k in range(4):
		var a := float(k) * (TAU / 4.0) + PI / 4.0
		var qp := c_quarts + Vector2(cos(a) * 9.5, sin(a) * 7.0)
		b.circle(qp + Vector2(2, 2), 6.5, sh)
		b.circle(qp, 6.0, BARCELONA_RED)
		b.circle(qp, 2.5, FAIXA)
		b.circle(qp + Vector2(cos(a) * 2.0, sin(a) * 2.0), 2.8, TROUSERS_WHITE)
		b.circle(qp - Vector2(cos(a), sin(a)) * 2.0, 3.5, HAIR_COL)

	# 8. Acotxador (pom de dalt crouched support at the apex)
	var c_acotx := c + sway * 0.75 + Vector2(0.0, -8.0)
	b.circle(c_acotx + Vector2(1, 2), 5.5, sh)
	b.circle(c_acotx, 5.0, BARCELONA_RED)
	b.circle(c_acotx, 2.0, FAIXA)
	b.circle(c_acotx + Vector2(0.0, 2.2), 2.4, TROUSERS_WHITE)
	# White protective casteller helmet with crimson stripe
	b.circle(c_acotx + Vector2(0.0, -3.0), 3.4, BANNER_WHITE)
	b.line(c_acotx + Vector2(-2.8, -3.0), c_acotx + Vector2(2.8, -3.0), BARCELONA_RED, 1.4)

	# 9. Anxaneta (apex crowning child climber)
	if phase_t < 4.0:
		# Pujant (0.0..4.0s): Climbing up the tiers toward the acotxador
		var prog := phase_t / 4.0
		var start_p := c + Vector2(6.0, 4.0)
		var target_p := c_acotx + Vector2(2.0, -5.0)
		var anx_p := start_p.lerp(target_p, prog) + sway * (prog * 0.7)
		b.circle(anx_p + Vector2(1, 2), 4.5, sh)
		b.circle(anx_p, 4.2, BARCELONA_RED)
		b.circle(anx_p + Vector2(0.0, 1.8), 2.0, TROUSERS_WHITE)
		b.circle(anx_p + Vector2(0.0, -2.6), 3.2, BANNER_WHITE)
		b.line(anx_p + Vector2(-2.4, -2.6), anx_p + Vector2(2.4, -2.6), BARCELONA_RED, 1.2)
		b.line(anx_p + Vector2(1.0, 0.0), anx_p + Vector2(3.5, -2.0), SKIN_COL, 1.5)
	elif phase_t <= 6.5:
		# L'Aleta (4.0..6.5s): Straddling the acotxador with right arm raised high with 4 fingers!
		var apex := c_acotx + Vector2(0.0, -7.0) + sway * 0.3
		b.circle(apex + Vector2(1, 2), 4.5, sh)
		b.circle(apex, 4.2, BARCELONA_RED)
		b.circle(apex + Vector2(0.0, 2.0), 2.2, TROUSERS_WHITE)
		b.circle(apex + Vector2(0.0, -3.0), 3.2, BANNER_WHITE)
		b.line(apex + Vector2(-2.5, -3.0), apex + Vector2(2.5, -3.0), BARCELONA_RED, 1.2)

		# Raised right arm reaching high in salute
		var hand_p := apex + Vector2(4.0, -10.0)
		b.line(apex + Vector2(2.0, -1.0), hand_p, SKIN_COL, 1.8)
		# Four outstretched fingers (les quatre barres)
		b.line(hand_p, hand_p + Vector2(-2.0, -3.0), SKIN_COL, 1.0)
		b.line(hand_p, hand_p + Vector2(-0.7, -3.5), SKIN_COL, 1.0)
		b.line(hand_p, hand_p + Vector2(0.7, -3.5), SKIN_COL, 1.0)
		b.line(hand_p, hand_p + Vector2(2.0, -3.0), SKIN_COL, 1.0)

		# 4 celebratory golden sparkle glints rotating around the raised hand
		for g in range(4):
			var sp_a := t * 4.0 + float(g) * (TAU / 4.0)
			var sp_pos := hand_p + Vector2(cos(sp_a), sin(sp_a)) * (7.0 + sin(t * 8.0) * 1.5)
			b.circle(sp_pos, 1.4, GOLD_GLINT)
			b.circle(sp_pos, 0.7, Color(1.0, 1.0, 0.9))
	else:
		# Descarregant (6.5..8.0s): Safe descent down the opposite flank
		var prog := (phase_t - 6.5) / 1.5
		var start_p := c_acotx + Vector2(0.0, -7.0)
		var end_p := c + Vector2(-6.0, 6.0)
		var anx_p := start_p.lerp(end_p, prog) + sway * ((1.0 - prog) * 0.7)
		b.circle(anx_p + Vector2(1, 2), 4.5, sh)
		b.circle(anx_p, 4.2, BARCELONA_RED)
		b.circle(anx_p + Vector2(0.0, 1.8), 2.0, TROUSERS_WHITE)
		b.circle(anx_p + Vector2(0.0, -2.6), 3.2, BANNER_WHITE)
		b.line(anx_p + Vector2(-2.4, -2.6), anx_p + Vector2(2.4, -2.6), BARCELONA_RED, 1.2)
