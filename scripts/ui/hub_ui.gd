class_name HubUI
extends CanvasLayer
## The Rig's interface: a small HUD (level, XP, salvage, perk points, prompts)
## and four station panels, built in code with one shared theme:
##   ARMORY      equipped gear, stash, compare, equip / unequip / scrap
##   FABRICATOR  spend salvage on crates
##   AUGMENTS    spend perk points
##   CONTRACTS   pick a depth and deploy

@export var number_font_names := PackedStringArray(["Rajdhani", "Exo 2", "Barlow", "Inter", "Arial", "sans-serif"])
@export var title_font_names := PackedStringArray(["Orbitron", "Exo 2", "Rajdhani", "Inter Display", "Arial Black", "sans-serif"])

const ACCENT := Color("19f4ff")
const DIM := Color(1, 1, 1, 0.6)
const GOOD := Color("3dff9a")
const BAD := Color("ff4b6b")
const LOWER_IS_BETTER := ["roll_cd", "noise", "spread"]

var open_panel := ""
var selected := {}  ## {"source": "stash"/"equipped", "item": {...}}
var stash_filter := "all"
var depth_choice := 1
var last_crate := {}

var _theme: Theme
var _font: Font
var _font_bold: Font
var _font_title: Font
var _root: Control
var _panel: PanelContainer
var _hud_level: Label
var _hud_xp_fill: ColorRect
var _hud_salvage: Label
var _hud_perks: Label
var _prompt: Label
var _banner: Label
var _crosshair: Crosshair
var _t := 0.0


func _ready() -> void:
	Game.hud = self
	_build_theme()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _theme
	add_child(_root)
	_build_hud()
	Profile.changed.connect(_refresh_hud)
	_refresh_hud()
	depth_choice = Profile.data.max_depth
	_connect_stations.call_deferred()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	if not Profile.last_result.is_empty():
		_show_last_result(Profile.last_result)
		Profile.last_result = {}


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _connect_stations() -> void:
	var hub := get_parent().get_node_or_null("HubLevel") as HubLevel
	if hub == null:
		return
	for id in hub.stations:
		var station: Interactable = hub.stations[id]
		station.used.connect(func(_by): open(id))


func _process(delta: float) -> void:
	_t += delta
	var p := Game.player
	var it: Interactable = p.current_interactable if p else null
	_prompt.text = ("[E]  " + it.get_prompt().to_upper()) if it and it.enabled and open_panel == "" else ""
	if Profile.data.perk_points > 0:
		_hud_perks.modulate.a = 0.65 + 0.35 * sin(_t * 4.0)


func _unhandled_input(event: InputEvent) -> void:
	if open_panel == "":
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		close()
		get_viewport().set_input_as_handled()


# ==========================================================================
# Panels
# ==========================================================================

func open(kind: String) -> void:
	close()
	open_panel = kind
	if Game.player:
		Game.player.input_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_crosshair.visible = false
	match kind:
		"armory":
			_build_armory()
		"fabricator":
			_build_fabricator()
		"augments":
			_build_augments()
		"contracts":
			_build_contracts()


func close() -> void:
	if _panel:
		_panel.queue_free()
		_panel = null
	if open_panel != "" and Game.player:
		Game.player.input_locked = false
	open_panel = ""
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	if _crosshair:
		_crosshair.visible = true


func _rebuild_open() -> void:
	var kind := open_panel
	if kind == "":
		return
	if _panel:
		_panel.queue_free()
		_panel = null
	open_panel = kind
	match kind:
		"armory":
			_build_armory()
		"fabricator":
			_build_fabricator()
		"augments":
			_build_augments()
		"contracts":
			_build_contracts()


## Centered panel with a title row; returns the content container.
func _make_panel(title: String, size: Vector2) -> VBoxContainer:
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _box(Color(0.02, 0.06, 0.07, 0.95), Color(ACCENT, 0.7), 2, 22))
	_panel.custom_minimum_size = size
	_root.add_child(_panel)
	# Centre by anchors + symmetric offsets; grow both ways if content is larger.
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -size.x * 0.5
	_panel.offset_right = size.x * 0.5
	_panel.offset_top = -size.y * 0.5
	_panel.offset_bottom = size.y * 0.5
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_panel.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	head.add_child(_lbl(title, 34, ACCENT, _font_title))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	head.add_child(_lbl("◆ %d SALVAGE" % Profile.data.salvage, 20, Palette.NEON_YELLOW, _font_bold))
	head.add_child(_btn("CLOSE  [E]", close))
	return v


# ---------------- ARMORY ----------------

func _build_armory() -> void:
	var v := _make_panel("ARMORY", Vector2(1400, 760))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(cols)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(360, 0)
	cols.add_child(left)
	left.add_child(_lbl("EQUIPPED", 18, DIM, _font_bold))
	for slot in Loot.SLOTS:
		var item := Profile.equipped(slot)
		var text := "%s   %s" % [Loot.SLOT_NAMES[slot].to_upper(), item.name if not item.is_empty() else "—  empty  —"]
		var b := _btn(text, _on_pick_equipped.bind(slot))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_color_override("font_color", Loot.color(item) if not item.is_empty() else DIM)
		left.add_child(b)
	left.add_child(_lbl("Lv %d  ·  %d perk points" % [Profile.data.level, Profile.data.perk_points], 16, DIM, _font))

	var mid := VBoxContainer.new()
	mid.custom_minimum_size = Vector2(440, 0)
	cols.add_child(mid)
	mid.add_child(_lbl("STASH  (%d)" % Profile.data.stash.size(), 18, DIM, _font_bold))
	var filters := HBoxContainer.new()
	mid.add_child(filters)
	for f in [["all", "ALL"], ["gun", "GUNS"], ["blade", "BLADES"], ["armour", "ARMOUR"], ["implant", "IMPLANTS"]]:
		var fb := _btn(f[1], _on_filter.bind(f[0]))
		if stash_filter == f[0]:
			fb.add_theme_color_override("font_color", ACCENT)
		filters.add_child(fb)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mid.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var items: Array = Profile.data.stash.duplicate()
	items.sort_custom(func(a, b): return a.rarity > b.rarity if a.rarity != b.rarity else a.level > b.level)
	var shown := 0
	for it in items:
		if not _passes_filter(it):
			continue
		shown += 1
		var b := _btn("%s   ·   Lv %d %s" % [it.name, int(it.level), Loot.kind_label(it)], _select.bind("stash", it, it.slot))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_color_override("font_color", Loot.color(it))
		if not selected.is_empty() and selected.item.get("id", "") == it.id:
			b.add_theme_stylebox_override("normal", _box(Color(0.08, 0.2, 0.23, 0.95), Color(ACCENT, 0.9), 1, 8))
		list.add_child(b)
	if shown == 0:
		list.add_child(_lbl("Nothing here yet. Extract with loot, or buy crates at the Fabricator.", 16, DIM, _font))

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(500, 0)
	right.add_theme_constant_override("separation", 6)
	cols.add_child(right)
	_build_details(right)


func _passes_filter(it: Dictionary) -> bool:
	match stash_filter:
		"all":
			return true
		"armour":
			return it.slot in ["helmet", "chest", "boots"]
	return it.slot == stash_filter


func _select(source: String, item: Dictionary, slot: String) -> void:
	selected = {"source": source, "item": item, "slot": slot}
	_rebuild_open()


func _build_details(box: VBoxContainer) -> void:
	if selected.is_empty() or selected.item.is_empty():
		box.add_child(_lbl("Select an item to inspect it.", 18, DIM, _font))
		return
	var item: Dictionary = selected.item
	var s := Profile.stats()
	box.add_child(_lbl(item.name, 30, Loot.color(item), _font_title))
	for line in Loot.describe(item, s):
		var l := _lbl(line[0], 18, line[1], _font_bold)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(l)
	if selected.source == "stash":
		var cur := Profile.equipped(item.slot)
		box.add_child(_lbl("VS EQUIPPED" + ("  (%s)" % cur.name if not cur.is_empty() else "  (empty slot)"), 16, DIM, _font_bold))
		for line in _compare(item, cur, s):
			box.add_child(_lbl(line[0], 18, line[1], _font_bold))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)
	if selected.source == "stash":
		buttons.add_child(_btn("EQUIP", _on_equip.bind(item), Vector2(160, 46)))
		buttons.add_child(_btn("SCRAP  +%d ◆" % Loot.scrap_value(item), _on_scrap.bind(item.id), Vector2(200, 46)))
	elif not item.slot in ["gun", "blade"]:
		buttons.add_child(_btn("UNEQUIP", _on_unequip.bind(item.slot), Vector2(160, 46)))


## Comparison lines vs. the currently equipped item: [text, colour].
func _compare(item: Dictionary, cur: Dictionary, s: Dictionary) -> Array:
	var out: Array = []
	if item.slot == "gun" or item.slot == "blade":
		var a := Loot.gun_dps(item, s) if item.slot == "gun" else Loot.blade_dps(item, s)
		var b := 0.0
		if not cur.is_empty():
			b = Loot.gun_dps(cur, s) if item.slot == "gun" else Loot.blade_dps(cur, s)
		var pct := (a / b - 1.0) * 100.0 if b > 0.0 else 100.0
		out.append(["DPS  %d  →  %d   (%s%d%%)" % [roundi(b), roundi(a), "+" if pct >= 0 else "", roundi(pct)], GOOD if pct >= 0 else BAD])
	var ta := _totals(item)
	var tb := _totals(cur)
	var keys := ta.keys()
	for k in tb.keys():
		if not k in keys:
			keys.append(k)
	for k in keys:
		var d: float = float(ta.get(k, 0.0)) - float(tb.get(k, 0.0))
		if absf(d) < 0.0005:
			continue
		var better := d < 0.0 if k in LOWER_IS_BETTER else d > 0.0
		out.append([Loot.format_stat(k, d), GOOD if better else BAD])
	if item.get("legendary", "") != "" and item.legendary != cur.get("legendary", ""):
		out.append(["+ " + Loot.LEGENDARIES[item.legendary].name + " effect", Loot.RARITY_COLORS[3]])
	return out


func _totals(item: Dictionary) -> Dictionary:
	var t := {}
	if item.is_empty():
		return t
	for stat in Loot.ARMOR_BASE.get(item.slot, {}):
		t[stat] = Loot.armor_base_value(item, stat)
	for a in item.get("affixes", []):
		t[a.stat] = float(t.get(a.stat, 0.0)) + float(a.value)
	return t


# ---------------- FABRICATOR ----------------

func _build_fabricator() -> void:
	var v := _make_panel("FABRICATOR", Vector2(1100, 640))
	v.add_child(_lbl("Spend salvage on sealed gear crates. Item level follows your deepest unlocked depth.", 18, DIM, _font))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	for id in Profile.CRATES:
		var c: Dictionary = Profile.CRATES[id]
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _box(Color(0.04, 0.1, 0.12, 0.95), Color(ACCENT, 0.35), 1, 14))
		card.custom_minimum_size = Vector2(330, 0)
		row.add_child(card)
		var cv := VBoxContainer.new()
		card.add_child(cv)
		cv.add_child(_lbl(c.name.to_upper(), 24, Palette.HUD_WHITE, _font_title))
		var d := _lbl(c.desc, 16, DIM, _font)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(d)
		cv.add_child(_lbl(_odds_text(c.weights), 15, Color("9ff8ff"), _font))
		var buy := _btn("BUY  ·  %d ◆" % c.cost, _on_buy.bind(id), Vector2(0, 46))
		buy.disabled = Profile.data.salvage < c.cost
		cv.add_child(buy)
	if not last_crate.is_empty():
		v.add_child(_lbl("FABRICATED:", 16, DIM, _font_bold))
		v.add_child(_lbl(last_crate.name, 28, Loot.color(last_crate), _font_title))
		for line in Loot.describe(last_crate, Profile.stats()):
			v.add_child(_lbl(line[0], 17, line[1], _font_bold))
		var crate_id: String = last_crate.id
		if Profile.find_in_stash(crate_id) >= 0:
			v.add_child(_btn("EQUIP NOW", _on_crate_equip.bind(crate_id), Vector2(200, 44)))


func _odds_text(w: Array) -> String:
	var total := 0.0
	for x in w:
		total += x
	var parts: PackedStringArray = []
	for i in w.size():
		if w[i] > 0.0:
			parts.append("%s %d%%" % [Loot.RARITY_NAMES[i], roundi(w[i] / total * 100.0)])
	return "  ·  ".join(parts)


# ---------------- AUGMENTS ----------------

func _build_augments() -> void:
	var v := _make_panel("AUGMENTS", Vector2(1240, 700))
	var pts: int = Profile.data.perk_points
	v.add_child(_lbl("PERK POINTS:  %d     (one per level, Lv %d)" % [pts, Profile.data.level], 22, Palette.NEON_YELLOW if pts > 0 else DIM, _font_bold))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	v.add_child(grid)
	for id in Perks.LIST:
		var perk: Dictionary = Perks.LIST[id]
		var rank: int = Profile.data.perks.get(id, 0)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _box(Color(0.04, 0.1, 0.12, 0.95), Color(ACCENT, 0.25 + 0.15 * rank), 1, 12))
		card.custom_minimum_size = Vector2(390, 0)
		grid.add_child(card)
		var cv := HBoxContainer.new()
		card.add_child(cv)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cv.add_child(info)
		info.add_child(_lbl(perk.name.to_upper(), 19, Palette.HUD_WHITE if rank > 0 else Color(1, 1, 1, 0.85), _font_bold))
		info.add_child(_lbl("%s per rank   ·   %s" % [perk.desc, "◆".repeat(rank) + "◇".repeat(perk.max - rank)], 15, Color("9ff8ff"), _font))
		var up := _btn("+", _on_perk.bind(id), Vector2(56, 48))
		up.disabled = pts <= 0 or rank >= perk.max
		cv.add_child(up)


# ---------------- CONTRACTS ----------------

func _build_contracts() -> void:
	var v := _make_panel("CONTRACTS", Vector2(1000, 640))
	v.add_child(_lbl("OPERATION: FIRST DIVE", 26, Palette.HUD_WHITE, _font_title))
	var brief := _lbl("Deepworks Sector 1. Drop to the reactor ring, run the uplink, hold until it finishes, and get back to the lift. Gear and salvage come home only if you do.", 18, DIM, _font)
	brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(brief)
	v.add_child(_lbl("DEPTH", 18, DIM, _font_bold))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	for d in range(1, Profile.MAX_DEPTH + 1):
		var unlocked: bool = d <= Profile.data.max_depth
		var b := _btn(str(d) if unlocked else "LOCKED %d" % d, _on_depth.bind(d), Vector2(80 if unlocked else 130, 56))
		b.disabled = not unlocked
		if d == depth_choice:
			b.add_theme_stylebox_override("normal", _box(Color(0.06, 0.25, 0.28, 0.95), ACCENT, 2, 8))
		row.add_child(b)
	var d := depth_choice
	var mods := "Bugs  +%d%% health, +%d%% damage   ·   Alarm waves +%d%%   ·   Elite odds x%.1f\nGear found: item level %d, better rarity odds   ·   XP +%d%%" % [
		roundi(35 * (d - 1)), roundi(18 * (d - 1)), roundi(15 * (d - 1)), 1.0 + 0.5 * (d - 1), Profile.item_level_for_depth(d), roundi(25 * (d - 1))]
	var ml := _lbl(mods, 18, Color("9ff8ff"), _font_bold)
	ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(ml)
	v.add_child(_lbl("Record: %d dives  ·  %d extractions  ·  best haul %d" % [Profile.data.dives, Profile.data.extractions, Profile.data.best_haul], 16, DIM, _font))
	v.add_child(_btn("DEPLOY TO DEPTH %d" % d, deploy.bind(d), Vector2(0, 64)))


# ---------------- button handlers ----------------

func _on_pick_equipped(slot: String) -> void:
	_select("equipped", Profile.equipped(slot), slot)


func _on_filter(f: String) -> void:
	stash_filter = f
	_rebuild_open()


func _on_equip(item: Dictionary) -> void:
	Profile.equip(item.id)
	selected = {"source": "equipped", "item": item, "slot": item.slot}
	_rebuild_open()


func _on_scrap(id: String) -> void:
	Profile.scrap(id)
	selected = {}
	_rebuild_open()


func _on_unequip(slot: String) -> void:
	Profile.unequip(slot)
	selected = {}
	_rebuild_open()


func _on_buy(id: String) -> void:
	last_crate = Profile.buy_crate(id)
	_rebuild_open()


func _on_crate_equip(id: String) -> void:
	Profile.equip(id)
	last_crate = {}
	_rebuild_open()


func _on_perk(id: String) -> void:
	Profile.upgrade_perk(id)
	_rebuild_open()


func _on_depth(d: int) -> void:
	depth_choice = d
	_rebuild_open()


func deploy(depth: int) -> void:
	Profile.start_dive(depth)
	close()
	Game.go_to_scene("res://scenes/dive.tscn")


# ==========================================================================
# HUD
# ==========================================================================

func _build_hud() -> void:
	var tl := VBoxContainer.new()
	tl.position = Vector2(48, 26)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(tl)
	tl.add_child(_lbl("THE RIG  ·  DEEPWORKS SHAFT", 15, ACCENT, _font_bold))
	_hud_level = _lbl("LV 1", 26, Palette.NEON_YELLOW, _font_title)
	tl.add_child(_hud_level)
	var track := ColorRect.new()
	track.custom_minimum_size = Vector2(320, 5)
	track.color = Color(1, 1, 1, 0.12)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.add_child(track)
	_hud_xp_fill = ColorRect.new()
	_hud_xp_fill.color = Palette.NEON_YELLOW
	_hud_xp_fill.size = Vector2(0, 5)
	_hud_xp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(_hud_xp_fill)
	_hud_salvage = _lbl("◆ SALVAGE 0", 22, Palette.NEON_YELLOW, _font_bold)
	tl.add_child(_hud_salvage)
	_hud_perks = _lbl("", 18, Palette.HUD_WHITE, _font_bold)
	tl.add_child(_hud_perks)

	var hint := _lbl("[E] use station   ·   [Q] swap weapon   ·   test your gear on the range", 15, DIM, _font)
	hint.position = Vector2(48, 0)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.position = Vector2(48, -60)
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	_root.add_child(hint)

	_prompt = _lbl("", 24, Palette.HUD_WHITE, _font_bold)
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.offset_left = -400
	_prompt.offset_right = 400
	_prompt.offset_top = -170
	_prompt.offset_bottom = -130
	_root.add_child(_prompt)

	_banner = _lbl("", 30, Palette.HUD_WHITE, _font_title)
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.offset_left = -700
	_banner.offset_right = 700
	_banner.offset_top = 30
	_banner.offset_bottom = 120
	_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(_banner)

	_crosshair = Crosshair.new()
	_crosshair.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_crosshair)


func _refresh_hud() -> void:
	if _hud_level == null:
		return
	_hud_level.text = "LV %d" % Profile.data.level
	_hud_xp_fill.size = Vector2(320.0 * Profile.xp_progress(), 5)
	_hud_salvage.text = "◆ SALVAGE %d" % Profile.data.salvage
	var pts: int = Profile.data.perk_points
	_hud_perks.text = ("%d PERK POINT%s READY  ·  VISIT AUGMENTS" % [pts, "" if pts == 1 else "S"]) if pts > 0 else ""


func _show_last_result(r: Dictionary) -> void:
	var lines := "EXTRACTED  ·  +%d SALVAGE  ·  %d ITEMS BANKED" % [r.haul, r.items.size()] if r.success else "SIGNAL LOST  ·  %d SALVAGE AND %d ITEMS LOST" % [r.haul, r.items.size()]
	if int(r.get("levels", 0)) > 0:
		lines += "\nLEVEL UP!  NOW LEVEL %d" % Profile.data.level
	if int(r.get("unlocked", 0)) > 0:
		lines += "\nDEPTH %d UNLOCKED" % int(r.unlocked)
	_banner.text = lines
	_banner.add_theme_color_override("font_color", Palette.NEON_CYAN if r.success else Palette.NEON_MAGENTA)
	var t := create_tween()
	t.tween_interval(6.0)
	t.tween_property(_banner, "modulate:a", 0.0, 1.0)


# ==========================================================================
# Theme helpers
# ==========================================================================

func _sys(names: PackedStringArray, weight: int, italic: bool) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = names
	f.font_weight = weight
	f.font_italic = italic
	return f


func _box(bg: Color, border: Color, border_w: int, margin: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(margin)
	return sb


func _build_theme() -> void:
	_font = _sys(number_font_names, 500, false)
	_font_bold = _sys(number_font_names, 700, true)
	_font_title = _sys(title_font_names, 900, true)
	_theme = Theme.new()
	_theme.default_font = _font_bold
	_theme.default_font_size = 18
	_theme.set_stylebox("normal", "Button", _box(Color(0.04, 0.1, 0.12, 0.95), Color(ACCENT, 0.35), 1, 8))
	_theme.set_stylebox("hover", "Button", _box(Color(0.07, 0.18, 0.21, 0.98), Color(ACCENT, 0.8), 1, 8))
	_theme.set_stylebox("pressed", "Button", _box(Color(0.05, 0.3, 0.34, 1.0), ACCENT, 1, 8))
	_theme.set_stylebox("disabled", "Button", _box(Color(0.03, 0.05, 0.06, 0.9), Color(1, 1, 1, 0.1), 1, 8))
	_theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	_theme.set_color("font_color", "Button", Palette.HUD_WHITE)
	_theme.set_color("font_hover_color", "Button", ACCENT)
	_theme.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.3))


func _lbl(text: String, size: int, color: Color, font: Font) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.03, 0.9))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _btn(text: String, callback: Callable, min_size := Vector2.ZERO) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.pressed.connect(callback)
	return b
