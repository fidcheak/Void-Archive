class_name AnomalyBanner
extends PanelContainer

const BAR_WIDTH := 220.0
const SLOT_HEIGHT := 34.0

var _name_label: Label
var _effect_label: Label
var _time_label: Label
var _bar_bg: ColorRect
var _bar_fill: ColorRect
var _acc := 0.0

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	custom_minimum_size = Vector2(0, SLOT_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var box := HBoxContainer.new()
	add_child(box)

	_name_label = Label.new()
	box.add_child(_name_label)

	_effect_label = Label.new()
	_effect_label.add_theme_color_override("font_color", Palette.TEXT_2)
	box.add_child(_effect_label)

	_bar_bg = ColorRect.new()
	_bar_bg.color = Palette.LINE
	_bar_bg.custom_minimum_size = Vector2(BAR_WIDTH, 6)
	box.add_child(_bar_bg)

	_bar_fill = ColorRect.new()
	_bar_fill.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	_bar_bg.add_child(_bar_fill)

	_time_label = Label.new()
	box.add_child(_time_label)

	Events.tick.connect(_on_tick)
	Events.anomaly_started.connect(_on_anomaly_started)
	Events.anomaly_ended.connect(_on_anomaly_ended)

	_refresh()

func _on_tick(delta: float) -> void:
	_acc += delta
	if _acc < 0.1: return
	_acc = 0.0
	_refresh()

func _on_anomaly_started(_id: String) -> void:
	_refresh()

func _on_anomaly_ended(_id: String) -> void:
	_refresh()

func _refresh() -> void:
	var anomaly := GameState.active_anomaly
	if anomaly.is_empty():
		modulate.a = 0.0
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		return

	modulate.a = 1.0
	mouse_filter = Control.MOUSE_FILTER_PASS

	var color: Color = Palette.SIGNAL if anomaly.get("type", "") == "signal" else Palette.CORRUPT

	_name_label.text = String(anomaly.get("name", ""))
	_name_label.add_theme_color_override("font_color", color)

	var mult := float(anomaly.get("mult", 1.0))
	_effect_label.text = "×%.1f производство" % mult

	var duration := float(anomaly.get("duration", 1.0))
	var time_left := float(anomaly.get("time_left", 0.0))
	_time_label.text = "%ds" % int(ceil(maxf(time_left, 0.0)))

	_bar_fill.color = color
	var frac := clampf(time_left / duration, 0.0, 1.0) if duration > 0.0 else 0.0
	_bar_fill.size = Vector2(BAR_WIDTH * frac, 6)
