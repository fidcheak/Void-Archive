class_name BuildingsPanel
extends TabContainer

var _rows := {}  # id -> { "name": Label, "effect": Label, "cost": Label, "button": Button }
var _power_warned := false
var _acc := 0.0

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var categories := PackedStringArray()
	var by_category := {}
	for b in BuildingsDB.get_list():
		var cat := String(b.get("category", "Прочее"))
		if not by_category.has(cat):
			by_category[cat] = []
			categories.append(cat)
		by_category[cat].append(b)

	var tier_colors := _build_tier_colors(by_category)

	for cat in categories:
		add_child(_build_tab(cat, by_category[cat], tier_colors))

	Events.tick.connect(_on_tick)
	Events.building_purchased.connect(_on_building_purchased)
	Events.research_completed.connect(_on_research_completed)
	Events.resource_changed.connect(_on_resource_changed)

	_refresh()

func _base_cost(b: Dictionary) -> float:
	var total := 0.0
	for v in b.get("cost", {}).values():
		total += float(v)
	return total

func _tier_color(t: float) -> Color:
	if t <= 0.5:
		return Palette.TEXT_DIM.lerp(Palette.RARITY_RARE, t * 2.0)
	return Palette.RARITY_RARE.lerp(Palette.RARITY_LEGENDARY, (t - 0.5) * 2.0)

func _build_tier_colors(by_category: Dictionary) -> Dictionary:
	var tier_colors := {}
	for cat in by_category.keys():
		var items: Array = (by_category[cat] as Array).duplicate()
		items.sort_custom(func(a, b): return _base_cost(a) < _base_cost(b))
		var n := items.size()
		for i in range(n):
			var t := 0.0 if n <= 1 else float(i) / float(n - 1)
			tier_colors[items[i]["id"]] = _tier_color(t)
	return tier_colors

func _build_tab(cat: String, items: Array, tier_colors: Dictionary) -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = cat
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 8)
	scroll.add_child(margin)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	margin.add_child(list)

	for b in items:
		list.add_child(_build_row(b, tier_colors.get(b["id"], Palette.TEXT_DIM)))

	return scroll

func _build_row(b: Dictionary, tier_color: Color) -> Control:
	var outer := HBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 8)

	var accent := ColorRect.new()
	accent.color = tier_color
	accent.custom_minimum_size = Vector2(3, 0)
	outer.add_child(accent)

	var row := VBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(row)

	var sep := HSeparator.new()
	row.add_child(sep)

	var name_label := Label.new()
	name_label.text = b["name"]
	name_label.add_theme_color_override("font_color", tier_color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(name_label)

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
		"effect": effect_label,
		"cost": cost_label,
		"button": buy_button,
		"accent": accent,
	}
	return outer

func _effect_text(b: Dictionary) -> String:
	var parts := PackedStringArray()
	for res_id in b.get("produces", {}).keys():
		parts.append("+%s %s/сек" % [Format.num(b["produces"][res_id]), Labels.res_name(res_id).to_lower()])
	for res_id in b.get("consumes", {}).keys():
		parts.append("-%s %s/сек" % [Format.num(b["consumes"][res_id]), Labels.res_name(res_id).to_lower()])
	return " · ".join(parts)

func _cost_text(id: String) -> String:
	var c := Buildings.cost(id)
	var parts := PackedStringArray()
	for res_id in c.keys():
		parts.append("%s %s" % [Format.num(c[res_id]), Labels.res_short(res_id)])
	return " · ".join(parts)

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

func _on_resource_changed(_id: String, _value: float) -> void:
	_refresh()

func _on_tick(delta: float) -> void:
	if GameState.power_ratio < 1.0 and not _power_warned:
		_power_warned = true
		Events.log_message.emit("> ВНИМАНИЕ: ДЕФИЦИТ ЭНЕРГИИ — ПРОИЗВОДСТВО СНИЖЕНО", "alert")
	elif GameState.power_ratio >= 1.0:
		_power_warned = false

	_acc += delta
	if _acc < 0.1: return
	_acc = 0.0
	if not is_visible_in_tree(): return
	_refresh()

func _refresh() -> void:
	if not is_visible_in_tree(): return
	for id in _rows.keys():
		var row: Dictionary = _rows[id]
		var def := Buildings.get_def(id)

		if Buildings.is_unlocked(id):
			row["name"].modulate.a = 1.0
			row["accent"].modulate.a = 1.0
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
			row["accent"].modulate.a = 0.5
			row["effect"].text = "🔒 Требуется исследование: %s" % _research_name(String(def.get("requires_research", "")))
			row["effect"].add_theme_color_override("font_color", Palette.TEXT_3)
			row["cost"].visible = false
			row["button"].visible = false
