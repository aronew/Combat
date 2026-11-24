class_name SaveData
## Tiny persistent profile (user://combat_save.cfg). Salvage is only banked here
## when you extract; dying loses everything you were carrying.

const PATH := "user://combat_save.cfg"


static func load_profile() -> Dictionary:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	return {
		"banked_salvage": cfg.get_value("profile", "banked_salvage", 0),
		"dives": cfg.get_value("profile", "dives", 0),
		"extractions": cfg.get_value("profile", "extractions", 0),
		"best_haul": cfg.get_value("profile", "best_haul", 0),
	}


static func save_profile(p: Dictionary) -> void:
	var cfg := ConfigFile.new()
	for k in p:
		cfg.set_value("profile", k, p[k])
	cfg.save(PATH)
