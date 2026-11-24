// Diagonal hazard-stripe floor panel with a metal frame (use on a PlaneMesh).
shader_type spatial;

uniform vec3 dark_color : source_color = vec3(0.05, 0.055, 0.06);
uniform vec3 stripe_color : source_color = vec3(0.55, 0.57, 0.6);
uniform vec3 frame_color : source_color = vec3(0.22, 0.24, 0.26);
uniform float stripes = 4.0;
uniform float border = 0.09;

void fragment() {
	vec2 uv = UV;
	float s = step(0.5, fract((uv.x + uv.y) * stripes));
	float inside = step(border, uv.x) * step(uv.x, 1.0 - border) * step(border, uv.y) * step(uv.y, 1.0 - border);
	float inner_line = inside * (1.0 - step(border * 1.6, uv.x) * step(uv.x, 1.0 - border * 1.6)
			* step(border * 1.6, uv.y) * step(uv.y, 1.0 - border * 1.6));
	vec3 col = mix(dark_color, stripe_color, s);
	col = mix(col, dark_color, inner_line);
	col = mix(frame_color, col, inside);
	ALBEDO = col;
	METALLIC = 0.45;
	ROUGHNESS = mix(0.7, 0.45, s);
}
