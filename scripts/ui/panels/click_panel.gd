class_name ClickPanel
extends PanelContainer

const VALUE_FONT_SIZE := 18

var _power_label: Label
var _combo_label: Label
var _autoclick_label: Label
var _cp_button: Button
var _ac_button: Button
var _acc := 0.0

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 8)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var header := Label.new()
	header.text = "ОПЕРАТОР"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", Palette.TEXT_DIM)
	header.add_theme_font_size_override("font_size", 11)
	box.add_child(header)
	box.add_child(HSeparator.new())

	_power_label = Label.new()
	_power_label.add_theme_color_override("font_color", Palette.AMBER)
	_power_label.add_theme_font_size_override("font_size", VALUE_FONT_SIZE)
	_power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_power_label)

	_combo_label = Label.new()
	_combo_label.add_theme_color_override("font_color", Palette.SIGNAL)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_combo_label)

	_autoclick_label = Label.new()
	_autoclick_label.add_theme_color_override("font_color", Palette.TEXT_2)
	_autoclick_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_autoclick_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 6)
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

	_power_label.text = "СИЛА КЛИКА: %s" % Format.num(Clicker.click_power())

	if GameState.combo_stacks > 0.0:
		_combo_label.visible = true
		_combo_label.text = "Комбо ×%s" % Format.num(Clicker.combo_mult())
	else:
		_combo_label.visible = false

	_autoclick_label.text = "АВТОКЛИКЕР УР. %d — %s/клик → +%s/сек" % [GameState.autoclick_level, Format.num(Clicker.autoclick_power()), Format.num(Clicker.autoclick_income())]

	_cp_button.text = "УСИЛИТЬ КЛИК (%s ДАН)" % Format.num(Clicker.click_power_cost())
	_cp_button.disabled = not Clicker.can_upgrade_click_power()
	_cp_button.modulate.a = 1.0 if Clicker.can_upgrade_click_power() else 0.5

	_ac_button.text = "УЛУЧШИТЬ АВТОКЛИКЕР (%s ДАН)" % Format.num(Clicker.autoclick_cost())
	_ac_button.disabled = not Clicker.can_upgrade_autoclick()
	_ac_button.modulate.a = 1.0 if Clicker.can_upgrade_autoclick() else 0.5
