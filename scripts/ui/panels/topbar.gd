class_name TopBar
extends PanelContainer

var _value_label: Label
var _rate_label: Label
var _compute_label: Label
var _compute_rate_label: Label
var _energy_label: Label
var _power_label: Label
var _power_bar: Panel
var _power_bar_bg: Panel
var _power_bar_style: StyleBoxFlat
var _box: HBoxContainer

const BAR_WIDTH := 80.0
const BAR_HEIGHT := 6.0
const NAV_BUTTON_SIZE := 48.0

func _ready() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 10)
	add_child(margin)

	_box = HBoxContainer.new()
	margin.add_child(_box)
	var box := _box

	var name_label := Label.new()
	name_label.text = "%s:" % Labels.res_name("data").to_upper()
	name_label.add_theme_color_override("font_color", Palette.AMBER)
	box.add_child(name_label)

	_value_label = Label.new()
	_value_label.text = Format.num(GameState.get_resource("data"))
	box.add_child(_value_label)

	_rate_label = Label.new()
	_rate_label.text = Format.rate(GameState.production_rates.get("data", 0.0))
	_rate_label.add_theme_color_override("font_color", Palette.TEXT_2)
	box.add_child(_rate_label)

	box.add_child(_spacer())

	var compute_name := Label.new()
	compute_name.text = "%s:" % Labels.res_name("compute").to_upper()
	compute_name.add_theme_color_override("font_color", Palette.COMPUTE)
	box.add_child(compute_name)

	_compute_label = Label.new()
	_compute_label.text = Format.num(GameState.get_resource("compute"))
	box.add_child(_compute_label)

	_compute_rate_label = Label.new()
	_compute_rate_label.text = Format.rate(GameState.production_rates.get("compute", 0.0))
	_compute_rate_label.add_theme_color_override("font_color", Palette.TEXT_2)
	box.add_child(_compute_rate_label)

	box.add_child(_spacer())

	var energy_name := Label.new()
	energy_name.text = "%s:" % Labels.res_name("energy").to_upper()
	energy_name.add_theme_color_override("font_color", Palette.ENERGY)
	box.add_child(energy_name)

	_energy_label = Label.new()
	box.add_child(_energy_label)

	_power_label = Label.new()
	box.add_child(_power_label)

	_power_bar_bg = Panel.new()
	_power_bar_bg.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_power_bar_bg.add_theme_stylebox_override("panel", _bar_style(Palette.LINE, BAR_HEIGHT))
	box.add_child(_power_bar_bg)

	_power_bar = Panel.new()
	_power_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	_power_bar_style = _bar_style(Palette.OK, BAR_HEIGHT)
	_power_bar.add_theme_stylebox_override("panel", _power_bar_style)
	_power_bar_bg.add_child(_power_bar)

	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(right_spacer)

	Events.resource_changed.connect(_on_resource_changed)
	Events.tick.connect(_on_tick)

	_refresh_energy()

func add_nav_button(glyph: String, tooltip: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = glyph
	btn.tooltip_text = tooltip
	btn.custom_minimum_size = Vector2(NAV_BUTTON_SIZE, NAV_BUTTON_SIZE)
	btn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.pressed.connect(callback)
	_box.add_child(btn)
	return btn

func _spacer() -> Label:
	var sep := Label.new()
	sep.text = "   "
	return sep

func _on_resource_changed(id: String, value: float) -> void:
	if id == "data":
		_value_label.text = Format.num(value)
	elif id == "compute":
		_compute_label.text = Format.num(value)

func _on_tick(_delta: float) -> void:
	_rate_label.text = Format.rate(GameState.production_rates.get("data", 0.0))
	_compute_rate_label.text = Format.rate(GameState.production_rates.get("compute", 0.0))
	_refresh_energy()

func _refresh_energy() -> void:
	var prod := GameState.energy_production
	var dem := GameState.energy_demand
	var ratio := GameState.power_ratio
	_energy_label.text = "%s / %s" % [Format.num(prod), Format.num(dem)]

	var pct := int(round(ratio * 100.0))
	_power_label.text = "Питание: %d%%" % pct

	var color := Palette.OK
	if ratio < 0.5:
		color = Palette.DANGER
	elif ratio < 1.0:
		color = Palette.WARN
	_power_label.add_theme_color_override("font_color", color)
	_power_bar_style.bg_color = color
	_power_bar.size = Vector2(BAR_WIDTH * clampf(ratio, 0.0, 1.0), BAR_HEIGHT)

func _bar_style(color: Color, height: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(height / 2.0))
	return sb
