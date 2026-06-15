class_name TopBar
extends MarginContainer

var _value_label: Label
var _rate_label: Label
var _compute_label: Label
var _compute_rate_label: Label
var _energy_label: Label
var _power_label: Label
var _power_bar: ProgressBar
var _power_bar_fill: StyleBoxFlat
var _box: HBoxContainer
var _acc := 0.0

const BAR_WIDTH := 80.0
const BAR_HEIGHT := 10.0
const GROUP_SEPARATION := 12
const NAV_BUTTON_SIZE := 34.0
const VALUE_FONT_SIZE := 20

func _ready() -> void:
	for side in ["left", "right", "top", "bottom"]:
		add_theme_constant_override("margin_%s" % side, 6)

	_box = HBoxContainer.new()
	_box.add_theme_constant_override("separation", GROUP_SEPARATION)
	add_child(_box)
	var box := _box

	box.add_child(_build_data_module())
	box.add_child(_build_compute_module())
	box.add_child(_build_energy_module())
	box.add_child(_build_crypto_module())

	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(right_spacer)

	Events.resource_changed.connect(_on_resource_changed)
	Events.tick.connect(_on_tick)

	_refresh_energy()

func _accent(color: Color) -> Control:
	var rect := ColorRect.new()
	rect.color = color
	rect.custom_minimum_size = Vector2(0, 2)
	return rect

func _build_data_module() -> Control:
	var m := ThemeBuilder.framed_module(Labels.res_name("data"))
	var body := m["body"] as VBoxContainer

	_value_label = Label.new()
	_value_label.text = Format.num(GameState.get_resource("data"))
	_value_label.add_theme_color_override("font_color", Palette.AMBER)
	_value_label.add_theme_font_size_override("font_size", VALUE_FONT_SIZE)
	body.add_child(_value_label)

	_rate_label = Label.new()
	_rate_label.text = Format.rate(GameState.production_rates.get("data", 0.0))
	_rate_label.add_theme_color_override("font_color", Palette.TEXT_DIM)
	body.add_child(_rate_label)

	body.add_child(_accent(Palette.AMBER))

	return m["panel"]

func _build_compute_module() -> Control:
	var m := ThemeBuilder.framed_module(Labels.res_name("compute"))
	var body := m["body"] as VBoxContainer

	_compute_label = Label.new()
	_compute_label.text = Format.num(GameState.get_resource("compute"))
	_compute_label.add_theme_color_override("font_color", Palette.COMPUTE)
	_compute_label.add_theme_font_size_override("font_size", VALUE_FONT_SIZE)
	body.add_child(_compute_label)

	_compute_rate_label = Label.new()
	_compute_rate_label.text = Format.rate(GameState.production_rates.get("compute", 0.0))
	_compute_rate_label.add_theme_color_override("font_color", Palette.TEXT_DIM)
	body.add_child(_compute_rate_label)

	body.add_child(_accent(Palette.COMPUTE))

	return m["panel"]

func _build_energy_module() -> Control:
	var m := ThemeBuilder.framed_module(Labels.res_name("energy"))
	var body := m["body"] as VBoxContainer

	_energy_label = Label.new()
	_energy_label.add_theme_color_override("font_color", Palette.ENERGY)
	_energy_label.add_theme_font_size_override("font_size", VALUE_FONT_SIZE)
	body.add_child(_energy_label)

	_power_label = Label.new()
	body.add_child(_power_label)

	_power_bar = ProgressBar.new()
	_power_bar.min_value = 0.0
	_power_bar.max_value = 100.0
	_power_bar.show_percentage = false
	_power_bar.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Palette.BG_DEEP
	bg_style.border_color = Palette.BORDER
	bg_style.set_border_width_all(1)
	bg_style.set_corner_radius_all(0)
	_power_bar.add_theme_stylebox_override("background", bg_style)

	_power_bar_fill = StyleBoxFlat.new()
	_power_bar_fill.bg_color = Palette.OK
	_power_bar_fill.set_corner_radius_all(0)
	_power_bar.add_theme_stylebox_override("fill", _power_bar_fill)

	body.add_child(_power_bar)

	return m["panel"]

func _build_crypto_module() -> Control:
	var m := ThemeBuilder.framed_module("Крипта")
	var body := m["body"] as VBoxContainer

	body.add_child(CryptoTracker.new())
	body.add_child(_accent(Palette.CRYPTO))

	return m["panel"]

func add_nav_button(glyph: String, tooltip: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = glyph
	btn.tooltip_text = tooltip
	btn.custom_minimum_size = Vector2(NAV_BUTTON_SIZE, NAV_BUTTON_SIZE)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.pressed.connect(callback)
	_box.add_child(btn)
	return btn

func _on_resource_changed(id: String, value: float) -> void:
	if id == "data":
		_value_label.text = Format.num(value)
	elif id == "compute":
		_compute_label.text = Format.num(value)

func _on_tick(delta: float) -> void:
	_acc += delta
	if _acc < 0.1: return
	_acc = 0.0
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
	_power_bar_fill.bg_color = color
	_power_bar.value = clampf(ratio, 0.0, 1.0) * 100.0
