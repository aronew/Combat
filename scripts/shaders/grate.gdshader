// Open metal grating for catwalk bridges: holes are discarded so the teal void shows through.
shader_type spatial;
render_mode cull_disabled;

uniform vec3 color : source_color = vec3(0.3, 0.33, 0.36);
uniform float cell_size = 0.22;
uniform float bar_width = 0.045;
uniform float frame_width = 0.12;
uniform vec2 frame_half_extents = vec2(100.0, 100.0);

varying vec3 local_pos;
varying vec3 world_pos;

void vertex() {
	local_pos = VERTEX;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 f = fract(world_pos.xz / cell_size);
	float b = bar_width / cell_size;
	bool hole = f.x > b && f.y > b;
	bool on_frame = abs(local_pos.x) > frame_half_extents.x - frame_width
			|| abs(local_pos.z) > frame_half_extents.y - frame_width;
	if (hole && !on_frame) {
		discard;
	}
	ALBEDO = color;
	METALLIC = 0.75;
	ROUGHNESS = 0.45;
}
