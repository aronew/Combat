shader_type spatial;
// Station surfaces with the cutaway: anything above `cut_height` that stands between the camera
// and the player (a band around the camera-to-player line, plus a column over the player) is
// not drawn, so walls, rock and ceiling beams drop to waist height wherever they would hide her.
// Back faces render solid black, so a cut wall shows a black top, as in Dreadhunter.
//
// Surfaces are textured by world-space triplanar mapping (kit pieces have no UVs), or by UV for
// imported models that bring their own textures (use_uv). Set the player and camera direction
// every frame through the global shader parameters `cutaway_player` and `cutaway_view`
// (see CutawayDriver).
render_mode cull_disabled;

global uniform vec3 cutaway_player;
global uniform vec3 cutaway_view;  // flat direction from the player toward the camera

uniform bool cut_enabled = true;
uniform float cut_height = 1.3;
uniform float cut_radius = 2.2;  // half-width of the cut, metres either side of the sight line
uniform float cut_widen = 0.15;  // the cut widens a little toward the camera
uniform float cut_reach = 6.0;  // beyond this (toward the camera) nothing is tall enough to hide her
uniform float cut_fade = 0.9;  // the edge of the cut dissolves over this many metres
// Overhead structure (girders, rails): hidden everywhere on the camera side of the player, so
// it never crosses the screen between the camera and the floor; it stays visible beyond her.
uniform bool overhead = false;
// Near walls (the room's camera-side rim) are always cut to waist height, wherever the player is.
instance uniform bool always_cut = false;

uniform vec4 tint : source_color = vec4(1.0);
uniform bool use_textures = false;
uniform bool use_uv = false;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D arm_tex : filter_linear_mipmap, repeat_enable;  // AO, roughness, metal
uniform float tex_scale = 0.25;  // repeats per metre (triplanar)
uniform float macro_var : hint_range(0.0, 1.0) = 0.0;  // large-scale light/dark patches against tiling
uniform float metallic : hint_range(0.0, 1.0) = 0.5;
uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform vec3 emission = vec3(0.0);
uniform float emission_energy = 0.0;
// grates over a glow: the dark gaps of the texture light up in this colour
uniform vec3 gap_glow = vec3(0.0);
// take the colour out of the texture before tinting, so one painted texture serves any paint
uniform float desaturate : hint_range(0.0, 1.0) = 0.0;
// Kit pieces carry baked vertex colours (R = ambient occlusion, G = outward edge): dirt
// collects in the creases and the paint wears off the edges, down to bare metal.
uniform bool use_wear = false;
uniform float grime : hint_range(0.0, 1.0) = 0.7;
uniform float edge_wear : hint_range(0.0, 1.0) = 0.6;
uniform vec4 bare_metal : source_color = vec4(0.55, 0.55, 0.58, 1.0);
// Wet floors: puddles where the large-scale pattern is low, shiny and a little darker.
uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform float puddle_level = 0.4;  // higher = more puddles

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec4 triplanar(sampler2D tex, vec3 p, vec3 n) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z);
	return texture(tex, p.zy * tex_scale) * w.x + texture(tex, p.xz * tex_scale) * w.y + texture(tex, p.xy * tex_scale) * w.z;
}

void fragment() {
	if (always_cut && wpos.y > cut_height) {
		discard;
	}
	// (no player set yet, e.g. in the editor: the global's default y is -1000 and nothing is cut)
	if (overhead && cutaway_player.y > -500.0) {
		float ahead = dot(wpos.xz - cutaway_player.xz, normalize(cutaway_view.xz + vec2(1e-5)));
		if (ahead > -2.5) {
			discard;
		}
	}
	if (cut_enabled && wpos.y > cut_height && cutaway_player.y > -500.0) {
		// only what stands between the camera and the player: in front of her (toward the
		// camera), close to the sight line, and near enough to be tall enough to hide her
		vec2 rel = wpos.xz - cutaway_player.xz;
		vec2 dir = normalize(cutaway_view.xz + vec2(1e-5));
		float along = dot(rel, dir);
		float lateral = length(rel - dir * along);
		float r = cut_radius + max(along, 0.0) * cut_widen;
		float k = smoothstep(r, r - cut_fade, lateral)
			* smoothstep(-0.2, 0.6, along)
			* smoothstep(cut_reach, cut_reach - cut_fade * 2.0, along);
		// dissolve the edge with a screen-space dither instead of a hard line
		float dither = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
		if (k > dither * 0.98 + 0.01) {
			discard;
		}
	}
	vec3 col = tint.rgb;
	vec3 glow = vec3(0.0);
	float wet = 0.0;
	float ao = 1.0;
	float rough = roughness;
	float metal = metallic;
	if (use_textures) {
		vec4 a;
		vec4 arm;
		if (use_uv) {
			a = texture(albedo_tex, UV);
			arm = texture(arm_tex, UV);
		} else {
			a = triplanar(albedo_tex, wpos, wnorm);
			arm = triplanar(arm_tex, wpos, wnorm);
		}
		float l = dot(a.rgb, vec3(0.333));
		a.rgb = mix(a.rgb, vec3(l * 1.15), desaturate);
		col *= a.rgb;
		glow = gap_glow * pow(clamp(1.0 - l * 6.0, 0.0, 1.0), 3.0);
		if (macro_var > 0.0 && !use_uv) {
			// the albedo sampled very large and offset breaks up the repeat into patches of wear
			float m = dot(texture(albedo_tex, wpos.xz * tex_scale * 0.071 + vec2(0.37, 0.11)).rgb, vec3(0.333));
			float m2 = dot(texture(albedo_tex, wpos.zx * tex_scale * 0.023 + vec2(0.71, 0.53)).rgb, vec3(0.333));
			col *= mix(1.0, 0.55 + 1.1 * m * m2 * 2.0, macro_var);
		}
		ao = arm.r;
		rough = clamp(arm.g * (roughness * 2.0), 0.05, 1.0);
		metal = clamp(arm.b + metallic * 0.5, 0.0, 1.0);
		if (use_wear) {
			// chips follow the texture's own grain, so wear is patchy rather than a clean line
			float chip = smoothstep(0.35, 0.75, COLOR.g * (0.45 + l * 1.6));
			col = mix(col, bare_metal.rgb * (0.6 + l), chip * edge_wear);
			metal = mix(metal, 0.9, chip * edge_wear);
			rough = mix(rough, 0.35, chip * edge_wear);
			float dirt = mix(1.0, COLOR.r, grime);
			col *= dirt;
			ao *= dirt;
		}
		if (wetness > 0.0) {
			float pud = dot(texture(albedo_tex, wpos.xz * tex_scale * 0.05 + vec2(0.21, 0.67)).rgb, vec3(0.333));
			float p2 = dot(texture(albedo_tex, wpos.zx * tex_scale * 0.13 + vec2(0.5, 0.1)).rgb, vec3(0.333));
			wet = smoothstep(puddle_level + 0.03, puddle_level - 0.03, pud * 0.7 + p2 * 0.3) * wetness;
			col *= mix(1.0, 0.62, wet);
			rough = mix(rough, 0.04, wet);
			metal = mix(metal, 0.0, wet);
		}
		if (use_uv) {
			NORMAL_MAP = texture(normal_tex, UV).rgb;
		} else if (abs(wnorm.y) > 0.7) {
			// floors: the normal map in the floor plane (world xz, the mesh's own tangent space)
			// standing water is flat: puddles drop the floor's bumps
			NORMAL_MAP = mix(texture(normal_tex, wpos.xz * tex_scale).rgb, vec3(0.5, 0.5, 1.0), wet);
		}
	}
	// Seen from inside (the hollow of a cut wall): judged by the mesh normal, not the face
	// winding, because the AI-made models have faces wound both ways. Godot flips NORMAL on back
	// faces; undo that to get the model's own normal back.
	vec3 own_normal = FRONT_FACING ? NORMAL : -NORMAL;
	bool inside = dot(own_normal, VIEW) < -0.08;
	if (!inside) {
		NORMAL = own_normal;
	}
	if (inside) {
		// the inside of a cut wall: a solid black cap
		ALBEDO = vec3(0.0);
		ROUGHNESS = 1.0;
		SPECULAR = 0.0;
		METALLIC = 0.0;
	} else {
		ALBEDO = col;
		AO = ao;
		ROUGHNESS = rough;
		METALLIC = metal;
		EMISSION = emission * emission_energy + glow;
	}
}
