// Deck floor. Three surface patterns, all in world space so neighbouring slabs line up:
//   0 = steel plates (square tiles, the original deck),
//   1 = hex tiles (bevelled hexagonal plates; a few cells glow faintly, like lit floor panels),
//   2 = flagstones (irregular worn stone slabs, for the overgrown, older levels).
// On top: per-tile tone variation, grime smudges, moss in the seams and in patches, wet patches
// that catch the lamp light, and glowing yellow-green hive cracks that spread around the hive.
// Seams are bevelled with a bump (the tiles read as separate, chunky pieces under the lamps).
shader_type spatial;

uniform int pattern = 0;
uniform vec3 base_color : source_color = vec3(0.34, 0.33, 0.31);
uniform vec3 seam_color : source_color = vec3(0.09, 0.09, 0.09);
uniform float tile_size = 3.0;
// size of a hex tile (flat to flat) or of a flagstone, in metres
uniform float cell_size = 1.5;
uniform float seam_width = 0.05;
uniform float bevel_width = 0.09;
uniform float bevel_strength = 0.9;
uniform float tile_variation = 0.16;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.25;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.62;
// How much of the deck is wet (shiny, slightly darker puddles).
uniform float wetness : hint_range(0.0, 1.0) = 0.45;
// Moss in the seams and in patches (0 = clean steel).
uniform float moss_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 moss_color : source_color = vec3(0.16, 0.24, 0.07);
// Hex floors: a few cells are lit panels.
uniform vec3 cell_glow_color : source_color = vec3(0.25, 0.8, 0.55);
uniform float cell_glow_amount : hint_range(0.0, 1.0) = 0.0;

uniform vec3 hive_center = vec3(13.5, 0.0, -8.5);
uniform float hive_radius = 7.0;
uniform vec3 grime_color : source_color = vec3(0.12, 0.13, 0.05);
uniform vec3 vein_color : source_color = vec3(0.78, 0.9, 0.12);
uniform float vein_energy = 0.7;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

// Square plates: cell id and distance to the nearest seam (metres).
vec3 plates(vec2 w) {
	vec2 p = w / tile_size;
	vec2 f = fract(p);
	float edge = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)) * tile_size;
	return vec3(floor(p), edge);
}

// Hex tiles: cell id and distance to the nearest edge (metres).
vec3 hexes(vec2 w) {
	vec2 p = w / cell_size;
	const vec2 s = vec2(1.0, 1.7320508);
	vec4 hc = floor(vec4(p, p - vec2(0.5, 1.0)) / s.xyxy) + 0.5;
	vec4 h = vec4(p - hc.xy * s, p - (hc.zw + 0.5) * s);
	vec2 local = h.xy;
	vec2 id = hc.xy;
	if (dot(h.zw, h.zw) < dot(h.xy, h.xy)) {
		local = h.zw;
		id = hc.zw + 0.5;
	}
	vec2 a = abs(local);
	float d = max(dot(a, s * 0.5), a.x);
	return vec3(id, (0.5 - d) * cell_size);
}

// Flagstones: a jittered Voronoi, stone id and distance to the nearest joint (metres).
vec3 stones(vec2 w) {
	vec2 p = w / cell_size;
	vec2 ip = floor(p);
	vec2 fp = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	vec2 id = vec2(0.0);
	vec2 c1 = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = g + 0.15 + 0.7 * hash2(ip + g) - fp;
			float d = dot(o, o);
			if (d < d1) {
				d2 = d1;
				d1 = d;
				id = ip + g;
				c1 = o;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	// distance to the bisector between the two nearest stones
	float edge = (sqrt(d2) - sqrt(d1)) * 0.5;
	return vec3(id, edge * cell_size);
}

vec3 cell_of(vec2 w) {
	if (pattern == 1) {
		return hexes(w);
	} else if (pattern == 2) {
		return stones(w);
	}
	return plates(w);
}

// Bump: perturbs the (view-space) normal by a height field using screen-space derivatives.
vec3 bump(vec3 n, vec3 pos, float h) {
	vec3 dpdx = dFdx(pos);
	vec3 dpdy = dFdy(pos);
	float dhdx = dFdx(h);
	float dhdy = dFdy(h);
	vec3 r1 = cross(dpdy, n);
	vec3 r2 = cross(n, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = sign(det) * (dhdx * r1 + dhdy * r2);
	return normalize(abs(det) * n - grad);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 w = world_pos.xz;
	vec3 c = cell_of(w);
	vec2 cell = c.xy;
	float edge = c.z;
	float sw = seam_width * (pattern == 2 ? 1.15 : 1.0);
	float seam = 1.0 - smoothstep(sw * 0.5, sw, edge);
	// bevel: tiles slope down into the seams
	float bevel = smoothstep(sw * 0.5, sw + bevel_width, edge);

	float tone = 1.0 + (hash(cell) - 0.5) * tile_variation * (pattern == 2 ? 2.4 : 1.0);
	float smudge = fbm(w * 0.35);
	vec3 col = base_color * tone * mix(0.75, 1.2, smudge);
	if (pattern == 2) {
		// stone: a little warmer, pitted
		col *= vec3(1.04, 1.0, 0.94) * mix(0.85, 1.05, vnoise(w * 3.1));
	}
	col = mix(col, seam_color, seam);

	// Moss: fills the seams and creeps over in patches.
	float patch = smoothstep(0.52, 0.72, fbm(w * 0.22 + vec2(5.3, 1.9)));
	float moss = clamp((seam * 0.9 + (1.0 - bevel) * 0.5) * smoothstep(0.35, 0.6, fbm(w * 0.6)) + patch * 0.85, 0.0, 1.0) * moss_amount;
	col = mix(col, moss_color * mix(0.7, 1.25, vnoise(w * 4.0)), moss);

	// Hive infestation: grime + glowing veins fading out with distance.
	float d = length(w - hive_center.xz) + (fbm(w * 0.5) - 0.5) * 4.0;
	float infest = 1.0 - smoothstep(hive_radius * 0.25, hive_radius, d);
	col = mix(col, grime_color, infest * 0.8);
	float n = fbm(w * 1.1 + vec2(3.7, 1.3));
	float vein = (1.0 - smoothstep(0.0, 0.018, abs(n - 0.5))) * step(0.45, fbm(w * 0.3 + vec2(1.7, 9.2)));

	// Wet patches: darker and glossy, so lamps leave bright streaks on the deck.
	float wet = smoothstep(0.62 - wetness * 0.25, 0.68 - wetness * 0.25, fbm(w * 0.12 + vec2(7.1, 2.3)));
	col *= mix(1.0, 0.72, wet);

	// Lit hex panels: a soft glow inside a few cells, brighter toward the middle.
	float lit = step(1.0 - cell_glow_amount, hash(cell + vec2(17.0, 3.0))) * (pattern == 1 ? 1.0 : 0.0);
	float lit_shape = smoothstep(0.0, cell_size * 0.45, edge) * (0.55 + 0.45 * vnoise(w * 1.3 + TIME * 0.15));

	ALBEDO = col;
	METALLIC = mix(metallic_value, 0.0, max(moss, pattern == 2 ? 1.0 : 0.0));
	ROUGHNESS = mix(mix(mix(roughness_value - 0.15 * smudge, 0.12, wet), 0.9, seam), 0.95, moss);
	NORMAL = bump(NORMAL, VERTEX, bevel * bevel_strength * 0.06);
	EMISSION = vein_color * vein * infest * vein_energy + cell_glow_color * lit * lit_shape * 0.35 * (1.0 - moss);
}
