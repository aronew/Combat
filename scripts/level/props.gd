class_name Props
extends RefCounted
## Set-dressing props (art_src/blender/build_props.py -> assets/models/props).
## Each entry: footprint (x, z) in metres for collision and spawn blockers,
## height, and whether it blocks movement. A prop's front faces -Z (yaw 0).

const DEFS := {
	"ac_unit": {"size": Vector2(1.76, 1.06), "h": 1.0, "solid": true},
	"electrical_box": {"size": Vector2(0.95, 0.5), "h": 1.6, "solid": true},
	"hard_case": {"size": Vector2(1.18, 0.75), "h": 0.62, "solid": true},
	"cable_spool": {"size": Vector2(1.2, 0.95), "h": 1.0, "solid": true},
	"switchgear": {"size": Vector2(1.2, 1.0), "h": 2.2, "solid": true},
	"server_rack": {"size": Vector2(0.72, 1.0), "h": 2.1, "solid": true},
	"console": {"size": Vector2(1.45, 0.8), "h": 1.4, "solid": true},
	"wall_panel": {"size": Vector2(3.0, 0.5), "h": 3.3, "solid": true},
	"door": {"size": Vector2(3.4, 0.8), "h": 3.6, "solid": true},
	"tank": {"size": Vector2(2.4, 2.4), "h": 3.3, "solid": true},
	"container": {"size": Vector2(6.0, 2.4), "h": 2.6, "solid": true},
	"egg_cluster": {"size": Vector2(2.0, 1.6), "h": 0.7, "solid": false},
	"floor_vent": {"size": Vector2(2.0, 1.4), "h": 0.06, "solid": false},
	"planter": {"size": Vector2(2.4, 1.0), "h": 0.6, "solid": true},
	"locker_row": {"size": Vector2(1.9, 0.5), "h": 2.0, "solid": true},
}

static var _scenes := {}
static var _tints := {}


static func scene(name: String) -> PackedScene:
	if not _scenes.has(name):
		_scenes[name] = load("res://assets/models/props/%s.glb" % name)
	return _scenes[name]


## Instance a prop under `kit.root` at `pos` (floor), rotated `yaw`, scaled.
## Solid props get a box collider; all props add a spawn blocker.
## `tint` recolours the prop's "Container" material (shipping containers).
static func place(kit: LevelKit, name: String, pos: Vector3, yaw: float, scale := Vector3.ONE, tint := Color(0, 0, 0, 0)) -> Node3D:
	var def: Dictionary = DEFS[name]
	var n: Node3D = scene(name).instantiate()
	n.position = pos
	n.rotation.y = yaw
	n.scale = scale
	kit.root.add_child(n)
	if tint.a > 0.0:
		_apply_tint(n, tint)
	var size: Vector2 = def.size * Vector2(scale.x, scale.z)
	var h: float = def.h * scale.y
	if def.solid:
		kit.collider(Vector3(size.x, h, size.y), pos + Vector3(0, h * 0.5, 0), yaw)
	kit.add_blocker(pos.x, pos.z, maxf(size.x, size.y) * 0.5 + 0.2)
	return n


static func _apply_tint(n: Node, tint: Color) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for s in m.mesh.get_surface_count():
			var mat := m.mesh.surface_get_material(s)
			if mat and mat.resource_name == "Container":
				var key := tint.to_html()
				if not _tints.has(key):
					var t: StandardMaterial3D = (mat as StandardMaterial3D).duplicate()
					t.albedo_color = tint
					_tints[key] = t
				m.set_surface_override_material(s, _tints[key])
