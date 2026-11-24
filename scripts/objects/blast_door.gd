class_name BlastDoor
extends Node3D
## Pressure-lock blast door (spans local Z). Hit the switch and it slams shut for
## a while: cuts a pursuing swarm off from you, and crushes anything under it.

@export var width := 3.0
@export var height := 3.2
@export var close_time := 12.0
@export var cooldown := 6.0
@export var slam_time := 0.25
@export var crush_damage := 400.0

enum Mode { OPEN, CLOSING, CLOSED, OPENING, COOLDOWN }

var switch: Interactable
var mode := Mode.OPEN

var _t := 0.0
var _slab: MeshInstance3D
var _shape: CollisionShape3D
var _red_mat: StandardMaterial3D


func _ready() -> void:
	var slab_mat := StandardMaterial3D.new()
	slab_mat.albedo_color = Color("5a6168")
	slab_mat.metallic = 0.7
	slab_mat.roughness = 0.4
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color("2a3036")
	frame_mat.metallic = 0.6
	_red_mat = StandardMaterial3D.new()
	_red_mat.albedo_color = Color(0.1, 0.01, 0.01)
	_red_mat.emission_enabled = true
	_red_mat.emission = Color("ff2a2a")
	_red_mat.emission_energy_multiplier = 0.6

	_slab = _box(Vector3(0.35, height, width), Vector3(0, height * 1.5, 0), slab_mat)
	_box(Vector3(0.36, 0.25, width * 0.9), Vector3(0, 0.4, 0), _red_mat).reparent(_slab, false)
	_box(Vector3(0.8, 0.5, width + 0.6), Vector3(0, height + 0.25, 0), frame_mat)
	for s in [-1.0, 1.0]:
		_box(Vector3(0.8, height, 0.3), Vector3(0, height * 0.5, s * (width * 0.5 + 0.15)), frame_mat)
		_box(Vector3(0.82, 0.3, 0.12), Vector3(0, height * 0.8, s * (width * 0.5 + 0.15)), _red_mat)

	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	_shape = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.5, height, width)
	_shape.shape = shape
	_shape.position = Vector3(0, height * 0.5, 0)
	_shape.disabled = true
	body.add_child(_shape)
	if switch:
		switch.used.connect(func(_by): close())
	_update_switch()


func close() -> void:
	if mode != Mode.OPEN:
		return
	mode = Mode.CLOSING
	_t = 0.0
	Audio.play_at(&"blast_door_close", global_position)
	_shape.set_deferred("disabled", false)
	_red_mat.emission_energy_multiplier = 5.0
	_update_switch()


func _physics_process(delta: float) -> void:
	if mode == Mode.OPEN:
		return
	_t += delta
	match mode:
		Mode.CLOSING:
			var k := clampf(_t / slam_time, 0.0, 1.0)
			_slab.position.y = lerpf(height * 1.5, height * 0.5, k * k)
			if k >= 1.0:
				mode = Mode.CLOSED
				_t = 0.0
				_crush()
		Mode.CLOSED:
			if _t >= close_time:
				mode = Mode.OPENING
				_t = 0.0
				Audio.play_at(&"blast_door_open", global_position)
		Mode.OPENING:
			var k := clampf(_t / 0.8, 0.0, 1.0)
			_slab.position.y = lerpf(height * 0.5, height * 1.5, k)
			if k >= 1.0:
				_shape.set_deferred("disabled", true)
				_red_mat.emission_energy_multiplier = 0.6
				mode = Mode.COOLDOWN
				_t = 0.0
				_update_switch()
		Mode.COOLDOWN:
			if _t >= cooldown:
				mode = Mode.OPEN
				_update_switch()


func _crush() -> void:
	Game.shake(0.35)
	var a := to_global(Vector3(0, 0, -width * 0.5))
	var b := to_global(Vector3(0, 0, width * 0.5))
	if Game.spawner:
		for e in Game.spawner.enemies_on_segment(a, b, 0.2):
			e.take_hit(crush_damage, global_transform.basis.x, 0.0, Game.TEAM_NEUTRAL, &"crush")
	if Game.fx:
		Game.fx.spark(global_position + Vector3.UP * 0.3, Color("ffae45"), Vector3.UP)


func _update_switch() -> void:
	if switch == null:
		return
	switch.set_enabled(mode == Mode.OPEN)
	switch.disabled_prompt = "Blast door sealed" if mode == Mode.CLOSING or mode == Mode.CLOSED else "Blast door cycling"


func _box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi
