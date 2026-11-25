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
uniform float cut_radius = 4.5;
uniform float cut_widen = 0.25;  // the band widens toward the camera
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
	if (cut_enabled && wpos.y > cut_height && cutaway_player.y > -500.0) {
		vec2 rel = wpos.xz - cutaway_player.xz;
		vec2 dir = normalize(cutaway_view.xz + vec2(1e-5));
		float along = dot(rel, dir);
		float lateral = length(rel - dir * along);
		if (along > -1.2 && lateral < cut_radius + max(along, 0.0) * cut_widen) {
			discard;
		}
	}
	vec3 col = tint.rgb;
	vec3 glow = vec3(0.0);
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
		col *= a.rgb;
		float l = dot(a.rgb, vec3(0.333));
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
		if (use_uv) {
			NORMAL_MAP = texture(normal_tex, UV).rgb;
		} else if (abs(wnorm.y) > 0.7) {
			// floors: the normal map in the floor plane (world xz, the mesh's own tangent space)
			NORMAL_MAP = texture(normal_tex, wpos.xz * tex_scale).rgb;
		}
	}
	if (!FRONT_FACING) {
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
