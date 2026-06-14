class_name PrestigeScreen
extends Control

signal back_pressed

const CONFIRM_TIMEOUT := 3.0

var _graph: TreeGraph
var _echo_label: Label
var _gain_label: Label
var _prestige_button: Button
var _confirm_armed := false
var _confirm_timer: Timer
var _acc := 0.0

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

	_confirm_timer = Timer.new()
	_confirm_timer.one_shot = true
	_confirm_timer.wait_time = CONFIRM_TIMEOUT
	_confirm_timer.timeout.connect(_on_confirm_timeout)
	add_child(_confirm_timer)

	Events.tick.connect(_on_tick)
	Events.prestige_done.connect(_on_prestige_done)
	Events.meta_upgrade_bought.connect(_on_meta_upgrade_bought)
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
	title.text = "ВРЕМЕННАЯ ЛИНИЯ"
	title.add_theme_color_override("font_color", Palette.VOID)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_echo_label = Label.new()
	_echo_label.add_theme_color_override("font_color", Palette.VOID)
	box.add_child(_echo_label)

	_gain_label = Label.new()
	_gain_label.add_theme_color_override("font_color", Palette.TEXT_2)
	box.add_child(_gain_label)

	_prestige_button = Button.new()
	_prestige_button.pressed.connect(_on_prestige_pressed)
	box.add_child(_prestige_button)

	return panel

func _nodes() -> Array:
	var result := []
	for m in MetaDB.get_list():
		var state := TreeGraph.NodeState.LOCKED
		if Prestige.is_owned(m["id"]):
			state = TreeGraph.NodeState.OWNED
		elif Prestige.prereqs_met(m["id"]):
			state = TreeGraph.NodeState.AVAILABLE

		result.append({
			"id": m["id"], "title": m["name"], "desc": String(m.get("desc", "")),
			"pos": m["pos"], "color": Palette.VOID,
			"state": state,
			"cost_text": "%s ЭХО" % Format.num(m["cost"]),
			"effect_text": _effect_text(m),
			"req_text": _req_text(m),
			"action_label": "Активировать",
			"requires": m.get("requires", []),
		})
	return result

func _effect_text(m: Dictionary) -> String:
	var eff: Dictionary = m.get("effects", {})
	if eff.has("click_mult"):
		return "Сила клика ×%s" % Format.num(float(eff["click_mult"]))
	if eff.has("mult_production"):
		return "Производство ×%s" % Format.num(float(eff["mult_production"]))
	if eff.has("start_data"):
		return "Старт: +%s данных" % Format.num(float(eff["start_data"]))
	if eff.has("echo_gain_mult"):
		return "Эхо ×%s" % Format.num(float(eff["echo_gain_mult"]))
	return "—"

func _req_text(m: Dictionary) -> String:
	var names := PackedStringArray()
	for p in m.get("requires", []):
		names.append(String(MetaDB.get_def(p).get("name", p)))
	return ", ".join(names)

func _do_action(id: String) -> bool:
	if not Prestige.buy(id):
		return false
	var mname := String(MetaDB.get_def(id)["name"])
	Events.log_message.emit("> ЭХО-ПЕРК АКТИВИРОВАН: %s" % mname, "sys")
	return true

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

func _on_tick(delta: float) -> void:
	_acc += delta
	if _acc < 0.1: return
	_acc = 0.0
	_refresh()

func _on_visibility_changed() -> void:
	if visible:
		_refresh()

func _refresh() -> void:
	if not is_visible_in_tree(): return
	_echo_label.text = "ХРОНО-ЭХО: %s" % Format.num(GameState.chrono_echo)
	_gain_label.text = "Получишь: +%s" % Format.num(Prestige.echo_gain())

	var can := Prestige.can_prestige()
	if _confirm_armed:
		_prestige_button.text = "ПОДТВЕРДИТЬ: УНИЧТОЖИТЬ АРХИВ"
		_prestige_button.add_theme_color_override("font_color", Palette.DANGER)
	else:
		_prestige_button.text = "Свернуть временную линию (+%s эхо)" % Format.num(Prestige.echo_gain())
		_prestige_button.remove_theme_color_override("font_color")
	_prestige_button.disabled = not can
	_prestige_button.modulate.a = 1.0 if can else 0.5

	_graph.refresh()
