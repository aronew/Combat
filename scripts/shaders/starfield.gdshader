shader_type spatial;
render_mode unshaded, cull_disabled;
// Deep space far below the starship decks: stars that twinkle, faint nebula
// clouds and a slow drift, laid out across the plane's world XZ.

uniform vec3 deep = vec3(0.004, 0.006, 0.02);
uniform vec3 nebula_a = vec3(0.30, 0.04, 0.22);
uniform vec3 nebula_b = vec3(0.03, 0.20, 0.34);
uniform float nebula_strength = 0.55;

varying vec2 wxz;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}
vec3 stars(vec2 p, float scale, float density, float size) {
	vec2 q = p * scale;
	vec2 cell = floor(q);
	float h = hash(cell);
	if (h > density) return vec3(0.0);
	vec2 off = vec2(hash(cell + 3.1), hash(cell + 7.7)) - 0.5;
	float d = length(fract(q) - 0.5 - off * 0.6);
	float tw = 0.55 + 0.45 * sin(TIME * (0.7 + h * 9.0) + h * 50.0);
	vec3 tint = mix(vec3(1.0, 0.85, 0.75), vec3(0.75, 0.85, 1.0), hash(cell + 1.3));
	return tint * smoothstep(size, 0.0, d) * tw;
}

void vertex() {
	wxz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 p = wxz * 0.01 + vec2(TIME * 0.002, 0.0);
	float n = fbm(p * 1.5);
	vec3 col = deep;
	col += mix(nebula_a, nebula_b, fbm(p * 0.7 + 4.0)) * smoothstep(0.42, 0.95, n) * nebula_strength;
	col += stars(p, 60.0, 0.10, 0.10) * 1.2;
	col += stars(p, 22.0, 0.05, 0.08) * 2.2;
	col += stars(p, 8.0, 0.03, 0.06) * 3.5;
	ALBEDO = col;
	EMISSION = col;
}
