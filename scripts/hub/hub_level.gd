@tool
class_name HubLevel
extends Node3D
## "The Rig": the safe platform at the top of the shaft between dives.
## Stations (E to use): ARMORY (gear), FABRICATOR (crates), AUGMENTS (perks),
## CONTRACTS (pick a depth and drop). Plus a test range with training dummies.

@export_tool_button("Rebuild rig") var rebuild_action := _rebuild
@export var deck := Rect2(-14, -9, 28, 18)
@export var lamp_color := Color("ffae45")
@export var sign_color := Color("19f4ff")

var player_start := Vector3(2, 0, 4)
var stations := {}  ## "armory" / "fabricator" / "augments" / "contracts" -> Interactable

var _kit: LevelKit


## The deck material (Graphics swaps its shader for a cheaper one on LOW).
func floor_material() -> ShaderMaterial:
	return _kit.mats.get("floor") if _kit else null


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	var old := get_node_or_null("Generated")
	if old:
		remove_child(old)
		old.free()
	stations.clear()
	_kit = LevelKit.new(self)
	_kit.lamp_fog_energy = 0.7
	_kit.make_materials(Vector3(0, 0, 500), 1.0, 3.0)
	var r := deck
	_kit.deck(r)
	_kit.rails_around(r, [], lamp_color, false)
	# Guide lines and floor markings.
	_kit.guide_line(Vector3(r.position.x + 1.0, 0, -4.5), Vector3(r.end.x - 1.0, 0, -4.5))
	_kit.guide_line(Vector3(-4.0, 0, -4.5), Vector3(-4.0, 0, r.end.y - 1.0), 0.12, _kit.mats.guide_white)
	_kit.hazard_panel(Vector2(6.0, 5.0), Vector3(10.0, 0, 2.0))
	_kit.hazard_panel(Vector2(3.0, 3.0), Vector3(-7.5, 0, 5.4))
	# Pump housings behind the north rail (Coolant Pumping Station concept).
	for x in [-9.0, 0.0, 9.0]:
		_kit.box(Vector3(5.0, 3.6, 2.6), Vector3(x, 1.0, r.position.y - 2.2), _kit.mats.machine)
		_kit.box(Vector3(3.6, 0.16, 0.05), Vector3(x, 2.4, r.position.y - 0.88), _kit.mats.teal_strip, false, 0.0, false)
	_kit.crate(6.2, 6.6, 0, 1)
	_kit.crate(7.9, 6.6, 0, 2)
	_kit.crate(-12.0, -1.0, 90, 1)
	_kit.void_dressing(r.grow(6.0), -2.5, 0.04, Color("b6bec6"), Color.BLACK)
	_kit.flush_batches()

	if Engine.is_editor_hint():
		return
	_station("armory", "ARMORY", "Open armory", Vector3(-8.0, 0, -7.2))
	_station("fabricator", "FABRICATOR", "Open fabricator", Vector3(-2.0, 0, -7.2))
	_station("augments", "AUGMENTS", "Spend perk points", Vector3(4.0, 0, -7.2))
	_station("contracts", "CONTRACTS", "Choose a contract", Vector3(10.0, 0, -2.6))
	var lift := ExtractionLift.new()
	lift.position = Vector3(10.0, 0, 2.0)
	_kit.root.add_child(lift)
	_sign("TEST RANGE", Vector3(-7.5, 0, 3.0), Color("ffae45"))
	for p in [Vector3(-10.5, 0, 6.2), Vector3(-7.5, 0, 7.0), Vector3(-4.5, 0, 6.2)]:
		var dummy := TrainingDummy.new()
		dummy.position = p
		dummy.rotation.y = PI
		_kit.root.add_child(dummy)


func _station(id: String, title: String, prompt: String, pos: Vector3) -> void:
	var it := Interactable.new()
	it.style = &"terminal"
	it.prompt = prompt
	it.ready_color = sign_color
	it.radius = 2.6
	it.position = pos
	_kit.root.add_child(it)
	stations[id] = it
	_sign(title, pos + Vector3(0, 0, 0.2), sign_color)


func _sign(text: String, pos: Vector3, color: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 64
	l.outline_size = 14
	l.pixel_size = 0.01
	l.modulate = color
	l.outline_modulate = Color(0.01, 0.04, 0.05, 1)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos + Vector3(0, 3.0, 0)
	_kit.root.add_child(l)
