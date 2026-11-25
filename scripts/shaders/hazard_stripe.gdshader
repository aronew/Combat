shader_type spatial;
// Painted hazard stripes on the floor: yellow and black diagonal bands, scuffed by wear.
// Use on a thin plane or box; the stripes follow world space so pieces line up.
uniform vec4 paint : source_color = vec4(0.85, 0.62, 0.08, 1.0);
uniform vec4 dark : source_color = vec4(0.03, 0.03, 0.035, 1.0);
uniform float stripe_width = 0.35;
uniform float wear = 0.45;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float band = step(0.5, fract((wpos.x + wpos.z) / (stripe_width * 2.0)));
	float n = noise(wpos.xz * 3.0) * 0.6 + noise(wpos.xz * 11.0) * 0.4;
	float worn = smoothstep(wear - 0.1, wear + 0.1, n);
	vec3 c = mix(dark.rgb, paint.rgb, band);
	c = mix(c, vec3(0.16, 0.16, 0.17), (1.0 - worn) * 0.85);
	ALBEDO = c;
	ROUGHNESS = mix(0.55, 0.9, 1.0 - worn);
	METALLIC = 0.0;
}
