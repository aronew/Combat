class_name StationLook
## Shared surface look for hand-built rooms: every kit piece and AI-made prop gets the cutaway
## shader (scripts/shaders/cutaway.gdshader), and the kit's flat colours become CC0 textures
## (assets/textures/cc0) with dirt in the creases and paint worn off the edges (baked into the
## kit's vertex colours by art_src/blender/build_station_kit.py).
##
##   StationLook.apply(node)              # after instancing a kit piece or prop
##   StationLook.apply(node, {"WallPanel": Color(...)})   # repaint a material for this room
##   StationLook.update_cutaway(viewport) # every frame, from the level

const CUTAWAY := preload("res://scripts/shaders/cutaway.gdshader")
const TEX := "res://assets/textures/cc0/%s_%s.jpg"

## How each kit material is surfaced: texture set, tint, roughness, repeats per metre,
## desaturation (0..1), wetness (0..1). Materials not listed keep their flat colour.
const KIT := {
	"FloorPlate": ["large_floor_tiles_02", Color(1.25, 1.17, 1.08), 0.55, 0.25, 0.3, 0.45],
	"FloorInset": ["large_floor_tiles_02", Color(1.1, 1.03, 0.96), 0.55, 0.25, 0.3, 0.45],
	"FloorSeam": ["metal_plate_02", Color(0.3, 0.3, 0.33), 0.5, 0.5, 0.5, 0.0],
	"WallDark": ["metal_plate_02", Color(0.9, 0.82, 0.92), 0.5, 0.35, 0.6, 0.0],
	"WallPanel": ["rusty_metal_02", Color(0.85, 0.62, 0.64), 0.5, 0.3, 0.75, 0.0],
	"WallTrim": ["metal_plate", Color(1.0, 0.95, 1.05), 0.5, 0.5, 0.5, 0.0],
	"MetalDark": ["metal_plate_02", Color(0.55, 0.52, 0.58), 0.5, 0.5, 0.6, 0.0],
	"HazardYellow": ["rusty_metal_02", Color(1.0, 0.7, 0.08), 0.5, 0.5, 1.0, 0.0],
	"CargoOrange": ["rusty_painted_metal", Color(1.15, 0.55, 0.25), 0.5, 0.4, 0.8, 0.0],
}

## Flat materials whose base colour is scaled down: the pillar's light panels are lit by the
## pillar's own lamp, and at full white they blow out to a glare.
const FLAT_SCALE := {"PillarLight": 0.3}

static var _cache := {}


## A triplanar CC0-textured surface with the cutaway.
static func surface(tex: String, tint: Color, roughness := 0.5, scale := 0.25, desat := 0.0, wet := 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = CUTAWAY
	m.set_shader_parameter("use_textures", true)
	m.set_shader_parameter("albedo_tex", load(TEX % [tex, "albedo"]))
	m.set_shader_parameter("normal_tex", load(TEX % [tex, "normal"]))
	m.set_shader_parameter("arm_tex", load(TEX % [tex, "arm"]))
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("roughness", roughness)
	m.set_shader_parameter("metallic", 0.0)
	m.set_shader_parameter("tex_scale", scale)
	m.set_shader_parameter("desaturate", desat)
	m.set_shader_parameter("wetness", wet)
	return m


## The cutaway version of an imported material: UV-textured for the AI models, CC0-textured
## with wear for the kit, flat colour for glows and anything else.
static func material_for(src: Material, overrides := {}) -> Material:
	var key := "%s|%s|%s" % [src.resource_name, src.get_instance_id(), overrides.get(src.resource_name, "")]
	if _cache.has(key):
		return _cache[key]
	var out: Material = src
	var std := src as BaseMaterial3D
	if std:
		var m: ShaderMaterial
		if std.albedo_texture:
			m = ShaderMaterial.new()
			m.shader = CUTAWAY
			m.set_shader_parameter("use_textures", true)
			m.set_shader_parameter("use_uv", true)
			m.set_shader_parameter("albedo_tex", std.albedo_texture)
			m.set_shader_parameter("normal_tex", std.normal_texture)
			m.set_shader_parameter("arm_tex", std.roughness_texture)
			m.set_shader_parameter("tint", std.albedo_color)
			m.set_shader_parameter("roughness", 0.5)
			m.set_shader_parameter("metallic", 0.0)
		elif KIT.has(src.resource_name):
			var k: Array = KIT[src.resource_name]
			var tint: Color = overrides.get(src.resource_name, k[1])
			m = surface(k[0], tint, k[2], k[3], k[4], k[5])
			m.set_shader_parameter("use_wear", true)
			if src.resource_name.begins_with("Floor"):
				m.set_shader_parameter("macro_var", 0.5)
				m.set_shader_parameter("edge_wear", 0.25)
		else:
			m = ShaderMaterial.new()
			m.shader = CUTAWAY
			var c: Color = overrides.get(src.resource_name, std.albedo_color)
			var k: float = FLAT_SCALE.get(src.resource_name, 1.0)
			m.set_shader_parameter("tint", Color(c.r * k, c.g * k, c.b * k))
			m.set_shader_parameter("roughness", std.roughness)
			m.set_shader_parameter("metallic", std.metallic)
		if std.emission_enabled:
			var e := std.emission
			m.set_shader_parameter("emission", Vector3(e.r, e.g, e.b))
			m.set_shader_parameter("emission_energy", std.emission_energy_multiplier)
		out = m
	_cache[key] = out
	return out


## Give every mesh under `n` its cutaway material (the window glass is left alone).
static func apply(n: Node, overrides := {}) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for s in m.mesh.get_surface_count():
			var src := m.get_surface_override_material(s)
			if src == null:
				src = m.mesh.surface_get_material(s)
			if src and src.resource_name != "SpaceGlass":
				m.set_surface_override_material(s, material_for(src, overrides))


## Keep a camera-side rim piece cut to waist height wherever the player is.
static func always_cut(n: Node) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as GeometryInstance3D).set_instance_shader_parameter("always_cut", true)


## A small lamp at the foot of a wall, washing light up it (as along the ribs of the station
## halls): a glowing block plus a short-range light.
static func wall_lamp(parent: Node3D, pos: Vector3, color: Color, energy := 1.4) -> void:
	var key := "lamp|%s" % color
	if not _cache.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 4.0
		_cache[key] = m
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.36, 0.14, 0.36)
	mi.mesh = bm
	mi.material_override = _cache[key]
	mi.position = pos + Vector3(0, 0.07, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	var l := OmniLight3D.new()
	l.position = pos + Vector3(0, 0.35, 0)
	l.light_color = color
	l.light_energy = energy
	l.omni_range = 3.2
	l.omni_attenuation = 1.4
	parent.add_child(l)


## Tell the cutaway where the player is and which way the camera looks at her.
static func update_cutaway(viewport: Viewport) -> void:
	var cam := viewport.get_camera_3d()
	if Game.player == null or cam == null:
		return
	var p: Vector3 = Game.player.global_position
	var v := cam.global_position - p
	v.y = 0.0
	RenderingServer.global_shader_parameter_set("cutaway_player", p)
	RenderingServer.global_shader_parameter_set("cutaway_view", v.normalized())
