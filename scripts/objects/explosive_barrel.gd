class_name ExplosiveBarrel
extends StaticBody3D
## Volatile coolant drum. Shoot it, slash it, or blow it up with another
## explosion; it detonates after a short fuse and damages EVERYTHING nearby,
## so kiting a swarm past one is a valid tactic.

@export var health := 12.0
@export var blast_radius := 3.8
@export var enemy_damage := 90.0
@export var player_damage := 32.0
@export var knockback := 14.0
@export var fuse := 0.14
@export var hit_radius := 0.45

var _alive := true
var _fused := false
var _shell_mat: StandardMaterial3D
var _band_mat: StandardMaterial3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.4
	shape.height = 1.05
	cs.shape = shape
	cs.position = Vector3(0, 0.525, 0)
	add_child(cs)

	_shell_mat = StandardMaterial3D.new()
	_shell_mat.albedo_color = Color("a3301e")
	_shell_mat.metallic = 0.4
	_shell_mat.roughness = 0.45
	_band_mat = StandardMaterial3D.new()
	_band_mat.albedo_color = Color("1a1a1a")
	_band_mat.emission_enabled = true
	_band_mat.emission = Color("ffb21e")
	_band_mat.emission_energy_multiplier = 1.6
	_add_cyl(0.38, 1.0, Vector3(0, 0.5, 0), _shell_mat)
	_add_cyl(0.395, 0.1, Vector3(0, 0.72, 0), _band_mat)
	_add_cyl(0.395, 0.06, Vector3(0, 0.3, 0), _band_mat)
	_add_cyl(0.3, 0.04, Vector3(0, 1.01, 0), _band_mat)
	Game.damageables.append(self)


func _exit_tree() -> void:
	Game.damageables.erase(self)


func is_alive() -> bool:
	return _alive and not _fused


func take_hit(damage: float, _direction: Vector3, _knockback: float, _team: int, _kind: StringName) -> float:
	if not is_alive():
		return 0.0
	health -= damage
	if health <= 0.0:
		_fused = true
		_shell_mat.emission_enabled = true
		_shell_mat.emission = Color("fff2c0")
		_shell_mat.emission_energy_multiplier = 4.0
		Game.delayed_explode(fuse, global_position + Vector3.UP * 0.5, blast_radius, enemy_damage, player_damage, knockback, self, 2.6)
		get_tree().create_timer(fuse, false).timeout.connect(_vanish)
	return damage


func _vanish() -> void:
	_alive = false
	visible = false
	collision_layer = 0


func _add_cyl(radius: float, height: float, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 14
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
