class_name Perks
## Permanent upgrades bought with perk points (1 per level) at the Rig.
## Each rank adds `per_rank` to `stat` in the player's stat sheet.

const LIST := {
	"carapace": {"name": "Thick Carapace", "desc": "+12 max health", "stat": "max_health", "per_rank": 12.0, "max": 5},
	"steady_hands": {"name": "Steady Hands", "desc": "+6% gun damage", "stat": "gun_damage", "per_rank": 0.06, "max": 5},
	"trigger": {"name": "Trigger Discipline", "desc": "+5% fire rate", "stat": "fire_rate", "per_rank": 0.05, "max": 5},
	"bladework": {"name": "Bladework", "desc": "+10% blade damage", "stat": "blade_damage", "per_rank": 0.1, "max": 5},
	"light_step": {"name": "Light Step", "desc": "-8% roll cooldown", "stat": "roll_cd", "per_rank": -0.08, "max": 3},
	"ghost": {"name": "Ghost", "desc": "Bugs see you from 10% less far", "stat": "stealth", "per_rank": 0.1, "max": 3},
	"scavenger": {"name": "Scavenger", "desc": "+10% salvage found", "stat": "salvage", "per_rank": 0.1, "max": 5},
	"demolitions": {"name": "Demolitions", "desc": "+15% explosion damage and size", "stat": "explosion", "per_rank": 0.15, "max": 3},
	"deadeye": {"name": "Deadeye", "desc": "+4% crit chance", "stat": "crit_chance", "per_rank": 0.04, "max": 5},
	"second_wind": {"name": "Second Wind", "desc": "+1.5 health regen per second", "stat": "regen", "per_rank": 1.5, "max": 3},
	"plating": {"name": "Plating", "desc": "+4% armour", "stat": "armor", "per_rank": 0.04, "max": 3},
	"quick_study": {"name": "Quick Study", "desc": "+10% XP gained", "stat": "xp", "per_rank": 0.1, "max": 3},
}
