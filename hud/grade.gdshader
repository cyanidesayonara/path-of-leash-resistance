shader_type canvas_item;

// Post-process for the world layer. Two jobs:
//
// 1. GRADE - split-toning (cool shadows, warm light), contrast, saturation,
//    a soft vignette and a black-lift so night never turns to unreadable
//    murk.
// 2. SURFACE - texture on the ground, by what the ground is. Flat colour
//    fills are what make procedural art read as cheap, but one noise laid
//    over everything (it was a 2 px speckle and soft blotches on every pixel)
//    reads as crayon on paper: water, timber and lawn all had the same tooth.
//    So the colour under each pixel picks a material - water, grass, sand,
//    timber and dirt, stone and paving - and each gets its own: a slow
//    shimmer, blades and clumps, fine grains and ripples, a grain along the
//    timber, aggregate and stains. It only goes on broad flat fills (a pixel
//    that differs from its neighbours is an edge, a person or a prop), so
//    everything drawn ON the ground stays crisp. Keyed to WORLD position, so
//    it sits on the ground rather than sliding over it.
//
// All of it is GPU work, so it costs the CPU-bound web build nothing.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
// the screen's top-left in world units, and the view's size in world units
// (the viewport over the camera zoom), so world position is exact at any
// zoom and window shape
uniform vec2 cam_off = vec2(0.0, 0.0);
uniform vec2 view_px = vec2(1000.0, 562.5);
uniform vec3 cool_shadows = vec3(0.90, 0.95, 1.09);
uniform vec3 warm_light = vec3(1.07, 1.01, 0.93);
uniform float saturation = 1.12;
uniform float contrast = 1.05;
uniform float vignette = 0.26;
// how fast the vignette closes in from the edge. The ordinary grade wants a
// wide, barely-there darkening; a mood wants to genuinely SHORTEN what you can
// see, and that is a tighter falloff rather than simply a darker one - turning
// vignette up alone just dims the whole picture evenly and reads as a fade.
uniform float vignette_tight = 1.6;
// a flat colour cast over everything, for moods that recolour the world
// wholesale rather than nudging its split-tone (seeing red).
uniform vec3 tint = vec3(1.0, 1.0, 1.0);
// scales the whole picture's brightness. Fright makes the street DARK, and
// darkness has to come off the light itself, not out of the black lift.
uniform float exposure = 1.0;
uniform float lift = 0.055;
// rain on the ground, 0 to 1: soaked mid-tones go darker and richer, and
// world-locked patches of sheen catch the sky like standing water
uniform float wet = 0.0;
// how much surface texture, 0 to 1
uniform float surface = 1.0;
// the world's animation clock in seconds (AnimClock, pinned in shot mode)
uniform float world_t = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// value noise, so the blotches have soft edges instead of hard cells
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// two octaves, centred on zero
float fbm(vec2 p) {
	return (vnoise(p) * 0.65 + vnoise(p * 2.3 + 17.0) * 0.35) - 0.5;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 col = texture(screen_tex, uv).rgb;

	// world position of this pixel, for texture that stays put on the ground
	vec2 wp = uv * view_px + cam_off;

	float lum = dot(col, vec3(0.299, 0.587, 0.114));

	// --- surface texture ---
	// flat: how alike this pixel and its neighbours two pixels out are
	vec2 px = SCREEN_PIXEL_SIZE * 2.0;
	vec3 n1 = texture(screen_tex, uv + vec2(px.x, 0.0)).rgb;
	vec3 n2 = texture(screen_tex, uv - vec2(px.x, 0.0)).rgb;
	vec3 n3 = texture(screen_tex, uv + vec2(0.0, px.y)).rgb;
	vec3 n4 = texture(screen_tex, uv - vec2(0.0, px.y)).rgb;
	vec3 dmax = max(max(abs(n1 - col), abs(n2 - col)), max(abs(n3 - col), abs(n4 - col)));
	float flat_fill = 1.0 - smoothstep(0.025, 0.09, max(max(dmax.r, dmax.g), dmax.b));
	// hold texture off the darkest and brightest ends so it reads as
	// surface, not as noise laid over silhouettes
	float tex_mask = smoothstep(0.04, 0.26, lum) * (1.0 - smoothstep(0.80, 0.98, lum)) * surface;

	// what the ground is, from its colour; the weights overlap softly
	float hi_c = max(max(col.r, col.g), col.b);
	float lo_c = min(min(col.r, col.g), col.b);
	float sat = (hi_c - lo_c) / max(hi_c, 0.001);
	float w_water = smoothstep(0.06, 0.16, col.b - col.r) * smoothstep(-0.10, 0.02, col.g - col.r);
	// olive and yellow-green lawns count: green need only edge out red
	float w_grass = smoothstep(-0.02, 0.04, col.g - col.r) * smoothstep(0.04, 0.10, col.g - col.b) * (1.0 - w_water);
	float warm = smoothstep(0.10, 0.22, col.r - col.b) * (1.0 - w_grass) * (1.0 - w_water);
	float w_sand = warm * smoothstep(0.50, 0.66, lum);
	float w_wood = warm * (1.0 - smoothstep(0.42, 0.58, lum));
	float w_stone = (1.0 - smoothstep(0.08, 0.20, sat)) * (1.0 - w_water) * (1.0 - warm);
	float w_other = clamp(1.0 - w_water - w_grass - w_sand - w_wood - w_stone, 0.0, 1.0);

	vec3 t = vec3(0.0);
	// stone and paving: aggregate - sparse dark and light chips, not an even
	// speckle - and broad stains of wear and weather
	float chip = hash(floor(wp * 0.9));
	float agg = (chip > 0.94 ? -0.06 : 0.0) + (chip < 0.035 ? 0.045 : 0.0);
	t += w_stone * vec3(agg + fbm(wp / 95.0) * 0.075 + fbm(wp / 26.0) * 0.03 + fbm(wp / 7.0) * 0.022);
	// grass: short blades (noise stretched one way), and clumps that lean
	// yellow or blue-green
	float blade = (vnoise(wp * vec2(1.1, 0.5)) - 0.5) * 0.7 + (hash(floor(wp * vec2(1.0, 0.5))) - 0.5) * 0.3;
	float clump = fbm(wp / 42.0);
	float patch = fbm(wp / 150.0);
	t += w_grass * (vec3(blade * 0.05) + clump * vec3(0.06, 0.07, -0.015) + patch * vec3(0.05, 0.035, -0.02));
	// sand and gravel: fine grains, a sparse scatter of darker and paler
	// pebbles, and a slow drift in tone. (Wind ripples were tried: they put
	// dunes on every gravel path and sidewalk of the same colour.)
	float grain = hash(floor(wp * 1.3)) - 0.5;
	float pebble = hash(floor(wp * 0.45) + 31.0);
	float peb = (pebble > 0.95 ? -0.05 : 0.0) + (pebble < 0.03 ? 0.04 : 0.0);
	t += w_sand * vec3(grain * 0.04 + peb + fbm(wp / 60.0) * 0.035);
	// timber and dirt: a grain run one way, and darker knots of wear
	float streak = vnoise(wp * vec2(0.07, 0.75)) - 0.5;
	t += w_wood * vec3(streak * 0.05 + fbm(wp / 30.0) * 0.03);
	// water: no tooth at all, a slow shimmer of light on it
	float sh = vnoise(wp / 11.0 + vec2(world_t * 0.35, world_t * 0.12)) * vnoise(wp / 15.0 - vec2(world_t * 0.22, -world_t * 0.15));
	t += w_water * vec3(0.7, 0.85, 1.0) * smoothstep(0.36, 0.6, sh) * 0.045;
	// anything else: a soft tonal drift
	t += w_other * vec3(fbm(wp / 50.0) * 0.035);
	col += t * tex_mask * flat_fill;

	if (wet > 0.0) {
		float mid = smoothstep(0.08, 0.35, lum) * (1.0 - smoothstep(0.65, 0.92, lum));
		col *= 1.0 - 0.12 * wet * mid;
		// standing water: long soft patches, stretched along the walk
		float pool = smoothstep(0.60, 0.78, vnoise(wp * vec2(1.0 / 70.0, 1.0 / 150.0)));
		float rip = 0.75 + 0.25 * vnoise(wp / 9.0);
		col += vec3(0.55, 0.62, 0.72) * pool * rip * mid * wet * 0.10;
	}

	// --- grade ---
	col *= mix(cool_shadows, warm_light, smoothstep(0.15, 0.85, lum));
	col = (col - 0.5) * contrast + 0.5;
	col = mix(vec3(lum), col, saturation);

	// lift the blacks so shadowed ground keeps its shape at night
	col += lift * (1.0 - col);

	// the mood's colour cast and its exposure, before the vignette so that
	// closing the world in still darkens the tinted picture rather than
	// fighting it
	col *= tint * exposure;

	// vignette. Squared distance from the middle, so it stays soft at the
	// centre however far it is wound up: the frame the player is actually
	// playing in never goes dark, only everything further out.
	vec2 d = uv - 0.5;
	col *= max(0.0, 1.0 - vignette * dot(d, d) * vignette_tight);

	COLOR = vec4(clamp(col, vec3(0.0), vec3(1.0)), 1.0);
}
