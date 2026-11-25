shader_type spatial;
// Blade trail ribbon (see scripts/vfx/blade_trail.gd). UV.x = age (0 just drawn .. 1 gone),
// UV.y = base (0) .. tip (1). A white-hot edge along the tip for the newest part of the swing,
// the blade's colour behind it, a soft fade toward the hilt, and noise that eats the tail away.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(0.1, 0.95, 1.0, 1.0);
uniform vec4 core : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float energy = 2.6;
// how far down from the tip the hot core reaches (fraction of the ribbon's width)
uniform float core_width = 0.35;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	float age = clamp(UV.x, 0.0, 1.0);
	float span = clamp(UV.y, 0.0, 1.0);
	// a thin sheet toward the hilt, crisp at the tip
	float width = smoothstep(0.15, 0.95, span) * (1.0 - smoothstep(0.97, 1.0, span));
	float alive = pow(1.0 - age, 2.0);
	// the tail breaks up as it ages
	float n = vnoise(vec2(age * 9.0, span * 5.0) + vec2(TIME * 2.3, 0.0));
	float erode = smoothstep(age - 0.15, age + 0.25, n);
	// hot edge: a narrow white line along the tip, newest part only
	float hot = pow(1.0 - age, 4.0) * smoothstep(1.0 - core_width, 0.975, span) * (1.0 - smoothstep(0.985, 1.0, span));
	vec3 col = mix(tint.rgb, core.rgb, clamp(hot * 1.6, 0.0, 1.0));
	ALBEDO = col * energy;
	ALPHA = clamp(width * width * alive * mix(1.0, erode, 0.8) * 0.5 + hot * 0.9, 0.0, 1.0);
}
