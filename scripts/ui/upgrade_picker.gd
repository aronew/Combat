class_name UpgradePicker
extends CanvasLayer
## Three run-upgrade cards after a cleared fight (RunUpgrades). The game pauses while you
## choose: click a card, press 1-3, or move between them with the d-pad / stick and confirm.
## The autoplay bot takes the first card after a moment.

signal picked(id: String)

var _ids: Array[String] = []
var _cards: Array[Button] = []
var _open := false


static func offer(parent: Node, ids: Array[String]) -> UpgradePicker:
	var p := UpgradePicker.new()
	parent.add_child(p)
	p._show(ids)
	return p


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30


func _show(ids: Array[String]) -> void:
	_ids = ids
	if ids.is_empty():
		queue_free()
		return
	Audio.play(&"card_reveal")
	_open = true
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.02, 0.03, 0.68)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	center.add_child(col)
	col.add_child(_label("CHOOSE AN UPGRADE", 34, Color("f2f6f8"), true))
	col.add_child(_label("IT LASTS FOR THIS OPERATION  ·  [1] [2] [3]", 15, Color(1, 1, 1, 0.55), true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)
	for i in ids.size():
		var card := _card(ids[i], i)
		row.add_child(card)
		_cards.append(card)
		card.modulate.a = 0.0
		var t := card.create_tween().set_ignore_time_scale(true)
		t.tween_interval(0.08 * i)
		t.tween_property(card, "modulate:a", 1.0, 0.18)
	_cards[0].grab_focus()
	get_tree().paused = true
	if Game.player and Game.player.autopilot:
		var delay := 0.5
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--pick-delay="):
				delay = arg.get_slice("=", 1).to_float()
		get_tree().create_timer(delay, true, false, true).timeout.connect(_choose.bind(0))


func _card(id: String, i: int) -> Button:
	var u: Dictionary = RunUpgrades.LIST[id]
	var c := RunUpgrades.color(id)
	var b := Button.new()
	b.custom_minimum_size = Vector2(300, 240)
	b.focus_mode = Control.FOCUS_ALL
	for state in ["normal", "hover", "focus", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.06, 0.08, 0.96) if state == "normal" else Color(0.07, 0.1, 0.13, 0.98)
		sb.border_color = c if state != "normal" else Color(c.r, c.g, c.b, 0.55)
		sb.set_border_width_all(4 if state != "normal" else 2)
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 18
		sb.content_margin_right = 18
		sb.content_margin_top = 16
		sb.content_margin_bottom = 16
		b.add_theme_stylebox_override(state, sb)
	b.pressed.connect(_choose.bind(i))
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 18
	v.offset_right = -18
	v.offset_top = 16
	v.offset_bottom = -16
	v.add_theme_constant_override("separation", 8)
	b.add_child(v)
	v.add_child(_label(RunUpgrades.kind_label(id) + "  ·  " + String(u.tag), 13, c))
	v.add_child(_label(String(u.name).to_upper(), 25, Color("f2f6f8")))
	var desc := _label(String(u.desc), 17, Color(1, 1, 1, 0.82))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc)
	var owned := int(Game.player.run_upgrades.get(id, 0)) if Game.player else 0
	v.add_child(_label(("[%d]" % (i + 1)) + ("   OWNED x%d" % owned if owned > 0 else ""), 14, Color(1, 1, 1, 0.45)))
	return b


func _label(text: String, size: int, color: Color, centered := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if centered:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = (event as InputEventKey).keycode
		if k >= KEY_1 and k < KEY_1 + _ids.size():
			_choose(k - KEY_1)
			get_viewport().set_input_as_handled()


func _choose(i: int) -> void:
	if not _open or i < 0 or i >= _ids.size():
		return
	_open = false
	var id := _ids[i]
	get_tree().paused = false
	Audio.play(&"card_pick")
	if Game.player:
		RunUpgrades.apply(id, Game.player)
		if Game.fx:
			Game.fx.text_popup(Game.player.global_position + Vector3.UP * 2.6, String(RunUpgrades.LIST[id].name).to_upper(), RunUpgrades.color(id), 1.1)
	picked.emit(id)
	queue_free()
