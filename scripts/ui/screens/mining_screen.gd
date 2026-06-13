class_name MiningScreen
extends Control

signal back_pressed

var _balance_rows := {}   # crypto_id -> { "balance": Label, "rate": Label }
var _rig_rows := {}       # rig_id -> { "count": Label, "cost": Label, "button": Button }
var _upg_rows := {}       # upg_id -> { "status": Label, "desc": Label, "cost": Label, "button": Button }

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)

	layout.add_child(_build_header())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	layout.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 14)
	scroll.add_child(margin)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	margin.add_child(list)

	_build_balances_section(list)
	list.add_child(HSeparator.new())
	_build_rigs_section(list)
	list.add_child(HSeparator.new())
	_build_upgrades_section(list)

	Events.tick.connect(_on_tick)
	Events.crypto_rig_bought.connect(_on_crypto_rig_bought)
	Events.mining_upgrade_bought.connect(_on_mining_upgrade_bought)
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
	title.text = "КРИПТО-ФЕРМА"
	title.add_theme_color_override("font_color", Palette.CRYPTO)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	return panel

func _build_balances_section(list: VBoxContainer) -> void:
	var header := Label.new()
	header.text = "БАЛАНСЫ"
	header.add_theme_color_override("font_color", Palette.AMBER)
	list.add_child(header)

	for c in CryptoDB.get_list():
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_label := Label.new()
		name_label.text = "%s (%s)" % [c["name"], c["short"]]
		name_label.add_theme_color_override("font_color", c["color"])
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		var balance_label := Label.new()
		row.add_child(balance_label)

		var rate_label := Label.new()
		rate_label.add_theme_color_override("font_color", Palette.TEXT_2)
		row.add_child(rate_label)

		list.add_child(row)
		_balance_rows[c["id"]] = { "balance": balance_label, "rate": rate_label }

func _build_rigs_section(list: VBoxContainer) -> void:
	var header := Label.new()
	header.text = "РИГИ"
	header.add_theme_color_override("font_color", Palette.AMBER)
	list.add_child(header)

	for r in MiningDB.get_rigs():
		list.add_child(_build_rig_row(r))

func _build_rig_row(r: Dictionary) -> Control:
	var row := VBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var top := HBoxContainer.new()
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(top)

	var name_label := Label.new()
	name_label.text = r["name"]
	name_label.add_theme_color_override("font_color", Palette.CRYPTO)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(name_label)

	var count_label := Label.new()
	top.add_child(count_label)

	var desc_label := Label.new()
	desc_label.text = String(r.get("desc", ""))
	desc_label.add_theme_color_override("font_color", Palette.TEXT_2)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(desc_label)

	var footer := HBoxContainer.new()
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(footer)

	var cost_label := Label.new()
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cost_label.add_theme_color_override("font_color", Palette.AMBER_SOFT)
	footer.add_child(cost_label)

	var button := Button.new()
	button.text = "Собрать"
	button.pressed.connect(_on_buy_rig_pressed.bind(r["id"]))
	footer.add_child(button)

	row.add_child(HSeparator.new())

	_rig_rows[r["id"]] = { "count": count_label, "cost": cost_label, "button": button }
	return row

func _build_upgrades_section(list: VBoxContainer) -> void:
	var header := Label.new()
	header.text = "РАЗГОН"
	header.add_theme_color_override("font_color", Palette.AMBER)
	list.add_child(header)

	for u in MiningDB.get_upgrades():
		list.add_child(_build_upgrade_row(u))

func _build_upgrade_row(u: Dictionary) -> Control:
	var row := VBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var top := HBoxContainer.new()
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(top)

	var name_label := Label.new()
	name_label.text = u["name"]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(name_label)

	var status_label := Label.new()
	top.add_child(status_label)

	var desc_label := Label.new()
	desc_label.add_theme_color_override("font_color", Palette.TEXT_2)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(desc_label)

	var footer := HBoxContainer.new()
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(footer)

	var cost_label := Label.new()
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cost_label.add_theme_color_override("font_color", Palette.CRYPTO)
	footer.add_child(cost_label)

	var button := Button.new()
	button.text = "Активировать"
	button.pressed.connect(_on_buy_upgrade_pressed.bind(u["id"]))
	footer.add_child(button)

	row.add_child(HSeparator.new())

	_upg_rows[u["id"]] = {
		"status": status_label,
		"desc": desc_label,
		"cost": cost_label,
		"button": button,
	}
	return row

func _cost_text(cost: Dictionary) -> String:
	var parts := PackedStringArray()
	for cid in cost.keys():
		parts.append("%s %s" % [Format.num(cost[cid]), _crypto_short(cid)])
	return ", ".join(parts)

func _crypto_short(cid: String) -> String:
	return String(CryptoDB.get_def(cid).get("short", cid))

func _requires_text(u: Dictionary) -> String:
	var names := PackedStringArray()
	for p in u.get("requires", []):
		names.append(String(MiningDB.get_upgrade(p).get("name", p)))
	return "🔒 требуется: %s" % ", ".join(names)

func _on_buy_rig_pressed(id: String) -> void:
	if not Mining.buy_rig(id):
		return
	var rname := String(MiningDB.get_rig(id)["name"])
	Events.log_message.emit("> УСТАНОВЛЕН РИГ: %s" % rname, "sys")
	_refresh()

func _on_buy_upgrade_pressed(id: String) -> void:
	if not Mining.upg_buy(id):
		return
	var uname := String(MiningDB.get_upgrade(id)["name"])
	Events.log_message.emit("> РАЗГОН АКТИВИРОВАН: %s" % uname, "sys")
	_refresh()

func _on_crypto_rig_bought(_id: String, _count: int) -> void:
	_refresh()

func _on_mining_upgrade_bought(_id: String) -> void:
	_refresh()

func _on_resource_changed(_id: String, _value: float) -> void:
	_refresh()

func _on_tick(_delta: float) -> void:
	_refresh()

func _on_visibility_changed() -> void:
	if visible:
		_refresh()

func _refresh() -> void:
	for id in _balance_rows.keys():
		var row: Dictionary = _balance_rows[id]
		row["balance"].text = Format.num(GameState.get_resource(id))
		row["rate"].text = Format.rate(Mining.crypto_rate(id))

	for id in _rig_rows.keys():
		var row: Dictionary = _rig_rows[id]
		var def := MiningDB.get_rig(id)
		row["count"].text = "×%d" % Mining.rig_count(id)
		row["cost"].text = "%s Данные" % Format.num(Mining.rig_cost(id))
		var affordable := Mining.can_buy_rig(id)
		row["button"].disabled = not affordable
		row["button"].modulate.a = 1.0 if affordable else 0.5

	for id in _upg_rows.keys():
		var row: Dictionary = _upg_rows[id]
		var def := MiningDB.get_upgrade(id)
		if Mining.upg_owned(id):
			row["status"].text = "✓"
			row["status"].add_theme_color_override("font_color", Palette.OK)
			row["desc"].text = String(def["desc"])
			row["cost"].visible = false
			row["button"].visible = false
		elif _prereqs_met(def):
			row["status"].text = ""
			row["desc"].text = String(def["desc"])
			row["cost"].visible = true
			row["cost"].text = _cost_text(def.get("cost", {}))
			row["button"].visible = true
			row["button"].disabled = not Mining.upg_can_buy(id)
			row["button"].modulate.a = 1.0 if Mining.upg_can_buy(id) else 0.5
		else:
			row["status"].text = ""
			row["desc"].text = _requires_text(def)
			row["cost"].visible = false
			row["button"].visible = false

func _prereqs_met(def: Dictionary) -> bool:
	for p in def.get("requires", []):
		if not Mining.upg_owned(p):
			return false
	return true
