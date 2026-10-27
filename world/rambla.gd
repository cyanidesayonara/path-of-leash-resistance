class_name Rambla
extends RefCounted

# LA RAMBLA visual polish pass:
# - Iconic undulating wave pavement (ones del paviment de la Rambla)
# - Joan Miró's Pla de l'Os pavement mosaic in Plaça de la Boqueria
# - Font de Canaletes: 4 bronze spouts, city crests, drain grates, 4-armed lantern
# - Newsstand kiosks with postcard carousel racks and newspaper bundles
# - Rambla de les Flors flower stalls with zinc buckets, potted plants, and petal drifts
# - Souvenir stalls with straw hats, espadrilles, and ceramic trencadis lizards
# - Caricaturist and painter pitches with easels, palettes, and sketch clotheslines
# - Living statues on weathered stone pedestals with tipping coin dishes

const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.05, 0.05, 0.08, 0.20)

# Colors
const CANALETES_IRON := Color(0.12, 0.13, 0.14)
const BRONZE_SPOUT := Color(0.74, 0.58, 0.28)
const LANTERN_GLOW := Color(1.0, 0.94, 0.76, 0.85)
const WATER_STREAM := Color(0.75, 0.88, 0.96, 0.70)
const CREST_RED := Color(0.85, 0.18, 0.18)
const CREST_GOLD := Color(0.95, 0.78, 0.18)

const MIRO_CREAM := Color(0.92, 0.90, 0.84)
const MIRO_CHARCOAL := Color(0.16, 0.16, 0.18)
const MIRO_BLUE := Color(0.12, 0.32, 0.72)
const MIRO_RED := Color(0.86, 0.18, 0.16)
const MIRO_YELLOW := Color(0.96, 0.80, 0.14)
const MIRO_GREEN := Color(0.18, 0.54, 0.32)

const ZINC_BUCKET := Color(0.62, 0.65, 0.68)
const ZINC_RIM := Color(0.74, 0.76, 0.78)
const ROSE_RED := Color(0.88, 0.16, 0.22)
const SUNFLOWER_GOLD := Color(0.98, 0.82, 0.16)
const LILY_WHITE := Color(0.98, 0.98, 0.95)
const LAVENDER_PURPLE := Color(0.68, 0.44, 0.82)
const POT_TERRACOTTA := Color(0.68, 0.40, 0.26)
const LEAF_GREEN := Color(0.24, 0.46, 0.22)

const KIOSK_GREEN := Color(0.16, 0.28, 0.20)
const KIOSK_CANOPY := Color(0.12, 0.22, 0.16)
const POSTCARD_BORDER := Color(0.92, 0.90, 0.86)
const PAPER_BUNDLE := Color(0.86, 0.84, 0.80)
const PAPER_STRING := Color(0.48, 0.42, 0.34)
const STRAW_HAT := Color(0.88, 0.78, 0.52)
const ESPADRILLE_STRIPE := Color(0.26, 0.40, 0.62)


static func _rr(r: Rect2, rad: float) -> PackedVector2Array:
	var k := minf(rad, minf(r.size.x, r.size.y) * 0.5)
	var cs := [Vector2(r.end.x - k, r.position.y + k), Vector2(r.end.x - k, r.end.y - k),
		Vector2(r.position.x + k, r.end.y - k), Vector2(r.position.x + k, r.position.y + k)]
	var pts := PackedVector2Array()
	for ci in range(4):
		for s in range(4):
			pts.append(cs[ci] + Vector2.from_angle(-PI * 0.5 + float(ci) * PI * 0.5 + float(s) * PI / 6.0) * k)
	return pts


# The paving's waves: cream bands undulating across the promenade over the
# grey, every other row, each band one polygon with a darker seam along both
# edges. What the real promenade is known by, so it reads at a glance.
const WAVE_ROW := 34.0
const WAVE_AMP := 8.0
const WAVE_K := 0.035
const WAVE_CREAM := Color(0.80, 0.77, 0.70)
const WAVE_SEAM := Color(0.56, 0.54, 0.50, 0.55)


static func draw_pavement_waves(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var top_w := maxf(vt - 60.0, m.GATE_Y)
	var bot_w := minf(vb + 60.0, m.START_Y)
	if bot_w <= top_w:
		return
	var wy := floorf(top_w / WAVE_ROW) * WAVE_ROW
	while wy < bot_w + WAVE_ROW:
		if wy >= top_w and wy <= bot_w and int(absf(wy) / WAVE_ROW) % 2 == 0:
			var we: Vector2 = m.walk_edges(wy)
			var wx0 := we.x + 12.0
			var wx1 := we.y - 12.0
			if wx1 > wx0 + 60.0:
				var top := PackedVector2Array()
				var x := wx0
				while x < wx1:
					top.append(Vector2(x, wy + sin(x * WAVE_K) * WAVE_AMP))
					x += 16.0
				top.append(Vector2(wx1, wy + sin(wx1 * WAVE_K) * WAVE_AMP))
				var band := top.duplicate()
				for i in range(top.size() - 1, -1, -1):
					band.append(top[i] + Vector2(0.0, WAVE_ROW))
				b.polygon(band, WAVE_CREAM)
				for i in range(top.size() - 1):
					b.line(top[i], top[i + 1], WAVE_SEAM, 2.0)
					b.line(top[i] + Vector2(0.0, WAVE_ROW), top[i + 1] + Vector2(0.0, WAVE_ROW), WAVE_SEAM, 2.0)
		wy += WAVE_ROW


static func draw_miro_mosaic(b: ShapeBatch, mc: Vector2, mr: float) -> void:
	# radial paving joints radiating into the Plaça de la Boqueria square
	for ri in range(16):
		var ra := float(ri) * TAU / 16.0
		b.line(mc + Vector2.from_angle(ra) * (mr + 8.0), mc + Vector2.from_angle(ra) * (mr + 48.0), Color(0.56, 0.52, 0.46, 0.40), 1.6)
	# outer border ring in dark terrazzo and pale marble tiles
	b.circle(mc, mr + 8.0, MIRO_CHARCOAL)
	b.circle(mc, mr + 5.0, MIRO_CREAM)
	b.circle(mc, mr, MIRO_CREAM.lightened(0.04))
	# inner tesserae subtle concentric rings
	b.circle(mc, mr * 0.75, Color(0.86, 0.84, 0.78, 0.5))
	b.circle(mc, mr * 0.45, Color(0.88, 0.86, 0.80, 0.5))
	# the primary color shapes
	# 1. ultramarine/cobalt blue circle with charcoal pupil
	b.circle(mc + Vector2(26, 18), 16.0, MIRO_BLUE)
	b.circle(mc + Vector2(26, 18), 13.0, MIRO_BLUE.lightened(0.12))
	b.circle(mc + Vector2(26, 18), 5.5, MIRO_CHARCOAL)
	# 2. vermilion red kidney/crescent
	b.circle(mc + Vector2(-22, -14), 22.0, MIRO_RED)
	b.circle(mc + Vector2(-22, -14), 18.0, MIRO_RED.lightened(0.08))
	b.circle(mc + Vector2(-15, -10), 12.0, MIRO_CREAM)
	# 3. radiant yellow disc
	b.circle(mc + Vector2(18, -30), 10.5, MIRO_YELLOW)
	b.circle(mc + Vector2(18, -30), 8.0, MIRO_YELLOW.lightened(0.15))
	# 4. emerald green circular patch
	b.circle(mc + Vector2(-30, 28), 9.5, MIRO_GREEN)
	b.circle(mc + Vector2(-30, 28), 7.0, MIRO_GREEN.lightened(0.12))
	# 5. Miro's iconic bold black calligraphic brushstrokes and stars
	b.line(mc + Vector2(-54, 10), mc + Vector2(50, -20), MIRO_CHARCOAL, 5.5)
	b.line(mc + Vector2(-10, 46), mc + Vector2(8, -52), MIRO_CHARCOAL, 4.5)
	b.circle(mc + Vector2(-42, 12), 3.0, MIRO_CHARCOAL)
	b.circle(mc + Vector2(38, -18), 3.0, MIRO_CHARCOAL)
	b.circle(mc + Vector2(-2, 38), 2.5, MIRO_CHARCOAL)


static func draw_canaletes(m: Node2D, wc: Object, f: Vector2) -> void:
	m.contact_shadow(wc, f, 22.0, 8.0, 0.28)
	wc.draw_circle(f, 22.0, Color(0.50, 0.48, 0.44))
	wc.draw_circle(f, 18.5, Color(0.68, 0.65, 0.60))
	wc.draw_circle(f, 15.0, Color(0.38, 0.40, 0.42))
	# drainage grates under the 4 spouts
	for k in range(4):
		var d := Vector2.from_angle(TAU * float(k) / 4.0 + PI / 4.0)
		var gp := f + d * 15.5
		wc.draw_rect(Rect2(gp.x - 3.5, gp.y - 3.5, 7.0, 7.0), Color(0.16, 0.16, 0.18))
		wc.draw_line(gp + Vector2(-2.5, 0), gp + Vector2(2.5, 0), Color(0.30, 0.30, 0.32), 1.0)
		wc.draw_line(f + d * 6.0, f + d * 14.5, CANALETES_IRON, 3.5)
		wc.draw_line(f + d * 11.0, f + d * 15.5, BRONZE_SPOUT, 2.2)
		wc.draw_circle(f + d * 15.5, 2.6, BRONZE_SPOUT)
		wc.draw_line(f + d * 15.5, f + d * 16.0 + Vector2(0, 2.0), WATER_STREAM, 1.4)
	# fluted cast-iron column body
	wc.draw_circle(f, 10.0, CANALETES_IRON)
	wc.draw_circle(f, 8.2, CANALETES_IRON.lightened(0.10))
	# Barcelona city crests on the 4 column facets
	for k in range(4):
		var cd := Vector2.from_angle(TAU * float(k) / 4.0)
		var cp := f + cd * 7.0
		wc.draw_rect(Rect2(cp.x - 2.0, cp.y - 2.0, 4.0, 4.0), CREST_RED)
		wc.draw_rect(Rect2(cp.x - 1.0, cp.y - 1.0, 2.0, 2.0), CREST_GOLD)
	# crowning 4-armed candelabra iron lantern standard
	for k in range(4):
		var la := Vector2.from_angle(TAU * float(k) / 4.0)
		var lp := f + la * 11.5
		wc.draw_line(f, lp, CANALETES_IRON, 2.2)
		wc.draw_circle(lp + Vector2(1, 1), 5.5, Color(0, 0, 0, 0.15))
		wc.draw_circle(lp, 4.5, LANTERN_GLOW)
		wc.draw_circle(lp + Vector2(-1, -1), 2.2, Color(1.0, 1.0, 0.95))
	wc.draw_circle(f, 3.5, BRONZE_SPOUT)
	wc.draw_circle(f, 1.5, Color(0.95, 0.85, 0.40))
	wc.draw_circle(f + Vector2(14, 11), 6.0, Color(0.42, 0.58, 0.68, 0.40))


static func draw_rambla_stall(m: Node2D, b: ShapeBatch, st: Vector2, kind: String, i: int) -> void:
	var r := Rect2(st.x - 48.0, st.y - 28.0, 96.0, 56.0)
	if kind == "icecream" or kind == "caricature":
		b.rect(Rect2(r.position + LIGHT * 12.0, r.size), Color(0.05, 0.05, 0.08, 0.22))
	else:
		m.box_shadow(b, r, 5.0, 12.0)
	match kind:
		"kiosk":
			b.rect(r, KIOSK_GREEN)
			b.rect(r.grow(-5.0), KIOSK_GREEN.lightened(0.12))
			b.line(Vector2(r.position.x + 5.0, st.y), Vector2(r.end.x - 5.0, st.y), KIOSK_CANOPY, 3.5)
			for k in range(8):
				var mc: Color = [Color(0.9, 0.3, 0.3), Color(0.95, 0.85, 0.3), Color(0.3, 0.55, 0.9), Color(0.95, 0.95, 0.9)][k % 4]
				b.rect(Rect2(r.position.x + 4.0 + float(k) * 11.5, r.end.y - 2.0, 9.0, 8.0), mc)
				b.line(Vector2(r.position.x + 5.0 + float(k) * 11.5, r.end.y + 2.0), Vector2(r.position.x + 11.0 + float(k) * 11.5, r.end.y + 2.0), Color(0.2, 0.2, 0.2), 1.0)
			for side: float in [-1.0, 1.0]:
				var rx := st.x + side * 54.0
				b.circle(Vector2(rx, st.y) + LIGHT * 4.0, 9.0, SHADOW)
				b.circle(Vector2(rx, st.y), 9.0, Color(0.32, 0.34, 0.36))
				b.circle(Vector2(rx, st.y), 7.0, POSTCARD_BORDER)
				for p in range(4):
					var a := float(p) * TAU / 4.0
					var pp := Vector2(rx, st.y) + Vector2.from_angle(a) * 5.0
					b.rect(Rect2(pp - Vector2(2, 2), Vector2(4, 4)), [Color(0.2, 0.5, 0.8), Color(0.8, 0.3, 0.2), Color(0.9, 0.8, 0.2), Color(0.3, 0.7, 0.4)][p])
			var nb := Rect2(r.position.x + 4.0, r.position.y - 10.0, 20.0, 12.0)
			b.rect(Rect2(nb.position + Vector2(1, 1), nb.size), Color(0, 0, 0, 0.16))
			b.rect(nb, PAPER_BUNDLE)
			b.line(Vector2(nb.position.x + 10.0, nb.position.y), Vector2(nb.position.x + 10.0, nb.end.y), PAPER_STRING, 1.2)
			b.line(Vector2(nb.position.x, nb.position.y + 6.0), Vector2(nb.end.x, nb.position.y + 6.0), PAPER_STRING, 1.2)
		"flowers":
			b.rect(r, Color(0.20, 0.34, 0.22))
			b.rect(r.grow(-4.0), Color(0.26, 0.40, 0.28))
			for k in range(12):
				var fc: Color = [ROSE_RED, SUNFLOWER_GOLD, Color(0.96, 0.60, 0.20), LAVENDER_PURPLE, LILY_WHITE][(k + i) % 5]
				var fp := Vector2(r.position.x + 10.0 + float(k % 6) * 15.0, r.position.y + 14.0 + float(k / 6) * 26.0)
				b.circle(fp + LIGHT * 2.0, 7.5, SHADOW)
				b.circle(fp, 7.0, ZINC_BUCKET)
				b.circle(fp, 5.5, ZINC_RIM)
				b.circle(fp + Vector2(-1, -1), 4.5, fc)
				b.circle(fp + Vector2(1, 1), 2.0, fc.lightened(0.25))
			for k in range(4):
				var bp := Vector2(r.position.x + 12.0 + float(k) * 24.0, r.end.y + 7.0)
				b.circle(bp + LIGHT * 2.0, 6.5, SHADOW)
				b.circle(bp, 6.0, ZINC_BUCKET)
				b.circle(bp, 4.5, ZINC_RIM)
				b.circle(bp + Vector2(-0.8, -0.8), 3.8, [ROSE_RED, SUNFLOWER_GOLD][k % 2])
			for side: float in [-1.0, 1.0]:
				var pot_p := Vector2(st.x + side * 54.0, st.y + 10.0)
				b.circle(pot_p + LIGHT * 3.0, 7.5, SHADOW)
				b.circle(pot_p, 7.0, POT_TERRACOTTA)
				b.circle(pot_p, 5.2, Color(0.38, 0.24, 0.16))
				for lf in range(5):
					var la := float(lf) * TAU / 5.0
					b.circle(pot_p + Vector2.from_angle(la) * 4.2, 3.2, LEAF_GREEN)
			for p in range(8):
				var pp := Vector2(r.position.x + 6.0 + fmod(float(p) * 23.3, r.size.x - 12.0), r.end.y + 12.0 + fmod(float(p) * 13.7, 16.0))
				b.circle(pp, 1.4, ROSE_RED if p % 2 == 0 else SUNFLOWER_GOLD)
			b.circle(Vector2(st.x, r.end.y + 16.0), 8.0, Color(0.40, 0.55, 0.65, 0.25))
		"souvenir":
			b.rect(r, Color(0.46, 0.36, 0.28))
			b.rect(r.grow(-4.0), Color(0.54, 0.44, 0.34))
			for h in range(3):
				var hp := Vector2(r.position.x + 14.0 + float(h) * 34.0, r.position.y + 10.0)
				b.circle(hp + LIGHT * 2.0, 8.5, SHADOW)
				b.circle(hp, 8.0, STRAW_HAT)
				b.circle(hp, 5.0, STRAW_HAT.darkened(0.12))
				b.circle(hp, 3.2, Color(0.85, 0.22, 0.24))
			for e in range(3):
				var ep := Vector2(r.position.x + 16.0 + float(e) * 32.0, r.position.y + 28.0)
				b.polygon(_rr(Rect2(ep - Vector2(5, 7), Vector2(10, 14)), 3.0), ESPADRILLE_STRIPE)
				b.line(ep - Vector2(4, 0), ep + Vector2(4, 0), STRAW_HAT, 1.4)
			for k in range(6):
				var liz_p := Vector2(r.position.x + 12.0 + float(k) * 15.0, r.end.y - 10.0)
				b.circle(liz_p, 4.5, [Color(0.15, 0.50, 0.85), Color(0.92, 0.40, 0.15), Color(0.20, 0.70, 0.35)][k % 3])
				b.circle(liz_p + Vector2(-1, -1), 2.0, Color(0.98, 0.90, 0.20))
		"caricature":
			b.rect(Rect2(r.position.x + 8.0, r.position.y, 80.0, r.size.y), Color(0.32, 0.26, 0.22))
			var ep := Vector2(st.x - 14.0, st.y - 4.0)
			b.line(ep + Vector2(-12, -18), ep + Vector2(0, 18), Color(0.48, 0.34, 0.22), 3.0)
			b.line(ep + Vector2(12, -18), ep + Vector2(0, 18), Color(0.48, 0.34, 0.22), 3.0)
			b.rect(Rect2(ep.x - 14.0, ep.y - 20.0, 28.0, 22.0), Color(0.98, 0.97, 0.94))
			b.circle(ep + Vector2(0, -9), 6.0, Color(0.92, 0.76, 0.62))
			b.circle(ep + Vector2(0, -9), 4.0, Color(0.2, 0.2, 0.2))
			var pal := Vector2(st.x + 24.0, st.y - 8.0)
			b.circle(pal + LIGHT * 2.0, 8.5, SHADOW)
			b.circle(pal, 8.0, Color(0.72, 0.56, 0.36))
			b.circle(pal + Vector2(4, 3), 2.0, Color(0.28, 0.20, 0.12))
			for c in range(4):
				var ca := float(c) * TAU / 4.0
				b.circle(pal + Vector2.from_angle(ca) * 5.0, 1.8, [Color(0.85, 0.18, 0.18), Color(0.20, 0.50, 0.85), Color(0.95, 0.80, 0.15), Color(0.95, 0.95, 0.95)][c])
			var stool := Vector2(st.x + 22.0, st.y + 14.0)
			b.circle(stool + LIGHT * 3.0, 7.5, SHADOW)
			b.circle(stool, 7.0, Color(0.58, 0.42, 0.28))
			b.circle(stool, 5.0, Color(0.44, 0.30, 0.18))
			b.line(Vector2(r.position.x + 4.0, r.position.y - 8.0), Vector2(r.end.x - 4.0, r.position.y - 8.0), Color(0.35, 0.35, 0.38), 1.2)
			for sk in range(4):
				var sp := Vector2(r.position.x + 12.0 + float(sk) * 22.0, r.position.y - 7.0)
				b.rect(Rect2(sp, Vector2(14.0, 10.0)), Color(0.96, 0.95, 0.92))
				b.circle(sp + Vector2(7, 5), 3.0, Color(0.2, 0.2, 0.2))
				b.rect(Rect2(sp.x + 6.0, sp.y - 2.0, 2.0, 3.0), Color(0.65, 0.50, 0.35))
		"painter":
			b.rect(Rect2(r.position.x, r.position.y, 60.0, r.size.y), Color(0.30, 0.24, 0.20))
			var views := [[Color(0.30, 0.56, 0.80), Color(0.94, 0.84, 0.56)], [Color(0.96, 0.62, 0.30), Color(0.62, 0.36, 0.28)],
				[Color(0.40, 0.66, 0.42), Color(0.86, 0.86, 0.80)], [Color(0.92, 0.46, 0.40), Color(0.32, 0.30, 0.52)]]
			for k in range(6):
				var fp := Vector2(r.position.x + 5.0 + float(k % 3) * 18.0, r.position.y + 5.0 + float(k / 3) * 25.0)
				var v: Array = views[(k + i) % views.size()]
				b.rect(Rect2(fp, Vector2(16.0, 21.0)), Color(0.78, 0.62, 0.30))
				b.rect(Rect2(fp + Vector2(2, 2), Vector2(12.0, 17.0)), v[0])
				b.rect(Rect2(fp + Vector2(2, 12), Vector2(12.0, 7.0)), v[1])
			b.line(Vector2(st.x + 24.0, st.y - 22.0), Vector2(st.x + 34.0, st.y + 20.0), Color(0.45, 0.32, 0.20), 3.0)
			b.line(Vector2(st.x + 44.0, st.y - 22.0), Vector2(st.x + 34.0, st.y + 20.0), Color(0.45, 0.32, 0.20), 3.0)
			b.rect(Rect2(st.x + 22.0, st.y - 26.0, 24.0, 18.0), Color(0.98, 0.97, 0.94))
			b.rect(Rect2(st.x + 25.0, st.y - 23.0, 18.0, 6.0), Color(0.30, 0.56, 0.80))
			b.rect(Rect2(st.x + 25.0, st.y - 17.0, 18.0, 6.0), Color(0.94, 0.84, 0.56))
		"icecream":
			b.rect(Rect2(st.x - 30.0, st.y - 18.0, 60.0, 36.0), Color(0.95, 0.93, 0.88))
			b.rect(Rect2(st.x - 30.0, st.y - 18.0, 60.0, 6.0), Color(0.55, 0.78, 0.86))
			for wx: float in [-22.0, 22.0]:
				b.circle(Vector2(st.x + wx, st.y + 20.0), 5.0, Color(0.15, 0.15, 0.16))
		"books":
			b.rect(r, Color(0.44, 0.32, 0.22))
			b.rect(r.grow(-4.0), Color(0.52, 0.38, 0.26))
			var spine := [Color(0.62, 0.16, 0.18), Color(0.16, 0.30, 0.52), Color(0.86, 0.78, 0.56),
				Color(0.24, 0.42, 0.28), Color(0.20, 0.18, 0.18), Color(0.82, 0.52, 0.22)]
			for row in range(2):
				var bx := r.position.x + 6.0
				var k := row * 5 + i
				while bx < r.end.x - 34.0:
					var w := 3.0 + float(k % 3)
					b.rect(Rect2(bx, r.position.y + 6.0 + float(row) * 22.0, w, 16.0 - float(k % 2) * 2.0), spine[k % spine.size()])
					bx += w + 1.0
					k += 1
			for ob in range(2):
				var op := Vector2(r.end.x - 30.0, r.position.y + 7.0 + float(ob) * 22.0)
				b.rect(Rect2(op, Vector2(24.0, 16.0)), Color(0.96, 0.95, 0.90))
				b.line(op + Vector2(12, 1), op + Vector2(12, 15), Color(0.70, 0.68, 0.62), 1.2)
				for ln in range(3):
					b.line(op + Vector2(3, 4 + ln * 4), op + Vector2(10, 4 + ln * 4), Color(0.6, 0.6, 0.6), 1.0)
					b.line(op + Vector2(14, 4 + ln * 4), op + Vector2(21, 4 + ln * 4), Color(0.6, 0.6, 0.6), 1.0)
		_:
			b.rect(r, Color(0.40, 0.32, 0.24))


static func draw_statue_dressing(m: Node2D, b: ShapeBatch, sp: Vector2, i: int, _paint: Color, _bow: float, _t: float) -> void:
	var base := Rect2(sp.x - 18.0, sp.y - 18.0, 36.0, 36.0)
	m.box_shadow(b, base, 5.0, 10.0)
	m.clay_slab(b, base, 5.0, Color(0.42, 0.40, 0.38), 3.0)
	b.rect(base.grow(-3.0), Color(0.50, 0.48, 0.45))
	var dish := Vector2(sp.x - 4.0, sp.y + 24.0)
	b.circle(dish + LIGHT * 2.0, 6.0, SHADOW)
	b.circle(dish, 5.5, BRONZE_SPOUT.darkened(0.2))
	b.circle(dish, 4.2, BRONZE_SPOUT)
	b.circle(dish + Vector2(-1.5, -0.5), 1.6, CREST_GOLD)
	b.circle(dish + Vector2(1.5, 0.5), 1.4, Color(0.85, 0.88, 0.92))
	if i % 2 == 0:
		b.circle(sp + Vector2(-4.0, 4.0), 3.0, Color(0.30, 0.60, 0.48, 0.45))
		b.circle(sp + Vector2(5.0, 2.0), 2.5, Color(0.30, 0.60, 0.48, 0.40))


static func draw_tree_leaf_drifts(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	for p: Vector2 in m.poles:
		if p.y < vt - 40.0 or p.y > vb + 40.0:
			continue
		for lf in range(4):
			var la := float(lf) * 1.7 + p.x
			var lp := p + Vector2.from_angle(la) * (20.0 + fmod(float(lf) * 4.3, 12.0))
			b.polygon(PackedVector2Array([lp, lp + Vector2(3, -2), lp + Vector2(5, 1), lp + Vector2(2, 3)]), Color(0.72, 0.50, 0.24))
