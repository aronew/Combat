// Full-screen damage vignette for the HUD.
shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0, 0.08, 0.2, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV - 0.5;
	float d = length(uv * vec2(1.0, 0.8));
	float v = smoothstep(0.25, 0.72, d);
	COLOR = vec4(color.rgb, v * intensity);
}
