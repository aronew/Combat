// Cheap floor for LOW graphics: tile seams and per-tile tone only (no noise,
// no hive veins). Accepts the same parameters as floor.gdshader.
shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.16, 0.175, 0.19);
uniform vec3 seam_color : source_color = vec3(0.05, 0.055, 0.06);
uniform float tile_size = 3.0;
uniform float seam_width = 0.05;
uniform float tile_variation = 0.16;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.55;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.55;
uniform vec3 hive_center = vec3(13.5, 0.0, -8.5);
uniform float hive_radius = 8.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz / tile_size;
	vec2 f = fract(p);
	float edge = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)) * tile_size;
	float seam = step(edge, seam_width);
	float tone = 1.0 + (fract(sin(dot(floor(p), vec2(127.1, 311.7))) * 43758.5453) - 0.5) * tile_variation;
	float infest = 1.0 - smoothstep(hive_radius * 0.3, hive_radius, length(world_pos.xz - hive_center.xz));
	vec3 col = mix(base_color * tone, vec3(0.07, 0.11, 0.03), infest * 0.7);
	ALBEDO = mix(col, seam_color, seam);
	METALLIC = metallic_value;
	ROUGHNESS = roughness_value;
}
