class_name PrestigePanel
extends PanelContainer

const CONFIRM_TIMEOUT := 3.0

var _echo_label: Label
var _count_label: Label
var _gain_label: Label
var _prestige_button: Button
var _confirm_armed := false
var _confirm_timer: Timer

var _rows := {}  # id -> { "name_label", "desc_label", "status_label", "cost_label", "button" }

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
		margin.add_theme_constant_override("margin_%s" % side, 8)
	scroll.add_child(margin)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	margin.add_child(list)

	_echo_label = Label.new()
	_echo_label.add_theme_color_override("font_color", Palette.VOID)
	list.add_child(_echo_label)

	_count_label = Label.new()
	_count_label.add_theme_color_override("font_color", Palette.TEXT_2)
	list.add_child(_count_label)

	_gain_label = Label.new()
	_gain_label.add_theme_color_override("font_color", Palette.TEXT_2)
	list.add_child(_gain_label)

	_prestige_button = Button.new()
	_prestige_button.pressed.connect(_on_prestige_pressed)
	list.add_child(_prestige_button)

	_confirm_timer = Timer.new()
	_confirm_timer.one_shot = true
	_confirm_timer.wait_time = CONFIRM_TIMEOUT
	_confirm_timer.timeout.connect(_on_confirm_timeout)
	add_child(_confirm_timer)

	list.add_child(HSeparator.new())

	var header := Label.new()
	header.text = "МЕТА-ДЕРЕВО"
	header.add_theme_color_override("font_color", Palette.AMBER)
	list.add_child(header)
	list.add_child(HSeparator.new())

	for m in MetaDB.get_list():
		list.add_child(_build_row(m))

	Events.tick.connect(_on_tick)
	Events.prestige_done.connect(_on_prestige_done)
	Events.meta_upgrade_bought.connect(_on_meta_upgrade_bought)

	_refresh()

func _build_row(m: Dictionary) -> Control:
	var row := VBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var top := HBoxContainer.new()
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(top)

	var name_label := Label.new()
	name_label.text = m["name"]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(name_label)

	var status_label := Label.new()
	top.add_child(status_label)

	var desc_label := Label.new()
	desc_label.text = m["desc"]
	desc_label.add_theme_color_override("font_color", Palette.TEXT_2)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(desc_label)

	var footer := HBoxContainer.new()
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(footer)

	var cost_label := Label.new()
	cost_label.text = "%s ЭХО" % Format.num(m["cost"])
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cost_label.add_theme_color_override("font_color", Palette.VOID)
	cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(cost_label)

	var button := Button.new()
	button.text = "Активировать"
	button.pressed.connect(_on_buy_pressed.bind(m["id"]))
	footer.add_child(button)

	row.add_child(HSeparator.new())

	_rows[m["id"]] = {
		"name_label": name_label,
		"desc_label": desc_label,
		"status_label": status_label,
		"cost_label": cost_label,
		"button": button,
	}
	return row

func _requires_text(m: Dictionary) -> String:
	var names := PackedStringArray()
	for p in m.get("requires", []):
		names.append(String(MetaDB.get_def(p).get("name", p)))
	return "🔒 требуется: %s" % ", ".join(names)

func _on_buy_pressed(id: String) -> void:
	if not Prestige.buy(id):
		return
	var mname := String(MetaDB.get_def(id)["name"])
	Events.log_message.emit("> ЭХО-ПЕРК АКТИВИРОВАН: %s" % mname, "sys")
	_refresh()

func _on_prestige_pressed() -> void:
	if not Prestige.can_prestige():
		return
	if not _confirm_armed:
		_confirm_armed = true
		_confirm_timer.start()
		_refresh()
		return
	_confirm_timer.stop()
	_confirm_armed = false
	Prestige.do_prestige()
	_refresh()

func _on_confirm_timeout() -> void:
	_confirm_armed = false
	_refresh()

func _on_prestige_done(_echo_gained: float) -> void:
	_refresh()

func _on_meta_upgrade_bought(_id: String) -> void:
	_refresh()

func _on_tick(_delta: float) -> void:
	_refresh()

func _refresh() -> void:
	_echo_label.text = "ХРОНО-ЭХО: %s" % Format.num(GameState.chrono_echo)
	_count_label.text = "Свёрнуто линий: %d" % GameState.prestige_count
	_gain_label.text = "Получишь сейчас: +%s эхо" % Format.num(Prestige.echo_gain())

	var can := Prestige.can_prestige()
	if _confirm_armed:
		_prestige_button.text = "ПОДТВЕРДИТЬ: УНИЧТОЖИТЬ АРХИВ"
		_prestige_button.add_theme_color_override("font_color", Palette.DANGER)
	else:
		_prestige_button.text = "Свернуть временную линию (+%s эхо)" % Format.num(Prestige.echo_gain())
		_prestige_button.remove_theme_color_override("font_color")
	_prestige_button.disabled = not can
	_prestige_button.modulate.a = 1.0 if can else 0.5
	if not can:
		_prestige_button.tooltip_text = "Нужно больше прогресса"
	else:
		_prestige_button.tooltip_text = ""

	for id in _rows.keys():
		var row: Dictionary = _rows[id]
		var def := MetaDB.get_def(id)
		if Prestige.is_owned(id):
			row["status_label"].text = "✓"
			row["status_label"].add_theme_color_override("font_color", Palette.OK)
			row["name_label"].add_theme_color_override("font_color", Palette.TEXT_2)
			row["desc_label"].text = def["desc"]
			row["desc_label"].add_theme_color_override("font_color", Palette.TEXT_2)
			row["cost_label"].visible = false
			row["button"].visible = false
		elif Prestige.prereqs_met(id):
			row["status_label"].text = ""
			row["name_label"].add_theme_color_override("font_color", Palette.VOID)
			row["desc_label"].text = def["desc"]
			row["desc_label"].add_theme_color_override("font_color", Palette.TEXT_2)
			row["cost_label"].visible = true
			row["button"].visible = true
			row["button"].disabled = not Prestige.can_buy(id)
			row["button"].modulate.a = 1.0 if Prestige.can_buy(id) else 0.5
		else:
			row["status_label"].text = ""
			row["name_label"].add_theme_color_override("font_color", Palette.TEXT_3)
			row["desc_label"].text = _requires_text(def)
			row["desc_label"].add_theme_color_override("font_color", Palette.TEXT_3)
			row["cost_label"].visible = false
			row["button"].visible = false
