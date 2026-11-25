class_name EnergyGate
extends Node3D
## A barrier of light across a doorway that seals a strike arena while its fight runs.
## Solid to everyone (world layer) while up. `raise()` and `drop()` animate it.

@export var width := 4.0
@export var height := 3.2
@export var color := Color(1.0, 0.35, 0.18)

var _mat := ShaderMaterial.new()
var _body: StaticBody3D
var _shape: CollisionShape3D
var _light: OmniLight3D
var _rise := 0.0
var _target := 0.0


func _ready() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, height, 0.12)
	mi.mesh = bm
	mi.position.y = height * 0.5
	_mat.shader = preload("res://scripts/shaders/energy_gate.gdshader")
	_mat.set_shader_parameter("tint", color)
	_mat.set_shader_parameter("rise", 0.0)
	_mat.set_shader_parameter("size", Vector2(width, height))
	mi.material_override = _mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	# emitters at both ends
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color("1c2024")
	post_mat.emission_enabled = true
	post_mat.emission = color
	post_mat.emission_energy_multiplier = 2.5
	for s in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.3, height + 0.3, 0.4)
		post.mesh = pm
		post.material_override = post_mat
		post.position = Vector3(s * (width * 0.5 + 0.1), (height + 0.3) * 0.5, 0)
		add_child(post)
	_body = StaticBody3D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, height, 0.5)
	_shape.shape = box
	_shape.position.y = height * 0.5
	_shape.disabled = true
	_body.add_child(_shape)
	add_child(_body)
	_light = OmniLight3D.new()
	_light.light_color = color
	_light.omni_range = 5.0
	_light.light_energy = 0.0
	_light.position.y = 1.4
	_light.light_volumetric_fog_energy = 0.0
	add_child(_light)
	visible = false


func raise() -> void:
	_target = 1.0
	visible = true
	_shape.set_deferred("disabled", false)


func drop() -> void:
	_target = 0.0
	_shape.set_deferred("disabled", true)


func is_up() -> bool:
	return _target > 0.5


func _process(delta: float) -> void:
	if is_equal_approx(_rise, _target):
		return
	_rise = move_toward(_rise, _target, delta * (3.0 if _target > _rise else 2.0))
	_mat.set_shader_parameter("rise", _rise)
	_light.light_energy = 1.6 * _rise
	if _rise <= 0.0:
		visible = false
