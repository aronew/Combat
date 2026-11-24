class_name TrainingDummy
extends StaticBody3D
## Indestructible target for the Rig's test range. Shows damage numbers and a
## rolling DPS readout so you can compare guns and blades.

@export var dps_window := 3.0
@export var hit_radius := 0.6
var surface_kind := Surface.Kind.METAL

var _hits: Array = []  # [time, damage]
var _t := 0.0
var _label: Label3D
var _flash := 0.0
var _body_mat: StandardMaterial3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 1.6
	cs.shape = shape
	cs.position = Vector3(0, 0.8, 0)
	add_child(cs)
	_body_mat = StandardMaterial3D.new()
	_body_mat.albedo_color = Color("6b737a")
	_body_mat.roughness = 0.6
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.2, 0.05, 0.02)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color("ff8a1e")
	ring_mat.emission_energy_multiplier = 2.5
	_mesh(CapsuleMesh.new(), Vector3(0, 0.85, 0), _body_mat, Vector3(1.0, 1.0, 1.0), {"radius": 0.4, "height": 1.5})
	_mesh(SphereMesh.new(), Vector3(0, 1.75, 0), _body_mat, Vector3.ONE, {"radius": 0.25, "height": 0.5})
	_mesh(TorusMesh.new(), Vector3(0, 1.1, -0.38), ring_mat, Vector3(0.3, 0.3, 0.3), {"inner_radius": 0.6, "outer_radius": 1.0})
	_mesh(BoxMesh.new(), Vector3(0, 0.05, 0), _body_mat, Vector3.ONE, {"size": Vector3(1.2, 0.1, 1.2)})
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.font_size = 40
	_label.outline_size = 10
	_label.pixel_size = 0.008
	_label.modulate = Color("ffd23d")
	_label.position = Vector3(0, 2.5, 0)
	_label.text = "DPS 0"
	add_child(_label)
	Game.damageables.append(self)


func _exit_tree() -> void:
	Game.damageables.erase(self)


func is_alive() -> bool:
	return true


func take_hit(damage: float, _direction: Vector3, _knockback: float, _team: int, kind: StringName) -> float:
	_hits.append([_t, damage])
	_flash = 1.0
	if Game.fx:
		Game.fx.on_enemy_hit(global_position, damage, false, kind)
	return damage


func _process(delta: float) -> void:
	_t += delta
	while not _hits.is_empty() and _t - float(_hits[0][0]) > dps_window:
		_hits.pop_front()
	var total := 0.0
	for h in _hits:
		total += float(h[1])
	_label.text = "DPS %d" % roundi(total / dps_window)
	_flash = maxf(_flash - delta * 8.0, 0.0)
	_body_mat.albedo_color = Color("6b737a").lerp(Color.WHITE, _flash)


func _mesh(m: PrimitiveMesh, pos: Vector3, mat: Material, scl: Vector3, props: Dictionary) -> void:
	for k in props:
		m.set(k, props[k])
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	add_child(mi)
