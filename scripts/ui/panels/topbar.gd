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
var _data_mult_label: Label
var _data_top_labels: Array = []
var _compute_mult_label: Label
var _compute_top_labels: Array = []
var _energy_eff_label: Label
var _energy_top_labels: Array = []
var _box: HBoxContainer
var _acc := 0.0

const BAR_WIDTH := 80.0
const BAR_HEIGHT := 10.0
const GROUP_SEPARATION := 12
const NAV_BUTTON_SIZE := 34.0
const VALUE_FONT_SIZE := 20
const WIDGET_WIDTH := 155.0
const CRYPTO_WIDGET_WIDTH := 190.0
const TOP_PRODUCERS_COUNT := 3

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
	m["panel"].custom_minimum_size = Vector2(WIDGET_WIDTH, 0)
	var body := m["body"] as VBoxContainer

	_value_label = Label.new()
	_value_label.text = Format.num(GameState.get_resource("data"))
	_value_label.add_theme_color_override("font_color", Palette.AMBER)
	_value_label.add_theme_font_size_override("font_size", VALUE_FONT_SIZE)
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	body.add_child(_value_label)

	_rate_label = Label.new()
	_rate_label.text = Format.rate(GameState.production_rates.get("data", 0.0))
	_rate_label.add_theme_color_override("font_color", Palette.TEXT_DIM)
	_rate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	body.add_child(_rate_label)

	body.add_child(_accent(Palette.AMBER))

	body.add_child(HSeparator.new())

	_data_mult_label = Label.new()
	_data_mult_label.add_theme_color_override("font_color", Palette.TEXT_2)
	_data_mult_label.add_theme_font_size_override("font_size", 10)
	_data_mult_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	body.add_child(_data_mult_label)

	_data_top_labels.clear()
	for i in range(TOP_PRODUCERS_COUNT):
		var l := Label.new()
		l.add_theme_color_override("font_color", Palette.TEXT_3)
		l.add_theme_font_size_override("font_size", 10)
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		body.add_child(l)
		_data_top_labels.append(l)

	_refresh_data_extra()

	return m["panel"]

func _build_compute_module() -> Control:
	var m := ThemeBuilder.framed_module(Labels.res_name("compute"))
	m["panel"].custom_minimum_size = Vector2(WIDGET_WIDTH, 0)
	var body := m["body"] as VBoxContainer

	_compute_label = Label.new()
	_compute_label.text = Format.num(GameState.get_resource("compute"))
	_compute_label.add_theme_color_override("font_color", Palette.COMPUTE)
	_compute_label.add_theme_font_size_override("font_size", VALUE_FONT_SIZE)
	_compute_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	body.add_child(_compute_label)

	_compute_rate_label = Label.new()
	_compute_rate_label.text = Format.rate(GameState.production_rates.get("compute", 0.0))
	_compute_rate_label.add_theme_color_override("font_color", Palette.TEXT_DIM)
	_compute_rate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	body.add_child(_compute_rate_label)

	body.add_child(_accent(Palette.COMPUTE))

	body.add_child(HSeparator.new())

	_compute_mult_label = Label.new()
	_compute_mult_label.add_theme_color_override("font_color", Palette.TEXT_2)
	_compute_mult_label.add_theme_font_size_override("font_size", 10)
	_compute_mult_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	body.add_child(_compute_mult_label)

	_compute_top_labels.clear()
	for i in range(TOP_PRODUCERS_COUNT):
		var l := Label.new()
		l.add_theme_color_override("font_color", Palette.TEXT_3)
		l.add_theme_font_size_override("font_size", 10)
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		body.add_child(l)
		_compute_top_labels.append(l)

	_refresh_compute_extra()

	return m["panel"]

func _build_energy_module() -> Control:
	var m := ThemeBuilder.framed_module(Labels.res_name("energy"))
	m["panel"].custom_minimum_size = Vector2(WIDGET_WIDTH, 0)
	var body := m["body"] as VBoxContainer

	_energy_label = Label.new()
	_energy_label.add_theme_color_override("font_color", Palette.ENERGY)
	_energy_label.add_theme_font_size_override("font_size", VALUE_FONT_SIZE)
	_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
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

	body.add_child(HSeparator.new())

	_energy_eff_label = Label.new()
	_energy_eff_label.add_theme_color_override("font_color", Palette.TEXT_2)
	_energy_eff_label.add_theme_font_size_override("font_size", 10)
	_energy_eff_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	body.add_child(_energy_eff_label)

	_energy_top_labels.clear()
	for i in range(TOP_PRODUCERS_COUNT):
		var l := Label.new()
		l.add_theme_color_override("font_color", Palette.TEXT_3)
		l.add_theme_font_size_override("font_size", 10)
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		body.add_child(l)
		_energy_top_labels.append(l)

	_refresh_energy_extra()

	return m["panel"]

func _build_crypto_module() -> Control:
	var m := ThemeBuilder.framed_module("Крипта")
	m["panel"].custom_minimum_size = Vector2(CRYPTO_WIDGET_WIDTH, 0)
	var body := m["body"] as VBoxContainer

	body.add_child(CryptoTracker.new())
	body.add_child(_accent(Palette.CRYPTO))

	return m["panel"]

# buttons: Array of { "glyph": String, "tooltip": String, "callback": Callable }
func add_nav_column(buttons: Array) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for b in buttons:
		var btn := Button.new()
		btn.text = String(b["glyph"])
		btn.tooltip_text = String(b["tooltip"])
		btn.custom_minimum_size = Vector2(NAV_BUTTON_SIZE, NAV_BUTTON_SIZE)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.pressed.connect(b["callback"])
		col.add_child(btn)
	_box.add_child(col)

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
	_refresh_data_extra()
	_refresh_compute_extra()
	_refresh_energy_extra()

func _refresh_data_extra() -> void:
	_data_mult_label.text = "×%s (множ.)" % Format.num(Research.get_production_mult("data"))

	var top := _top_data_producers()
	for i in range(_data_top_labels.size()):
		if i < top.size():
			var e: Dictionary = top[i]
			var short_name := String(e["name"]).left(7).rstrip(" ")
			_data_top_labels[i].text = "%s ×%d ×%s" % [short_name, e["count"], Format.num(e["mult"])]
		else:
			_data_top_labels[i].text = ""

func _top_data_producers() -> Array:
	var entries := []
	for b in BuildingsDB.get_list():
		var n := Buildings.count(b["id"])
		if n <= 0: continue
		var produce := float(b.get("produces", {}).get("data", 0.0))
		if produce <= 0.0: continue
		var bmult := Research.get_building_mult(b["id"])
		entries.append({
			"name": String(b.get("name", b["id"])),
			"count": n,
			"mult": bmult,
			"contribution": produce * float(n) * bmult,
		})
	entries.sort_custom(func(a, b): return a["contribution"] > b["contribution"])
	return entries.slice(0, TOP_PRODUCERS_COUNT)

func _refresh_compute_extra() -> void:
	_compute_mult_label.text = "×%s (множ.)" % Format.num(Research.get_production_mult("compute"))
	var top := _top_compute_producers()
	for i in range(_compute_top_labels.size()):
		if i < top.size():
			var e: Dictionary = top[i]
			_compute_top_labels[i].text = "%s ×%d ×%s" % [String(e["name"]).left(7), e["count"], Format.num(e["mult"])]
		else:
			_compute_top_labels[i].text = ""

func _top_compute_producers() -> Array:
	var entries := []
	for b in BuildingsDB.get_list():
		var n := Buildings.count(b["id"])
		if n <= 0: continue
		var produce := float(b.get("produces", {}).get("compute", 0.0))
		if produce <= 0.0: continue
		var bmult := Research.get_building_mult(b["id"])
		entries.append({
			"name": String(b.get("name", b["id"])),
			"count": n,
			"mult": bmult,
			"contribution": produce * float(n) * bmult,
		})
	entries.sort_custom(func(a, b): return a["contribution"] > b["contribution"])
	return entries.slice(0, TOP_PRODUCERS_COUNT)

func _refresh_energy_extra() -> void:
	var demand_mult := Research.get_energy_demand_mult()
	if demand_mult < 1.0:
		_energy_eff_label.text = "КПД ×%s" % Format.num(demand_mult)
	else:
		_energy_eff_label.text = "+%s база" % Format.num(Research.get_base_energy_bonus())
	var top := _top_energy_producers()
	for i in range(_energy_top_labels.size()):
		if i < top.size():
			var e: Dictionary = top[i]
			_energy_top_labels[i].text = "%s +%s/с" % [String(e["name"]).left(7), Format.num(e["rate"])]
		else:
			_energy_top_labels[i].text = ""

func _top_energy_producers() -> Array:
	var entries := []
	for b in BuildingsDB.get_list():
		var n := Buildings.count(b["id"])
		if n <= 0: continue
		var produce := float(b.get("produces", {}).get("energy", 0.0))
		if produce <= 0.0: continue
		entries.append({
			"name": String(b.get("name", b["id"])),
			"count": n,
			"rate": produce * float(n),
		})
	entries.sort_custom(func(a, b): return a["rate"] > b["rate"])
	return entries.slice(0, TOP_PRODUCERS_COUNT)

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
