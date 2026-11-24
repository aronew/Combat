shader_type spatial;
render_mode blend_mix, unshaded, depth_draw_never, cull_disabled, shadows_disabled;
// Alpha-blended VFX: smoke, dust, ichor. See vfx_common.gdshaderinc.
#include "res://scripts/shaders/vfx/vfx_common.gdshaderinc"

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float a = vfx_shape(uv, v_age) * COLOR.a * tint.a * anim.x;
	ALBEDO = COLOR.rgb * tint.rgb * energy;
	ALPHA = clamp(a, 0.0, 1.0);
}
