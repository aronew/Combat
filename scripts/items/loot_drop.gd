class_name LootDrop
extends Node3D
## An item lying on the deck: a light column in its rarity colour plus a name
## tag. Walk over it to pick it up into the dive bag (banked only if you extract).

@export var pickup_radius := 1.5
@export var beam_height := 5.0

var item := {}

var _t := 0.0
var _taken := false
var _beam_mat: ShaderMaterial
var _label: Label3D
var _core: MeshInstance3D


func setup(it: Dictionary) -> void:
	item = it


func _ready() -> void:
	var c := Loot.color(item)
	var rarity := int(item.get("rarity", 0))
	var shader := preload("res://scripts/shaders/neon_fade.gdshader")
	_beam_mat = ShaderMaterial.new()
	_beam_mat.shader = shader
	_beam_mat.set_shader_parameter("tint", c)
	_beam_mat.set_shader_parameter("energy", 1.2 + rarity * 0.6)
	_beam_mat.set_shader_parameter("fade", 0.5)
	_beam_mat.set_shader_parameter("edge_softness", 0.85)
	var beam := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.12
	cyl.bottom_radius = 0.35
	cyl.height = beam_height * (0.7 + rarity * 0.2)
	cyl.radial_segments = 10
	beam.mesh = cyl
	beam.material_override = _beam_mat
	beam.position = Vector3(0, cyl.height * 0.5, 0)
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(beam)

	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.75
	tm.outer_radius = 0.9
	ring.mesh = tm
	ring.material_override = _beam_mat
	ring.scale = Vector3(1, 0.2, 1)
	ring.position.y = 0.05
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)

	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = c.darkened(0.5)
	core_mat.emission_enabled = true
	core_mat.emission = c
	core_mat.emission_energy_multiplier = 3.0
	_core = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.35, 0.22, 0.6) if item.get("slot", "") in ["gun", "blade"] else Vector3(0.4, 0.4, 0.4)
	_core.mesh = bm
	_core.material_override = core_mat
	_core.position.y = 0.6
	add_child(_core)

	_label = Label3D.new()
	_label.text = item.get("name", "Item")
	_label.modulate = c
	_label.outline_modulate = Color(0.02, 0.02, 0.04, 1)
	_label.font_size = 40
	_label.outline_size = 10
	_label.pixel_size = 0.008
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.render_priority = 12
	_label.position.y = 1.5
	add_child(_label)
	if rarity >= Loot.Rarity.EPIC and Game.fx:
		Game.fx.burst(global_position + Vector3.UP * 0.5, Vector3.ZERO, 1.0 + rarity * 0.3, c)


func _process(delta: float) -> void:
	_t += delta
	_core.rotation.y += delta * 2.0
	_core.position.y = 0.6 + sin(_t * 3.0) * 0.1
	_beam_mat.set_shader_parameter("fade", 0.4 + 0.15 * sin(_t * 4.0))
	if _taken:
		return
	var p := Game.player
	if p and p.alive and Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length() < pickup_radius:
		_take()


func _take() -> void:
	_taken = true
	Profile.add_to_bag(item)
	Game.loot_picked.emit(item)
	if Game.fx:
		Game.fx.burst(global_position + Vector3.UP * 0.5, Vector3.ZERO, 0.8, Loot.color(item))
	queue_free()
