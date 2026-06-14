class_name MachineRoster
extends PanelContainer

const ICON_SIZE := 48.0

var detail_overlay: Control

var _list: VBoxContainer
var _icons := {}  # id -> { "root": Control, "button": Button, "badge": Label }
var _acc := 0.0

var _detail_title: Label
var _detail_count: Label
var _detail_produces: Label
var _detail_produces_total: Label
var _detail_consumes: Label
var _detail_consumes_total: Label
var _detail_panel: PanelContainer

func _ready() -> void:
	custom_minimum_size = Vector2(110, 0)
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 8)
	scroll.add_child(margin)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.alignment = BoxContainer.ALIGNMENT_BEGIN
	_list.add_theme_constant_override("separation", 12)
	margin.add_child(_list)

	for b in BuildingsDB.get_list():
		_list.add_child(_build_icon(b))

	_build_detail_overlay()

	Events.tick.connect(_on_tick)
	Events.building_purchased.connect(_on_building_purchased)

	_refresh()

func _build_icon(b: Dictionary) -> Control:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.alignment = BoxContainer.ALIGNMENT_CENTER

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	btn.text = String(b.get("icon", "?"))
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER

	var sb := StyleBoxFlat.new()
	sb.bg_color = b.get("icon_color", Palette.AMBER)
	sb.set_corner_radius_all(8)
	for state in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(state, sb)
	btn.add_theme_color_override("font_color", Palette.BG)
	btn.add_theme_color_override("font_hover_color", Palette.BG)
	btn.add_theme_color_override("font_pressed_color", Palette.BG)

	btn.pressed.connect(_on_icon_pressed.bind(b["id"]))
	root.add_child(btn)

	var badge := Label.new()
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_color_override("font_color", Palette.TEXT_2)
	root.add_child(badge)

	root.visible = false
	_icons[b["id"]] = { "root": root, "button": btn, "badge": badge }
	return root

func _build_detail_overlay() -> void:
	detail_overlay = Control.new()
	detail_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_overlay.visible = false

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_overlay.add_child(center)

	_detail_panel = PanelContainer.new()
	_detail_panel.custom_minimum_size = Vector2(320, 0)
	_detail_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(_detail_panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 14)
	_detail_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)

	_detail_title = Label.new()
	_detail_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_title.add_theme_color_override("font_color", Palette.AMBER)
	header.add_child(_detail_title)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.pressed.connect(_on_close_pressed)
	header.add_child(close_btn)

	box.add_child(HSeparator.new())

	_detail_count = Label.new()
	box.add_child(_detail_count)

	_detail_produces = Label.new()
	_detail_produces.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_produces.add_theme_color_override("font_color", Palette.TEXT_2)
	box.add_child(_detail_produces)

	_detail_produces_total = Label.new()
	_detail_produces_total.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_detail_produces_total)

	_detail_consumes = Label.new()
	_detail_consumes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_consumes.add_theme_color_override("font_color", Palette.TEXT_2)
	box.add_child(_detail_consumes)

	_detail_consumes_total = Label.new()
	_detail_consumes_total.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_detail_consumes_total)

func _rate_text(d: Dictionary) -> String:
	var parts := PackedStringArray()
	for res_id in d.keys():
		parts.append("%s %s/сек" % [Format.num(float(d[res_id])), Labels.res_name(res_id).to_lower()])
	if parts.is_empty():
		return "—"
	return ", ".join(parts)

func _totals_text(d: Dictionary, count: int) -> String:
	var totals := {}
	for res_id in d.keys():
		totals[res_id] = float(d[res_id]) * count
	return _rate_text(totals)

func _on_icon_pressed(id: String) -> void:
	var def := Buildings.get_def(id)
	var count := Buildings.count(id)

	_detail_title.text = String(def.get("name", id))
	_detail_count.text = "Количество: %d" % count
	_detail_produces.text = "Производит (за единицу): %s" % _rate_text(def.get("produces", {}))
	_detail_produces_total.text = "Итого: %s" % _totals_text(def.get("produces", {}), count)
	_detail_consumes.text = "Потребляет (за единицу): %s" % _rate_text(def.get("consumes", {}))
	_detail_consumes_total.text = "Итого: %s" % _totals_text(def.get("consumes", {}), count)

	detail_overlay.visible = true

func _on_close_pressed() -> void:
	detail_overlay.visible = false

func _on_building_purchased(_id: String, _count: int) -> void:
	_refresh()

func _on_tick(delta: float) -> void:
	_acc += delta
	if _acc < 0.1: return
	_acc = 0.0
	_refresh()

func _refresh() -> void:
	if not is_visible_in_tree(): return
	for id in _icons.keys():
		var row: Dictionary = _icons[id]
		var count := Buildings.count(id)
		row["root"].visible = count > 0
		row["badge"].text = "×%d" % count
