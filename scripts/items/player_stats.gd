class_name PlayerStats
## Aggregates equipped gear + perks + level into one flat stat sheet.
## Percent stats are fractions (0.1 = +10%); max_health / regen / pierce are flat.

const KEYS := ["gun_damage", "fire_rate", "crit_chance", "crit_damage", "pierce", "proj_speed", "noise", "spread",
	"burn", "shock", "cryo", "corrode", "blade_damage", "blade_speed", "blade_reach", "regen", "max_health", "armor",
	"stealth", "xp", "salvage", "explosion", "move_speed", "roll_cd"]

const CAPS := {"armor": 0.6, "crit_chance": 0.7, "stealth": 0.6, "burn": 0.6, "shock": 0.6, "cryo": 0.6, "corrode": 0.6}
const FLOORS := {"roll_cd": -0.5, "noise": -0.8, "spread": -0.8}

const HEALTH_PER_LEVEL := 4.0


static func compute(equipped: Dictionary, perks: Dictionary, level: int) -> Dictionary:
	var s := {}
	for k in KEYS:
		s[k] = 0.0
	var legendaries: Array = []
	for slot in equipped:
		var item: Dictionary = equipped[slot]
		if item.is_empty():
			continue
		for stat in Loot.ARMOR_BASE.get(item.slot, {}):
			s[stat] += Loot.armor_base_value(item, stat)
		for a in item.get("affixes", []):
			if s.has(a.stat):
				s[a.stat] += float(a.value)
		if item.get("legendary", "") != "":
			legendaries.append(item.legendary)
	for id in perks:
		var perk: Dictionary = Perks.LIST.get(id, {})
		if not perk.is_empty():
			s[perk.stat] += perk.per_rank * int(perks[id])
	s.max_health += HEALTH_PER_LEVEL * (level - 1)
	for k in CAPS:
		s[k] = minf(s[k], CAPS[k])
	for k in FLOORS:
		s[k] = maxf(s[k], FLOORS[k])
	s["legendaries"] = legendaries
	return s
