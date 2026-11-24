class_name HiveNest
extends StaticBody3D
## Pulsing egg cluster. While it lives, the Hive Director can pour bugs out of it
## once the station is hunting you. Destroy it to choke off spawns (and loot it).

signal destroyed(nest: HiveNest)

@export var max_health := 160.0
@export var hit_radius := 1.3
@export var salvage := 12
@export var glow := 1.4

var health := 0.0
var _alive := true
var _pods: Array[MeshInstance3D] = []
var _pod_mat: StandardMaterial3D
var _light: OmniLight3D
var _flash := 0.0
var _t := 0.0


func _ready() -> void:
	health = max_health
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.0
	shape.height = 1.6
	cs.shape = shape
	cs.position = Vector3(0, 0.8, 0)
	add_child(cs)

	var flesh := StandardMaterial3D.new()
	flesh.albedo_color = Color("1a2410")
	flesh.roughness = 0.35
	flesh.emission_enabled = true
	flesh.emission = Color("8dff2e")
	flesh.emission_energy_multiplier = 0.12
	_pod_mat = StandardMaterial3D.new()
	_pod_mat.albedo_color = Color("4f9a12")
	_pod_mat.roughness = 0.25
	_pod_mat.emission_enabled = true
	_pod_mat.emission = Color("8dff2e")
	_pod_mat.emission_energy_multiplier = glow

	_sphere(1.25, Vector3(0, 0, 0), flesh, Vector3(1.0, 0.45, 1.0))
	_sphere(0.8, Vector3(0.9, 0, 0.5), flesh, Vector3(1.0, 0.4, 1.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(global_position.x * 13.0 + global_position.z * 7.0))
	for i in 9:
		var ang := rng.randf() * TAU
		var r := rng.randf_range(0.2, 1.1)
		var s := rng.randf_range(0.2, 0.42)
		_pods.append(_sphere(s, Vector3(cos(ang) * r, 0.3 + s * 0.5, sin(ang) * r), _pod_mat, Vector3(1.0, 1.3, 1.0)))
	_pods.append(_sphere(0.5, Vector3(0.1, 0.75, -0.1), _pod_mat, Vector3(1.0, 1.35, 1.0)))

	_light = OmniLight3D.new()
	_light.light_color = Color("8dff2e")
	_light.light_energy = 1.2
	_light.omni_range = 6.0
	_light.light_volumetric_fog_energy = 0.5
	_light.position = Vector3(0, 1.6, 0)
	add_child(_light)
	Game.damageables.append(self)


func _exit_tree() -> void:
	Game.damageables.erase(self)


func is_alive() -> bool:
	return _alive


## A point just outside the nest where a bug can crawl out.
func get_spawn_point() -> Vector3:
	var ang := randf() * TAU
	var p := global_position + Vector3(cos(ang), 0.0, sin(ang)) * randf_range(1.9, 2.6)
	return Game.level.clamp_to_walkable(p) if Game.level else p


func _process(delta: float) -> void:
	if not _alive:
		return
	_t += delta
	_flash = maxf(_flash - delta * 6.0, 0.0)
	var pulse := 0.85 + 0.15 * sin(_t * 3.0)
	_pod_mat.emission_energy_multiplier = glow * pulse + _flash * 6.0
	_light.light_energy = 1.2 * pulse + _flash * 2.0


func take_hit(damage: float, _direction: Vector3, _knockback: float, _team: int, _kind: StringName) -> float:
	if not _alive:
		return 0.0
	health -= damage
	_flash = 1.0
	Audio.play_at(&"nest_hit", global_position)
	if Game.fx:
		Game.fx.spark(global_position + Vector3.UP * 0.8, Color("8dff2e"), Vector3.UP)
	if health <= 0.0:
		_destroy()
	return damage


func _destroy() -> void:
	_alive = false
	collision_layer = 0
	for p in _pods:
		p.visible = false
	_light.light_energy = 0.0
	Audio.play_at(&"nest_destroyed", global_position)
	if Game.fx:
		Game.fx.burst(global_position + Vector3.UP * 0.6, Vector3.ZERO, 2.0)
		Game.fx.damage_number(global_position + Vector3.UP * 2.0, "NEST DESTROYED", Color("8dff2e"), 1.1)
	Game.shake(0.4)
	if Game.pickups:
		Game.pickups.drop_salvage(global_position, salvage)
	destroyed.emit(self)


func _sphere(radius: float, pos: Vector3, mat: Material, squash: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 14
	sm.rings = 7
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	mi.scale = squash
	add_child(mi)
	return mi
