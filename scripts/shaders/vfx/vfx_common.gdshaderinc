// Shared body of the VFX shaders (additive and alpha-blended variants include it).
// One material per look, many shapes: soft dot, streak, star, ring, noisy puff
// that erodes with age, hex ripple, flare. Colour comes from the particle colour
// ramp (COLOR) times a per-instance tint, so one material serves every weapon
// and every bug's ichor. Billboards the quad for particles (keeps per-particle
// scale and spin) unless `billboard` is off (flat ground rings, streaks that the
// emitter already aligns to velocity).

uniform int shape = 0;            // 0 dot, 1 streak, 2 star, 3 ring, 4 puff, 5 hex, 6 flare
uniform float energy = 2.0;       // HDR multiplier (additive look); keep 1 for smoke
uniform bool billboard = true;
uniform float softness = 1.0;
uniform float ring_width = 0.12;
uniform float star_points = 6.0;
uniform float erosion = 0.7;      // puff: how much the shape eats away as it ages
uniform float noise_scale = 2.6;

// Per play: tint, and anim = (fade, spin, age override or -1, unused). Plain
// uniforms, not instance uniforms: every pooled effect owns its material copies
// (VfxEffect._ready), so there is no per-instance buffer limit to run into.
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 anim = vec4(1.0, 0.0, -1.0, 0.0);

varying float v_age;
varying float v_seed;

float vfx_hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vfx_noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(vfx_hash(i), vfx_hash(i + vec2(1, 0)), u.x), mix(vfx_hash(i + vec2(0, 1)), vfx_hash(i + vec2(1, 1)), u.x), u.y);
}
float vfx_fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * vfx_noise(p); p *= 2.1; a *= 0.5; }
	return v;
}

void vertex() {
	v_age = anim.z >= 0.0 ? anim.z : INSTANCE_CUSTOM.y;
	v_seed = fract(float(INSTANCE_ID) * 0.6180339 + MODEL_MATRIX[3].x * 0.13);
	if (billboard) {
		float a = INSTANCE_CUSTOM.x + anim.y;
		mat4 world = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
		world = world * mat4(vec4(cos(a), -sin(a), 0.0, 0.0), vec4(sin(a), cos(a), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
		MODELVIEW_MATRIX = VIEW_MATRIX * world;
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}
}

float vfx_shape(vec2 uv, float age) {
	float r = length(uv);
	if (shape == 0) {
		return pow(clamp(1.0 - r, 0.0, 1.0), 1.0 + softness);
	} else if (shape == 1) {
		float across = clamp(1.0 - abs(uv.x), 0.0, 1.0);
		float along = clamp(1.0 - uv.y * uv.y, 0.0, 1.0);
		return pow(across, 2.0) * along;
	} else if (shape == 2) {
		float ang = atan(uv.y, uv.x);
		float spikes = pow(abs(cos(ang * star_points * 0.5)), 10.0) * exp(-r * 2.2);
		return clamp(exp(-r * 7.0) * 2.0 + spikes * 1.4, 0.0, 1.0) * smoothstep(1.0, 0.85, r);
	} else if (shape == 3) {
		return smoothstep(ring_width, 0.0, abs(r - 0.82)) * smoothstep(1.0, 0.95, r);
	} else if (shape == 4) {
		float n = vfx_fbm(uv * noise_scale + v_seed * 17.0 + age * 0.8);
		float body = smoothstep(1.0, 0.25, r + (n - 0.5) * 0.7);
		float cut = age * erosion;
		// the noise can push the body past the quad's edge: fade it out before the corners
		return clamp((body - cut) / max(1.0 - cut, 0.05), 0.0, 1.0) * smoothstep(1.0, 0.7, r);
	} else if (shape == 5) {
		vec2 p = uv * 6.0;
		vec2 h = vec2(1.0, 1.732);
		vec2 a = mod(p, h) - h * 0.5;
		vec2 b = mod(p - h * 0.5, h) - h * 0.5;
		vec2 g = dot(a, a) < dot(b, b) ? a : b;
		float edge = smoothstep(0.38, 0.48, max(abs(g.x) * 0.866 + abs(g.y) * 0.5, abs(g.y)));
		float ringf = smoothstep(0.35, 0.0, abs(r - 0.6 - age * 0.3)) * smoothstep(1.0, 0.9, r);
		return clamp(edge * ringf + exp(-r * 3.0) * 0.25, 0.0, 1.0) * smoothstep(1.0, 0.85, r);
	}
	return clamp(exp(-r * 8.0) * 3.0 + exp(-r * 2.6) * 0.6, 0.0, 1.0) * smoothstep(1.0, 0.9, r);
}
