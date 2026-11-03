// Cheap film-look overlay: animated grain, vignette, and faint scanlines.
//
// This intentionally does NOT sample the screen texture. A screen-copy pass was
// the most expensive part of the old noir grade on integrated GPUs; blending a
// transparent grain layer over the 3D view keeps the look while avoiding that
// full-screen copy. Colour grading lives in the WorldEnvironment instead.
shader_type canvas_item;
render_mode unshaded;

uniform float grain_amount : hint_range(0.0, 0.12) = 0.015;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.18;
uniform float scanline_strength : hint_range(0.0, 0.1) = 0.004;

// Cheap deterministic hash used for per-pixel grain.
float hash(vec2 p) {
	p = fract(p * vec2(443.897, 441.423));
	p += dot(p, p.yx + 19.19);
	return fract((p.x + p.y) * p.x);
}

void fragment() {
	vec2 uv = UV;

	// Quantising time to 24 updates per second avoids a distracting shimmer
	// while still keeping the grain alive.
	float ticks = floor(TIME * 24.0);
	float noise = hash(FRAGCOORD.xy + ticks * 31.7) * 2.0 - 1.0;

	float grain_alpha = abs(noise) * grain_amount;
	vec3 grain_color = noise > 0.0
		? vec3(0.78, 0.84, 0.80)
		: vec3(0.005, 0.01, 0.01);

	// Soft black vignette at the edges of the frame.
	float edge = distance(uv, vec2(0.5));
	float vignette = smoothstep(0.30, 0.86, edge) * vignette_strength;

	// Faint horizontal scanlines for a worn-film feel.
	float scan = (0.5 + 0.5 * sin(uv.y * 1080.0 * 3.14159265)) * scanline_strength;

	// Whichever effect is strongest supplies the blend colour and alpha.
	vec3 color = grain_color;
	float alpha = grain_alpha;
	if (vignette > alpha) {
		alpha = vignette;
		color = vec3(0.0);
	}
	if (scan > alpha) {
		alpha = scan;
		color = vec3(0.0);
	}

	COLOR = vec4(color, alpha);
}
