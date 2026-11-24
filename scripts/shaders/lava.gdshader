shader_type spatial;
render_mode unshaded;
// The molten lake under the Furnace Chasm: dark crust plates drifting over
// bright flowing metal, with hot seams that pulse.

uniform vec3 hot = vec3(1.0, 0.55, 0.12);
uniform vec3 white_hot = vec3(1.0, 0.9, 0.55);
uniform vec3 crust = vec3(0.035, 0.016, 0.012);
uniform float energy = 1.7;
uniform float scale = 0.06;

varying vec2 wxz;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.07; a *= 0.5; }
	return v;
}
// Distance to the nearest cell border: the seams between crust plates.
float cells(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	float d1 = 8.0; float d2 = 8.0;
	for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
		vec2 g = vec2(float(x), float(y));
		vec2 o = vec2(hash(i + g), hash(i + g + 5.3));
		o = 0.5 + 0.4 * sin(TIME * 0.15 + 6.28 * o);
		float d = length(g + o - f);
		if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
	}
	return d2 - d1;
}

void vertex() {
	wxz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 p = wxz * scale;
	vec2 flow = vec2(fbm(p * 0.8 + TIME * 0.03), fbm(p * 0.8 - TIME * 0.025 + 3.0));
	float seam = cells(p * 1.3 + flow * 0.8);
	float glow = 1.0 - smoothstep(0.0, 0.07, seam);
	float molten = smoothstep(0.58, 0.8, fbm(p * 0.45 + flow + TIME * 0.02));
	float heat = clamp(glow + molten, 0.0, 1.0);
	float pulse = 0.85 + 0.15 * sin(TIME * 1.3 + fbm(p * 2.0) * 6.0);
	vec3 col = mix(crust, hot, heat * heat);
	col = mix(col, white_hot, smoothstep(0.75, 1.0, heat) * 0.7);
	ALBEDO = col;
	EMISSION = col * heat * energy * pulse + crust * 0.2;
}
