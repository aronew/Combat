shader_type spatial;
render_mode unshaded, cull_back;
// Viewport glass on the starship's hull windows: deep space with stars and a
// slow-drifting nebula. Placed in world space so neighbouring windows line up.

uniform vec3 deep = vec3(0.01, 0.015, 0.04);
uniform vec3 nebula_a = vec3(0.35, 0.05, 0.25);
uniform vec3 nebula_b = vec3(0.04, 0.25, 0.4);
uniform float star_density = 0.06;

varying vec3 wpos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = vec2(wpos.x + wpos.z, wpos.y) * 1.4;
	float n = noise(p * 0.35 + TIME * 0.02) * 0.6 + noise(p * 0.9 - TIME * 0.015) * 0.4;
	vec3 col = deep + mix(nebula_a, nebula_b, noise(p * 0.2)) * smoothstep(0.45, 1.0, n) * 0.6;
	vec2 cell = floor(p * 6.0);
	float s = hash(cell);
	if (s < star_density) {
		vec2 f = fract(p * 6.0) - 0.5;
		float tw = 0.6 + 0.4 * sin(TIME * (1.0 + s * 20.0) + s * 40.0);
		col += vec3(0.9, 0.95, 1.0) * smoothstep(0.12, 0.0, length(f)) * tw * 2.0;
	}
	ALBEDO = col;
	EMISSION = col;
}
