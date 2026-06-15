class_name MachineRoster
extends PanelContainer

const CATEGORIES := ["Данные", "Энергия", "Вычисления"]
const CATEGORY_COLORS := {
	"Данные": Palette.AMBER,
	"Энергия": Palette.ENERGY,
	"Вычисления": Palette.COMPUTE,
}

var detail_overlay: Control

var _icons := {}  # id -> { "root": Control, "count": Label }
var _empty_labels := {}  # category -> Label
var _acc := 0.0

var _detail_title: Label
var _detail_count: Label
var _detail_produces: Label
var _detail_produces_total: Label
var _detail_consumes: Label
var _detail_consumes_total: Label
var _detail_panel: PanelContainer

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 8)
	add_child(margin)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	margin.add_child(outer)

	var header := Label.new()
	header.text = "ПОСТРОЕНО"
	header.add_theme_color_override("font_color", Palette.TEXT_DIM)
	header.add_theme_font_size_override("font_size", 11)
	outer.add_child(header)
	outer.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	outer.add_child(scroll)

	var columns := HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 12)
	scroll.add_child(columns)

	for cat in CATEGORIES:
		columns.add_child(_build_column(cat))

	_build_detail_overlay()

	Events.tick.connect(_on_tick)
	Events.building_purchased.connect(_on_building_purchased)

	_refresh()

func _build_column(category: String) -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)

	var header := Label.new()
	header.text = category.to_upper()
	header.add_theme_color_override("font_color", CATEGORY_COLORS.get(category, Palette.TEXT_DIM))
	header.add_theme_font_size_override("font_size", 11)
	col.add_child(header)
	col.add_child(HSeparator.new())

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 4)
	col.add_child(rows)

	var empty_label := Label.new()
	empty_label.text = "—"
	empty_label.add_theme_color_override("font_color", Palette.TEXT_MUTE)
	col.add_child(empty_label)
	_empty_labels[category] = empty_label

	for b in BuildingsDB.get_list():
		if b.get("category", "") == category:
			rows.add_child(_build_row(b))

	return col

func _build_icon_box(b: Dictionary) -> Control:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(20, 20)

	var sb := StyleBoxFlat.new()
	sb.bg_color = b.get("icon_color", Palette.AMBER)
	sb.set_corner_radius_all(0)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	box.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.text = String(b.get("icon", "?"))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Palette.BG)
	lbl.add_theme_font_size_override("font_size", 11)
	box.add_child(lbl)

	return box

func _build_row(b: Dictionary) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 22)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 6)
	holder.add_child(hbox)

	hbox.add_child(_build_icon_box(b))

	var name_label := Label.new()
	name_label.text = String(b.get("name", b["id"]))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 11)
	hbox.add_child(name_label)

	var count_label := Label.new()
	count_label.add_theme_color_override("font_color", Palette.TEXT_2)
	count_label.add_theme_font_size_override("font_size", 11)
	hbox.add_child(count_label)

	var btn := Button.new()
	btn.flat = true
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(s, empty)
	btn.pressed.connect(_on_icon_pressed.bind(b["id"]))
	holder.add_child(btn)

	holder.visible = false
	_icons[b["id"]] = { "root": holder, "count": count_label }
	return holder

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
		margin.add_theme_constant_override("margin_%s" % side, 8)
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
	var owned_categories := {}
	for id in _icons.keys():
		var row: Dictionary = _icons[id]
		var count := Buildings.count(id)
		row["root"].visible = count > 0
		row["count"].text = "×%d" % count
		if count > 0:
			owned_categories[BuildingsDB.get_def(id).get("category", "")] = true

	for cat in _empty_labels.keys():
		_empty_labels[cat].visible = not owned_categories.get(cat, false)
