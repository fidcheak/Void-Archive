class_name CorruptionBar
extends PanelContainer

const BAR_WIDTH := 220.0

var _label: Label
var _pct_label: Label
var _bar_bg: ColorRect
var _bar_fill: ColorRect
var _purge_button: Button

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var box := HBoxContainer.new()
	add_child(box)

	_label = Label.new()
	_label.text = "ЦЕЛОСТНОСТЬ АРХИВА:"
	_label.add_theme_color_override("font_color", Palette.AMBER)
	box.add_child(_label)

	_bar_bg = ColorRect.new()
	_bar_bg.color = Palette.LINE
	_bar_bg.custom_minimum_size = Vector2(BAR_WIDTH, 10)
	box.add_child(_bar_bg)

	_bar_fill = ColorRect.new()
	_bar_fill.color = Palette.OK
	_bar_fill.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	_bar_bg.add_child(_bar_fill)

	_pct_label = Label.new()
	box.add_child(_pct_label)

	var spacer := Label.new()
	spacer.text = "   "
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	_purge_button = Button.new()
	_purge_button.pressed.connect(_on_purge_pressed)
	box.add_child(_purge_button)

	Events.tick.connect(_on_tick)

	_refresh()

func _on_tick(_delta: float) -> void:
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

	_bar_fill.color = color
	_bar_fill.size = Vector2(BAR_WIDTH * clampf(integrity, 0.0, 1.0), 10)
	_pct_label.text = "%d%%" % int(round(integrity * 100.0))
	_pct_label.add_theme_color_override("font_color", color)

	_purge_button.text = "Стабилизировать (%s ВЫЧ)" % Format.num(Corruption.purge_cost())
	_purge_button.disabled = not Corruption.can_purge()
