@tool
class_name Level
extends Node3D
## "First Dive": five hand-built rooms connected by catwalks over the void.
##   Drop Lift -> Catwalk Deck -> Switchgear Gallery -> Pressure Lock -> Reactor Ring
## Built from primitives at load (and in the editor, geometry only). Also owns:
## - a region graph (convex walkable rects + portals) that enemies use to route
##   between rooms (see get_nav_target), so swarms follow you through doorways;
## - spawn queries for the Hive Director (burrow/drop points, void leap edges);
## - the hand-placed population and the gameplay objects (barrels, nests,
##   laser grid, blast door, uplink terminal, extraction lift).
## Rects are XZ: Rect2(x, z, width, depth). -Z is north (top of the screen).

@export_tool_button("Rebuild level") var rebuild_action := _rebuild

@export_group("Look")
@export var tile_size := 3.0
@export var hive_center := Vector3(36.5, 0.0, -62.0)
@export var hive_radius := 11.0
@export var lamp_energy := 3.2
@export var lamp_range := 7.0
@export var lamp_emission := 6.0
@export var lamp_fog_energy := 1.5

@export_group("Room lighting")
@export var lift_lamp_color := Color("ffae45")
@export var deck_lamp_color := Color("ffae45")
@export var gallery_lamp_color := Color("7fb2ff")
@export var lock_lamp_color := Color("e8eef5")
@export var reactor_lamp_color := Color("ffae45")

@export_group("Void")
@export var void_fog_density := 0.04
@export var void_fog_top := -2.5
@export var void_fog_albedo := Color("b4dcd8")
@export var void_fog_emission := Color("127078")

const ROOMS := [
	{"id": &"lift", "name": "Drop Lift", "rect": Rect2(-5, 12, 10, 8)},
	{"id": &"deck", "name": "Catwalk Deck", "rect": Rect2(-12, -9, 24, 18)},
	{"id": &"gallery", "name": "Switchgear Gallery", "rect": Rect2(-15, -31, 30, 14), "block": Rect2(-8, -26, 16, 4)},
	{"id": &"lock", "name": "Pressure Lock", "rect": Rect2(23, -33, 18, 18), "split_x": 32.0, "door": Vector2(-21, -18)},
	{"id": &"reactor", "name": "Reactor Ring", "rect": Rect2(23.5, -67, 26, 26), "hole": Rect2(31.5, -59, 10, 10)},
]
const BRIDGES := [
	{"rect": Rect2(-2, 9, 4, 3), "solid": true},
	{"rect": Rect2(-1.5, -17, 3, 8)},
	{"rect": Rect2(15, -25.5, 8, 3)},
	{"rect": Rect2(35, -41, 3, 8)},
]

## Positions the Mission and HUD care about.
var player_start := Vector3(0, 0, 16.5)
var lift_position := Vector3(0, 0, 16.0)
var lift_radius := 3.0
var uplink_position := Vector3(36.5, 0, -64.4)

var regions: Array[Dictionary] = []  # {rect, room, name}
var portals: Array[Dictionary] = []  # {a, b, center, normal (a->b), half}
var placements: Array[Dictionary] = []  # enemies to spawn at mission start
var spawn_edges: Array[Dictionary] = []  # void edges bugs leap over {a, b, inward, length, region, from_shaft}
var minimap_solids: Array[Rect2] = []  # blocks/walls drawn on the minimap
var bounds := Rect2()

# Gameplay objects (runtime only).
var uplink: Interactable
var lift: ExtractionLift
var nests: Array[HiveNest] = []
var turret_spots: Array[Dictionary] = []

var _kit: LevelKit
var _adj: Array = []  # region -> Array of portal indices
var _next: Array = []  # [from][to] -> portal index (or -1)
var _blockers: Array[Vector3] = []


func _ready() -> void:
	_rebuild()
	if not Engine.is_editor_hint():
		Game.level = self


# ==========================================================================
# Navigation & spatial queries
# ==========================================================================

func region_of(p: Vector3) -> int:
	var q := Vector2(p.x, p.z)
	for i in regions.size():
		if (regions[i].rect as Rect2).grow(0.05).has_point(q):
			return i
	return -1


func room_of(p: Vector3) -> StringName:
	var r := region_of(p)
	return regions[r].room if r >= 0 else &""


func region_neighbors(r: int) -> Array[int]:
	var out: Array[int] = []
	if r < 0:
		return out
	for pi in _adj[r]:
		var p: Dictionary = portals[pi]
		out.append(p.b if p.a == r else p.a)
	return out


## Next point to run toward to get from `from` to `to`, routing through
## doorways/bridges. Inside the same convex region it is simply `to`.
func get_nav_target(from: Vector3, to: Vector3) -> Vector3:
	var rf := region_of(from)
	var rt := region_of(to)
	if rf < 0 or rt < 0 or rf == rt:
		return to
	var pi: int = _next[rf][rt]
	if pi < 0:
		return to
	var p: Dictionary = portals[pi]
	var n: Vector3 = p.normal if p.a == rf else -p.normal
	var c: Vector3 = p.center
	var lat := Vector3(-n.z, 0.0, n.x)
	var rel := from - c
	rel.y = 0.0
	var along := rel.dot(n)
	var side := rel.dot(lat)
	var limit := maxf(p.half - 0.6, 0.0)
	var entry := c + lat * clampf(side, -limit, limit)
	if along > -1.6 and absf(side) < p.half - 0.45:
		return entry + n * 1.4
	return entry - n * 1.0


func is_walkable(p: Vector3) -> bool:
	return region_of(p) >= 0


## Pulls a point onto the deck, at least `margin` from any edge.
func clamp_to_walkable(p: Vector3, margin := 0.8) -> Vector3:
	var best := p
	var best_d := INF
	for reg in regions:
		var inner := (reg.rect as Rect2).grow(-margin)
		if inner.size.x <= 0.0 or inner.size.y <= 0.0:
			inner = reg.rect
		var q := Vector2(clampf(p.x, inner.position.x, inner.end.x), clampf(p.z, inner.position.y, inner.end.y))
		var d := q.distance_squared_to(Vector2(p.x, p.z))
		if d < best_d:
			best_d = d
			best = Vector3(q.x, p.y, q.y)
	return best


func is_blocked(p: Vector3, radius: float) -> bool:
	for b in _blockers:
		if Vector2(p.x - b.x, p.z - b.y).length() < b.z + radius:
			return true
	return false


## Random free floor point in the given regions, between min_d and max_d from `near`.
## Returns Vector3.INF if nothing suitable was found.
func random_point(region_ids: Array[int], near: Vector3, min_d: float, max_d: float, margin := 0.9) -> Vector3:
	if region_ids.is_empty():
		return Vector3.INF
	var total := 0.0
	for r in region_ids:
		total += (regions[r].rect as Rect2).get_area()
	for attempt in 24:
		var pick := randf() * total
		var rect: Rect2 = regions[region_ids[0]].rect
		for r in region_ids:
			pick -= (regions[r].rect as Rect2).get_area()
			if pick <= 0.0:
				rect = regions[r].rect
				break
		var inner := rect.grow(-margin)
		if inner.size.x <= 0.0 or inner.size.y <= 0.0:
			continue
		var p := Vector3(randf_range(inner.position.x, inner.end.x), 0.0, randf_range(inner.position.y, inner.end.y))
		var d := Vector2(p.x - near.x, p.z - near.z).length()
		if d < min_d or d > max_d:
			continue
		if is_blocked(p, 0.6):
			continue
		return p
	return Vector3.INF


## [start_in_void, landing_point] for a bug leaping over a railing in the given regions.
func get_leap_spawn(region_ids: Array[int], near: Vector3, min_d: float, max_d: float) -> Array[Vector3]:
	var edges: Array[Dictionary] = []
	var total := 0.0
	for e in spawn_edges:
		if e.region in region_ids:
			edges.append(e)
			total += e.length
	if edges.is_empty():
		return []
	for attempt in 16:
		var pick := randf() * total
		var edge: Dictionary = edges[0]
		for e in edges:
			pick -= e.length
			if pick <= 0.0:
				edge = e
				break
		var p: Vector3 = (edge.a as Vector3).lerp(edge.b, randf_range(0.06, 0.94))
		var land: Vector3 = clamp_to_walkable(p + edge.inward * randf_range(1.3, 2.2))
		var d := Vector2(land.x - near.x, land.z - near.z).length()
		if (d < min_d or d > max_d) and attempt < 12:
			continue
		if is_blocked(land, 0.6):
			continue
		var depth := -4.5 if edge.from_shaft else -3.2
		var start: Vector3 = p - edge.inward * (2.0 if edge.from_shaft else 2.4) + Vector3(0.0, depth, 0.0)
		return [start, land]
	return []


# ==========================================================================
# Building
# ==========================================================================

func _rebuild() -> void:
	var old := get_node_or_null("Generated")
	if old:
		remove_child(old)
		old.free()
	regions.clear()
	portals.clear()
	placements.clear()
	spawn_edges.clear()
	minimap_solids.clear()
	nests.clear()
	turret_spots.clear()
	_blockers.clear()

	_kit = LevelKit.new(self)
	_kit.lamp_energy = lamp_energy
	_kit.lamp_range = lamp_range
	_kit.lamp_emission = lamp_emission
	_kit.lamp_fog_energy = lamp_fog_energy
	_kit.make_materials(hive_center, hive_radius, tile_size)

	_build_regions()
	_build_rooms()
	_build_bridges()
	_finish_spawn_edges()
	_kit.void_dressing(bounds, void_fog_top, void_fog_density, void_fog_albedo, void_fog_emission)
	_blockers.append_array(_kit.blockers)
	if not Engine.is_editor_hint():
		_build_gameplay()
		_build_placements()


func _add_region(rect: Rect2, room: StringName, name_: String) -> int:
	regions.append({"rect": rect, "room": room, "name": name_})
	bounds = rect if regions.size() == 1 else bounds.merge(rect)
	return regions.size() - 1


func _ring_strips(o: Rect2, i: Rect2) -> Array[Rect2]:
	return [
		Rect2(o.position.x, o.position.y, o.size.x, i.position.y - o.position.y),  # north
		Rect2(o.position.x, i.end.y, o.size.x, o.end.y - i.end.y),  # south
		Rect2(o.position.x, i.position.y, i.position.x - o.position.x, i.size.y),  # west
		Rect2(i.end.x, i.position.y, o.end.x - i.end.x, i.size.y),  # east
	]


func _build_regions() -> void:
	for room in ROOMS:
		var r: Rect2 = room.rect
		if room.has("hole") or room.has("block"):
			var inner: Rect2 = room.hole if room.has("hole") else room.block
			var names := ["north", "south", "west", "east"]
			var strips := _ring_strips(r, inner)
			for k in 4:
				_add_region(strips[k], room.id, "%s (%s)" % [room.name, names[k]])
		elif room.has("split_x"):
			var sx: float = room.split_x
			_add_region(Rect2(r.position.x, r.position.y, sx - r.position.x, r.size.y), room.id, room.name + " (west)")
			_add_region(Rect2(sx, r.position.y, r.end.x - sx, r.size.y), room.id, room.name + " (east)")
		else:
			_add_region(r, room.id, room.name)
	for b in BRIDGES:
		_add_region(b.rect, &"bridge", "Catwalk")

	# Portals between every pair of touching regions.
	for i in regions.size():
		for j in range(i + 1, regions.size()):
			var e := _shared_edge(regions[i].rect, regions[j].rect)
			if e.is_empty():
				continue
			var room_i: StringName = regions[i].room
			if room_i == regions[j].room:
				for room in ROOMS:
					if room.id == room_i and room.has("door"):
						e = _clip_edge(e, room.door.x, room.door.y)
			if e.is_empty():
				continue
			e.a = i
			e.b = j
			portals.append(e)

	_adj.clear()
	for i in regions.size():
		_adj.append([])
	for pi in portals.size():
		_adj[portals[pi].a].append(pi)
		_adj[portals[pi].b].append(pi)
	# Next-hop table: BFS outward from every destination.
	_next.clear()
	for i in regions.size():
		var row: Array[int] = []
		row.resize(regions.size())
		row.fill(-1)
		_next.append(row)
	for dest in regions.size():
		var queue: Array[int] = [dest]
		var seen := {dest: true}
		while not queue.is_empty():
			var cur: int = queue.pop_front()
			for pi in _adj[cur]:
				var p: Dictionary = portals[pi]
				var other: int = p.b if p.a == cur else p.a
				if seen.has(other):
					continue
				seen[other] = true
				_next[other][dest] = pi  # from `other`, step through pi toward dest
				queue.append(other)


## Shared boundary segment of two touching rects, or {} if they don't touch.
func _shared_edge(a: Rect2, b: Rect2) -> Dictionary:
	const EPS := 0.02
	if absf(a.end.x - b.position.x) < EPS or absf(b.end.x - a.position.x) < EPS:
		var lo := maxf(a.position.y, b.position.y)
		var hi := minf(a.end.y, b.end.y)
		if hi - lo > 0.3:
			var x := a.end.x if absf(a.end.x - b.position.x) < EPS else a.position.x
			var n := Vector3.RIGHT if absf(a.end.x - b.position.x) < EPS else Vector3.LEFT
			return {"center": Vector3(x, 0, (lo + hi) * 0.5), "normal": n, "half": (hi - lo) * 0.5, "lo": lo, "hi": hi, "axis": &"x"}
	if absf(a.end.y - b.position.y) < EPS or absf(b.end.y - a.position.y) < EPS:
		var lo := maxf(a.position.x, b.position.x)
		var hi := minf(a.end.x, b.end.x)
		if hi - lo > 0.3:
			var z := a.end.y if absf(a.end.y - b.position.y) < EPS else a.position.y
			var n := Vector3.BACK if absf(a.end.y - b.position.y) < EPS else Vector3.FORWARD
			return {"center": Vector3((lo + hi) * 0.5, 0, z), "normal": n, "half": (hi - lo) * 0.5, "lo": lo, "hi": hi, "axis": &"z"}
	return {}


func _clip_edge(e: Dictionary, lo: float, hi: float) -> Dictionary:
	var l := maxf(e.lo, minf(lo, hi))
	var h := minf(e.hi, maxf(lo, hi))
	if h - l < 0.3:
		return {}
	var c: Vector3 = e.center
	if e.axis == &"x":
		c.z = (l + h) * 0.5
	else:
		c.x = (l + h) * 0.5
	e.center = c
	e.lo = l
	e.hi = h
	e.half = (h - l) * 0.5
	return e


## Gaps in a room's outer railing where bridges attach.
func _openings_for(r: Rect2) -> Array:
	var out: Array = []
	for b in BRIDGES:
		var e := _shared_edge(r, b.rect)
		if e.is_empty():
			continue
		var side: StringName
		if e.axis == &"x":
			side = &"e" if absf(e.center.x - r.end.x) < 0.05 else &"w"
		else:
			side = &"s" if absf(e.center.z - r.end.y) < 0.05 else &"n"
		out.append({"side": side, "lo": e.lo, "hi": e.hi})
	return out


func _build_rooms() -> void:
	for room in ROOMS:
		var r: Rect2 = room.rect
		match room.id:
			&"lift":
				_kit.deck(r)
				_kit.rails_around(r, _openings_for(r), lift_lamp_color)
				_dress_lift(r)
			&"deck":
				_kit.deck(r)
				_kit.rails_around(r, _openings_for(r), deck_lamp_color)
				_dress_deck(r)
			&"gallery":
				_kit.deck(r)
				_kit.rails_around(r, _openings_for(r), gallery_lamp_color)
				_kit.machinery_block(room.block)
				minimap_solids.append(room.block)
				_dress_gallery(r, room.block)
			&"lock":
				_kit.deck(r)
				_kit.rails_around(r, _openings_for(r), lock_lamp_color)
				_dress_lock(r, room.split_x, room.door)
			&"reactor":
				var hole: Rect2 = room.hole
				for strip in _ring_strips(r, hole):
					_kit.deck(strip, null, false)
				_kit.rails_around(r, _openings_for(r), reactor_lamp_color)
				_hole_rails(hole)
				_dress_reactor(r, hole)


func _build_bridges() -> void:
	for i in BRIDGES.size():
		var b: Dictionary = BRIDGES[i]
		var r: Rect2 = b.rect
		# Travel direction = across the edges where the bridge meets a room.
		var along_x := r.size.x > r.size.y
		for room in ROOMS:
			var e := _shared_edge(r, room.rect)
			if not e.is_empty():
				along_x = e.axis == &"x"
				break
		_kit.bridge(r, along_x, b.get("solid", false))
		if along_x:
			_kit.rail_run(Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, 0, r.position.y), Vector3.BACK, deck_lamp_color, i % 2 == 0)
			_kit.rail_run(Vector3(r.position.x, 0, r.end.y), Vector3(r.end.x, 0, r.end.y), Vector3.FORWARD, deck_lamp_color, i % 2 == 1)
		else:
			_kit.rail_run(Vector3(r.position.x, 0, r.position.y), Vector3(r.position.x, 0, r.end.y), Vector3.RIGHT, deck_lamp_color, i % 2 == 0)
			_kit.rail_run(Vector3(r.end.x, 0, r.position.y), Vector3(r.end.x, 0, r.end.y), Vector3.LEFT, deck_lamp_color, i % 2 == 1)


func _hole_rails(h: Rect2) -> void:
	var red: Material = _kit.mats.rail_red
	_kit.rail_run(Vector3(h.position.x, 0, h.position.y), Vector3(h.end.x, 0, h.position.y), Vector3.FORWARD, reactor_lamp_color, false, true, true, red)
	_kit.rail_run(Vector3(h.position.x, 0, h.end.y), Vector3(h.end.x, 0, h.end.y), Vector3.BACK, reactor_lamp_color, false, true, true, red)
	_kit.rail_run(Vector3(h.position.x, 0, h.position.y), Vector3(h.position.x, 0, h.end.y), Vector3.LEFT, reactor_lamp_color, false, true, true, red)
	_kit.rail_run(Vector3(h.end.x, 0, h.position.y), Vector3(h.end.x, 0, h.end.y), Vector3.RIGHT, reactor_lamp_color, false, true, true, red)


## Tag each void edge with the region its landing point is in.
func _finish_spawn_edges() -> void:
	for e in _kit.spawn_edges:
		var mid: Vector3 = (e.a + e.b) * 0.5 + e.inward * 1.5
		var r := region_of(mid)
		if r < 0:
			continue
		var copy: Dictionary = e.duplicate()
		copy.region = r
		spawn_edges.append(copy)


# --------------------------------------------------------------------------
# Room dressing (geometry, runs in the editor too)
# --------------------------------------------------------------------------

func _dress_lift(r: Rect2) -> void:
	_kit.hazard_panel(Vector2(6.0, 5.0), Vector3(lift_position.x, 0, lift_position.z))
	_kit.guide_line(Vector3(-2.0, 0, 9.0), Vector3(-2.0, 0, 13.4))
	_kit.guide_line(Vector3(2.0, 0, 9.0), Vector3(2.0, 0, 13.4))
	# Lift shaft housing behind the pad.
	_kit.box(Vector3(10.0, 5.0, 1.2), Vector3(0, 2.0, r.end.y + 0.6), _kit.mats.machine, true)
	_kit.box(Vector3(6.0, 0.18, 0.06), Vector3(0, 3.6, r.end.y - 0.02), _kit.mats.amber_strip, false, 0.0, false)


func _dress_deck(r: Rect2) -> void:
	for c in [Vector4(-8.5, -5.5, 0, 2), Vector4(-6.8, -5.5, 0, 1), Vector4(-8.5, -3.8, 90, 1),
			Vector4(6.5, 5.0, 0, 1), Vector4(8.2, 5.0, 0, 2), Vector4(-9.0, 6.0, 0, 1)]:
		_kit.crate(c.x, c.y, c.z, int(c.w))
	_kit.guide_line(Vector3(-11.0, 0, 7.0), Vector3(11.0, 0, 7.0))
	_kit.guide_line(Vector3(0, 0, 9.0), Vector3(0, 0, -9.0), 0.12, _kit.mats.guide_white)
	_kit.hazard_panel(Vector2(3.0, 3.0), Vector3(-4.5, 0, -6.0))
	_kit.hazard_panel(Vector2(2.4, 4.0), Vector3(9.5, 0, -1.0))


func _dress_gallery(r: Rect2, block: Rect2) -> void:
	# White loop line around the switchgear (Cobalt Switchgear Gallery concept).
	var g := block.grow(1.6)
	var w: Material = _kit.mats.guide_white
	_kit.guide_line(Vector3(g.position.x, 0, g.position.y), Vector3(g.end.x, 0, g.position.y), 0.14, w)
	_kit.guide_line(Vector3(g.position.x, 0, g.end.y), Vector3(g.end.x, 0, g.end.y), 0.14, w)
	_kit.guide_line(Vector3(g.position.x, 0, g.position.y), Vector3(g.position.x, 0, g.end.y), 0.14, w)
	_kit.guide_line(Vector3(g.end.x, 0, g.position.y), Vector3(g.end.x, 0, g.end.y), 0.14, w)
	_kit.hazard_panel(Vector2(3.0, 3.0), Vector3(11.5, 0, -19.5))
	_kit.crate(-13.4, -18.6, 0, 1)
	_kit.crate(12.6, -29.6, 90, 1)


func _dress_lock(r: Rect2, sx: float, door: Vector2) -> void:
	_kit.wall(Vector3(sx, 0, r.position.y), Vector3(sx, 0, door.x))
	_kit.wall(Vector3(sx, 0, door.y), Vector3(sx, 0, r.end.y))
	minimap_solids.append(Rect2(sx - 0.3, r.position.y, 0.6, door.x - r.position.y))
	minimap_solids.append(Rect2(sx - 0.3, door.y, 0.6, r.end.y - door.y))
	for s in [-1.0, 1.0]:
		_kit.hazard_panel(Vector2(2.0, 3.0), Vector3(sx + s * 1.4, 0, (door.x + door.y) * 0.5))
	_kit.crate(25.0, -31.2, 0, 2)
	_kit.crate(39.6, -23.5, 90, 1)
	_kit.crate(25.0, -16.6, 0, 1)
	_kit.guide_line(Vector3(r.position.x, 0, -24.0), Vector3(sx - 1.0, 0, -24.0))


func _dress_reactor(r: Rect2, hole: Rect2) -> void:
	# The reactor core glowing far down the shaft.
	var c := Vector3(hole.get_center().x, 0.0, hole.get_center().y)
	_kit.box(Vector3(4.0, 60.0, 4.0), c + Vector3(0, -34.0, 0), _kit.mats.machine_dark, false, 0.0, false)
	for k in 4:
		var ring := _kit.torus(2.4, 2.9, c + Vector3(0, -4.0 - k * 5.0, 0), _kit.mats.teal_strip if k % 2 == 0 else _kit.mats.amber_strip)
		ring.scale = Vector3(1.0, 0.3, 1.0)
	_kit.omni(c + Vector3(0, -6.0, 0), Color("4ff0e0"), 4.0, 16.0, 2.0)
	for corner in [Vector3(r.position.x + 1.2, 0, r.position.y + 1.2), Vector3(r.end.x - 1.2, 0, r.position.y + 1.2)]:
		_kit.box(Vector3(1.6, 1.0, 1.0), corner + Vector3(0, 0.5, 0), _kit.mats.machine, true)
		_kit.add_blocker(corner.x, corner.z, 1.2)
	_kit.hazard_panel(Vector2(3.0, 3.0), Vector3(r.position.x + 4.0, 0, r.end.y - 4.0))
	_kit.hazard_panel(Vector2(3.0, 3.0), Vector3(r.end.x - 4.0, 0, r.end.y - 4.0))
	_kit.guide_line(Vector3(r.position.x + 1.0, 0, hole.position.y - 3.0), Vector3(r.end.x - 1.0, 0, hole.position.y - 3.0), 0.12, _kit.mats.guide_white)


# --------------------------------------------------------------------------
# Gameplay objects & population (runtime only)
# --------------------------------------------------------------------------

func _gameplay_root() -> Node3D:
	return _kit.root


func _add_obj(node: Node3D, pos: Vector3, rot_y := 0.0, blocker := 0.0) -> Node3D:
	node.position = pos
	node.rotation.y = rot_y
	_gameplay_root().add_child(node)
	if blocker > 0.0:
		_blockers.append(Vector3(pos.x, pos.z, blocker))
	return node


func _build_gameplay() -> void:
	# Extraction lift (where you dropped in).
	lift = ExtractionLift.new()
	_add_obj(lift, lift_position)

	# Uplink terminal on the reactor ring's north walkway, facing south.
	uplink = Interactable.new()
	uplink.style = &"terminal"
	uplink.prompt = "Start uplink"
	uplink.disabled_prompt = ""
	uplink.ready_color = Color("19f4ff")
	uplink.radius = 2.6
	_add_obj(uplink, uplink_position, 0.0, 1.4)

	for p in [Vector3(9.0, 0, -7.4), Vector3(4.2, 0, -7.6), Vector3(-3.0, 0, -29.4), Vector3(3.5, 0, -19.4),
			Vector3(29.4, 0, -31.6), Vector3(30.6, 0, -30.6), Vector3(29.0, 0, -65.3), Vector3(44.0, 0, -65.3),
			Vector3(25.6, 0, -45.6), Vector3(47.4, 0, -45.6)]:
		_add_obj(ExplosiveBarrel.new(), p, 0.0, 0.7)

	for p in [Vector3(-13.0, 0, -29.2), Vector3(26.0, 0, -54.0), Vector3(47.0, 0, -54.0)]:
		var nest := HiveNest.new()
		_add_obj(nest, p, 0.0, 1.6)
		nests.append(nest)

	# Laser fence across the gallery -> lock catwalk; switch just inside the lock.
	var grid_switch := Interactable.new()
	grid_switch.prompt = "Arm laser grid"
	_add_obj(grid_switch, Vector3(24.4, 0, -21.4), PI * 0.5, 0.5)
	var grid := LaserGrid.new()
	grid.switch = grid_switch
	grid.span = 3.0
	_add_obj(grid, Vector3(19.0, 0, -24.0))

	# Blast door in the lock bulkhead; switch on the west (exit) side.
	var door_switch := Interactable.new()
	door_switch.prompt = "Seal blast door"
	_add_obj(door_switch, Vector3(30.8, 0, -16.2), PI, 0.5)
	var door := BlastDoor.new()
	door.switch = door_switch
	door.width = 3.0
	_add_obj(door, Vector3(32.0, 0, -19.5))

	# Turret positions (spawned by the Mission as enemies).
	turret_spots = [
		{"pos": Vector3(13.4, 0, -29.6), "yaw": PI * 0.5},
		{"pos": Vector3(25.3, 0, -42.8), "yaw": -PI * 0.25},
		{"pos": Vector3(47.7, 0, -42.8), "yaw": PI * 0.25},
	]
	for t in turret_spots:
		_blockers.append(Vector3(t.pos.x, t.pos.z, 1.0))


func _build_placements() -> void:
	# Catwalk Deck: a sleeping cluster by the barrels, one patrol across the middle.
	for p in [Vector3(6.0, 0, -5.2), Vector3(7.2, 0, -4.0), Vector3(5.2, 0, -3.6), Vector3(7.8, 0, -5.8), Vector3(4.8, 0, -5.0)]:
		_place(&"swarmer", p, &"dormant")
	_place(&"swarmer", Vector3(-9.0, 0, -1.0), &"patrol", Vector3(9.0, 0, -1.0))
	# Switchgear Gallery: patrol looping the south walkway, shield bug + bursters north.
	_place(&"swarmer", Vector3(-11.0, 0, -19.5), &"patrol", Vector3(11.0, 0, -19.5))
	_place(&"swarmer", Vector3(-10.0, 0, -20.6), &"patrol", Vector3(10.0, 0, -20.6))
	_place(&"shield", Vector3(-11.0, 0, -28.4), &"dormant", Vector3.ZERO, Enemy.Tier.BLUE)
	_place(&"burster", Vector3(10.4, 0, -28.6), &"dormant")
	_place(&"burster", Vector3(9.4, 0, -27.6), &"dormant")
	# Pressure Lock: west sleepers by the barrels; east patrol shield + sleepers.
	for p in [Vector3(26.6, 0, -28.2), Vector3(27.6, 0, -27.0), Vector3(25.8, 0, -26.6), Vector3(28.0, 0, -29.0)]:
		_place(&"swarmer", p, &"dormant")
	_place(&"shield", Vector3(36.5, 0, -28.0), &"patrol", Vector3(36.5, 0, -18.5))
	for p in [Vector3(39.0, 0, -30.6), Vector3(38.0, 0, -31.2), Vector3(39.6, 0, -29.4)]:
		_place(&"swarmer", p, &"dormant")
	# Reactor Ring: guards around the uplink.
	for p in [Vector3(31.0, 0, -63.4), Vector3(32.0, 0, -61.8), Vector3(30.2, 0, -61.6),
			Vector3(42.0, 0, -63.4), Vector3(41.0, 0, -62.0), Vector3(43.0, 0, -62.2)]:
		_place(&"swarmer", p, &"dormant")
	_place(&"swarmer", Vector3(36.5, 0, -61.0), &"dormant", Vector3.ZERO, Enemy.Tier.GOLD)
	_place(&"burster", Vector3(28.0, 0, -50.0), &"patrol", Vector3(28.0, 0, -62.0))


func _place(type: StringName, pos: Vector3, mode: StringName, to := Vector3.ZERO, tier := 0) -> void:
	placements.append({"type": type, "pos": pos, "mode": mode, "to": to, "tier": tier})
