extends Node2D

# The walk's lamps at night, over the dog, the owner and everything on the
# ground, so whoever walks into a pool of light is lit by it, and under the
# tree crowns, which a street lamp does not light from below. The pools are
# drawn through SkyLook.light() so they stay warm under the night's blue tint. In
# the rain each lamp also lies in the wet paving as a long reflection.
#
# The lamps never move: this redraws only when the camera has gone far enough
# that a lamp near the edge would come into view, or when the sky changes.

const SkyLook := preload("res://systems/sky.gd")
const REDRAW_STEP := 160.0
const MARGIN := 420.0
const RINGS := 9
const REFLECT_BITS := 7
const WARM := Color(1.0, 0.84, 0.56)
const BULB := Color(1.0, 0.96, 0.84)

var main: Node2D
var _drawn_at := Vector2(INF, INF)
var _drawn_sky := ""


func setup(m: Node2D) -> void:
	main = m


func _process(_delta: float) -> void:
	if main == null or main.cam == null:
		return
	var sky := "%s|%s" % [Game.weather, Game.night]
	if sky != _drawn_sky or main.cam.position.distance_to(_drawn_at) > REDRAW_STEP:
		_drawn_sky = sky
		_drawn_at = main.cam.position
		queue_redraw()


func _draw() -> void:
	if main == null or not Game.night:
		return
	var tint: Color = main.night_cm.color
	var wet: bool = Game.weather == "rain"
	var c: Vector2 = _drawn_at
	var half: Vector2 = get_viewport_rect().size * 0.5 / maxf(main.cam.zoom.x, 0.01) + Vector2(MARGIN, MARGIN)
	var b := ShapeBatch.new(self)
	for l: Vector3 in main.night_lights():
		if absf(l.x - c.x) > half.x or absf(l.y - c.y) > half.y:
			continue
		var at := Vector2(l.x, l.y)
		var r := l.z
		# many thin rings: a smooth falloff instead of visible banding
		for ring in range(RINGS):
			var f := float(ring) / float(RINGS - 1)
			b.circle(at, lerpf(r, r * 0.14, f), SkyLook.light(Color(WARM.r, WARM.g, WARM.b, 0.014 + f * f * 0.095), tint))
		if wet:
			# the lamp in the wet paving: a long soft streak toward the viewer
			# that breaks up and fades as it comes away from the lamp
			for k in range(REFLECT_BITS):
				var f := float(k) / float(REFLECT_BITS)
				var w := lerpf(9.0, 3.0, f) * (0.8 + 0.4 * absf(sin(float(k) * 2.3 + l.x)))
				var y0 := at.y + 6.0 + f * r * 0.9
				b.rect(Rect2(at.x - w * 0.5, y0, w, r * 0.9 / float(REFLECT_BITS) - 2.0),
					SkyLook.light(Color(1.0, 0.88, 0.62, 0.16 * (1.0 - f)), tint))
		if r < main.NIGHT_LAMP_R:
			# a wall lamp: the bracket and the lit glass
			b.circle(at, 5.0, Color(0.16, 0.15, 0.17))
			b.circle(at, 3.4, SkyLook.light(BULB, tint))
			b.circle(at, 8.0, SkyLook.light(Color(BULB.r, BULB.g, BULB.b, 0.30), tint))
	b.flush()
