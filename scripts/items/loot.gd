class_name Loot
## Item generation, naming and tooltips. Items are plain Dictionaries so they
## save to JSON as-is:
##   { id, slot, archetype, rarity, level, name, affixes: [{stat, value}], legendary }
## Rarity colours match the enemy tiers: white / blue / gold / purple.

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

const RARITY_NAMES := ["Common", "Rare", "Epic", "Legendary"]
const RARITY_COLORS := [Color("d8dde2"), Color("3aa0ff"), Color("ffc23d"), Color("b04dff")]
const RARITY_BASE := [1.0, 1.08, 1.16, 1.25]  ## Base-stat multiplier.
const RARITY_AFFIX := [0.8, 1.0, 1.15, 1.3]  ## Affix-value multiplier.
const RARITY_AFFIX_COUNT := [1, 2, 3, 3]

const SLOTS := ["gun", "blade", "helmet", "chest", "boots", "implant"]
const SLOT_NAMES := {"gun": "Gun", "blade": "Blade", "helmet": "Helmet", "chest": "Chest", "boots": "Boots", "implant": "Implant"}

## Gun archetypes: how the weapon fires. Damage/fire_rate scale with item level and rarity.
const GUNS := {
	"rifle": {"name": "Assault Rifle", "code": "AR", "damage": 12.0, "fire_rate": 12.0, "pellets": 1, "spread": 3.5, "speed": 44.0,
		"lifetime": 0.85, "knockback": 6.5, "pierce": 0, "noise": 1.0, "blast": 0.0, "color": "19f4ff", "shake": 0.035, "bolt": 1.0},
	"smg": {"name": "SMG", "code": "SM", "damage": 6.5, "fire_rate": 20.0, "pellets": 1, "spread": 7.0, "speed": 40.0,
		"lifetime": 0.6, "knockback": 3.0, "pierce": 0, "noise": 0.75, "blast": 0.0, "color": "2fffc8", "shake": 0.02, "bolt": 0.75},
	"shotgun": {"name": "Scattergun", "code": "SG", "damage": 9.0, "fire_rate": 2.2, "pellets": 7, "spread": 16.0, "speed": 38.0,
		"lifetime": 0.36, "knockback": 9.0, "pierce": 0, "noise": 1.4, "blast": 0.0, "color": "ffb03b", "shake": 0.16, "bolt": 0.8},
	"railgun": {"name": "Rail Lance", "code": "RL", "damage": 70.0, "fire_rate": 1.3, "pellets": 1, "spread": 0.4, "speed": 120.0,
		"lifetime": 0.5, "knockback": 14.0, "pierce": 5, "noise": 1.6, "blast": 0.0, "color": "e6f6ff", "shake": 0.22, "bolt": 2.2},
	"launcher": {"name": "Hive Popper", "code": "HP", "damage": 40.0, "fire_rate": 1.6, "pellets": 1, "spread": 2.0, "speed": 26.0,
		"lifetime": 1.1, "knockback": 4.0, "pierce": 0, "noise": 1.5, "blast": 3.2, "color": "ff2bd6", "shake": 0.15, "bolt": 1.4},
}

const BLADES := {
	"mono": {"name": "Mono-Blade", "damage": 26.0, "finisher": 48.0, "cooldown": 0.24, "range": 2.5, "arc": 140.0,
		"finisher_arc": 230.0, "color": "19f4ff"},
	"cleaver": {"name": "Breach Cleaver", "damage": 44.0, "finisher": 82.0, "cooldown": 0.4, "range": 2.9, "arc": 170.0,
		"finisher_arc": 260.0, "color": "ff8a1e"},
}

## Base stats for armour pieces (scaled by level and rarity).
const ARMOR_BASE := {
	"helmet": {"armor": 0.04, "max_health": 6.0},
	"chest": {"armor": 0.07, "max_health": 18.0},
	"boots": {"move_speed": 0.04, "roll_cd": -0.05},
	"implant": {},
}

## Random-stat pools per slot: [stat, min, max] at item level 1.
const AFFIXES := {
	"gun": [["gun_damage", 0.06, 0.14], ["fire_rate", 0.05, 0.12], ["crit_chance", 0.03, 0.08], ["crit_damage", 0.15, 0.4],
		["pierce", 1.0, 1.0], ["proj_speed", 0.1, 0.25], ["noise", -0.35, -0.15], ["spread", -0.3, -0.15],
		["burn", 0.08, 0.18], ["shock", 0.08, 0.18], ["cryo", 0.08, 0.18], ["corrode", 0.08, 0.18]],
	"blade": [["blade_damage", 0.08, 0.2], ["blade_speed", 0.05, 0.12], ["blade_reach", 0.08, 0.18], ["crit_chance", 0.03, 0.08],
		["burn", 0.12, 0.25], ["cryo", 0.12, 0.25], ["regen", 0.5, 1.5]],
	"helmet": [["max_health", 6.0, 14.0], ["armor", 0.02, 0.05], ["stealth", 0.06, 0.15], ["crit_chance", 0.02, 0.05],
		["xp", 0.05, 0.12], ["salvage", 0.05, 0.15]],
	"chest": [["max_health", 10.0, 25.0], ["armor", 0.03, 0.07], ["regen", 0.5, 2.0], ["explosion", 0.1, 0.25], ["blade_damage", 0.05, 0.12]],
	"boots": [["move_speed", 0.03, 0.08], ["roll_cd", -0.12, -0.05], ["max_health", 5.0, 12.0], ["stealth", 0.05, 0.12], ["armor", 0.02, 0.04]],
	"implant": [["gun_damage", 0.05, 0.12], ["blade_damage", 0.06, 0.15], ["crit_chance", 0.03, 0.07], ["crit_damage", 0.15, 0.35],
		["fire_rate", 0.04, 0.1], ["regen", 0.5, 1.5], ["salvage", 0.06, 0.15], ["xp", 0.06, 0.14], ["explosion", 0.1, 0.25], ["move_speed", 0.02, 0.06]],
}
const FLAT_STATS := ["max_health", "regen", "pierce"]
const ELEMENTS := ["burn", "shock", "cryo", "corrode"]

## Legendary effects (one per purple item). Implemented in Player / Enemy.
const LEGENDARIES := {
	"splitter": {"slot": "gun", "name": "Hydra", "desc": "Kills split your bolt into three more."},
	"chain_reaction": {"slot": "gun", "name": "Ruinmaker", "desc": "Bugs you kill have a 35% chance to explode."},
	"reaper": {"slot": "blade", "name": "Widowmaker", "desc": "Blade kills heal 4 and refresh your roll."},
	"bulwark": {"slot": "chest", "name": "Bastion Core", "desc": "After a roll, take 50% less damage for 1.5 s."},
	"phase_step": {"slot": "boots", "name": "Ghostwalkers", "desc": "Rolls go 40% further and chill nearby bugs."},
	"hunters_eye": {"slot": "helmet", "name": "Predator Visor", "desc": "Unaware bugs take double damage."},
	"adrenal": {"slot": "implant", "name": "Adrenal Spike", "desc": "Kills give +8% fire rate and speed for 3 s (stacks 5)."},
	"overclock": {"slot": "implant", "name": "Overclock Chip", "desc": "Every 8th gun shot also fires a piercing rail bolt."},
}

const STAT_LABELS := {
	"gun_damage": "Gun damage", "fire_rate": "Fire rate", "crit_chance": "Crit chance", "crit_damage": "Crit damage",
	"pierce": "Pierce", "proj_speed": "Bolt speed", "noise": "Noise", "spread": "Spread", "burn": "Burn chance",
	"shock": "Shock chance", "cryo": "Cryo chance", "corrode": "Corrode chance", "blade_damage": "Blade damage",
	"blade_speed": "Blade speed", "blade_reach": "Blade reach", "regen": "Regen", "max_health": "Max health",
	"armor": "Armour", "stealth": "Stealth", "xp": "XP gain", "salvage": "Salvage find", "explosion": "Explosion power",
	"move_speed": "Move speed", "roll_cd": "Roll cooldown",
}

const MAKERS := ["Kestrel", "Valkyr", "Hammerhead", "Orbis", "Deepworks", "Mantis", "Corvid", "Halcyon"]
const ARMOR_NOUNS := {"helmet": ["Visor", "Helm", "Hood"], "chest": ["Plate", "Carapace", "Rig"], "boots": ["Treads", "Striders", "Boots"], "implant": ["Chip", "Node", "Graft"]}
const BLADE_NOUNS := {"mono": ["Mono-Edge", "Filament", "Needle"], "cleaver": ["Cleaver", "Breaker", "Hewer"]}
const ROMAN := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]


# ==========================================================================
# Generation
# ==========================================================================

static func new_id() -> String:
	return "%x%04x" % [Time.get_ticks_usec(), randi() % 65536]


## Roll a random item. Empty slot/archetype = random.
static func roll_item(level: int, rarity: int, slot := "", archetype := "") -> Dictionary:
	if slot == "":
		slot = ["gun", "gun", "blade", "helmet", "chest", "boots", "implant"].pick_random()
	if archetype == "":
		if slot == "gun":
			archetype = GUNS.keys().pick_random()
		elif slot == "blade":
			archetype = BLADES.keys().pick_random()
		else:
			archetype = slot
	var item := {
		"id": new_id(), "slot": slot, "archetype": archetype, "rarity": rarity, "level": maxi(level, 1),
		"name": "", "affixes": [], "legendary": "",
	}
	var count: int = RARITY_AFFIX_COUNT[rarity]
	if rarity == Rarity.COMMON and randf() < 0.5 and slot != "implant":
		count = 0  # implants have no base stats, so they always roll at least one
	var pool: Array = AFFIXES[slot].duplicate()
	pool.shuffle()
	var has_element := false
	for entry in pool:
		if item.affixes.size() >= count:
			break
		var stat: String = entry[0]
		if stat in ELEMENTS:
			if has_element:
				continue
			has_element = true
		if stat == "noise" and archetype == "launcher":
			continue
		item.affixes.append({"stat": stat, "value": _affix_value(stat, entry[1], entry[2], level, rarity)})
	if rarity == Rarity.LEGENDARY:
		var options: Array = []
		for key in LEGENDARIES:
			if LEGENDARIES[key].slot == slot:
				options.append(key)
		if not options.is_empty():
			item.legendary = options.pick_random()
	item.name = _make_name(item)
	return item


static func _affix_value(stat: String, lo: float, hi: float, level: int, rarity: int) -> float:
	var v: float = randf_range(lo, hi) * RARITY_AFFIX[rarity]
	if stat == "pierce":
		return 1.0 + (1.0 if rarity >= Rarity.EPIC and randf() < 0.5 else 0.0)
	if stat in FLAT_STATS:
		v *= 1.0 + 0.1 * (level - 1)
		return snappedf(v, 0.1)
	v *= 1.0 + 0.03 * (level - 1)
	return snappedf(v, 0.005)


static func _make_name(item: Dictionary) -> String:
	if item.legendary != "":
		return LEGENDARIES[item.legendary].name
	var maker: String = MAKERS.pick_random()
	var mk: String = ROMAN[clampi(int(item.level / 3), 0, ROMAN.size() - 1)]
	match item.slot:
		"gun":
			return "%s %s-%d" % [maker, GUNS[item.archetype].code, randi_range(2, 19)]
		"blade":
			return "%s %s" % [maker, BLADE_NOUNS[item.archetype].pick_random()]
	return "%s %s Mk.%s" % [maker, ARMOR_NOUNS[item.slot].pick_random(), mk]


static func starter_gun() -> Dictionary:
	var g := roll_item(1, Rarity.COMMON, "gun", "rifle")
	g.affixes = []
	g.name = "Deepworks AR-1"
	return g


static func starter_blade() -> Dictionary:
	var b := roll_item(1, Rarity.COMMON, "blade", "mono")
	b.affixes = []
	b.name = "Deepworks Mono-Edge"
	return b


## Weighted rarity roll. weights = [common, rare, epic, legendary].
static func roll_rarity(weights: Array) -> int:
	var total := 0.0
	for w in weights:
		total += w
	var r := randf() * total
	for i in weights.size():
		r -= weights[i]
		if r <= 0.0:
			return i
	return 0


## Rarity weights for a drop from an enemy of the given tier at the given depth.
static func drop_weights(enemy_tier: int, depth: int) -> Array:
	var d := float(depth - 1)
	match enemy_tier:
		3:
			return [0.0, 0.0, 70.0 - d * 5.0, 30.0 + d * 5.0]
		2:
			return [10.0, 50.0, 35.0 + d * 3.0, 5.0 + d * 2.0]
		1:
			return [40.0, 45.0, 12.0 + d * 2.0, 3.0 + d]
	return [70.0 - d * 5.0, 25.0 + d * 3.0, 4.5 + d * 1.5, 0.5 + d * 0.5]


# ==========================================================================
# Resolved weapon numbers
# ==========================================================================

static func level_mult(item: Dictionary) -> float:
	var rb: float = RARITY_BASE[int(item.rarity)]
	return (1.0 + 0.1 * (int(item.level) - 1)) * rb


## Final gun numbers after item level, rarity and the player's aggregated stats.
static func gun_profile(item: Dictionary, s: Dictionary) -> Dictionary:
	var a: Dictionary = GUNS.get(item.get("archetype", "rifle"), GUNS.rifle)
	var p := a.duplicate()
	p.damage = a.damage * level_mult(item) * (1.0 + s.get("gun_damage", 0.0))
	p.fire_rate = a.fire_rate * (1.0 + s.get("fire_rate", 0.0))
	p.spread = a.spread * maxf(1.0 + s.get("spread", 0.0), 0.2)
	p.speed = a.speed * (1.0 + s.get("proj_speed", 0.0))
	p.pierce = int(a.pierce + s.get("pierce", 0.0))
	p.noise = a.noise * maxf(1.0 + s.get("noise", 0.0), 0.2)
	p.blast = a.blast * (1.0 + s.get("explosion", 0.0) * 0.5)
	p.crit_chance = clampf(0.05 + s.get("crit_chance", 0.0), 0.0, 0.75)
	p.crit_mult = 1.5 + s.get("crit_damage", 0.0)
	return p


static func blade_profile(item: Dictionary, s: Dictionary) -> Dictionary:
	var a: Dictionary = BLADES.get(item.get("archetype", "mono"), BLADES.mono)
	var p := a.duplicate()
	var dmg: float = level_mult(item) * (1.0 + s.get("blade_damage", 0.0))
	p.damage = a.damage * dmg
	p.finisher = a.finisher * dmg
	p.cooldown = a.cooldown / (1.0 + s.get("blade_speed", 0.0))
	p.range = a.range * (1.0 + s.get("blade_reach", 0.0))
	p.crit_chance = clampf(0.05 + s.get("crit_chance", 0.0), 0.0, 0.75)
	p.crit_mult = 1.5 + s.get("crit_damage", 0.0)
	return p


## Rough damage-per-second for comparisons.
static func gun_dps(item: Dictionary, s: Dictionary) -> float:
	var p := gun_profile(item, s)
	return p.damage * p.pellets * p.fire_rate * (1.0 + p.crit_chance * (p.crit_mult - 1.0))


static func blade_dps(item: Dictionary, s: Dictionary) -> float:
	var p := blade_profile(item, s)
	return (p.damage * 2.0 + p.finisher) / (p.cooldown * 3.5) * (1.0 + p.crit_chance * (p.crit_mult - 1.0))


# ==========================================================================
# Presentation
# ==========================================================================

static func color(item: Dictionary) -> Color:
	return RARITY_COLORS[clampi(int(item.get("rarity", 0)), 0, 3)]


static func kind_label(item: Dictionary) -> String:
	match item.slot:
		"gun":
			return GUNS[item.archetype].name
		"blade":
			return BLADES[item.archetype].name
	return SLOT_NAMES[item.slot]


static func scrap_value(item: Dictionary) -> int:
	return roundi([12, 40, 110, 300][int(item.rarity)] * (1.0 + 0.1 * (int(item.level) - 1)))


static func format_stat(stat: String, value: float) -> String:
	var label: String = STAT_LABELS.get(stat, stat)
	if stat in FLAT_STATS:
		var unit := " /s" if stat == "regen" else ""
		return "%s%s %s%s" % ["+" if value >= 0 else "", str(snappedf(value, 0.1)), label, unit]
	if stat in ["noise", "roll_cd", "spread"]:
		return "%d%% %s" % [roundi(value * 100.0), label]
	return "+%s%% %s" % [str(snappedf(value * 100.0, 0.1)), label]


## Tooltip lines: [text, color] pairs.
static func describe(item: Dictionary, s := {}) -> Array:
	var lines: Array = []
	lines.append(["%s %s  ·  Level %d" % [RARITY_NAMES[int(item.rarity)], kind_label(item), int(item.level)], color(item)])
	match item.slot:
		"gun":
			var p := gun_profile(item, s)
			var dmg: String = ("%d" % roundi(p.damage)) if p.pellets == 1 else ("%d x %d" % [roundi(p.damage), p.pellets])
			lines.append(["Damage %s   ·   %.1f shots/s" % [dmg, p.fire_rate], Color.WHITE])
			var extra := []
			if p.pierce > 0:
				extra.append("pierces %d" % p.pierce)
			if p.blast > 0.0:
				extra.append("%.1fm blast" % p.blast)
			extra.append("noise " + ("LOUD" if p.noise >= 1.3 else ("quiet" if p.noise < 0.8 else "normal")))
			lines.append([", ".join(extra), Color(1, 1, 1, 0.7)])
			lines.append(["DPS ~%d" % roundi(gun_dps(item, s)), Color("9ff8ff")])
		"blade":
			var p := blade_profile(item, s)
			lines.append(["Damage %d / finisher %d   ·   %.2fs swing" % [roundi(p.damage), roundi(p.finisher), p.cooldown], Color.WHITE])
			lines.append(["DPS ~%d" % roundi(blade_dps(item, s)), Color("9ff8ff")])
		_:
			var base: Dictionary = ARMOR_BASE.get(item.slot, {})
			for stat in base:
				lines.append([format_stat(stat, armor_base_value(item, stat)), Color.WHITE])
	for a in item.affixes:
		lines.append([format_stat(a.stat, a.value), Color("9ff8ff")])
	if item.legendary != "":
		lines.append(["◆ " + LEGENDARIES[item.legendary].desc, RARITY_COLORS[3]])
	return lines


static func armor_base_value(item: Dictionary, stat: String) -> float:
	var base: Dictionary = ARMOR_BASE.get(item.slot, {})
	var v: float = base.get(stat, 0.0)
	if stat == "max_health":
		return v * level_mult(item)
	return v * (1.0 + 0.03 * (int(item.level) - 1)) * RARITY_BASE[int(item.rarity)]
