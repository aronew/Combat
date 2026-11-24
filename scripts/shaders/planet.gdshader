shader_type spatial;
render_mode unshaded;
// A gas giant hanging below the starship: banded clouds, a storm, a bright
// atmosphere rim and a dark night side.

uniform vec3 band_a = vec3(0.55, 0.22, 0.35);
uniform vec3 band_b = vec3(0.16, 0.10, 0.28);
uniform vec3 band_c = vec3(0.85, 0.55, 0.45);
uniform vec3 rim_color = vec3(0.9, 0.45, 0.75);
uniform vec3 sun_dir = vec3(0.5, 0.6, 0.3);

varying vec3 lpos;
varying vec3 wnormal;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void vertex() {
	lpos = normalize(VERTEX);
	wnormal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float lat = lpos.y;
	float lon = atan(lpos.z, lpos.x);
	float w = noise(vec2(lon * 3.0 + TIME * 0.01, lat * 20.0)) * 0.15;
	float b = sin((lat + w) * 28.0) * 0.5 + 0.5;
	vec3 col = mix(band_b, band_a, b);
	col = mix(col, band_c, smoothstep(0.75, 1.0, sin((lat + w) * 9.0 + 1.3)) * 0.6);
	float storm = smoothstep(0.12, 0.0, length(vec2(lon - 0.8, (lat - 0.25) * 2.5)));
	col = mix(col, band_c * 1.2, storm);
	float light = clamp(dot(wnormal, normalize(sun_dir)) * 0.8 + 0.35, 0.05, 1.0);
	col *= light;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	col += rim_color * rim * 1.5;
	ALBEDO = col;
	EMISSION = col * 0.9;
}
