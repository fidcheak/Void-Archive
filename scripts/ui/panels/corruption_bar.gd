class_name CorruptionBar
extends PanelContainer

const BAR_HEIGHT := 14.0

var _label: Label
var _pct_label: Label
var _bar: ProgressBar
var _fill_style: StyleBoxFlat
var _purge_button: Button
var _acc := 0.0

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 6)
	add_child(margin)

	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	_label = Label.new()
	_label.text = "ЦЕЛОСТНОСТЬ АРХИВА:"
	_label.add_theme_color_override("font_color", Palette.AMBER)
	box.add_child(_label)

	_bar = ProgressBar.new()
	_bar.min_value = 0.0
	_bar.max_value = 100.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, BAR_HEIGHT)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Palette.LINE
	bg_style.set_corner_radius_all(int(BAR_HEIGHT / 2.0))
	_bar.add_theme_stylebox_override("background", bg_style)

	_fill_style = StyleBoxFlat.new()
	_fill_style.bg_color = Palette.OK
	_fill_style.set_corner_radius_all(int(BAR_HEIGHT / 2.0))
	_bar.add_theme_stylebox_override("fill", _fill_style)

	box.add_child(_bar)

	_pct_label = Label.new()
	box.add_child(_pct_label)

	_purge_button = Button.new()
	_purge_button.pressed.connect(_on_purge_pressed)
	box.add_child(_purge_button)

	Events.tick.connect(_on_tick)

	_refresh()

func _on_tick(delta: float) -> void:
	_acc += delta
	if _acc < 0.1: return
	_acc = 0.0
	_refresh()

func _on_purge_pressed() -> void:
	Corruption.purge()
	_refresh()

func _refresh() -> void:
	var corruption := GameState.corruption
	var integrity := 1.0 - corruption

	var color := Palette.OK
	if corruption >= 0.5:
		color = Palette.WARN.lerp(Palette.CORRUPT, (corruption - 0.5) / 0.5)
	elif corruption > 0.0:
		color = Palette.OK.lerp(Palette.WARN, corruption / 0.5)

	_fill_style.bg_color = color
	_bar.value = integrity * 100.0
	_pct_label.text = "%d%%" % int(round(integrity * 100.0))
	_pct_label.add_theme_color_override("font_color", color)

	_purge_button.text = "Стабилизировать (%s %s)" % [Format.num(Corruption.purge_cost()), Labels.res_short("compute")]
	_purge_button.disabled = not Corruption.can_purge()
