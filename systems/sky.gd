extends RefCounted

# The sky over a walk: the world's tint, the grade the weather and the hour lay
# over the mood's, and the colour a light has to be drawn in so it still reads
# as light under that tint. Pure functions of the weather, the hour and the
# walk; main.gd and mood_wiring.gd apply them.

# The world's CanvasModulate. Night is deep blue rather than a grey-lavender
# wash, so a lamp pool reads as light against it; the lights themselves are
# drawn through light() and stay warm.
const NIGHT := Color(0.42, 0.47, 0.66)
const DAWN := Color(1.0, 0.86, 0.78)
const RAIN := Color(0.74, 0.78, 0.84)
const WIND := Color(0.95, 0.91, 0.82)
const SNOW := Color(0.93, 0.97, 1.04)

# What the weather and the hour do to the grade, as changes to whatever the
# mood asks for: k_ multiplies, add_ adds. A clear day changes nothing, so
# the shipped look and every mood's look are exactly what they were.
const NONE := {
	"k_sat": 1.0, "k_con": 1.0, "k_exp": 1.0, "add_vig": 0.0, "add_lift": 0.0,
	"k_tint": Vector3.ONE, "k_cool": Vector3.ONE, "k_warm": Vector3.ONE, "wet": 0.0,
}
# overcast: colour drains, the ground darkens and shines, the light goes grey-blue
const GRADE_RAIN := {
	"k_sat": 0.84, "k_con": 1.08, "k_exp": 0.96, "add_vig": 0.10, "add_lift": 0.0,
	"k_tint": Vector3(0.97, 1.0, 1.04), "k_cool": Vector3(0.96, 1.0, 1.06), "k_warm": Vector3(0.98, 1.0, 1.02), "wet": 1.0,
}
# a dry, dusty wind: warm haze in the highlights, a little contrast lost
const GRADE_WIND := {
	"k_sat": 0.94, "k_con": 0.96, "k_exp": 1.02, "add_vig": 0.04, "add_lift": 0.03,
	"k_tint": Vector3(1.03, 1.0, 0.95), "k_cool": Vector3.ONE, "k_warm": Vector3(1.04, 1.01, 0.94), "wet": 0.0,
}
# snow light: bright, cold, low-contrast, with the shadows gone blue
const GRADE_SNOW := {
	"k_sat": 0.90, "k_con": 0.94, "k_exp": 1.05, "add_vig": 0.0, "add_lift": 0.05,
	"k_tint": Vector3(0.98, 1.0, 1.03), "k_cool": Vector3(0.94, 0.99, 1.10), "k_warm": Vector3.ONE, "wet": 0.0,
}
# night: moonlit shadows, a closer vignette, and enough lift that the
# ground keeps its shape between the lamps
const GRADE_NIGHT := {
	"k_sat": 0.78, "k_con": 1.08, "k_exp": 1.0, "add_vig": 0.22, "add_lift": 0.015,
	"k_tint": Vector3.ONE, "k_cool": Vector3(0.95, 0.98, 1.05), "k_warm": Vector3(1.08, 1.0, 0.90), "wet": 0.0,
}
# La Neteja's dawn: low gold light and long pink shadows
const GRADE_DAWN := {
	"k_sat": 1.04, "k_con": 1.02, "k_exp": 1.0, "add_vig": 0.06, "add_lift": 0.0,
	"k_tint": Vector3.ONE, "k_cool": Vector3(1.03, 0.94, 1.04), "k_warm": Vector3(1.08, 1.0, 0.88), "wet": 0.0,
}


static func tint(lvl: String, weather: String, night: bool) -> Color:
	var c := NIGHT if night else Color.WHITE
	if lvl == "neteja" and not night:
		c = DAWN
	match weather:
		"rain": c = c * RAIN
		"wind": c = c * WIND
		"snow": c = c * SNOW
	return c


static func is_dawn(lvl: String, night: bool) -> bool:
	return lvl == "neteja" and not night


# the weather's and the hour's changes to the grade, combined
static func grade_mod(lvl: String, weather: String, night: bool) -> Dictionary:
	var out: Dictionary = NONE.duplicate()
	match weather:
		"rain": out = _stack(out, GRADE_RAIN)
		"wind": out = _stack(out, GRADE_WIND)
		"snow": out = _stack(out, GRADE_SNOW)
	if night:
		out = _stack(out, GRADE_NIGHT)
	elif is_dawn(lvl, night):
		out = _stack(out, GRADE_DAWN)
	return out


static func _stack(a: Dictionary, b: Dictionary) -> Dictionary:
	var o := {}
	for k: String in a:
		if k.begins_with("add_"):
			o[k] = float(a[k]) + float(b[k])
		elif k == "wet":
			o[k] = maxf(float(a[k]), float(b[k]))
		else:
			o[k] = a[k] * b[k]
	return o


# the mood's grade (mood.gd's keys) with the sky's changes laid over it
static func compose(g: Dictionary, s: Dictionary) -> Dictionary:
	return {
		"sat": float(g["sat"]) * float(s["k_sat"]),
		"con": float(g["con"]) * float(s["k_con"]),
		"vig": float(g["vig"]) + float(s["add_vig"]),
		"tight": g["tight"],
		"exp": float(g["exp"]) * float(s["k_exp"]),
		"tint": (g["tint"] as Vector3) * (s["k_tint"] as Vector3),
		"lift": float(g["lift"]) + float(s["add_lift"]),
		"cool": (g["cool"] as Vector3) * (s["k_cool"] as Vector3),
		"warm": (g["warm"] as Vector3) * (s["k_warm"] as Vector3),
		"wet": s["wet"],
	}


static func apply(gm: ShaderMaterial, g: Dictionary) -> void:
	gm.set_shader_parameter("saturation", g["sat"])
	gm.set_shader_parameter("contrast", g["con"])
	gm.set_shader_parameter("vignette", g["vig"])
	gm.set_shader_parameter("vignette_tight", g["tight"])
	gm.set_shader_parameter("exposure", g["exp"])
	gm.set_shader_parameter("tint", g["tint"])
	gm.set_shader_parameter("lift", g["lift"])
	gm.set_shader_parameter("cool_shadows", g["cool"])
	gm.set_shader_parameter("warm_light", g["warm"])
	gm.set_shader_parameter("wet", g["wet"])


# The colour to draw a light in so it shows as `col` once the world's tint
# multiplies it: over 1.0 on the channels the tint takes away.
static func light(col: Color, t: Color) -> Color:
	return Color(col.r / maxf(t.r, 0.05), col.g / maxf(t.g, 0.05), col.b / maxf(t.b, 0.05), col.a)
