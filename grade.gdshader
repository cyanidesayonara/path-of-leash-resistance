shader_type canvas_item;

// Post-process for the world layer. Two jobs:
//
// 1. GRADE - split-toning (cool shadows, warm light), contrast, saturation,
//    a soft vignette and a black-lift so night never turns to unreadable
//    murk.
// 2. SURFACE - world-locked grain and blotches. This is the important one:
//    flat colour fills are what make procedural art read as cheap, and a
//    texture pass kills that everywhere at once. The noise is keyed to
//    WORLD position (via the camera offset), so it sits on the ground like
//    aggregate in asphalt instead of sliding around like a film overlay.
//
// All of it is GPU work, so it costs the CPU-bound web build nothing.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec2 cam_off = vec2(0.0, 0.0);
uniform vec3 cool_shadows = vec3(0.90, 0.95, 1.09);
uniform vec3 warm_light = vec3(1.07, 1.01, 0.93);
uniform float saturation = 1.12;
uniform float contrast = 1.05;
uniform float vignette = 0.26;
uniform float lift = 0.055;
uniform float grain_fine = 0.055;
uniform float grain_blotch = 0.045;
uniform float time_seed = 0.0;

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

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 col = texture(screen_tex, uv).rgb;

	// world position of this pixel, for texture that stays put on the ground
	vec2 wp = uv * vec2(1280.0, 720.0) + cam_off;

	float lum = dot(col, vec3(0.299, 0.587, 0.114));

	// --- surface texture ---
	// fine aggregate: tight, per-pixel-ish speckle
	float fine = hash(floor(wp / 2.0)) - 0.5;
	// broad blotches: damp patches, wear, tonal drift
	float blotch = vnoise(wp / 34.0) - 0.5;
	// hold texture off the darkest and brightest ends so it reads as
	// surface, not as noise laid over silhouettes
	float tex_mask = smoothstep(0.04, 0.30, lum) * (1.0 - smoothstep(0.72, 0.98, lum));
	col += (fine * grain_fine + blotch * grain_blotch) * tex_mask;

	// --- grade ---
	col *= mix(cool_shadows, warm_light, smoothstep(0.15, 0.85, lum));
	col = (col - 0.5) * contrast + 0.5;
	col = mix(vec3(lum), col, saturation);

	// lift the blacks so shadowed ground keeps its shape at night
	col += lift * (1.0 - col);

	// vignette
	vec2 d = uv - 0.5;
	col *= 1.0 - vignette * dot(d, d) * 1.6;

	// a whisper of animated grain over the top, so stills look filmic
	float n = hash(uv * vec2(1280.0, 720.0) + time_seed);
	col += (n - 0.5) * 0.016;

	COLOR = vec4(clamp(col, vec3(0.0), vec3(1.0)), 1.0);
}
