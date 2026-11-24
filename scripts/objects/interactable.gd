class_name Interactable
extends Node3D
## Something the player can use with E (switches, the uplink terminal).
## The player picks the nearest enabled one in range; the HUD shows `prompt`.

signal used(by: Node)

@export var prompt := "Use"
@export var disabled_prompt := ""
@export var radius := 2.3
## &"switch" (wall-side pedestal) or &"terminal" (big uplink console).
@export var style: StringName = &"switch"
@export var ready_color := Color("3dff9a")
@export var busy_color := Color("ff3b3b")

var enabled := true

var _light: OmniLight3D
var _lamp_mat: StandardMaterial3D


func _ready() -> void:
	_build()
	Game.interactables.append(self)
	set_enabled(enabled)


func _exit_tree() -> void:
	Game.interactables.erase(self)


func get_prompt() -> String:
	return prompt if enabled else disabled_prompt


func set_enabled(v: bool) -> void:
	enabled = v
	var c := ready_color if enabled else busy_color
	if _lamp_mat:
		_lamp_mat.emission = c
	if _light:
		_light.light_color = c


func use(by: Node) -> void:
	if enabled:
		used.emit(by)


func _build() -> void:
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color("2a3036")
	dark.metallic = 0.6
	dark.roughness = 0.45
	var light_grey := StandardMaterial3D.new()
	light_grey.albedo_color = Color("9aa2a8")
	light_grey.roughness = 0.55
	_lamp_mat = StandardMaterial3D.new()
	_lamp_mat.albedo_color = Color(0.05, 0.05, 0.05)
	_lamp_mat.emission_enabled = true
	_lamp_mat.emission_energy_multiplier = 4.0

	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	cs.shape = shape
	body.add_child(cs)

	if style == &"terminal":
		_add_box(Vector3(1.8, 1.2, 0.9), Vector3(0, 0.6, 0), light_grey)
		_add_box(Vector3(1.9, 0.12, 1.0), Vector3(0, 1.22, 0), dark)
		var screen_mat := StandardMaterial3D.new()
		screen_mat.albedo_color = Color(0.02, 0.08, 0.09)
		screen_mat.emission_enabled = true
		screen_mat.emission = Color("19f4ff")
		screen_mat.emission_energy_multiplier = 2.5
		var screen := _add_box(Vector3(1.3, 0.7, 0.06), Vector3(0, 1.65, 0.1), screen_mat)
		screen.rotation.x = -0.35
		_add_box(Vector3(0.25, 0.25, 0.25), Vector3(0.7, 1.35, 0.25), _lamp_mat)
		# Cable bundle into the floor.
		_add_box(Vector3(0.18, 0.12, 1.6), Vector3(-0.6, 0.06, -1.1), dark)
		shape.size = Vector3(1.8, 1.4, 0.9)
		cs.position = Vector3(0, 0.7, 0)
	else:
		_add_box(Vector3(0.5, 1.1, 0.35), Vector3(0, 0.55, 0), dark)
		_add_box(Vector3(0.36, 0.3, 0.06), Vector3(0, 0.95, 0.18), light_grey)
		_add_box(Vector3(0.16, 0.16, 0.08), Vector3(0, 0.95, 0.22), _lamp_mat)
		shape.size = Vector3(0.5, 1.1, 0.35)
		cs.position = Vector3(0, 0.55, 0)

	_light = OmniLight3D.new()
	_light.light_energy = 0.8
	_light.omni_range = 3.0
	_light.position = Vector3(0, 1.3, 0.6)
	add_child(_light)


func _add_box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi
