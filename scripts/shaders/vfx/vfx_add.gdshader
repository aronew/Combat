shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
// Additive VFX: flashes, sparks, fire, energy. See vfx_common.gdshaderinc.
#include "res://scripts/shaders/vfx/vfx_common.gdshaderinc"

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float a = vfx_shape(uv, v_age) * COLOR.a * tint.a * anim.x;
	ALBEDO = COLOR.rgb * tint.rgb * energy * a;
	ALPHA = 1.0;
}
