extends Node
## Autoload "Profile": your persistent mercenary. Salvage, XP/level, perk
## points and perks, the stash, equipped gear and unlocked depth, saved as JSON
## (user://combat_profile.json). Also holds the state of the current dive:
## loot found this dive sits in `dive_bag` and only reaches the stash on extraction.

signal changed

const PATH := "user://combat_profile.json"
const LEGACY_PATH := "user://combat_save.cfg"
const MAX_LEVEL := 30
const MAX_DEPTH := 5

## Fabricator crates: cost in salvage and rarity weights [common, rare, epic, legendary].
const CRATES := {
	"field": {"name": "Field Crate", "cost": 120, "weights": [55.0, 35.0, 9.0, 1.0], "desc": "One random item. Mostly common and rare."},
	"armory": {"name": "Armory Crate", "cost": 450, "weights": [0.0, 60.0, 33.0, 7.0], "desc": "One rare-or-better item."},
	"elite": {"name": "Elite Cache", "cost": 1400, "weights": [0.0, 0.0, 72.0, 28.0], "desc": "One epic-or-better item."},
}

var data := {}
var dive_depth := 1
var dive_bag: Array = []
var dive_xp := 0
var dive_levels := 0
var last_result := {}
## Dev/test switch: when false nothing is written to disk (autoplay --gear runs).
var persist := true

var _stats_cache := {}


func _ready() -> void:
	load_profile()


func defaults() -> Dictionary:
	return {
		"version": 1, "salvage": 0, "xp": 0, "level": 1, "perk_points": 0, "perks": {},
		"stash": [], "equipped": {"gun": Loot.starter_gun(), "blade": Loot.starter_blade()},
		"max_depth": 1, "dives": 0, "extractions": 0, "best_haul": 0,
	}


func load_profile() -> void:
	data = defaults()
	if FileAccess.file_exists(PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			for k in parsed:
				data[k] = parsed[k]
			_normalize()
	elif FileAccess.file_exists(LEGACY_PATH):
		var cfg := ConfigFile.new()
		if cfg.load(LEGACY_PATH) == OK:
			data.salvage = int(cfg.get_value("profile", "banked_salvage", 0))
			data.dives = int(cfg.get_value("profile", "dives", 0))
			data.extractions = int(cfg.get_value("profile", "extractions", 0))
			data.best_haul = int(cfg.get_value("profile", "best_haul", 0))
	_touch()


## JSON turns ints into floats; put the important ones back.
func _normalize() -> void:
	for k in ["salvage", "xp", "level", "perk_points", "max_depth", "dives", "extractions", "best_haul"]:
		data[k] = int(data.get(k, 0))
	data.level = maxi(data.level, 1)
	data.max_depth = clampi(data.max_depth, 1, MAX_DEPTH)
	var perks := {}
	for id in data.get("perks", {}):
		perks[id] = int(data.perks[id])
	data.perks = perks
	for item in data.stash:
		_normalize_item(item)
	for slot in data.equipped:
		_normalize_item(data.equipped[slot])
	if not data.equipped.has("gun"):
		data.equipped.gun = Loot.starter_gun()
	if not data.equipped.has("blade"):
		data.equipped.blade = Loot.starter_blade()


func _normalize_item(item: Dictionary) -> void:
	item.rarity = int(item.get("rarity", 0))
	item.level = int(item.get("level", 1))


func save() -> void:
	if not persist:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


func reset_profile() -> void:
	data = defaults()
	save()
	_touch()


func _touch() -> void:
	_stats_cache = PlayerStats.compute(data.equipped, data.perks, data.level)
	changed.emit()


# --------------------------------------------------------------------------
# Character
# --------------------------------------------------------------------------

func stats() -> Dictionary:
	return _stats_cache


func equipped(slot: String) -> Dictionary:
	return data.equipped.get(slot, {})


func has_legendary(id: String) -> bool:
	return id in _stats_cache.get("legendaries", [])


func xp_needed(level: int) -> int:
	return roundi(120.0 * pow(level, 1.55))


func xp_progress() -> float:
	if data.level >= MAX_LEVEL:
		return 1.0
	return clampf(float(data.xp) / xp_needed(data.level), 0.0, 1.0)


## Returns how many levels were gained.
func add_xp(amount: int) -> int:
	var gained := 0
	amount = roundi(amount * (1.0 + _stats_cache.get("xp", 0.0)))
	data.xp += amount
	dive_xp += amount
	while data.level < MAX_LEVEL and data.xp >= xp_needed(data.level):
		data.xp -= xp_needed(data.level)
		data.level += 1
		data.perk_points += 1
		gained += 1
	if gained > 0:
		dive_levels += gained
		_touch()
	return gained


func upgrade_perk(id: String) -> bool:
	var perk: Dictionary = Perks.LIST.get(id, {})
	if perk.is_empty() or data.perk_points <= 0:
		return false
	var rank: int = data.perks.get(id, 0)
	if rank >= perk.max:
		return false
	data.perks[id] = rank + 1
	data.perk_points -= 1
	save()
	_touch()
	return true


# --------------------------------------------------------------------------
# Inventory
# --------------------------------------------------------------------------

func find_in_stash(id: String) -> int:
	for i in data.stash.size():
		if data.stash[i].id == id:
			return i
	return -1


## Equip a stash item; whatever was in that slot goes back to the stash.
func equip(id: String) -> bool:
	var i := find_in_stash(id)
	if i < 0:
		return false
	var item: Dictionary = data.stash[i]
	data.stash.remove_at(i)
	var old: Dictionary = data.equipped.get(item.slot, {})
	if not old.is_empty():
		data.stash.append(old)
	data.equipped[item.slot] = item
	save()
	_touch()
	return true


## Armour and implants can be taken off (the gun and blade slots can't be empty).
func unequip(slot: String) -> bool:
	if slot == "gun" or slot == "blade" or not data.equipped.has(slot):
		return false
	data.stash.append(data.equipped[slot])
	data.equipped.erase(slot)
	save()
	_touch()
	return true


func scrap(id: String) -> int:
	var i := find_in_stash(id)
	if i < 0:
		return 0
	var value := Loot.scrap_value(data.stash[i])
	data.stash.remove_at(i)
	data.salvage += value
	save()
	_touch()
	return value


func item_level_for_depth(depth: int) -> int:
	return clampi(depth * 3 - 2 + int(data.level / 4), 1, 40)


func buy_crate(kind: String) -> Dictionary:
	var crate: Dictionary = CRATES.get(kind, {})
	if crate.is_empty() or data.salvage < crate.cost:
		return {}
	data.salvage -= crate.cost
	var level := item_level_for_depth(data.max_depth)
	var item := Loot.roll_item(level, Loot.roll_rarity(crate.weights))
	data.stash.append(item)
	save()
	_touch()
	return item


# --------------------------------------------------------------------------
# Dives
# --------------------------------------------------------------------------

func start_dive(depth: int) -> void:
	dive_depth = clampi(depth, 1, data.max_depth)
	dive_bag.clear()
	dive_xp = 0
	dive_levels = 0


func add_to_bag(item: Dictionary) -> void:
	dive_bag.append(item)


## Extraction: loot and salvage come home; next depth unlocks.
func bank_dive(haul: int) -> Dictionary:
	var result := {"success": true, "haul": haul, "items": dive_bag.duplicate(), "xp": dive_xp, "levels": dive_levels, "depth": dive_depth}
	data.stash.append_array(dive_bag)
	data.salvage += haul
	data.dives += 1
	data.extractions += 1
	data.best_haul = maxi(data.best_haul, haul)
	if dive_depth >= data.max_depth and data.max_depth < MAX_DEPTH:
		data.max_depth += 1
		result.unlocked = data.max_depth
	dive_bag.clear()
	last_result = result
	save()
	_touch()
	return result


## Death: everything found this dive is lost (XP and levels are kept).
func lose_dive(haul: int) -> Dictionary:
	var result := {"success": false, "haul": haul, "items": dive_bag.duplicate(), "xp": dive_xp, "levels": dive_levels, "depth": dive_depth}
	data.dives += 1
	dive_bag.clear()
	last_result = result
	save()
	_touch()
	return result
