class_name BuildingsPanel
extends PanelContainer

var _rows := {}  # id -> { "name": Label, "owned": Label, "effect": Label, "cost": Label, "button": Button }
var _power_warned := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 14)
	scroll.add_child(margin)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	margin.add_child(list)

	for b in BuildingsDB.get_list():
		list.add_child(_build_row(b))

	Events.tick.connect(_on_tick)
	Events.building_purchased.connect(_on_building_purchased)
	Events.research_completed.connect(_on_research_completed)

	_refresh()

func _build_row(b: Dictionary) -> Control:
	var row := VBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var sep := HSeparator.new()
	row.add_child(sep)

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(header)

	var name_label := Label.new()
	name_label.text = b["name"]
	name_label.add_theme_color_override("font_color", Palette.AMBER)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(name_label)

	var owned_label := Label.new()
	owned_label.text = "×%d" % Buildings.count(b["id"])
	header.add_child(owned_label)

	var effect_label := Label.new()
	effect_label.add_theme_color_override("font_color", Palette.TEXT_2)
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(effect_label)

	var footer := HBoxContainer.new()
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(footer)

	var cost_label := Label.new()
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(cost_label)

	var buy_button := Button.new()
	buy_button.text = "Установить"
	buy_button.pressed.connect(_on_buy_pressed.bind(b["id"]))
	footer.add_child(buy_button)

	_rows[b["id"]] = {
		"name": name_label,
		"owned": owned_label,
		"effect": effect_label,
		"cost": cost_label,
		"button": buy_button,
	}
	return row

func _effect_text(b: Dictionary) -> String:
	var parts := PackedStringArray()
	for res_id in b.get("produces", {}).keys():
		parts.append("+%s %s/сек" % [Format.num(b["produces"][res_id]), _res_name(res_id)])
	for res_id in b.get("consumes", {}).keys():
		parts.append("-%s %s/сек" % [Format.num(b["consumes"][res_id]), _res_name(res_id)])
	return " · ".join(parts)

func _cost_text(id: String) -> String:
	var c := Buildings.cost(id)
	var parts := PackedStringArray()
	for res_id in c.keys():
		parts.append("%s %s" % [Format.num(c[res_id]), _res_short(res_id)])
	return " · ".join(parts)

func _res_name(res_id: String) -> String:
	var defs := ResourcesDB.get_defs()
	if defs.has(res_id):
		return String(defs[res_id]["name"]).to_lower()
	if res_id == "compute":
		return "вычислений"
	var cdef := CryptoDB.get_def(res_id)
	if not cdef.is_empty():
		return String(cdef["name"]).to_lower()
	return res_id

func _res_short(res_id: String) -> String:
	var defs := ResourcesDB.get_defs()
	if defs.has(res_id):
		return String(defs[res_id]["short"])
	if res_id == "compute":
		return "ВЫЧ"
	var cdef := CryptoDB.get_def(res_id)
	if not cdef.is_empty():
		return String(cdef["short"])
	return res_id

func _research_name(id: String) -> String:
	return String(Research.get_def(id).get("name", id))

func _on_buy_pressed(id: String) -> void:
	if not Buildings.buy(id):
		return
	var bname := String(Buildings.get_def(id)["name"])
	Events.log_message.emit("> УСТАНОВЛЕН МОДУЛЬ: %s" % bname, "sys")
	_refresh()

func _on_building_purchased(_id: String, _count: int) -> void:
	_refresh()

func _on_research_completed(_id: String) -> void:
	_refresh()

func _on_tick(_delta: float) -> void:
	_refresh()
	if GameState.power_ratio < 1.0 and not _power_warned:
		_power_warned = true
		Events.log_message.emit("> ВНИМАНИЕ: ДЕФИЦИТ ЭНЕРГИИ — ПРОИЗВОДСТВО СНИЖЕНО", "alert")
	elif GameState.power_ratio >= 1.0:
		_power_warned = false

func _refresh() -> void:
	for id in _rows.keys():
		var row: Dictionary = _rows[id]
		var def := Buildings.get_def(id)
		row["owned"].text = "×%d" % Buildings.count(id)

		if Buildings.is_unlocked(id):
			row["name"].modulate.a = 1.0
			row["effect"].text = _effect_text(def)
			row["effect"].add_theme_color_override("font_color", Palette.TEXT_2)
			row["cost"].visible = true
			row["cost"].text = _cost_text(id)
			var affordable := Buildings.can_afford(id)
			row["button"].visible = true
			row["button"].disabled = not affordable
			row["button"].modulate.a = 1.0 if affordable else 0.5
		else:
			row["name"].modulate.a = 0.5
			row["effect"].text = "🔒 Требуется исследование: %s" % _research_name(String(def.get("requires_research", "")))
			row["effect"].add_theme_color_override("font_color", Palette.TEXT_3)
			row["cost"].visible = false
			row["button"].visible = false
