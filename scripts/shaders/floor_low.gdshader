// Cheap floor for LOW graphics: tile seams and per-tile tone only (no noise, no bevels, no
// hive veins). Accepts the same parameters as floor.gdshader; hex floors stay hex, flagstones
// become staggered slabs.
shader_type spatial;

uniform int pattern = 0;
uniform vec3 base_color : source_color = vec3(0.34, 0.33, 0.31);
uniform vec3 seam_color : source_color = vec3(0.09, 0.09, 0.09);
uniform float tile_size = 3.0;
uniform float cell_size = 1.5;
uniform float seam_width = 0.05;
uniform float tile_variation = 0.16;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.25;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.62;
uniform float wetness : hint_range(0.0, 1.0) = 0.45;
uniform float moss_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 moss_color : source_color = vec3(0.16, 0.24, 0.07);
uniform vec3 hive_center = vec3(13.5, 0.0, -8.5);
uniform float hive_radius = 8.0;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 cell;
	float edge;
	if (pattern == 1) {
		vec2 p = world_pos.xz / cell_size;
		const vec2 s = vec2(1.0, 1.7320508);
		vec4 hc = floor(vec4(p, p - vec2(0.5, 1.0)) / s.xyxy) + 0.5;
		vec4 h = vec4(p - hc.xy * s, p - (hc.zw + 0.5) * s);
		vec2 local = h.xy;
		cell = hc.xy;
		if (dot(h.zw, h.zw) < dot(h.xy, h.xy)) {
			local = h.zw;
			cell = hc.zw + 0.5;
		}
		vec2 a = abs(local);
		edge = (0.5 - max(dot(a, s * 0.5), a.x)) * cell_size;
	} else {
		float size = pattern == 2 ? cell_size * 1.3 : tile_size;
		vec2 p = world_pos.xz / size;
		if (pattern == 2) {
			p.x += 0.5 * mod(floor(p.y), 2.0);
		}
		vec2 f = fract(p);
		cell = floor(p);
		edge = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)) * size;
	}
	float seam = step(edge, seam_width);
	float tone = 1.0 + (hash(cell) - 0.5) * tile_variation;
	float infest = 1.0 - smoothstep(hive_radius * 0.3, hive_radius, length(world_pos.xz - hive_center.xz));
	vec3 col = mix(base_color * tone, vec3(0.07, 0.11, 0.03), infest * 0.7);
	col = mix(col, moss_color, step(0.82, hash(cell + vec2(3.0, 7.0))) * moss_amount);
	ALBEDO = mix(col, seam_color, seam);
	METALLIC = pattern == 2 ? 0.0 : metallic_value;
	ROUGHNESS = roughness_value;
}
