// Worn concrete-steel deck plating: world-space tile seams, per-tile tone
// variation, grime smudges, wet patches that catch the lamp light, and glowing
// yellow-green hive cracks that spread around the hive.
shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.34, 0.33, 0.31);
uniform vec3 seam_color : source_color = vec3(0.09, 0.09, 0.09);
uniform float tile_size = 3.0;
uniform float seam_width = 0.05;
uniform float tile_variation = 0.16;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.25;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.62;
// How much of the deck is wet (shiny, slightly darker puddles).
uniform float wetness : hint_range(0.0, 1.0) = 0.45;

uniform vec3 hive_center = vec3(13.5, 0.0, -8.5);
uniform float hive_radius = 7.0;
uniform vec3 grime_color : source_color = vec3(0.12, 0.13, 0.05);
uniform vec3 vein_color : source_color = vec3(0.78, 0.9, 0.12);
uniform float vein_energy = 0.7;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz / tile_size;
	vec2 cell = floor(p);
	vec2 f = fract(p);
	float edge = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)) * tile_size;
	float seam = 1.0 - smoothstep(seam_width * 0.5, seam_width, edge);

	float tone = 1.0 + (hash(cell) - 0.5) * tile_variation;
	float smudge = fbm(world_pos.xz * 0.35);
	vec3 col = base_color * tone * mix(0.75, 1.2, smudge);
	col = mix(col, seam_color, seam);

	// Hive infestation: grime + glowing veins fading out with distance.
	float d = length(world_pos.xz - hive_center.xz) + (fbm(world_pos.xz * 0.5) - 0.5) * 4.0;
	float infest = 1.0 - smoothstep(hive_radius * 0.25, hive_radius, d);
	col = mix(col, grime_color, infest * 0.8);
	float n = fbm(world_pos.xz * 1.1 + vec2(3.7, 1.3));
	float vein = (1.0 - smoothstep(0.0, 0.018, abs(n - 0.5))) * step(0.45, fbm(world_pos.xz * 0.3 + vec2(1.7, 9.2)));

	// Wet patches: darker and glossy, so lamps leave bright streaks on the deck.
	float wet = smoothstep(0.62 - wetness * 0.25, 0.68 - wetness * 0.25, fbm(world_pos.xz * 0.12 + vec2(7.1, 2.3)));
	col *= mix(1.0, 0.72, wet);

	ALBEDO = col;
	METALLIC = metallic_value;
	ROUGHNESS = mix(mix(roughness_value - 0.15 * smudge, 0.12, wet), 0.9, seam);
	EMISSION = vein_color * vein * infest * vein_energy;
}
