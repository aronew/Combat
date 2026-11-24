extends SceneTree
## Generated-floor sanity test: builds many floors of the Deepworks complex and
## checks that every region is reachable from the arrival lift, that objectives,
## objects and the starting population stand on walkable deck, and reports sizes.
##   godot --headless --path . --script res://tests/test_complex.gd

const SEEDS := 24

var fails := 0


func _initialize() -> void:
	await process_frame  # autoloads join the tree after _initialize
	var prof = root.get_node("/root/Profile")
	var level_scene: PackedScene = load("res://scenes/level.tscn")
	var classic_area := 0.0
	prof.dive_layout = "classic"
	var classic = level_scene.instantiate()
	root.add_child(classic)
	classic_area = _area(classic)
	classic.queue_free()
	await process_frame

	prof.dive_layout = "complex"
	prof.dive_destination = "deepworks"
	var total_area := {}
	var t0 := Time.get_ticks_msec()
	var builds := 0
	for depth in [1, 3, 5]:
		prof.dive_depth = depth
		var dive_areas: Array[float] = []
		for s in SEEDS:
			prof.dive_seed = 1000 + s * 7919
			prof.dive_floors = ComplexGen.floor_count(depth)
			var dive_area := 0.0
			for f in prof.dive_floors:
				prof.dive_floor = f
				var lvl = level_scene.instantiate()
				root.add_child(lvl)
				builds += 1
				_check_floor(lvl, "depth %d seed %d floor %d" % [depth, prof.dive_seed, f + 1])
				dive_area += _area(lvl)
				lvl.queue_free()
				await process_frame
			dive_areas.append(dive_area)
		dive_areas.sort()
		total_area[depth] = dive_areas[dive_areas.size() / 2]
	# The other destinations: same checks on a few dives each (depth 3).
	for dest in ["starship", "foundry"]:
		prof.dive_destination = dest
		prof.dive_depth = 3
		prof.dive_floors = ComplexGen.floor_count(3)
		for s in 8:
			prof.dive_seed = 5000 + s * 7919
			for f in prof.dive_floors:
				prof.dive_floor = f
				var lvl = level_scene.instantiate()
				root.add_child(lvl)
				builds += 1
				_check_floor(lvl, "%s seed %d floor %d" % [dest, prof.dive_seed, f + 1])
				lvl.queue_free()
				await process_frame
	prof.dive_destination = "deepworks"
	var ms := Time.get_ticks_msec() - t0
	print("classic level walkable area: %d m2" % roundi(classic_area))
	for d in total_area:
		print("depth %d: %d floors, median dive area %d m2 (%.1fx classic)" % [d, ComplexGen.floor_count(d), roundi(total_area[d]), total_area[d] / classic_area])
	print("%d floors built in %d ms (%.0f ms each)" % [builds, ms, float(ms) / builds])
	print("RESULT: %s (%d failures)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(1 if fails > 0 else 0)


func _area(lvl) -> float:
	var a := 0.0
	for r in lvl.regions:
		a += (r.rect as Rect2).get_area()
	return a


func _fail(where: String, what: String) -> void:
	fails += 1
	if fails <= 40:
		print("FAIL %s: %s" % [where, what])


func _check_floor(lvl, where: String) -> void:
	var start: int = lvl.region_of(lvl.player_start)
	if start < 0:
		_fail(where, "player start off the deck")
		return
	# Every region reachable from the start (the next-hop table has a route).
	for r in lvl.regions.size():
		if r != start and lvl._next[start][r] < 0:
			_fail(where, "region %d (%s) unreachable" % [r, lvl.regions[r].name])
	# Catwalk doorways are full width (not split by walkway-strip seams).
	for pt in lvl.portals:
		var a: int = pt.a
		var b: int = pt.b
		if (lvl.regions[a].room == &"bridge") != (lvl.regions[b].room == &"bridge") and pt.half * 2.0 < 2.2:
			_fail(where, "narrow catwalk doorway (%.1f m) at %s" % [pt.half * 2.0, pt.center])
	# Every bridge links two rooms.
	for i in lvl.regions.size():
		if lvl.regions[i].room == &"bridge" and lvl.region_neighbors(i).size() < 2:
			_fail(where, "catwalk region %d has %d links" % [i, lvl.region_neighbors(i).size()])
	if lvl.is_final_floor:
		if lvl.uplink == null or not lvl.is_walkable(lvl.uplink_position):
			_fail(where, "uplink missing or off the deck")
	else:
		if lvl.cargo == null or not lvl.is_walkable(lvl.cargo_position):
			_fail(where, "cargo lift missing or off the deck")
		if lvl.breakers.is_empty():
			_fail(where, "no breakers")
		for b in lvl.breakers:
			if not lvl.is_walkable(b.position):
				_fail(where, "breaker off the deck at %s" % b.position)
	if not lvl.is_walkable(lvl.lift_position):
		_fail(where, "arrival lift off the deck")
	for p in lvl.placements:
		if not lvl.is_walkable(p.pos):
			_fail(where, "%s placed off the deck at %s" % [p.type, p.pos])
		if p.mode == &"patrol" and lvl.region_of(p.pos) != lvl.region_of(p.to):
			_fail(where, "patrol crosses regions %s -> %s" % [p.pos, p.to])
		for wp in p.get("route", []):
			if not lvl.is_walkable(wp):
				_fail(where, "roaming route point off the deck at %s" % wp)
		if p.get("idle", &"") == &"feed" and Vector2(p.pos.x - p.food.x, p.pos.z - p.food.z).length() > 2.0:
			_fail(where, "feeding bug too far from its food")
	for t in lvl.turret_spots:
		if not lvl.is_walkable(t.pos):
			_fail(where, "turret off the deck at %s" % t.pos)
	for n in lvl.nests:
		if not lvl.is_walkable(n.position):
			_fail(where, "nest off the deck at %s" % n.position)
