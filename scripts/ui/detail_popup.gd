extends CanvasLayer

const POPUP_WIDTH := 240.0
const OFFSET := Vector2(18, 18)

var _scrim: Control
var _panel: PanelContainer
var _title: Label
var _lines_box: VBoxContainer

func _ready() -> void:
	layer = 50

	_scrim = Control.new()
	_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_scrim.gui_input.connect(_on_scrim_input)
	_scrim.visible = false
	add_child(_scrim)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(POPUP_WIDTH, 0)
	_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_scrim.add_child(_panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, int(Palette.PAD))
	_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)

	_title = Label.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_color_override("font_color", Palette.AMBER)
	header.add_child(_title)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.pressed.connect(hide_popup)
	header.add_child(close_btn)

	box.add_child(HSeparator.new())

	_lines_box = VBoxContainer.new()
	_lines_box.add_theme_constant_override("separation", 2)
	box.add_child(_lines_box)

func show_at(global_pos: Vector2, title: String, lines: Array, title_color: Color = Palette.AMBER) -> void:
	_title.text = title
	_title.add_theme_color_override("font_color", title_color)

	for child in _lines_box.get_children():
		child.queue_free()
	for line in lines:
		var l := Label.new()
		l.text = String(line)
		l.add_theme_color_override("font_color", Palette.TEXT_2)
		_lines_box.add_child(l)

	_scrim.visible = true
	_panel.position = global_pos + OFFSET
	await get_tree().process_frame
	_clamp_to_viewport(global_pos)

func _clamp_to_viewport(global_pos: Vector2) -> void:
	if not _scrim.visible:
		return
	var vp_size := get_viewport().get_visible_rect().size
	var panel_size := _panel.size
	var p := global_pos + OFFSET
	p.x = clampf(p.x, Palette.EDGE, maxf(Palette.EDGE, vp_size.x - panel_size.x - Palette.EDGE))
	p.y = clampf(p.y, Palette.EDGE, maxf(Palette.EDGE, vp_size.y - panel_size.y - Palette.EDGE))
	_panel.position = p

func hide_popup() -> void:
	_scrim.visible = false

func _on_scrim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide_popup()
