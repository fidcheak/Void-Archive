class_name ResearchTreeScreen
extends Control

signal back_pressed

var _graph: TreeGraph
var _compute_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)

	layout.add_child(_build_header())

	_graph = TreeGraph.new()
	_graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph.node_provider = _nodes
	_graph.action_handler = _do_action
	layout.add_child(_graph)
	_graph.build()

	Events.research_completed.connect(_on_research_completed)
	Events.resource_changed.connect(_on_resource_changed)
	visibility_changed.connect(_on_visibility_changed)

	_refresh()

func _build_header() -> Control:
	var panel := PanelContainer.new()

	var box := HBoxContainer.new()
	panel.add_child(box)

	var back_btn := Button.new()
	back_btn.text = "← НАЗАД"
	back_btn.pressed.connect(func(): back_pressed.emit())
	box.add_child(back_btn)

	var title := Label.new()
	title.text = "ДЕРЕВО ИССЛЕДОВАНИЙ"
	title.add_theme_color_override("font_color", Palette.AMBER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var compute_name := Label.new()
	compute_name.text = "%s:" % Labels.res_name("compute").to_upper()
	compute_name.add_theme_color_override("font_color", Palette.COMPUTE)
	box.add_child(compute_name)

	_compute_label = Label.new()
	box.add_child(_compute_label)

	return panel

func _nodes() -> Array:
	var branch_colors := {}
	for b in ResearchDB.get_branches():
		branch_colors[b["id"]] = b["color"]

	var result := []
	for r in ResearchDB.get_list():
		var state := TreeGraph.NodeState.LOCKED
		if Research.is_owned(r["id"]):
			state = TreeGraph.NodeState.OWNED
		elif Research.is_available(r["id"]):
			state = TreeGraph.NodeState.AVAILABLE

		result.append({
			"id": r["id"], "title": r["name"], "desc": String(r.get("desc", "")),
			"pos": r["pos"], "color": branch_colors.get(r["branch"], Palette.TEXT_3),
			"state": state,
			"cost_text": _cost_text(r),
			"effect_text": _effect_text(r),
			"req_text": _req_text(r),
			"action_label": "Изучить",
			"requires": r.get("requires", []),
		})
	return result

func _cost_text(r: Dictionary) -> String:
	var cost: Dictionary = r.get("cost", {})
	if cost.is_empty():
		return "—"
	var parts := PackedStringArray()
	for res_id in cost.keys():
		parts.append("%s %s" % [Format.num(cost[res_id]), Labels.res_short(res_id)])
	return ", ".join(parts)

func _effect_text(r: Dictionary) -> String:
	var eff: Dictionary = r.get("effects", {})
	var parts := PackedStringArray()
	if eff.has("mult_production"):
		var mp: Dictionary = eff["mult_production"]
		for res_id in mp.keys():
			var factor := float(mp[res_id])
			var tag := " (дебафф)" if factor < 1.0 else ""
			parts.append("%s ×%s%s" % [Labels.res_name(res_id), Format.num(factor), tag])
	if eff.has("mult_building"):
		var mb: Dictionary = eff["mult_building"]
		for b_id in mb.keys():
			parts.append("%s ×%s" % [_building_name(b_id), Format.num(float(mb[b_id]))])
	if eff.has("add_base_energy"):
		var bonus := float(eff["add_base_energy"])
		var tag := " (дебафф)" if bonus < 0.0 else ""
		parts.append("%+d базовой энергии%s" % [int(bonus), tag])
	var ability := _ability_unlock(r["id"])
	if not ability.is_empty():
		parts.append("Открывает: %s" % String(ability["name"]))
	var building := _building_unlock(r["id"])
	if not building.is_empty():
		parts.append("Открывает постройку: %s" % String(building["name"]))
	if parts.is_empty():
		return "—"
	return ", ".join(parts)

func _ability_unlock(node_id: String) -> Dictionary:
	for a in AbilitiesDB.get_list():
		if String(a.get("unlocked_by", "")) == node_id:
			return a
	return {}

func _building_unlock(node_id: String) -> Dictionary:
	for b in BuildingsDB.get_list():
		if String(b.get("requires_research", "")) == node_id:
			return b
	return {}

func _req_text(r: Dictionary) -> String:
	if Research.is_excluded(r["id"]):
		return "Путь закрыт (выбран другой узел)"

	var flag := String(r.get("requires_flag", ""))
	if flag != "" and not GameState.flags.get(flag, false):
		return "Требуется обнаружить повреждённый сектор (целостность < 50%)"

	var names := PackedStringArray()
	for p in r.get("requires", []):
		names.append(String(Research.get_def(p).get("name", p)))
	return ", ".join(names)

func _do_action(id: String) -> bool:
	if not Research.research(id):
		return false
	var rname := String(Research.get_def(id)["name"])
	Events.log_message.emit("> ТЕХНОЛОГИЯ ВНЕДРЕНА: %s" % rname, "sys")
	return true

func _building_name(b_id: String) -> String:
	for b in BuildingsDB.get_list():
		if b["id"] == b_id:
			return String(b["name"])
	return b_id

func _on_research_completed(_id: String) -> void:
	_refresh()

func _on_resource_changed(_id: String, _value: float) -> void:
	_refresh()

func _on_visibility_changed() -> void:
	if visible:
		_refresh()

func _refresh() -> void:
	if not is_visible_in_tree(): return
	_compute_label.text = Format.num(GameState.get_resource("compute"))
	_graph.refresh()
