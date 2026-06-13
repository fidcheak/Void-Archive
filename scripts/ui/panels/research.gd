class_name ResearchPanel
extends PanelContainer

var _rows := {}  # id -> { "container": Control, "status": Label, "button": Button }

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

	for branch in ResearchDB.get_branches():
		var header := Label.new()
		header.text = branch["name"].to_upper()
		header.add_theme_color_override("font_color", Palette.AMBER)
		list.add_child(header)
		list.add_child(_thin_separator())

		var nodes := []
		for r in ResearchDB.get_list():
			if r["branch"] == branch["id"]:
				nodes.append(r)

		if nodes.is_empty():
			if branch.get("locked", false):
				var stub := Label.new()
				stub.text = "[ДАННЫЕ ПОВРЕЖДЕНЫ]"
				stub.add_theme_color_override("font_color", Palette.TEXT_3)
				list.add_child(stub)
		else:
			for i in range(nodes.size()):
				list.add_child(_build_row(nodes[i]))
				if i < nodes.size() - 1:
					list.add_child(_thin_separator())

		list.add_child(HSeparator.new())

	Events.tick.connect(_on_tick)
	Events.research_completed.connect(_on_research_completed)
	Events.resource_changed.connect(_on_resource_changed)

	_refresh()

func _thin_separator() -> HSeparator:
	return HSeparator.new()

func _build_row(r: Dictionary) -> Control:
	var row := VBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(header)

	var name_label := Label.new()
	name_label.text = r["name"]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(name_label)

	var status_label := Label.new()
	header.add_child(status_label)

	var desc_label := Label.new()
	desc_label.text = r["desc"]
	desc_label.add_theme_color_override("font_color", Palette.TEXT_2)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(desc_label)

	var footer := HBoxContainer.new()
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(footer)

	var cost_label := Label.new()
	cost_label.text = _cost_text(r)
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cost_label.add_theme_color_override("font_color", Palette.COMPUTE)
	cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(cost_label)

	var button := Button.new()
	button.text = "Изучить"
	button.pressed.connect(_on_research_pressed.bind(r["id"]))
	footer.add_child(button)

	_rows[r["id"]] = {
		"name_label": name_label,
		"desc_label": desc_label,
		"status_label": status_label,
		"cost_label": cost_label,
		"button": button,
	}
	return row

func _cost_text(r: Dictionary) -> String:
	var parts := PackedStringArray()
	for res_id in r.get("cost", {}).keys():
		parts.append("%s %s" % [Format.num(r["cost"][res_id]), _res_short(res_id)])
	return " ".join(parts)

func _res_short(res_id: String) -> String:
	var defs := ResourcesDB.get_defs()
	if defs.has(res_id):
		return String(defs[res_id]["short"])
	return res_id

func _requires_text(r: Dictionary) -> String:
	var names := PackedStringArray()
	for p in r.get("requires", []):
		names.append(String(Research.get_def(p).get("name", p)))
	return "🔒 требуется: %s" % ", ".join(names)

func _on_research_pressed(id: String) -> void:
	if not Research.research(id):
		return
	var rname := String(Research.get_def(id)["name"])
	Events.log_message.emit("> ТЕХНОЛОГИЯ ВНЕДРЕНА: %s" % rname, "sys")
	_refresh()

func _on_research_completed(_id: String) -> void:
	_refresh()

func _on_resource_changed(_id: String, _value: float) -> void:
	_refresh()

func _on_tick(_delta: float) -> void:
	_refresh()

func _refresh() -> void:
	for id in _rows.keys():
		var row: Dictionary = _rows[id]
		var def := Research.get_def(id)
		if Research.is_owned(id):
			row["status_label"].text = "✓ ИЗУЧЕНО"
			row["status_label"].add_theme_color_override("font_color", Palette.OK)
			row["name_label"].add_theme_color_override("font_color", Palette.TEXT_2)
			row["desc_label"].text = def["desc"]
			row["cost_label"].visible = false
			row["button"].visible = false
		elif Research.is_available(id):
			row["status_label"].text = ""
			row["name_label"].add_theme_color_override("font_color", Palette.AMBER)
			row["desc_label"].text = def["desc"]
			row["desc_label"].add_theme_color_override("font_color", Palette.TEXT_2)
			row["cost_label"].visible = true
			row["button"].visible = true
			row["button"].disabled = not Research.can_afford(id)
			row["button"].modulate.a = 1.0 if Research.can_afford(id) else 0.5
		else:
			row["status_label"].text = ""
			row["name_label"].add_theme_color_override("font_color", Palette.TEXT_3)
			row["desc_label"].text = _requires_text(def)
			row["desc_label"].add_theme_color_override("font_color", Palette.TEXT_3)
			row["cost_label"].visible = false
			row["button"].visible = false
