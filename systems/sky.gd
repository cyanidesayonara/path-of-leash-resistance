extends RefCounted

# The sky over a walk: the world's tint, the grade the weather and the hour lay
# over the mood's, and the colour a light has to be drawn in so it still reads
# as light under that tint. Pure functions of the weather, the hour and the
# walk; main.gd and mood_wiring.gd apply them.

# The world's CanvasModulate. Night is deep blue rather than a grey-lavender
# wash, so a lamp pool reads as light against it; the lights themselves are
# drawn through light() and stay warm.
const NIGHT := Color(0.42, 0.47, 0.66)
# L'Estacio is a lit mainline concourse: night keeps indoor lighting rather than
# turning it into a dark street.
const STATION_NIGHT := Color(0.92, 0.92, 0.95)
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
# toward the sun. `mist` is how thick the morning haze lies. `haze` lifts the
# shadows per channel toward a coloured veil (the calima's dust); a grade that
# does not name it leaves it at none.
const NONE := {
	"k_sat": 1.0, "k_con": 1.0, "k_exp": 1.0, "add_vig": 0.0, "add_lift": 0.0,
	"k_tint": Vector3.ONE, "k_cool": Vector3.ONE, "k_warm": Vector3.ONE, "wet": 0.0,
	"sun": Vector3.ZERO, "shade": Vector3.ZERO, "sun_dir": Vector2.ZERO, "mist": 0.0, "haze": Vector3.ZERO,
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
const GRADE_STATION_NIGHT := {
	"k_sat": 0.96, "k_con": 1.02, "k_exp": 1.0, "add_vig": 0.03, "add_lift": 0.0,
	"k_tint": Vector3.ONE, "k_cool": Vector3(0.98, 0.99, 1.02), "k_warm": Vector3(1.02, 1.0, 0.98), "wet": 0.0,
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


# The skies (Game.SKIES) beyond the four kinds: a grade of their own, laid
# over the kind's at the sky's strength.
const FOG := Color(0.93, 0.94, 0.96)
const STORM := Color(0.86, 0.88, 0.94)
# The blue hour: the sun gone, the sky still lit, deeper and bluer than dusk
# and brighter than night, the lamps already on. Morning: a low, clean sun
# from the east side of the screen, warm but not gold, the mist burned off.
const EVENING := Color(0.72, 0.72, 0.92)
const MORNING := Color(1.0, 0.98, 0.94)
# fog: colour and contrast drain, the whole street lifts toward a pale grey,
# and the banks of mist lie over everything
const GRADE_FOG := {
	"k_sat": 0.80, "k_con": 0.84, "k_exp": 1.03, "add_vig": 0.06, "add_lift": 0.07,
	"k_tint": Vector3(0.99, 1.0, 1.02), "k_cool": Vector3(0.98, 1.0, 1.04), "k_warm": Vector3.ONE, "wet": 0.3,
	"sun": Vector3.ZERO, "shade": Vector3.ZERO, "sun_dir": Vector2.ZERO, "mist": 1.7,
}
# a storm on top of the rain: darker, heavier at the edges
const GRADE_STORM := {
	"k_sat": 0.92, "k_con": 1.04, "k_exp": 0.90, "add_vig": 0.10, "add_lift": 0.0,
	"k_tint": Vector3(0.98, 0.99, 1.03), "k_cool": Vector3(0.96, 0.99, 1.06), "k_warm": Vector3.ONE, "wet": 1.0,
	"sun": Vector3.ZERO, "shade": Vector3.ZERO, "sun_dir": Vector2.ZERO, "mist": 0.0,
}
const GRADE_MORNING := {
	"k_sat": 1.0, "k_con": 1.02, "k_exp": 1.01, "add_vig": 0.04, "add_lift": 0.0,
	"k_tint": Vector3.ONE, "k_cool": Vector3(0.97, 0.99, 1.05), "k_warm": Vector3(1.05, 1.02, 0.95), "wet": 0.0,
	"sun": Vector3(0.20, 0.15, 0.06), "shade": Vector3(0.05, 0.05, 0.02), "sun_dir": Vector2(-1.0, 0.35), "mist": 0.0,
}
const GRADE_EVENING := {
	"k_sat": 0.92, "k_con": 1.04, "k_exp": 1.02, "add_vig": 0.10, "add_lift": 0.02,
	"k_tint": Vector3.ONE, "k_cool": Vector3(0.94, 0.98, 1.10), "k_warm": Vector3(1.10, 1.0, 0.88), "wet": 0.0,
	"sun": Vector3(0.16, 0.04, 0.12), "shade": Vector3(0.05, 0.06, 0.0), "sun_dir": Vector2(1.0, -0.2), "mist": 0.0,
}
# the calima: Sahara dust in the air. By day an ochre haze, the shadows lifted
# into it, contrast and colour lost; after dark the lamps' sodium light caught
# in the dust, a dim orange murk instead of the night's blue. Both lie over
# the hour's look at the sky's dust (Game.dust_amount).
const CALIMA := Color(1.0, 0.88, 0.72)
const CALIMA_NIGHT := Color(0.50, 0.38, 0.26)
const GRADE_CALIMA := {
	"k_sat": 0.80, "k_con": 0.84, "k_exp": 0.98, "add_vig": 0.06, "add_lift": 0.0,
	"k_tint": Vector3(1.03, 0.98, 0.90), "k_cool": Vector3(1.05, 0.99, 0.88), "k_warm": Vector3(1.06, 0.98, 0.82), "wet": 0.0,
	"sun": Vector3.ZERO, "shade": Vector3.ZERO, "sun_dir": Vector2.ZERO, "mist": 0.0,
	"haze": Vector3(0.13, 0.09, 0.04),
}
# after dark the night's blue shadows are turned back to orange
const GRADE_CALIMA_NIGHT := {
	"k_sat": 0.84, "k_con": 0.90, "k_exp": 1.0, "add_vig": 0.04, "add_lift": 0.0,
	"k_tint": Vector3(1.05, 0.96, 0.82), "k_cool": Vector3(1.10, 0.99, 0.84), "k_warm": Vector3(1.04, 0.98, 0.86), "wet": 0.0,
	"sun": Vector3.ZERO, "shade": Vector3.ZERO, "sun_dir": Vector2.ZERO, "mist": 0.0,
	"haze": Vector3(0.05, 0.03, 0.01),
}
const GameScript := preload("res://autoload/game.gd")


# the time as a string; true and false still mean night and day
static func _hour(hour: Variant) -> String:
	if hour is bool:
		return "night" if hour else "day"
	return String(hour)


# a sky's entry (Game.SKY); a kind's name is its own sky
static func _sky(weather: String) -> Dictionary:
	return GameScript.SKY.get(weather, GameScript.SKY.clear)


# a grade at a fraction of its strength: every change eased back toward none
static func _scaled(g: Dictionary, k: float) -> Dictionary:
	var o := {}
	for key: String in NONE:
		var v: Variant = g.get(key, NONE[key])
		var none: Variant = NONE[key]
		if v is float:
			o[key] = lerpf(float(none), float(v), k)
		elif v is Vector3 or v is Vector2:
			o[key] = none.lerp(v, k)
		else:
			o[key] = v
	return o


# how strongly the sky shows its kind's look: a drizzle is a light rain, a
# breeze a soft wind
static func _kind_k(sky: Dictionary) -> float:
	match String(sky.kind):
		"rain": return clampf(0.35 + 0.65 * float(sky.rain), 0.0, 1.0)
		"wind": return float(sky.wind)
	return 1.0


static func tint(lvl: String, weather: String, hour: Variant) -> Color:
	var c := Color.WHITE
	match _hour(hour):
		"night": c = STATION_NIGHT if lvl == "station" else NIGHT
		"evening": c = STATION_NIGHT if lvl == "station" else EVENING
		"dawn": c = DAWN
		"morning": c = MORNING
		"dusk": c = DUSK
	var sk := _sky(weather)
	var k := _kind_k(sk)
	match String(sk.kind):
		"rain": c = c * Color.WHITE.lerp(RAIN, k)
		"wind": c = c * Color.WHITE.lerp(WIND, k)
		"snow": c = c * SNOW
	if weather == "storm":
		c = c * STORM
	if float(sk.fog) > 0.0:
		c = c * Color.WHITE.lerp(FOG, float(sk.fog))
	var dust := float(sk.get("dust", 0.0))
	if dust > 0.0:
		if _dark(lvl, hour):
			c = c.lerp(CALIMA_NIGHT, dust * 0.8)
		else:
			c = c * Color.WHITE.lerp(CALIMA, dust)
	return c


# a dark street: night and the blue hour, except the lit station concourse
static func _dark(lvl: String, hour: Variant) -> bool:
	var h := _hour(hour)
	return (h == "night" or h == "evening") and lvl != "station"


# the weather's and the hour's changes to the grade, combined. Under rain,
# snow, fog or a storm the low sun is behind the cloud: most of its side light
# goes; in a calima much of it.
static func grade_mod(lvl: String, weather: String, hour: Variant) -> Dictionary:
	var out: Dictionary = NONE.duplicate()
	var sk := _sky(weather)
	var k := _kind_k(sk)
	match String(sk.kind):
		"rain": out = _stack(out, _scaled(GRADE_RAIN, k))
		"wind": out = _stack(out, _scaled(GRADE_WIND, k))
		"snow": out = _stack(out, GRADE_SNOW)
	if weather == "storm":
		out = _stack(out, GRADE_STORM)
	var fog := float(sk.fog)
	if fog > 0.0:
		out = _stack(out, _scaled(GRADE_FOG, fog))
	match _hour(hour):
		"night": out = _stack(out, GRADE_STATION_NIGHT if lvl == "station" else GRADE_NIGHT)
		"evening": out = _stack(out, GRADE_STATION_NIGHT if lvl == "station" else GRADE_EVENING)
		"dawn": out = _stack(out, GRADE_DAWN)
		"morning": out = _stack(out, GRADE_MORNING)
		"dusk": out = _stack(out, GRADE_DUSK)
	var dust := float(sk.get("dust", 0.0))
	if dust > 0.0:
		out = _stack(out, _scaled(GRADE_CALIMA_NIGHT if _dark(lvl, hour) else GRADE_CALIMA, dust))
	# the dust veils a low sun to a pale disc: its side light goes soft
	var cloud := 1.0 if String(sk.kind) == "rain" or String(sk.kind) == "snow" else maxf(fog, dust * 0.6)
	if cloud > 0.0:
		var keep := lerpf(1.0, 0.3, cloud)
		out["sun"] = (out["sun"] as Vector3) * keep
		out["shade"] = (out["shade"] as Vector3) * keep
	return out


static func _stack(a: Dictionary, b: Dictionary) -> Dictionary:
	var o := {}
	for k: String in NONE:
		var av: Variant = a.get(k, NONE[k])
		var bv: Variant = b.get(k, NONE[k])
		if k.begins_with("add_"):
			o[k] = float(av) + float(bv)
		elif k == "sun" or k == "shade" or k == "haze":
			o[k] = (av as Vector3) + (bv as Vector3)
		elif k == "sun_dir":
			o[k] = bv if (bv as Vector2) != Vector2.ZERO else av
		elif k == "wet" or k == "mist":
			o[k] = maxf(float(av), float(bv))
		else:
			o[k] = av * bv
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
		"haze": s.get("haze", Vector3.ZERO),
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
	gm.set_shader_parameter("haze", g.get("haze", Vector3.ZERO))


# The colour to draw a light in so it shows as `col` once the world's tint
# multiplies it: over 1.0 on the channels the tint takes away.
static func light(col: Color, t: Color) -> Color:
	return Color(col.r / maxf(t.r, 0.05), col.g / maxf(t.g, 0.05), col.b / maxf(t.b, 0.05), col.a)
