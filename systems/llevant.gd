class_name Llevant
extends RefCounted

# WALK 24: PLATJA DE LLEVANT (the dog beach at the far end of the coast)
# Barcelona's northernmost beach by the Fòrum, where the fenced Platja dels
# Gossos (the city's dog beach) stands at the end of the coastal esplanade.
# Out of the metro onto the concrete seafront walk, past the Fòrum's tilted
# solar pergola, the stone groins (espigons), the beach showers and the
# rollerbladers along the bike lane, to the palisade fence of Platja dels
# Gossos where she goes off the leash into the surf.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const LevelBuild := preload("res://world/level_build.gd")
const Surfaces := preload("res://world/surfaces.gd")

const SAND_TO_X := 380.0
const PERGOLA_RECT := Rect2(996.0, -1720.0, 184.0, 560.0)
const GROIN_YS: Array[float] = [-2180.0, -3780.0]
const DOG_SHOWER_RECT := Rect2(988.0, -3180.0, 148.0, 140.0)


static func draw_edge_layer(_m: Node2D, _c: Object, _vt: float, _vb: float) -> void:
	pass


static func draw_cross_section(m: Node2D, wc: ShapeBatch, top: float, bottom: float, ctop: float, vt: float, vb: float) -> void:
	var ftop: float = m.GATE_Y - 30.0
	# Mediterranean sea, shallows, wet sand, foam and shells along the shore
	wc.draw_rect(Rect2(-400.0, ctop, 630.0, bottom - ctop), m.BEACH_SEA_DEEP)
	wc.draw_rect(Rect2(m.BEACH_GATE_SHORE_X - m.BEACH_SHALLOW_W, ctop, m.BEACH_SHALLOW_W, bottom - ctop), m.BEACH_SEA_SHALLOW)
	var wt := AnimClock.msec() / 1000.0
	var fy := top + 40.0
	while fy < bottom:
		if fy > vt and fy < vb:
			wc.draw_line(Vector2(72.0 + sin(fy * 0.011 + wt * 1.5) * 9.0, fy), Vector2(84.0 + sin(fy * 0.013 + wt * 1.5) * 9.0, fy + 70.0), Color(1, 1, 1, 0.25), 3.0)
		fy += 150.0
	wc.draw_rect(Rect2(230.0, ftop, 150.0, bottom - ftop), m.BEACH_SAND)
	wc.draw_rect(Rect2(m.BEACH_GATE_SHORE_X, ftop, m.BEACH_WET_W, bottom - ftop), m.BEACH_WET)
	var foam := ShapeBatch.new()
	var fmy := maxf(ftop, vt - fmod(vt, 52.0) - 52.0)
	while fmy < minf(bottom, vb + 52.0):
		var fmx: float = m.BEACH_GATE_SHORE_X + 4.0 + sin(fmy * 0.02 + wt * 1.4) * 4.0
		var fml := 30.0 + 14.0 * (0.5 + 0.5 * sin(fmy * 0.037))
		foam.line(Vector2(fmx, fmy), Vector2(fmx - 2.0, fmy + fml), Color(1, 1, 1, 0.26), 3.0)
		fmy += 52.0
	foam.flush(wc)
	m._draw_espigo(wc)
	# Stone coastal groins (espigons) jutting into the surf along Llevant
	var bg := ShapeBatch.new()
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22)
	for gy0: float in GROIN_YS:
		if gy0 > vt - 80.0 and gy0 < vb + 80.0:
			bg.rect(Rect2(-140.0, gy0 - 18.0, 420.0, 36.0), sh)
			var rx := -130.0
			var rk := 0
			while rx < 270.0:
				var rr := 14.0 + fmod(float(rk) * 5.3, 6.0)
				var ry := gy0 + (-5.0 if rk % 2 == 0 else 5.0)
				bg.circle(Vector2(rx, ry) + m.LIGHT * 3.0, rr, sh)
				bg.circle(Vector2(rx, ry), rr, Color(0.58, 0.57, 0.54) if rk % 2 == 0 else Color(0.68, 0.67, 0.63))
				bg.circle(Vector2(rx - 3.0, ry - 3.0), rr * 0.45, Color(0.78, 0.77, 0.73))
				rx += 18.0
				rk += 1
	bg.flush(wc)
	# Seaward timber boardwalk (380..490), skate/bike lane (490..570), esplanade (570..980)
	wc.draw_rect(Rect2(380.0, ftop, 110.0, bottom - ftop), Color(0.48, 0.30, 0.23))
	var bdeck := ShapeBatch.new()
	var py := minf(m.START_Y + 200.0, vb + 22.0 - fmod(vb, 22.0))
	while py - 20.0 >= ftop and py > vt - 22.0:
		if py < vb and py > vt:
			bdeck.line(Vector2(380.0, py), Vector2(490.0, py), Color(0.34, 0.20, 0.15), 2.0)
		py -= 22.0
	bdeck.flush(wc)
	wc.draw_rect(Rect2(490.0, ftop, 80.0, bottom - ftop), Color(0.80, 0.78, 0.72))
	var ddy := minf(m.START_Y + 200.0, vb + 64.0 - fmod(vb, 64.0))
	while ddy > m.GATE_Y and ddy > vt - 64.0:
		if ddy < vb and ddy > vt:
			wc.draw_line(Vector2(530.0, ddy), Vector2(530.0, ddy - 26.0), Color(0.97, 0.96, 0.93, 0.8), 3.0)
		ddy -= 64.0
	wc.draw_rect(Rect2(570.0, ftop, 410.0, bottom - ftop), Color(0.82, 0.80, 0.74))
	var sy := minf(m.START_Y + 200.0, vb + 150.0 - fmod(vb, 150.0))
	while sy > m.GATE_Y and sy > vt - 150.0:
		if sy < vb and sy > vt:
			wc.draw_line(Vector2(560.0, sy), Vector2(980.0, sy), Color(0.73, 0.70, 0.64), 2.0)
		sy -= 150.0
	wc.draw_rect(Rect2(980.0, ftop, 210.0, bottom - ftop), Color(0.76, 0.73, 0.66))
	wc.draw_rect(Rect2(1190.0, ctop, 510.0, bottom - ctop), Color(0.36, 0.35, 0.33))
	Passeig._roofs(m, vt, vb)
	_landmarks(m, vt, vb)
	for ps: Vector2 in m.palm_spots:
		if ps.y < vt - 60.0 or ps.y > vb + 60.0:
			continue
		var cut := Rect2(ps.x - 27.0, ps.y - 27.0, 54.0, 54.0)
		wc.draw_rect(cut, Color(0.62, 0.58, 0.50))
		wc.draw_rect(cut.grow(-5.0), Color(0.40, 0.34, 0.26))
		wc.draw_rect(cut, Color(0.34, 0.31, 0.27, 0.55), false, 2.0)
	wc.draw_line(Vector2(380.0, bottom), Vector2(380.0, ftop), Color(0.55, 0.45, 0.32), 3.0)
	wc.draw_line(Vector2(490.0, bottom), Vector2(490.0, ftop), m.COL_SEAM, 2.0)
	wc.draw_line(Vector2(570.0, bottom), Vector2(570.0, ftop), m.COL_SEAM, 2.0)
	wc.draw_line(Vector2(980.0, bottom), Vector2(980.0, ftop), m.COL_SEAM, 2.0)
	Passeig._sand_creep(m, wc, vt, vb)
	for t in m.tufts:
		if t.y > vt and t.y < vb and t.x > 110.0 and (t.x < 330.0 or t.x > 1000.0) and t.x < 1170.0:
			wc.draw_circle(t, 4.0, Color(0.78, 0.70, 0.54))
	for ti in range(m.towels.size()):
		if (m.towels[ti].rect as Rect2).end.y > vt - 40.0 and (m.towels[ti].rect as Rect2).position.y < vb + 40.0:
			Passeig._towel(m, m.towels[ti], ti)


static func _landmarks(m: Node2D, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22)
	for sp: Vector2 in LevelBuild.BEACH_SHOWERS:
		if sp.y > vt - 60.0 and sp.y < vb + 60.0:
			Passeig._access_ramp(m, b, 380.0, 345.0, sp.y, 32.0)
	var tw: Vector2 = LevelBuild.BEACH_TOWER
	if tw.y > vt - 120.0 and tw.y < vb + 80.0:
		Passeig._access_ramp(m, b, 380.0, 320.0, tw.y, 32.0)
	# Fòrum Photovoltaic Pergola (La Pèrgola Solar) on the eastern esplanade
	if Passeig._drawn_window(PERGOLA_RECT, vt, vb):
		b.rect(Rect2(PERGOLA_RECT.position + m.LIGHT * 22.0, PERGOLA_RECT.size), sh)
		for py: float in [PERGOLA_RECT.position.y + 70.0, PERGOLA_RECT.end.y - 70.0]:
			b.circle(Vector2(PERGOLA_RECT.position.x + 28.0, py) + m.LIGHT * 8.0, 12.0, sh)
			b.circle(Vector2(PERGOLA_RECT.position.x + 28.0, py), 11.0, Color(0.56, 0.58, 0.60))
		b.rect(PERGOLA_RECT, Color(0.14, 0.22, 0.38))
		b.rect(PERGOLA_RECT.grow(-6.0), Color(0.18, 0.32, 0.56))
		var sy := PERGOLA_RECT.position.y + 16.0
		while sy < PERGOLA_RECT.end.y - 8.0:
			b.line(Vector2(PERGOLA_RECT.position.x + 8.0, sy), Vector2(PERGOLA_RECT.end.x - 8.0, sy), Color(0.36, 0.54, 0.78, 0.65), 1.6)
			sy += 22.0
		var sx := PERGOLA_RECT.position.x + 36.0
		while sx < PERGOLA_RECT.end.x - 12.0:
			b.line(Vector2(sx, PERGOLA_RECT.position.y + 8.0), Vector2(sx, PERGOLA_RECT.end.y - 8.0), Color(0.62, 0.72, 0.84, 0.55), 1.4)
			sx += 36.0
	# Dog Rinse & Shade Station (Duxa de Gossos) before Platja dels Gossos
	if Passeig._drawn_window(DOG_SHOWER_RECT, vt, vb):
		b.rect(Rect2(DOG_SHOWER_RECT.position + m.LIGHT * 6.0, DOG_SHOWER_RECT.size), sh)
		b.rect(DOG_SHOWER_RECT, Color(0.56, 0.40, 0.26))
		b.rect(DOG_SHOWER_RECT.grow(-8.0), Color(0.34, 0.62, 0.74))
		b.circle(DOG_SHOWER_RECT.get_center(), 18.0, Color(0.22, 0.50, 0.64))
		b.circle(DOG_SHOWER_RECT.get_center(), 6.0, Color(0.76, 0.80, 0.84))
	b.flush(m._wc)
	if Passeig._drawn_window(LevelBuild.BEACH_COURT, vt, vb):
		Passeig._volley_court(m, LevelBuild.BEACH_COURT)
	for sp: Vector2 in LevelBuild.BEACH_SHOWERS:
		if sp.y > vt - 60.0 and sp.y < vb + 60.0:
			m._draw_beach_shower(m._wc, sp)
	if tw.y > vt - 120.0 and tw.y < vb + 80.0:
		m._draw_lifeguard_tower(m._wc, tw, true, false)


static func draw_overhead(m: Node2D, c: CanvasItem) -> void:
	m._draw_lifeguard_tower(c, LevelBuild.BEACH_TOWER, false, true)
	m._draw_lifeguard_tower(c, m.dog_beach_tower(), false, true)


static func surface(m: Node2D, p: Vector2) -> int:
	if p.x < SAND_TO_X:
		return Surfaces.S.SAND
	if p.y < m.GATE_Y - 30.0:
		return Surfaces.S.SAND
	return Surfaces.S.PAVEMENT


static func takes_prints(m: Node2D, p: Vector2) -> bool:
	var s: int = m.surface_at(p)
	if p.y < m.GATE_Y:
		return s != Surfaces.S.WATER
	return s == Surfaces.S.SAND


static func draw_bin(m: Node2D, c: Object, bn: Vector2) -> void:
	Passeig._recycling_station(m, c, bn)


static func rider_lane(_m: Node2D, _up: bool) -> Dictionary:
	var kid := randf() < 0.45
	var speed := randf_range(80.0, 130.0) if kid else randf_range(290.0, 420.0)
	if kid and randf() < 0.5:
		return {"kid": true, "speed": speed, "x": randf_range(590.0, 950.0), "lo": 575.0, "hi": 960.0}
	return {"kid": kid, "speed": speed, "x": randf_range(492.0, 552.0), "lo": 486.0, "hi": 554.0}
