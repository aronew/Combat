class_name ComplexGen
extends RefCounted
## Procedural floors for the Deepworks complex.
##
## Rooms sit on a coarse grid (one per cell) and are joined by catwalk bridges
## over the void: a branching layout grown out from the arrival lift, plus a
## few extra links that make loops, so there is always somewhere to run.
## The output is plain data that Level builds with LevelKit (the same
## room / bridge format as the hand-built First Dive) plus dressing, objects
## and the starting population.
##
## Floor roles:
##   upper floors: arrive on a lift, switch on the breakers, ride the cargo lift down;
##   bottom floor: the reactor uplink, then extract on the lift you came down on.
## Rects are XZ: Rect2(x, z, width, depth). -Z is north (top of the screen).

const CELL := 36.0
## Minimum gap between a room and its cell edge, so bridges are at least 2x this long.
const MARGIN := 2.5

const THEMES := [
	{"name": "Upper Decks", "lamp": Color("ffc178"), "alt": Color("ffe3b8"), "red_rails": true,
		"kinds": {"plain": 5, "block": 2, "split": 1, "hole": 2}},
	{"name": "Switchgear Halls", "lamp": Color("9cc4ff"), "alt": Color("ffd9a8"),
		"kinds": {"plain": 2, "block": 5, "split": 2, "hole": 1}},
	{"name": "Pump Works", "lamp": Color("ffd9a8"), "alt": Color("8fe8ff"), "red_rails": true,
		"kinds": {"plain": 3, "block": 2, "split": 3, "hole": 3}},
	{"name": "Hive Foundry", "lamp": Color("ffe2b0"), "alt": Color("c8ff8a"),
		"kinds": {"plain": 3, "block": 2, "split": 2, "hole": 3}},
]
const FINAL_THEME := {"name": "Reactor Core", "lamp": Color("ffb35c"), "alt": Color("e8eef5"), "red_rails": true,
	"kinds": {"plain": 3, "block": 3, "split": 2, "hole": 2}}

## What a room is for: decides its name, props, walls and floor tint.
const PURPOSES := {
	"plain": ["loading", "hydroponics", "crew", "control", "crossroads"],
	"block": ["switchgear", "servers", "containers"],
	"hole": ["pump", "well"],
	"split": ["lock"],
	"start": ["landing"],
	"cargo": ["cargo_lift"],
	"reactor": ["reactor"],
}
const PURPOSE_NAMES := {
	"loading": ["Loading Bay", "Freight Yard", "Staging Deck", "Crane Deck"],
	"hydroponics": ["Hydroponics", "Grow Deck", "Overgrown Garden"],
	"crew": ["Crew Quarters", "Locker Room", "Mess Deck"],
	"control": ["Control Room", "Ops Deck", "Monitoring Station"],
	"crossroads": ["Junction", "Crossroads", "Gantry"],
	"switchgear": ["Switchgear Hall", "Transformer Bay", "Relay Room"],
	"servers": ["Server Gallery", "Data Vault"],
	"containers": ["Container Yard", "Cargo Hold"],
	"pump": ["Pump Shaft", "Coolant Well"],
	"well": ["Vent Ring", "Cable Well", "Drill Shaft"],
	"lock": ["Pressure Lock", "Decon Lock", "Bulkhead Section"],
	"landing": ["Lift Landing"],
	"cargo_lift": ["Cargo Lift"],
	"reactor": ["Reactor Ring"],
}
## Chance each far side (north, west: the top of the screen) gets a solid wall.
const WALL_CHANCE := {"loading": 0.4, "hydroponics": 0.7, "crew": 0.85, "control": 0.85,
	"switchgear": 0.7, "servers": 0.85, "containers": 0.35, "pump": 0.4, "lock": 0.6}
## Floor tint per purpose (else the default worn concrete).
const FLOOR_TINTS := {
	"control": Color(0.27, 0.3, 0.34), "servers": Color(0.24, 0.27, 0.31), "crew": Color(0.33, 0.31, 0.28),
	"hydroponics": Color(0.25, 0.28, 0.22), "containers": Color(0.31, 0.28, 0.25), "switchgear": Color(0.3, 0.31, 0.32),
}
## Props lined up against walls, by purpose.
const WALL_PROPS := {
	"loading": ["electrical_box", "cable_spool", "hard_case"],
	"hydroponics": ["planter", "planter", "electrical_box"],
	"crew": ["locker_row", "locker_row", "electrical_box"],
	"control": ["console", "console", "server_rack"],
	"switchgear": ["electrical_box", "cable_spool", "switchgear"],
	"servers": ["server_rack", "server_rack", "console"],
	"containers": ["electrical_box", "hard_case"],
	"pump": ["electrical_box", "tank"],
	"lock": ["console", "electrical_box"],
}

const NAMES := {
	"plain": ["Catwalk Deck", "Loading Bay", "Gantry", "Cargo Hold", "Staging Deck", "Crane Deck", "Freight Yard"],
	"block": ["Switchgear Hall", "Transformer Bay", "Server Gallery", "Relay Room", "Capacitor Hall"],
	"split": ["Pressure Lock", "Bulkhead Section", "Decon Lock", "Airlock"],
	"hole": ["Pump Shaft", "Coolant Well", "Vent Ring", "Drill Shaft", "Cable Well"],
	"start": ["Lift Landing"],
	"cargo": ["Cargo Lift"],
	"reactor": ["Reactor Ring"],
}

var rng := RandomNumberGenerator.new()

var _rooms: Array = []
var _bridges: Array = []
var _cells: Array[Vector2i] = []
var _links: Array = []  # [i, j, on_main_path]
var _occupied: Array[Vector3] = []  # x, z, radius: spots objects must keep clear of
var _out := {}


## Floors per dive by depth (deeper dives are taller complexes).
static func floor_count(depth: int) -> int:
	return [2, 3, 3, 4, 4][clampi(depth, 1, 5) - 1]


## Rooms on one floor.
static func room_count(depth: int, floor_idx: int) -> int:
	return mini(10 + depth + floor_idx, 16)


static func theme_for(seed_: int, floor_idx: int, floors: int) -> Dictionary:
	if floor_idx >= floors - 1:
		return FINAL_THEME
	return THEMES[posmod(seed_ + floor_idx, THEMES.size())]


func generate(seed_: int, floor_idx: int, floors: int, depth: int) -> Dictionary:
	rng.seed = hash([seed_, floor_idx, depth])
	var final := floor_idx >= floors - 1
	var theme := theme_for(seed_, floor_idx, floors)
	var n := room_count(depth, floor_idx)
	var cols := 5 if n <= 12 else 6
	var rows := 4 if n <= 12 else 5

	_grow(n, cols, rows)
	var dist := _bfs(0)
	var end := 0
	for i in dist.size():
		if dist[i] > dist[end]:
			end = i
	var path := _path_to(end)
	for l in _links:
		l[2] = path.has(l[0]) and path.has(l[1])
	_add_loops()

	_out = {
		"name": theme.name, "final": final, "floor": floor_idx, "floors": floors, "lamp": theme.lamp,
		"red_rails": theme.get("red_rails", false),
		"barrels": [], "nests": [], "turrets": [], "breakers": [], "lasers": [], "doors": [],
		"crates": [], "panels": [], "guides": [], "placements": [], "shaft_glows": [], "carcasses": [],
		"props": [], "wall_lights": [], "guide_loops": [], "shaft_pipes": [],
		"uplink": Vector3.INF, "cargo": Vector3.INF,
	}
	var used_names := {}
	for i in _cells.size():
		var role := "start" if i == 0 else ("end" if i == end else "normal")
		var kind := _pick_kind(theme, role, final)
		_rooms.append(_make_room(i, kind, role, theme, used_names))
	for l in _links:
		_make_bridge(l[0], l[1], l[2])

	# Bridge openings stay clear of crates and objects.
	for b in _bridges:
		for p in b.ends:
			_occupied.append(Vector3(p.x, p.y, 3.4))

	_place_specials(end, final, dist, path)
	for i in _rooms.size():
		_dress_room(i, floor_idx, final)
	for i in _rooms.size():
		if i != 0:
			_populate(i, floor_idx, depth, final)
	_hazard_bridges(floor_idx)
	_roaming_packs(floor_idx, dist)

	var hive := _rooms[end].center3 as Vector3
	var best_nests := 0
	for r in _rooms:
		if r.nests > best_nests:
			best_nests = r.nests
			hive = r.center3
	_out.hive_center = hive
	var rooms_out: Array = []
	for r in _rooms:
		var d := {"id": r.id, "name": r.name, "rect": r.rect, "kind": r.kind, "lamp": r.lamp, "role": r.role,
			"purpose": r.purpose, "walls": r.walls, "floor_tint": r.floor_tint}
		for k in ["block", "hole", "split_x", "door", "block_props"]:
			if r.has(k):
				d[k] = r[k]
		rooms_out.append(d)
	_out.rooms = rooms_out
	var bridges_out: Array = []
	for b in _bridges:
		bridges_out.append({"rect": b.rect, "solid": false, "along_x": b.along_x})
	_out.bridges = bridges_out
	_out.main_path = path
	return _out


# ==========================================================================
# Layout graph
# ==========================================================================

## Growing tree: mostly extends the newest room (long runs), sometimes branches.
func _grow(n: int, cols: int, rows: int) -> void:
	var start := Vector2i(rng.randi_range(1, cols - 2), rows - 1)
	_cells.append(start)
	var taken := {start: 0}
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var attempts := 0
	while _cells.size() < n and attempts < 4000:
		attempts += 1
		var from_i := _cells.size() - 1 if rng.randf() < 0.55 else rng.randi_range(0, _cells.size() - 1)
		var from := _cells[from_i]
		_shuffle(dirs)
		for d in dirs:
			var c := from + d
			if c.x < 0 or c.y < 0 or c.x >= cols or c.y >= rows or taken.has(c):
				continue
			taken[c] = _cells.size()
			_cells.append(c)
			_links.append([from_i, _cells.size() - 1, false])
			break


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


func _neighbors(i: int) -> Array[int]:
	var out: Array[int] = []
	for l in _links:
		if l[0] == i:
			out.append(l[1])
		elif l[1] == i:
			out.append(l[0])
	return out


func _bfs(from: int) -> Array[int]:
	var dist: Array[int] = []
	dist.resize(_cells.size())
	dist.fill(-1)
	dist[from] = 0
	var queue: Array[int] = [from]
	while not queue.is_empty():
		var cur: int = queue.pop_front()
		for nb in _neighbors(cur):
			if dist[nb] < 0:
				dist[nb] = dist[cur] + 1
				queue.append(nb)
	return dist


## Room indices on the tree path from the start (0) to `end`.
func _path_to(end: int) -> Array[int]:
	var parent := {0: -1}
	var queue: Array[int] = [0]
	while not queue.is_empty():
		var cur: int = queue.pop_front()
		for nb in _neighbors(cur):
			if not parent.has(nb):
				parent[nb] = cur
				queue.append(nb)
	var path: Array[int] = []
	var c := end
	while c >= 0:
		path.push_front(c)
		c = parent.get(c, -1)
	return path


## Extra links between neighbouring rooms: loops to run around.
func _add_loops() -> void:
	var budget := maxi(1, _cells.size() / 4)
	var pairs: Array = []
	for i in _cells.size():
		for j in range(i + 1, _cells.size()):
			var d := _cells[i] - _cells[j]
			if absi(d.x) + absi(d.y) != 1:
				continue
			var linked := false
			for l in _links:
				if (l[0] == i and l[1] == j) or (l[0] == j and l[1] == i):
					linked = true
					break
			if not linked:
				pairs.append([i, j])
	_shuffle(pairs)
	for p in pairs:
		if budget <= 0:
			break
		if rng.randf() < 0.55:
			_links.append([p[0], p[1], false])
			budget -= 1


# ==========================================================================
# Rooms
# ==========================================================================

func _pick_kind(theme: Dictionary, role: String, final: bool) -> String:
	if role == "start":
		return "start"
	if role == "end":
		return "reactor" if final else "cargo"
	var total := 0
	for k in theme.kinds:
		total += int(theme.kinds[k])
	var pick := rng.randi_range(1, total)
	for k in theme.kinds:
		pick -= int(theme.kinds[k])
		if pick <= 0:
			return k
	return "plain"


func _make_room(i: int, kind: String, role: String, theme: Dictionary, used_names: Dictionary) -> Dictionary:
	var w := 0.0
	var h := 0.0
	match kind:
		"start":
			w = rng.randf_range(15.0, 19.0)
			h = rng.randf_range(13.0, 16.0)
		"cargo":
			w = rng.randf_range(18.0, 22.0)
			h = rng.randf_range(16.0, 20.0)
		"reactor":
			w = 26.0
			h = 26.0
		"plain":
			w = rng.randf_range(14.0, 25.0)
			h = rng.randf_range(12.0, 23.0)
		"block", "split":
			w = rng.randf_range(18.0, 26.0)
			h = rng.randf_range(15.0, 23.0)
		"hole":
			w = rng.randf_range(19.0, 26.0)
			h = clampf(w + rng.randf_range(-3.0, 3.0), 19.0, 26.0)
	w = snappedf(w, 0.5)
	h = snappedf(h, 0.5)
	var cell := _cells[i] - _cells[0]
	var cc := Vector2(cell.x * CELL, cell.y * CELL)
	# Stay inside the cell, and always cover the cell's centre band so bridges line up.
	var jx := maxf(minf((CELL - 2.0 * MARGIN - w) * 0.5, w * 0.5 - 5.5), 0.0)
	var jz := maxf(minf((CELL - 2.0 * MARGIN - h) * 0.5, h * 0.5 - 5.5), 0.0)
	if kind == "start":
		jx = 0.0
		jz = 0.0
	var c := Vector2(snappedf(cc.x + rng.randf_range(-jx, jx), 0.5), snappedf(cc.y + rng.randf_range(-jz, jz), 0.5))
	var rect := Rect2(c.x - w * 0.5, c.y - h * 0.5, w, h)

	var purposes: Array = PURPOSES[kind]
	var purpose: String = purposes[rng.randi_range(0, purposes.size() - 1)]
	var name_list: Array = PURPOSE_NAMES[purpose]
	var base: String = name_list[rng.randi_range(0, name_list.size() - 1)]
	var nm := base
	var k := 2
	while used_names.has(nm):
		nm = "%s %s" % [base, ["", "", "II", "III", "IV", "V", "VI"][mini(k, 6)]]
		k += 1
	used_names[nm] = true

	var room := {
		"id": StringName("r%d" % i), "name": nm, "rect": rect, "role": role, "center3": Vector3(c.x, 0, c.y),
		"lamp": theme.alt if rng.randf() < 0.3 else theme.lamp, "nests": 0, "side": {},
		"kind": {"start": "plain", "cargo": "plain", "reactor": "hole"}.get(kind, kind), "tag": kind,
		"purpose": purpose, "walls": [], "floor_tint": FLOOR_TINTS.get(purpose, Color(0, 0, 0, 0)),
	}
	match kind:
		"block":
			var bw := w - 2.0 * rng.randf_range(3.5, 5.0)
			var bh := clampf(h * rng.randf_range(0.22, 0.32), 3.0, h - 9.0)
			room.block = Rect2(c.x - bw * 0.5, c.y - bh * 0.5, bw, bh)
		"hole":
			var hs := maxf(minf(w, h) * rng.randf_range(0.3, 0.4), 6.0)
			hs = minf(hs, minf(w, h) - 10.0)
			room.hole = Rect2(c.x - hs * 0.5, c.y - hs * 0.5, hs, hs)
		"reactor":
			room.hole = Rect2(c.x - 5.0, c.y - 5.0, 10.0, 10.0)
		"split":
			var sx := snappedf(c.x + rng.randf_range(-2.0, 2.0), 0.5)
			room.split_x = sx
			var dz := snappedf(rng.randf_range(rect.position.y + 3.5, rect.end.y - 3.5), 0.5)
			room.door = Vector2(dz - 1.75, dz + 1.75)
	return room


## The walkable convex pieces of a room (what Level turns into regions).
func _pieces(r: Dictionary) -> Array[Rect2]:
	var rect: Rect2 = r.rect
	var out: Array[Rect2] = []
	if r.has("hole") or r.has("block"):
		var inner: Rect2 = r.hole if r.has("hole") else r.block
		out.append(Rect2(rect.position.x, rect.position.y, rect.size.x, inner.position.y - rect.position.y))
		out.append(Rect2(rect.position.x, inner.end.y, rect.size.x, rect.end.y - inner.end.y))
		out.append(Rect2(rect.position.x, inner.position.y, inner.position.x - rect.position.x, inner.size.y))
		out.append(Rect2(inner.end.x, inner.position.y, rect.end.x - inner.end.x, inner.size.y))
	elif r.has("split_x"):
		var sx: float = r.split_x
		out.append(Rect2(rect.position.x, rect.position.y, sx - 0.5 - rect.position.x, rect.size.y))
		out.append(Rect2(sx + 0.5, rect.position.y, rect.end.x - sx - 0.5, rect.size.y))
	else:
		out.append(rect)
	return out


# ==========================================================================
# Bridges
# ==========================================================================

func _make_bridge(i: int, j: int, main: bool) -> void:
	var a: Dictionary = _rooms[i]
	var b: Dictionary = _rooms[j]
	var bw := 4.0 if main else 3.0
	var ca := _cells[i]
	var cb := _cells[j]
	var bridge := {}
	if ca.y == cb.y:
		var west := a if ca.x < cb.x else b
		var east := b if ca.x < cb.x else a
		var rw: Rect2 = west.rect
		var re: Rect2 = east.rect
		# Pick z inside one walkway strip of each room (never across the seam
		# between a hole/block room's strips: that would split the doorway
		# into two narrow halves big bugs can't path through).
		var z := _pick_lateral(_edge_spans(west), _edge_spans(east), bw)
		if is_nan(z) and bw > 3.0:
			bw = 3.0
			z = _pick_lateral(_edge_spans(west), _edge_spans(east), bw)
		if is_nan(z):
			z = (maxf(rw.position.y, re.position.y) + minf(rw.end.y, re.end.y)) * 0.5
		z = snappedf(z, 0.25)
		bridge.rect = Rect2(rw.end.x, z - bw * 0.5, re.position.x - rw.end.x, bw)
		bridge.along_x = true
		bridge.ends = [Vector2(rw.end.x, z), Vector2(re.position.x, z)]
		west.side["e"] = z
		east.side["w"] = z
	else:
		var north := a if ca.y < cb.y else b
		var south := b if ca.y < cb.y else a
		var rn: Rect2 = north.rect
		var rs: Rect2 = south.rect
		var lo := maxf(rn.position.x, rs.position.x) + bw * 0.5 + 1.5
		var hi := minf(rn.end.x, rs.end.x) - bw * 0.5 - 1.5
		var x := (lo + hi) * 0.5
		var found := false
		for attempt in 24:
			var cand := rng.randf_range(lo, hi) if hi > lo else (lo + hi) * 0.5
			var ok := true
			for r in [north, south]:
				if r.has("split_x") and absf(cand - float(r.split_x)) < bw * 0.5 + 1.4:
					ok = false
			if ok:
				x = cand
				found = true
				break
		x = snappedf(x, 0.5)
		if not found:
			# The bulkhead would cut this catwalk off: drop the bulkhead instead.
			for r in [north, south]:
				if r.has("split_x") and absf(x - float(r.split_x)) < bw * 0.5 + 1.0:
					r.erase("split_x")
					r.erase("door")
					r.kind = "plain"
					r.tag = "plain"
		bridge.rect = Rect2(x - bw * 0.5, rn.end.y, bw, rs.position.y - rn.end.y)
		bridge.along_x = false
		bridge.ends = [Vector2(x, rn.end.y), Vector2(x, rs.position.y)]
		north.side["s"] = x
		south.side["n"] = x
	bridge.main = main
	bridge.width = bw
	_bridges.append(bridge)


# ==========================================================================
# Objects and dressing
# ==========================================================================

## Z ranges of a room's east/west edge that lie within one walkway strip.
func _edge_spans(r: Dictionary) -> Array[Vector2]:
	var rect: Rect2 = r.rect
	if r.has("hole") or r.has("block"):
		var inner: Rect2 = r.hole if r.has("hole") else r.block
		return [Vector2(rect.position.y, inner.position.y), Vector2(inner.position.y, inner.end.y), Vector2(inner.end.y, rect.end.y)]
	return [Vector2(rect.position.y, rect.end.y)]


## A random lateral position for a catwalk of width `bw` that sits inside one
## span of each side (with margins), or NAN if there's none.
func _pick_lateral(a: Array[Vector2], b: Array[Vector2], bw: float) -> float:
	var ok: Array[Vector2] = []
	var m := bw * 0.5 + 0.6
	for sa in a:
		for sb in b:
			var lo := maxf(sa.x, sb.x) + m
			var hi := minf(sa.y, sb.y) - m
			if hi >= lo:
				ok.append(Vector2(lo, hi))
	if ok.is_empty():
		return NAN
	var total := 0.0
	for o in ok:
		total += o.y - o.x + 0.01
	var pick := rng.randf() * total
	for o in ok:
		pick -= o.y - o.x + 0.01
		if pick <= 0.0:
			return rng.randf_range(o.x, o.y)
	return ok[0].x


## Random free floor point in a room, `margin` from its edges and clear of
## everything placed so far. Returns [point, piece] or [] if none fits.
func _free_spot(r: Dictionary, margin: float, clear: float, piece := -1) -> Array:
	var pieces := _pieces(r)
	for attempt in 40:
		var pi := piece if piece >= 0 else _weighted_piece(pieces)
		var inner := pieces[pi].grow(-margin)
		if inner.size.x <= 0.2 or inner.size.y <= 0.2:
			if piece >= 0:
				return []
			continue
		var p := Vector2(rng.randf_range(inner.position.x, inner.end.x), rng.randf_range(inner.position.y, inner.end.y))
		if _is_clear(p, clear):
			return [p, pi]
	return []


func _weighted_piece(pieces: Array[Rect2]) -> int:
	var total := 0.0
	for p in pieces:
		total += p.get_area()
	var pick := rng.randf() * total
	for i in pieces.size():
		pick -= pieces[i].get_area()
		if pick <= 0.0:
			return i
	return pieces.size() - 1


func _is_clear(p: Vector2, clear: float) -> bool:
	for o in _occupied:
		if Vector2(o.x, o.y).distance_to(p) < o.z + clear:
			return false
	return true


func _occupy(p: Vector2, r: float) -> void:
	_occupied.append(Vector3(p.x, p.y, r))


## Arrival lift, cargo lift + breakers or the reactor uplink.
func _place_specials(end: int, final: bool, dist: Array[int], path: Array[int]) -> void:
	var start: Dictionary = _rooms[0]
	var sc: Vector3 = start.center3
	_out.arrival = sc
	_out.player_start = sc + Vector3(0, 0, 0.5)
	_occupy(Vector2(sc.x, sc.z), 4.5)

	var er: Dictionary = _rooms[end]
	var ec: Vector3 = er.center3
	if final:
		# Uplink on the walkway across the shaft from where the route comes in.
		var prev: int = path[path.size() - 2] if path.size() >= 2 else 0
		var d := _cells[end] - _cells[prev]
		var dir := Vector3(d.x, 0, d.y)
		var hole: Rect2 = er.hole
		var reach := hole.size.x * 0.5 + ((er.rect as Rect2).size.x - hole.size.x) * 0.25
		_out.uplink = ec + dir * reach
		_occupy(Vector2(_out.uplink.x, _out.uplink.z), 3.0)
		_out.shaft_glows.append({"pos": ec, "size": hole.size.x, "reactor": true})
	else:
		_out.cargo = ec
		_occupy(Vector2(ec.x, ec.z), 5.0)
		# Breakers: dead ends far from the route first, then anywhere off the route.
		var count := 1 if int(_out.floor) == 0 else 2
		var cands: Array = []
		for i in _rooms.size():
			if i == 0 or i == end:
				continue
			var leaf := _neighbors(i).size() == 1
			var score := float(dist[i]) + (6.0 if leaf else 0.0) + (3.0 if not path.has(i) else 0.0) + rng.randf() * 2.0
			cands.append([score, i])
		cands.sort_custom(func(p, q): return p[0] > q[0])
		for k in mini(count, cands.size()):
			var r: Dictionary = _rooms[cands[k][1]]
			var spot := _free_spot(r, 1.6, 2.5)
			if spot.is_empty():
				continue
			var p: Vector2 = spot[0]
			_occupy(p, 2.5)
			_out.breakers.append({"pos": Vector3(p.x, 0, p.y), "room": r.name})

	# Hole rooms: a glow far down the shaft.
	for r in _rooms:
		if r.tag == "hole":
			var h: Rect2 = r.hole
			_out.shaft_glows.append({"pos": r.center3, "size": h.size.x, "reactor": false})


func _dress_room(i: int, floor_idx: int, final: bool) -> void:
	var r: Dictionary = _rooms[i]
	var rect: Rect2 = r.rect
	var tag: String = r.tag
	# Blast door in every split room's bulkhead, switch on the side nearest the start.
	if r.has("split_x"):
		var sx: float = r.split_x
		var door: Vector2 = r.door
		var west_side := (r.center3 as Vector3).x > 0.0
		var sw := Vector3(sx + (-0.62 if west_side else 0.62), 0, door.y + 1.6 if door.y + 2.5 < rect.end.y else door.x - 1.6)
		_out.doors.append({"pos": Vector3(sx, 0, (door.x + door.y) * 0.5), "width": door.y - door.x,
			"switch": sw, "switch_rot": PI if west_side else 0.0})
		_occupy(Vector2(sx, (door.x + door.y) * 0.5), 3.0)
		_occupy(Vector2(sw.x, sw.z), 1.5)
		var zz := rect.position.y
		while zz <= rect.end.y:
			if zz < door.x - 0.5 or zz > door.y + 0.5:
				_occupy(Vector2(sx, zz), 0.8)
			zz += 1.2
	if tag == "start" or tag == "cargo":
		_out.panels.append({"size": Vector2(6.0, 5.0), "pos": r.center3})
		var c: Vector3 = r.center3
		_out.guides.append([c + Vector3(-3.5, 0, -4.0), c + Vector3(-3.5, 0, 4.0)])
		_out.guides.append([c + Vector3(3.5, 0, -4.0), c + Vector3(3.5, 0, 4.0)])
	_dress_purpose(r)
	for k in rng.randi_range(0, 2):
		var spot := _free_spot(r, 2.5, 0.0)
		if not spot.is_empty():
			_out.panels.append({"size": Vector2(rng.randf_range(2.0, 3.5), rng.randf_range(2.0, 3.5)), "pos": Vector3(spot[0].x, 0, spot[0].y)})
	if rng.randf() < 0.6:
		var along_x := rect.size.x > rect.size.y
		var pcs := _pieces(r)
		var pc: Rect2 = pcs[rng.randi_range(0, pcs.size() - 1)]
		if along_x and pc.size.x > 6.0:
			var z := pc.get_center().y
			_out.guides.append([Vector3(pc.position.x + 1.0, 0, z), Vector3(pc.end.x - 1.0, 0, z)])
		elif not along_x and pc.size.y > 6.0:
			var x := pc.get_center().x
			_out.guides.append([Vector3(x, 0, pc.position.y + 1.0), Vector3(x, 0, pc.end.y - 1.0)])

	if tag == "start":
		return
	# Explosive barrels.
	for k in rng.randi_range(0, 2):
		var spot := _free_spot(r, 1.5, 1.4)
		if not spot.is_empty():
			_out.barrels.append(Vector3(spot[0].x, 0, spot[0].y))
			_occupy(spot[0], 0.9)
	# Hive nests (more the deeper you go in this dive).
	var nest_p := 0.14 + 0.08 * floor_idx + (0.08 if final else 0.0)
	if tag != "cargo" and rng.randf() < nest_p:
		var spot := _free_spot(r, 2.0, 2.4)
		if not spot.is_empty():
			_out.nests.append(Vector3(spot[0].x, 0, spot[0].y))
			_occupy(spot[0], 2.0)
			r.nests += 1
			var egg := _free_spot(r, 1.4, 0.6)
			if not egg.is_empty() and (egg[0] as Vector2).distance_to(spot[0]) < 6.0:
				_prop("egg_cluster", egg[0], rng.randf() * TAU)
				_occupy(egg[0], 1.2)
			# A couple of bugs tending the nest, crawling round it.
			var nest_pos: Vector2 = spot[0]
			for k in rng.randi_range(1, 3):
				var a := rng.randf() * TAU
				var tp := nest_pos + Vector2(cos(a), sin(a)) * 1.9
				if _in_pieces(r, tp):
					_place(&"swarmer", tp, &"dormant", Vector2.INF, 0, {"idle": &"wander", "radius": 2.2})
	# Sentry turrets in a corner, facing into the room.
	var turret_p := 0.12 + 0.07 * floor_idx
	if tag != "cargo" and rng.randf() < turret_p:
		var pcs := _pieces(r)
		var pc: Rect2 = pcs[rng.randi_range(0, pcs.size() - 1)]
		var corners := [pc.position + Vector2(1.8, 1.8), Vector2(pc.end.x - 1.8, pc.position.y + 1.8),
			Vector2(pc.position.x + 1.8, pc.end.y - 1.8), pc.end - Vector2(1.8, 1.8)]
		_shuffle(corners)
		for cp in corners:
			var cpos: Vector2 = cp
			if pc.grow(-1.0).has_point(cpos) and _is_clear(cpos, 2.5):
				var to: Vector2 = Vector2((r.center3 as Vector3).x, (r.center3 as Vector3).z) - cpos
				_out.turrets.append({"pos": Vector3(cpos.x, 0, cpos.y), "yaw": atan2(-to.x, -to.y)})
				_occupy(cpos, 2.0)
				break


# --------------------------------------------------------------------------
# Room purposes: walls, props, centrepieces
# --------------------------------------------------------------------------

func _prop(name: String, p: Vector2, yaw: float, scale := Vector3.ONE, tint := Color(0, 0, 0, 0)) -> void:
	_out.props.append({"name": name, "pos": Vector3(p.x, 0, p.y), "yaw": yaw, "scale": scale, "tint": tint})


## Yaw that turns a prop's front (-Z) to face `dir` (XZ).
func _face(dir: Vector2) -> float:
	return atan2(-dir.x, -dir.y)


func _dress_purpose(r: Dictionary) -> void:
	var purpose: String = r.purpose
	var rect: Rect2 = r.rect
	var c := rect.get_center()
	# Solid walls on the far sides (top of the screen), with props against them.
	if WALL_CHANCE.has(purpose):
		for side in ["n", "w"]:
			if r.side.has(side) or rng.randf() > WALL_CHANCE[purpose]:
				continue
			_build_wall(r, side)
	# Props along the open railing edges (AC units, cabinets, cases).
	var edge_props: Array = ["ac_unit", "electrical_box", "hard_case"]
	if purpose == "hydroponics":
		edge_props = ["planter"]
	elif purpose == "reactor" or purpose == "landing" or purpose == "cargo_lift":
		edge_props = ["ac_unit", "ac_unit", "electrical_box"]
	for side in ["n", "s", "w", "e"]:
		if r.walls.has(side):
			continue
		_line_props(r, side, edge_props, 0.6 if purpose != "crossroads" else 0.25, 0.75)
	match purpose:
		"switchgear", "servers", "containers":
			_fill_block(r, purpose)
		"loading":
			for k in rng.randi_range(2, 3):
				_case_cluster(r)
			for k in rng.randi_range(0, 1):
				var sp := _free_spot(r, 3.4, 1.8)
				if not sp.is_empty():
					_prop("cable_spool", sp[0], rng.randf() * TAU)
					_occupy(sp[0], 1.3)
		"crossroads":
			var loop := Rect2(c - Vector2(4.0, 4.0), Vector2(8.0, 8.0))
			if rect.grow(-2.0).encloses(loop):
				_out.guide_loops.append({"rect": loop, "chamfer": 1.2})
		"control":
			if rect.size.x >= 16.0 and rect.size.y >= 13.0 and _is_clear(c, 2.0):
				_prop("console", c + Vector2(0, -0.45), PI)
				_prop("console", c + Vector2(0, 0.45), 0.0)
				_occupy(c, 1.8)
			_case_cluster(r)
		"pump":
			var hole: Rect2 = r.hole
			for corner in [rect.position + Vector2(1.9, 1.9), Vector2(rect.end.x - 1.9, rect.position.y + 1.9),
					Vector2(rect.position.x + 1.9, rect.end.y - 1.9), rect.end - Vector2(1.9, 1.9)]:
				var cp: Vector2 = corner
				if rng.randf() < 0.6 and _is_clear(cp, 1.6) and not hole.grow(1.5).has_point(cp):
					_prop("tank", cp, rng.randf() * TAU)
					_occupy(cp, 1.8)
			_out.shaft_pipes.append({"rect": hole, "count": 2})
		"well", "reactor":
			_out.shaft_pipes.append({"rect": r.hole, "count": 1 if purpose == "reactor" else 2})
			if purpose == "reactor":
				_case_cluster(r)
		"crew", "hydroponics", "lock", "landing", "cargo_lift":
			_case_cluster(r)
	# A floor vent or two (walkable).
	for k in rng.randi_range(0, 2):
		var sp := _free_spot(r, 2.0, 1.4)
		if not sp.is_empty():
			_prop("floor_vent", sp[0], 0.0 if rng.randf() < 0.5 else PI * 0.5)
			_occupy(sp[0], 1.0)


func _build_wall(r: Dictionary, side: String) -> void:
	var rect: Rect2 = r.rect
	var a := rect.position
	var b := Vector2(rect.end.x, rect.position.y) if side == "n" else Vector2(rect.position.x, rect.end.y)
	var inward := Vector2(0, 1) if side == "n" else Vector2(1, 0)
	var length := a.distance_to(b)
	var dir := (b - a) / length
	r.walls.append(side)
	var n := maxi(1, roundi(length / 3.0))
	var seg := length / n
	var door_k := rng.randi_range(0, n - 1) if rng.randf() < 0.45 and n >= 3 else -1
	for k in n:
		var mid := a + dir * (k + 0.5) * seg + inward * 0.25
		if k == door_k:
			_prop("door", mid + inward * 0.12, _face(inward), Vector3(seg / 3.4, 1, 1))
		else:
			_prop("wall_panel", mid, _face(inward), Vector3(seg / 3.0, 1, 1))
	# Keep spawns and other props off the wall strip.
	var t := 0.0
	while t <= length:
		_occupy(a + dir * t + inward * 0.4, 0.9)
		t += 1.5
	# Wall lights.
	var lights := maxi(1, roundi(length / 9.0))
	for k in lights:
		var lp := a + dir * (k + 0.5) * (length / lights) + inward * 0.9
		_out.wall_lights.append({"pos": Vector3(lp.x, 2.7, lp.y), "color": r.lamp})
	# Props against the wall.
	var list: Array = WALL_PROPS.get(r.purpose, ["electrical_box"])
	_line_props(r, side, list, 0.7, 0.55, true)


## Props in a row along one side of the room, facing inward.
func _line_props(r: Dictionary, side: String, names: Array, density: float, inset: float, wall := false) -> void:
	var rect: Rect2 = r.rect
	var a: Vector2
	var b: Vector2
	var inward: Vector2
	match side:
		"n":
			a = rect.position
			b = Vector2(rect.end.x, rect.position.y)
			inward = Vector2(0, 1)
		"s":
			a = Vector2(rect.position.x, rect.end.y)
			b = rect.end
			inward = Vector2(0, -1)
		"w":
			a = rect.position
			b = Vector2(rect.position.x, rect.end.y)
			inward = Vector2(1, 0)
		_:
			a = Vector2(rect.end.x, rect.position.y)
			b = rect.end
			inward = Vector2(-1, 0)
	var length := a.distance_to(b)
	var dir := (b - a) / length
	var t := 2.2
	while t < length - 2.2:
		var pick: String = names[rng.randi_range(0, names.size() - 1)]
		var size: Vector2 = Props.DEFS[pick].size
		var depth := size.y
		# Flush against the wall or railing: no gap for bugs to get wedged in.
		var p := a + dir * (t + size.x * 0.5) + inward * ((0.55 if wall else 0.28) + depth * 0.5)
		if rng.randf() < density and _is_clear(p, maxf(size.x, size.y) * 0.5 + 0.4) and _in_pieces(r, p):
			_prop(pick, p, _face(inward))
			_occupy(p, maxf(size.x, size.y) * 0.5 + 0.3)
			t += size.x + rng.randf_range(0.8, 2.5)
		else:
			t += 1.5


## A few hard cases stacked as cover.
func _case_cluster(r: Dictionary) -> void:
	# Keep the whole cluster well clear of edges, so bugs can walk round it.
	var sp := _free_spot(r, 3.6, 2.0)
	if sp.is_empty():
		return
	var p: Vector2 = sp[0]
	var yaw := rng.randf_range(-0.3, 0.3) + (0.0 if rng.randf() < 0.5 else PI * 0.5)
	_prop("hard_case", p, yaw)
	var off := Vector2(cos(-yaw), sin(-yaw)) * 1.25
	for q in [p + off, p - off * 0.95 + Vector2(0.1, 0.8).rotated(-yaw)]:
		var qq: Vector2 = q
		if rng.randf() < 0.65 and _in_pieces_margin(r, qq, 2.4) and _is_clear(qq, 0.9):
			_prop("hard_case", qq, yaw + rng.randf_range(-0.2, 0.2))
	_occupy(p, 2.4)


func _in_pieces_margin(r: Dictionary, p: Vector2, margin: float) -> bool:
	for pc in _pieces(r):
		if pc.grow(-margin).has_point(p):
			return true
	return false


## Fill a block room's central block with a row of cabinets, racks or containers.
func _fill_block(r: Dictionary, purpose: String) -> void:
	var blk: Rect2 = r.block
	r.block_props = true
	match purpose:
		"switchgear", "servers":
			var name := "switchgear" if purpose == "switchgear" else "server_rack"
			var w: float = Props.DEFS[name].size.x
			var n := maxi(1, int(blk.size.x / w))
			var sx := blk.size.x / (n * w)
			var rows := [[blk.position.y + 0.5, 0.0]]  # north row, facing north
			if blk.size.y >= 1.9:
				rows.append([blk.end.y - 0.5, PI])  # south row, facing south
			for row in rows:
				for k in n:
					var x := blk.position.x + (k + 0.5) * w * sx
					_prop(name, Vector2(x, row[0]), row[1], Vector3(sx, 1, 1))
		"containers":
			var n := maxi(1, roundi(blk.size.x / 6.2))
			var sx := clampf(blk.size.x / (n * 6.0), 0.6, 1.25)
			var m := maxi(1, int(blk.size.y / 2.45))
			var sz := blk.size.y / (m * 2.4)
			var tints := [Color(0.45, 0.16, 0.1), Color(0.14, 0.24, 0.38), Color(0.46, 0.34, 0.1), Color(0.2, 0.3, 0.2), Color(0.38, 0.38, 0.38)]
			for i in n:
				for j in m:
					var p := Vector2(blk.position.x + (i + 0.5) * blk.size.x / n, blk.position.y + (j + 0.5) * blk.size.y / m)
					_prop("container", p, 0.0 if rng.randf() < 0.5 else PI, Vector3(sx, 1, sz), tints[rng.randi_range(0, tints.size() - 1)])
					if rng.randf() < 0.4:
						_out.props.append({"name": "container", "pos": Vector3(p.x, 2.6, p.y), "yaw": 0.0, "scale": Vector3(sx, 1, sz),
							"tint": tints[rng.randi_range(0, tints.size() - 1)]})


func _in_pieces(r: Dictionary, p: Vector2) -> bool:
	for pc in _pieces(r):
		if pc.grow(-1.0).has_point(p):
			return true
	return false


## Laser fences across some of the longer catwalks.
func _hazard_bridges(floor_idx: int) -> void:
	var count := 0
	var order := range(_bridges.size())
	_shuffle(order)
	for bi in order:
		var b: Dictionary = _bridges[bi]
		var rect: Rect2 = b.rect
		var length := rect.size.x if b.along_x else rect.size.y
		if length < 7.0 or count >= 1 + floor_idx / 2 or rng.randf() > 0.35:
			continue
		var c := rect.get_center()
		var end_a: Vector2 = b.ends[0]
		var lateral := Vector2(0, 1) if b.along_x else Vector2(1, 0)
		var inward := (end_a - c).normalized()
		var sw: Vector2 = end_a + inward * 1.6 + lateral * (b.width * 0.5 + 1.4)
		if not _is_clear(sw, 0.8):
			sw = end_a + inward * 1.6 - lateral * (b.width * 0.5 + 1.4)
		_out.lasers.append({"pos": Vector3(c.x, 0, c.y), "rot": 0.0 if b.along_x else PI * 0.5, "span": b.width,
			"switch": Vector3(sw.x, 0, sw.y), "switch_rot": atan2(-inward.x, -inward.y)})
		_occupy(sw, 1.2)
		count += 1


# ==========================================================================
# Population
# ==========================================================================

func _populate(i: int, floor_idx: int, depth: int, final: bool) -> void:
	var r: Dictionary = _rooms[i]
	var tag: String = r.tag
	var area := (r.rect as Rect2).get_area()
	var budget := area / 75.0 * (1.0 + 0.15 * floor_idx) * rng.randf_range(0.7, 1.25)
	if tag == "cargo":
		budget *= 1.2
	elif tag == "reactor":
		budget *= 0.8  # the uplink alarm brings plenty more
	var blue_p := 0.05 + 0.05 * floor_idx + 0.03 * (depth - 1)
	while budget > 0.0:
		var roll := rng.randf()
		if roll < 0.45:
			# A group of swarmers doing something: feeding on a carcass,
			# burrowed in wait, or milling about.
			var spot := _free_spot(r, 1.8, 1.0)
			if spot.is_empty():
				break
			var c: Vector2 = spot[0]
			var count := rng.randi_range(3, 5)
			var act := rng.randf()
			if act < 0.4:
				_out.carcasses.append([Vector3(c.x, 0, c.y), rng.randf() * TAU])
				_occupy(c, 1.4)
				var a0 := rng.randf() * TAU
				for k in count:
					var a := a0 + TAU * k / count + rng.randf_range(-0.3, 0.3)
					var p := c + Vector2(cos(a), sin(a)) * rng.randf_range(1.0, 1.4)
					if not _in_pieces(r, p):
						continue
					_place(&"swarmer", p, &"dormant", Vector2.INF, 1 if rng.randf() < blue_p else 0, {"idle": &"feed", "food": Vector3(c.x, 0, c.y)})
			else:
				var mode: StringName = &"burrow" if act < 0.7 else &"wander"
				var spread := 2.4 if mode == &"burrow" else 1.6
				for k in count:
					var p := c + Vector2(rng.randf_range(-spread, spread), rng.randf_range(-spread, spread))
					if not _in_pieces(r, p):
						p = c
					_place(&"swarmer", p, &"dormant", Vector2.INF, 1 if rng.randf() < blue_p else 0, {"idle": mode, "radius": 2.5})
			budget -= count * 0.8
		elif roll < 0.68:
			# A patrol walking the length of one walkway.
			var spot := _free_spot(r, 1.4, 0.0)
			if spot.is_empty():
				break
			var to := _free_spot(r, 1.4, 0.0, spot[1])
			if to.is_empty():
				continue
			var t: StringName = &"shield" if rng.randf() < 0.25 + 0.05 * floor_idx else &"swarmer"
			_place(t, spot[0], &"patrol", to[0], 1 if rng.randf() < blue_p else 0)
			var buddy: Vector2 = spot[0] + Vector2(0.8, 0.6)
			if t == &"swarmer" and rng.randf() < 0.6 and _in_pieces(r, buddy) and _in_pieces(r, to[0] + Vector2(0.8, 0.6)):
				_place(&"swarmer", buddy, &"patrol", to[0] + Vector2(0.8, 0.6), 0)
				budget -= 1.0
			budget -= 2.0 if t == &"shield" else 1.0
		elif roll < 0.82:
			var spot := _free_spot(r, 1.6, 0.8)
			if spot.is_empty():
				break
			var b_idle := {"idle": &"burrow"} if rng.randf() < 0.5 else {"idle": &"wander", "radius": 2.0}
			_place(&"burster", spot[0], &"dormant", Vector2.INF, 0, b_idle)
			if _in_pieces(r, spot[0] + Vector2(1.0, 0.4)):
				_place(&"burster", spot[0] + Vector2(1.0, 0.4), &"dormant", Vector2.INF, 0, b_idle)
			budget -= 2.0
		elif roll < 0.94:
			var spot := _free_spot(r, 1.8, 0.8)
			if spot.is_empty():
				break
			_place(&"shield", spot[0], &"dormant", Vector2.INF, 1 if rng.randf() < blue_p * 2.0 else 0,
				{"idle": &"wander", "radius": 3.0} if rng.randf() < 0.6 else {})
			budget -= 2.5
		else:
			if floor_idx == 0 and not final:
				budget -= 1.0
				continue
			var spot := _free_spot(r, 1.6, 0.8)
			if spot.is_empty():
				break
			_place(&"swarmer", spot[0], &"dormant", Vector2.INF, 2, {"idle": &"wander", "radius": 1.8})
			budget -= 3.0


func _place(type: StringName, p: Vector2, mode: StringName, to: Vector2, tier: int, extra := {}) -> void:
	var to3 := Vector3.ZERO if to == Vector2.INF else Vector3(to.x, 0, to.y)
	var d := {"type": type, "pos": Vector3(p.x, 0, p.y), "mode": mode, "to": to3, "tier": tier}
	d.merge(extra)
	_out.placements.append(d)


## Packs that walk a loop through a few neighbouring rooms (never the arrival room).
func _roaming_packs(floor_idx: int, dist: Array[int]) -> void:
	var packs := mini(1 + floor_idx, 3)
	for k in packs:
		var cands: Array[int] = []
		for i in _rooms.size():
			if i != 0 and dist[i] >= 2:
				cands.append(i)
		if cands.is_empty():
			return
		var cur: int = cands[rng.randi_range(0, cands.size() - 1)]
		var stops: Array[int] = [cur]
		for step in rng.randi_range(2, 3):
			var nbs: Array[int] = []
			for nb in _neighbors(cur):
				if nb != 0 and not stops.has(nb):
					nbs.append(nb)
			if nbs.is_empty():
				break
			cur = nbs[rng.randi_range(0, nbs.size() - 1)]
			stops.append(cur)
		if stops.size() < 2:
			continue
		var route: Array[Vector3] = []
		for ri in stops:
			var sp := _free_spot(_rooms[ri], 2.0, 0.0)
			if not sp.is_empty():
				route.append(Vector3(sp[0].x, 0, sp[0].y))
		if route.size() < 2:
			continue
		var start := Vector2(route[0].x, route[0].z)
		for m in rng.randi_range(2, 4):
			var p := start + Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
			if not _in_pieces(_rooms[stops[0]], p):
				p = start
			_place(&"swarmer", p, &"dormant", Vector2.INF, 0, {"idle": &"roam", "route": route})
