class_name RunUpgrades
## Upgrades you pick during a strike (one of three after every cleared fight). They last for
## this operation only and stack into a build: stat cards nudge numbers, the rest change how
## you play. Legendary cards grant a legendary item's effect for the run (Profile.run_legendaries).
##   kind "stat":      adds `stats` to the player's stat sheet (same keys as gear affixes)
##   kind "legendary": the legendary effect `id` (see Loot.LEGENDARIES)
##   kind "flag":      a run-only mechanic the Player checks (Player.run_flags)

const LIST := {
	# Mechanics: these change how you play.
	"exec_nova": {"kind": "flag", "name": "Chain Execution", "tag": "EXECUTIONS",
		"desc": "Executions release a small shockwave: bugs around you break, ready to execute."},
	"breaker_roll": {"kind": "flag", "name": "Breaker Roll", "tag": "MOBILITY",
		"desc": "Rolling through bugs breaks them. Roll in, cut them down."},
	"overcharge": {"kind": "flag", "name": "Overcharge", "tag": "SHOCKWAVE",
		"desc": "Shockwave costs 35 energy instead of 50 and reaches 20% further."},
	"siphon": {"kind": "flag", "name": "Blood Siphon", "tag": "BLADE",
		"desc": "Blade kills heal 2. Executions heal 50% more."},
	# Legendary effects, for this run.
	"splitter": {"kind": "legendary", "name": "Hydra Rounds", "tag": "GUN", "desc": "Kills split your bolt into three more."},
	"chain_reaction": {"kind": "legendary", "name": "Ruinmaker", "tag": "GUN", "desc": "Bugs you kill have a 35% chance to explode."},
	"reaper": {"kind": "legendary", "name": "Widowmaker", "tag": "BLADE", "desc": "Blade kills heal 4 and refresh your roll."},
	"bulwark": {"kind": "legendary", "name": "Bastion Core", "tag": "DEFENCE", "desc": "After a roll, take 50% less damage for 1.5 s."},
	"phase_step": {"kind": "legendary", "name": "Ghostwalkers", "tag": "MOBILITY", "desc": "Rolls go 40% further and chill nearby bugs."},
	"adrenal": {"kind": "legendary", "name": "Adrenal Spike", "tag": "TEMPO", "desc": "Kills give +8% fire rate and speed for 3 s (stacks 5)."},
	"overclock": {"kind": "legendary", "name": "Overclock Chip", "tag": "GUN", "desc": "Every 8th gun shot also fires a piercing rail bolt."},
	# Stats: smaller, stackable.
	"trigger": {"kind": "stat", "name": "Hair Trigger", "tag": "GUN", "desc": "+25% fire rate.", "stats": {"fire_rate": 0.25}},
	"heavy_hand": {"kind": "stat", "name": "Heavy Hand", "tag": "BLADE", "desc": "+30% blade damage, +15% reach.", "stats": {"blade_damage": 0.3, "blade_reach": 0.15}},
	"deadeye": {"kind": "stat", "name": "Deadeye", "tag": "CRIT", "desc": "+10% crit chance, +50% crit damage.", "stats": {"crit_chance": 0.1, "crit_damage": 0.5}},
	"incendiary": {"kind": "stat", "name": "Incendiary", "tag": "ELEMENT", "desc": "Hits set bugs on fire.", "stats": {"burn": 0.35}},
	"arc": {"kind": "stat", "name": "Arc Coil", "tag": "ELEMENT", "desc": "Hits can arc lightning to two more bugs.", "stats": {"shock": 0.3}},
	"momentum": {"kind": "stat", "name": "Momentum", "tag": "MOBILITY", "desc": "+12% move speed, rolls recharge 20% faster.", "stats": {"move_speed": 0.12, "roll_cd": -0.2}},
	"carapace": {"kind": "stat", "name": "Carapace", "tag": "DEFENCE", "desc": "+30 max health, +2 health per second.", "stats": {"max_health": 30.0, "regen": 2.0}},
}

## Stat cards can be taken more than once; the others once per run.
const REPEATABLE_KIND := "stat"


## `n` different offers, never something already owned (except stats). Leans toward mechanics:
## at least one card that isn't a plain stat whenever any are left.
static func roll(n: int, owned: Dictionary) -> Array[String]:
	var mech: Array[String] = []
	var stat: Array[String] = []
	for id in LIST:
		var u: Dictionary = LIST[id]
		if u.kind == REPEATABLE_KIND:
			stat.append(id)
		elif not owned.has(id) and not Profile.has_legendary(id):
			mech.append(id)
	mech.shuffle()
	stat.shuffle()
	var out: Array[String] = []
	if not mech.is_empty():
		out.append(mech.pop_back())
	var pool: Array[String] = mech + stat
	pool.shuffle()
	while out.size() < n and not pool.is_empty():
		out.append(pool.pop_back())
	return out


static func color(id: String) -> Color:
	match String(LIST[id].kind):
		"legendary":
			return Loot.RARITY_COLORS[3]
		"flag":
			return Loot.RARITY_COLORS[2]
	return Loot.RARITY_COLORS[1]


static func kind_label(id: String) -> String:
	return {"legendary": "LEGENDARY EFFECT", "flag": "MECHANIC", "stat": "UPGRADE"}.get(String(LIST[id].kind), "")


## Grant `id` to the player for the rest of the run.
static func apply(id: String, p: Player) -> void:
	var u: Dictionary = LIST[id]
	p.run_upgrades[id] = int(p.run_upgrades.get(id, 0)) + 1
	match String(u.kind):
		"stat":
			for k in u.stats:
				p.run_stats[k] = float(p.run_stats.get(k, 0.0)) + float(u.stats[k])
		"legendary":
			Profile.run_legendaries[id] = true
		"flag":
			p.run_flags[id] = true
	p.load_loadout()
