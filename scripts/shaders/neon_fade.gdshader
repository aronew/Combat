// Additive glowing shell (explosion flash, shockwave ring, dash ghost). `fade` is animated from script.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0);
uniform float energy = 4.0;
uniform float fade : hint_range(0.0, 1.0) = 1.0;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float facing = clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
	ALBEDO = tint.rgb * energy;
	ALPHA = tint.a * fade * mix(1.0, facing, edge_softness);
}
