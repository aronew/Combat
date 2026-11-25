shader_type spatial;
// Silhouette rim for the player character: an additive glow on the edges facing away from the
// camera, drawn as a second pass over the character's own material. Keeps a dark model readable
// against dark floors from the high isometric camera.
render_mode blend_add, unshaded, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform vec4 rim_color : source_color = vec4(0.62, 0.8, 1.0, 1.0);
uniform float strength = 0.32;
uniform float power = 4.0;

void fragment() {
	float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), power);
	ALBEDO = rim_color.rgb * rim * strength;
}
