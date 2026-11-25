shader_type spatial;
// Energy barrier sealing an arena doorway: a translucent sheet of light with scrolling bars,
// a hex lattice, a bright frame along the floor and the top, and flicker. `rise` animates it
// up from the floor (0 = down, 1 = full height).
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.35, 0.18, 1.0);
uniform float energy = 2.2;
uniform float rise : hint_range(0.0, 1.0) = 1.0;
// the gate's mesh size (the mesh is centred on its origin)
uniform vec2 size = vec2(4.0, 3.2);

varying vec3 local_pos;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	// u along the wall, h up from the floor (0) to the top (1)
	float u = local_pos.x / size.x + 0.5;
	float h = local_pos.y / size.y + 0.5;
	if (h > rise) {
		discard;
	}
	float along = u * size.x * 1.5;
	float bars = smoothstep(0.75, 1.0, sin(along * 6.2831 - TIME * 4.0) * 0.5 + 0.5) * 0.5;
	vec2 hp = vec2(along, h * size.y * 1.8);
	hp.x += mod(floor(hp.y), 2.0) * 0.5;
	vec2 f = abs(fract(hp) - 0.5);
	float lattice = smoothstep(0.42, 0.5, max(f.x, f.y)) * 0.35;
	float frame = smoothstep(0.06, 0.0, h) + smoothstep(0.06, 0.0, rise - h) * 1.5;
	float flicker = 0.85 + 0.15 * hash(floor(TIME * 18.0));
	float body = 0.18 + bars + lattice;
	ALBEDO = tint.rgb * energy;
	ALPHA = clamp((body + frame) * flicker * rise, 0.0, 1.0);
}
