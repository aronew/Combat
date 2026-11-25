shader_type spatial;
// The blade's crescent: a flat arc around the player that sweeps open in the direction the
// blade travels, with a white-hot leading edge and a tail that fades behind it. Shows the
// area the cut hits. UV.x runs along the arc (0 = her left end, 1 = right end), UV.y from the
// inner edge (0) to the outer edge (1). Driven from player.gd: `progress` 0..1 over the strike,
// then `fade` 1..0.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(0.1, 0.95, 1.0, 1.0);
uniform vec4 core : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float energy = 2.4;
uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float fade : hint_range(0.0, 1.0) = 1.0;
// +1: opens from the left end to the right end; -1: right to left
uniform float sweep = 1.0;
// how much of the arc behind the leading edge stays lit
uniform float tail = 0.7;

void fragment() {
	float u = sweep > 0.0 ? UV.x : 1.0 - UV.x;
	float v = clamp(UV.y, 0.0, 1.0);
	float behind = progress * 1.08 - u;
	if (behind < 0.0) {
		discard;
	}
	float trail = 1.0 - clamp(behind / tail, 0.0, 1.0);
	float lead = exp(-behind * 14.0);
	// bright outer rim, soft inner edge
	float edge = smoothstep(0.0, 0.9, v) * (1.0 - smoothstep(0.94, 1.0, v));
	float rim = smoothstep(0.75, 0.95, v) * (1.0 - smoothstep(0.95, 1.0, v));
	vec3 col = mix(tint.rgb, core.rgb, clamp(lead * 0.9 + rim * 0.35, 0.0, 1.0));
	ALBEDO = col * energy;
	ALPHA = clamp((trail * trail * 0.55 + lead * 0.8) * edge + rim * trail * 0.35, 0.0, 1.0) * fade;
}
