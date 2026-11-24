// Additive projectile glow. Projectiles share one material per gun colour
// (see Projectile._material_for), which works on every renderer.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 bolt_tint : source_color = vec4(0.1, 0.95, 1.0, 1.0);
uniform float energy = 3.0;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.5;
uniform float core_whiteness : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float facing = clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
	vec3 c = mix(bolt_tint.rgb, vec3(1.0), core_whiteness);
	ALBEDO = c * energy;
	ALPHA = bolt_tint.a * mix(1.0, facing, edge_softness);
}
