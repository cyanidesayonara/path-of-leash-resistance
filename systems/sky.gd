extends RefCounted

# The sky over a walk: the world's tint, the grade the weather and the hour lay
# over the mood's, and the colour a light has to be drawn in so it still reads
# as light under that tint. Pure functions of the weather, the hour and the
# walk; main.gd and mood_wiring.gd apply them.

# The world's CanvasModulate. Night is deep blue rather than a grey-lavender
# wash, so a lamp pool reads as light against it; the lights themselves are
# drawn through light() and stay warm.
const NIGHT := Color(0.42, 0.47, 0.66)
# First light: the sun is barely up, so the street is still dim and blue, and
# the gold comes only from the sun's side (the grade's sun, below).
const DAWN := Color(0.86, 0.84, 0.94)
# Golden hour: the whole street warm, the low sun from the other side.
const DUSK := Color(1.0, 0.89, 0.80)
const RAIN := Color(0.74, 0.78, 0.84)
const WIND := Color(0.95, 0.91, 0.82)
const SNOW := Color(0.93, 0.97, 1.04)

# What the weather and the hour do to the grade, as changes to whatever the
# mood asks for: k_ multiplies, add_ adds. A clear day changes nothing, so
# the shipped look and every mood's look are exactly what they were.
# The low sun: `sun` brightens the screen's sun side by that much per channel,
# `shade` darkens the far side, `sun_dir` points from the middle of the screen
# toward the sun. `mist` is how thick the morning haze lies.
const NONE := {
	"k_sat": 1.0, "k_con": 1.0, "k_exp": 1.0, "add_vig": 0.0, "add_lift": 0.0,
	"k_tint": Vector3.ONE, "k_cool": Vector3.ONE, "k_warm": Vector3.ONE, "wet": 0.0,
	"sun": Vector3.ZERO, "shade": Vector3.ZERO, "sun_dir": Vector2.ZERO, "mist": 0.0,
}
# overcast: colour drains, the ground darkens and shines, the light goes grey-blue
const GRADE_RAIN := {
	"k_sat": 0.84, "k_con": 1.08, "k_exp": 0.96, "add_vig": 0.10, "add_lift": 0.0,
	"k_tint": Vector3(0.97, 1.0, 1.04), "k_cool": Vector3(0.96, 1.0, 1.06), "k_warm": Vector3(0.98, 1.0, 1.02), "wet": 1.0,
	"sun": Vector3.ZERO, "shade": Vector3.ZERO, "sun_dir": Vector2.ZERO, "mist": 0.0,
}
# a dry, dusty wind: warm haze in the highlights, a little contrast lost
const GRADE_WIND := {
	"k_sat": 0.94, "k_con": 0.96, "k_exp": 1.02, "add_vig": 0.04, "add_lift": 0.03,
	"k_tint": Vector3(1.03, 1.0, 0.95), "k_cool": Vector3.ONE, "k_warm": Vector3(1.04, 1.01, 0.94), "wet": 0.0,
	"sun": Vector3.ZERO, "shade": Vector3.ZERO, "sun_dir": Vector2.ZERO, "mist": 0.0,
}
# snow light: bright, cold, low-contrast, with the shadows gone blue
const GRADE_SNOW := {
	"k_sat": 0.90, "k_con": 0.94, "k_exp": 1.05, "add_vig": 0.0, "add_lift": 0.05,
	"k_tint": Vector3(0.98, 1.0, 1.03), "k_cool": Vector3(0.94, 0.99, 1.10), "k_warm": Vector3.ONE, "wet": 0.0,
	"sun": Vector3.ZERO, "shade": Vector3.ZERO, "sun_dir": Vector2.ZERO, "mist": 0.0,
}
# night: moonlit shadows, a closer vignette, and enough lift that the
# ground keeps its shape between the lamps
const GRADE_NIGHT := {
	"k_sat": 0.78, "k_con": 1.08, "k_exp": 1.0, "add_vig": 0.22, "add_lift": 0.015,
	"k_tint": Vector3.ONE, "k_cool": Vector3(0.95, 0.98, 1.05), "k_warm": Vector3(1.08, 1.0, 0.90), "wet": 0.0,
	"sun": Vector3.ZERO, "shade": Vector3.ZERO, "sun_dir": Vector2.ZERO, "mist": 0.0,
}
# dawn: blue shadows, gold only where the low sun reaches (from the left,
# the sea's side on the beach), the far side still in the night's shade, and a mist lying in
# the street that the sun has not burned off yet
const GRADE_DAWN := {
	"k_sat": 0.92, "k_con": 1.03, "k_exp": 0.98, "add_vig": 0.10, "add_lift": 0.01,
	"k_tint": Vector3.ONE, "k_cool": Vector3(0.93, 0.96, 1.10), "k_warm": Vector3(1.10, 1.01, 0.86), "wet": 0.0,
	"sun": Vector3(0.42, 0.24, 0.02), "shade": Vector3(0.08, 0.07, 0.0), "sun_dir": Vector2(-1.0, 0.3), "mist": 1.0,
}
# dusk: golden hour, warm everywhere, the sun low from the right and the far
# side going violet. Gentle: a walk's own warm ground does the rest.
const GRADE_DUSK := {
	"k_sat": 1.0, "k_con": 1.04, "k_exp": 1.0, "add_vig": 0.10, "add_lift": 0.0,
	"k_tint": Vector3.ONE, "k_cool": Vector3(1.02, 0.95, 1.07), "k_warm": Vector3(1.08, 1.01, 0.90), "wet": 0.0,
	"sun": Vector3(0.20, 0.08, -0.03), "shade": Vector3(0.10, 0.12, 0.03), "sun_dir": Vector2(1.0, -0.25), "mist": 0.0,
}


# the hour as a string; true and false still mean night and day
static func _hour(hour: Variant) -> String:
	if hour is bool:
		return "night" if hour else "day"
	return String(hour)


static func tint(_lvl: String, weather: String, hour: Variant) -> Color:
	var c := Color.WHITE
	match _hour(hour):
		"night": c = NIGHT
		"dawn": c = DAWN
		"dusk": c = DUSK
	match weather:
		"rain": c = c * RAIN
		"wind": c = c * WIND
		"snow": c = c * SNOW
	return c


# the weather's and the hour's changes to the grade, combined. Under rain or
# snow the low sun is behind the cloud: most of its side light goes.
static func grade_mod(_lvl: String, weather: String, hour: Variant) -> Dictionary:
	var out: Dictionary = NONE.duplicate()
	match weather:
		"rain": out = _stack(out, GRADE_RAIN)
		"wind": out = _stack(out, GRADE_WIND)
		"snow": out = _stack(out, GRADE_SNOW)
	match _hour(hour):
		"night": out = _stack(out, GRADE_NIGHT)
		"dawn": out = _stack(out, GRADE_DAWN)
		"dusk": out = _stack(out, GRADE_DUSK)
	if weather == "rain" or weather == "snow":
		out["sun"] = (out["sun"] as Vector3) * 0.3
		out["shade"] = (out["shade"] as Vector3) * 0.3
	return out


static func _stack(a: Dictionary, b: Dictionary) -> Dictionary:
	var o := {}
	for k: String in a:
		if k.begins_with("add_"):
			o[k] = float(a[k]) + float(b[k])
		elif k == "sun" or k == "shade":
			o[k] = (a[k] as Vector3) + (b[k] as Vector3)
		elif k == "sun_dir":
			o[k] = b[k] if (b[k] as Vector2) != Vector2.ZERO else a[k]
		elif k == "wet" or k == "mist":
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
		"sun": s["sun"], "shade": s["shade"], "sun_dir": s["sun_dir"], "mist": s["mist"],
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
	var sd: Vector2 = g.get("sun_dir", Vector2.ZERO)
	gm.set_shader_parameter("sun_dir", sd.normalized() if sd != Vector2.ZERO else Vector2.RIGHT)
	gm.set_shader_parameter("sun_col", g.get("sun", Vector3.ZERO))
	gm.set_shader_parameter("sun_shade", g.get("shade", Vector3.ZERO))
	gm.set_shader_parameter("mist", g.get("mist", 0.0))


# The colour to draw a light in so it shows as `col` once the world's tint
# multiplies it: over 1.0 on the channels the tint takes away.
static func light(col: Color, t: Color) -> Color:
	return Color(col.r / maxf(t.r, 0.05), col.g / maxf(t.g, 0.05), col.b / maxf(t.b, 0.05), col.a)
