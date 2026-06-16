class_name ClickPanel
extends PanelContainer

const VALUE_FONT_SIZE := 14

var _power_label: Label
var _combo_label: Label
var _autoclick_short_label: Label
var _cp_button: Button
var _ac_button: Button
var _acc := 0.0

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 5)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)

	var top_row := HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 6)
	box.add_child(top_row)

	_power_label = Label.new()
	_power_label.add_theme_color_override("font_color", Palette.AMBER)
	_power_label.add_theme_font_size_override("font_size", VALUE_FONT_SIZE)
	_power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(_power_label)

	var info_btn := Button.new()
	info_btn.text = "ⓘ"
	info_btn.tooltip_text = "Подробности оператора"
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus"]:
		info_btn.add_theme_stylebox_override(s, empty)
	info_btn.add_theme_color_override("font_color", Palette.TEXT_DIM)
	info_btn.add_theme_font_size_override("font_size", 11)
	info_btn.pressed.connect(_show_details)
	top_row.add_child(info_btn)

	_combo_label = Label.new()
	_combo_label.add_theme_color_override("font_color", Palette.SIGNAL)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.custom_minimum_size = Vector2(0, 14)
	_combo_label.add_theme_font_size_override("font_size", 11)
	box.add_child(_combo_label)

	_autoclick_short_label = Label.new()
	_autoclick_short_label.add_theme_color_override("font_color", Palette.TEXT_2)
	_autoclick_short_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_autoclick_short_label.add_theme_font_size_override("font_size", 11)
	box.add_child(_autoclick_short_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 4)
	box.add_child(buttons)

	_cp_button = Button.new()
	_cp_button.pressed.connect(_on_cp_pressed)
	buttons.add_child(_cp_button)

	_ac_button = Button.new()
	_ac_button.pressed.connect(_on_ac_pressed)
	buttons.add_child(_ac_button)

	Events.tick.connect(_on_tick)
	Events.resource_changed.connect(_on_resource_changed)

	_refresh()

func _show_details() -> void:
	var lines: Array = [
		"Сила клика: %s" % Format.num(Clicker.click_power()),
	]
	if GameState.combo_stacks > 0.0:
		lines.append("Комбо ×%s (%d серий)" % [Format.num(Clicker.combo_mult()), int(GameState.combo_stacks)])
	else:
		lines.append("Комбо: нет")
	lines.append("Автокликер ур.%d" % GameState.autoclick_level)
	lines.append("  %s/клик → +%s/сек" % [Format.num(Clicker.autoclick_power()), Format.num(Clicker.autoclick_income())])
	DetailPopup.show_at(get_global_mouse_position(), "Оператор", lines)

func _on_cp_pressed() -> void:
	if Clicker.upgrade_click_power():
		_refresh()

func _on_ac_pressed() -> void:
	if Clicker.upgrade_autoclick():
		_refresh()

func _on_resource_changed(_id: String, _value: float) -> void:
	_refresh()

func _on_tick(delta: float) -> void:
	_acc += delta
	if _acc < 0.1: return
	_acc = 0.0
	_refresh()

func _refresh() -> void:
	if not is_visible_in_tree(): return

	_power_label.text = "КЛИК %s" % Format.num(Clicker.click_power())

	if GameState.combo_stacks > 0.0:
		_combo_label.text = "Комбо ×%s" % Format.num(Clicker.combo_mult())
		_combo_label.modulate.a = 1.0
	else:
		_combo_label.text = ""
		_combo_label.modulate.a = 0.0

	_autoclick_short_label.text = "+%s/сек авто" % Format.num(Clicker.autoclick_income())

	_cp_button.text = "УСИЛИТЬ (%s ДАН)" % Format.num(Clicker.click_power_cost())
	_cp_button.disabled = not Clicker.can_upgrade_click_power()
	_cp_button.modulate.a = 1.0 if Clicker.can_upgrade_click_power() else 0.5

	_ac_button.text = "АВТОКЛ. (%s ДАН)" % Format.num(Clicker.autoclick_cost())
	_ac_button.disabled = not Clicker.can_upgrade_autoclick()
	_ac_button.modulate.a = 1.0 if Clicker.can_upgrade_autoclick() else 0.5
