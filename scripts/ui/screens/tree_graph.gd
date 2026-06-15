class_name TreeGraph
extends Control

enum NodeState { OWNED, AVAILABLE, LOCKED }

const WIDGET_PAD := 14.0
const DETAIL_WIDTH := 360.0
const ZOOM_MIN := 0.3
const ZOOM_MAX := 1.5
const ZOOM_STEP := 1.1
const FILL_ANIM_TIME := 0.4
const GRID_STEP := 64.0

var node_provider: Callable     # () -> Array[узлов]
var action_handler: Callable    # (id: String) -> bool

var pan_offset := Vector2.ZERO
var zoom := 1.0

var _content: Control
var _edges_layer: EdgesLayer
var _canvas_bg: Control
var _detail: PanelContainer
var _detail_style: StyleBoxFlat
var _detail_title: Label
var _detail_rarity: Label
var _detail_desc: Label
var _detail_effect: Label
var _detail_cost: Label
var _detail_req: Label
var _detail_state: Label
var _detail_action: Button

var _node_widgets := {}   # id -> NodeWidget
var _node_labels := {}    # id -> Label (название)
var _node_sublabels := {} # id -> Label ("X/Y")
var _nodes_by_id := {}     # id -> node dict
var _selected_id := ""
var _dragging := false
var _initialized_pan := false

# ---- кастомный узел-кружок: размер по редкости, заливка по уровню, кольцо/свечение редкости ----
class NodeWidget extends Control:
	signal pressed(id: String)

	var id := ""
	var branch_color: Color = Color.WHITE
	var rarity := "common"
	var state: int = TreeGraph.NodeState.LOCKED

	var _anim_fill := 0.0
	var _initialized := false

	func radius() -> float:
		match rarity:
			"legendary": return 27.0
			"rare": return 22.0
			_: return 18.0

	func set_data(n: Dictionary) -> void:
		id = n["id"]
		branch_color = n["color"]
		rarity = String(n.get("rarity", "common"))
		state = int(n["state"])

		var r := radius()
		var new_size := Vector2.ONE * (r + TreeGraph.WIDGET_PAD) * 2.0
		if size != new_size:
			size = new_size
			pivot_offset = size / 2.0

		var target := 0.0
		if n.has("level"):
			var max_lvl := maxi(int(n.get("max_level", 1)), 1)
			target = float(int(n["level"])) / float(max_lvl)
		elif state == TreeGraph.NodeState.OWNED:
			target = 1.0

		if not _initialized:
			_anim_fill = target
			_initialized = true
		elif not is_equal_approx(target, _anim_fill):
			var t := create_tween()
			t.tween_method(_set_anim_fill, _anim_fill, target, TreeGraph.FILL_ANIM_TIME) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		queue_redraw()

	func _set_anim_fill(v: float) -> void:
		_anim_fill = v
		queue_redraw()

	func _draw() -> void:
		var c := size / 2.0
		var r := radius()
		var dim := state == TreeGraph.NodeState.LOCKED

		# 1) свечение редкости (за кругом)
		if rarity == "legendary":
			draw_circle(c, r + 9.0, Color(Palette.RARITY_LEGENDARY, 0.12 if not dim else 0.04))
			draw_circle(c, r + 4.0, Color(Palette.RARITY_LEGENDARY, 0.18 if not dim else 0.06))
		elif rarity == "rare":
			draw_circle(c, r + 5.0, Color(Palette.RARITY_RARE, 0.14 if not dim else 0.05))

		# 2) тёмный «пустой» шар
		draw_circle(c, r, Palette.NODE_BG)

		# 3) жидкая заливка по уровню (снизу), обрезанная кругом
		var frac := clampf(_anim_fill, 0.0, 1.0)
		if frac > 0.0:
			var fill_col := branch_color if not dim else Color(branch_color, 0.35)
			var fill_h := frac * (2.0 * r)
			var top_y := c.y + r - fill_h
			var yy := int(ceil(top_y))
			var bottom := int(c.y + r)
			while yy < bottom:
				var dy := float(yy) - c.y
				var hw := sqrt(maxf(0.0, r * r - dy * dy))
				draw_line(Vector2(c.x - hw, float(yy)), Vector2(c.x + hw, float(yy)), fill_col, 1.0)
				yy += 1

		# 4) кольцо редкости
		var ring_col := branch_color
		var ring_w := 2.0
		match rarity:
			"rare":
				ring_col = Palette.RARITY_RARE
				ring_w = 3.0
			"legendary":
				ring_col = Palette.RARITY_LEGENDARY
				ring_w = 3.0
		if dim:
			ring_col = Color(ring_col, 0.4)
		draw_arc(c, r, 0.0, TAU, 48, ring_col, ring_w, true)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			pressed.emit(id)
			accept_event()

class EdgesLayer extends Control:
	var edges: Array = []  # Array of { "a": Vector2, "b": Vector2, "color": Color } — базовые координаты узлов
	var pan_offset := Vector2.ZERO
	var zoom := 1.0

	func _draw() -> void:
		_draw_grid()
		for e in edges:
			var a: Vector2 = e["a"] * zoom + pan_offset
			var b: Vector2 = e["b"] * zoom + pan_offset
			var pts := _bezier(a, b)
			var col: Color = e["color"]
			# псевдо-glow под основной линией
			draw_polyline(pts, Color(col.r, col.g, col.b, col.a * 0.25), maxf(2.0, 6.0 * zoom), true)
			draw_polyline(pts, Color(col.r, col.g, col.b, col.a), maxf(1.0, 2.0 * zoom), true)

	func _draw_grid() -> void:
		var step := TreeGraph.GRID_STEP * zoom
		if step < 8.0:
			return
		var col := Color(Palette.LINE, 0.25)
		var start_x := fposmod(pan_offset.x, step)
		var start_y := fposmod(pan_offset.y, step)
		var x := start_x
		while x < size.x:
			draw_line(Vector2(x, 0.0), Vector2(x, size.y), col, 1.0)
			x += step
		var y := start_y
		while y < size.y:
			draw_line(Vector2(0.0, y), Vector2(size.x, y), col, 1.0)
			y += step

	func _bezier(a: Vector2, b: Vector2) -> PackedVector2Array:
		var c1 := a + Vector2(0, (b.y - a.y) * 0.5)
		var c2 := b - Vector2(0, (b.y - a.y) * 0.5)
		var pts := PackedVector2Array()
		for i in 17:
			var t := float(i) / 16.0
			pts.append(a.bezier_interpolate(c1, c2, b, t))
		return pts

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var root := HBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var viewport := Control.new()
	viewport.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport.clip_contents = true
	root.add_child(viewport)

	var bg := ColorRect.new()
	bg.color = Palette.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport.add_child(bg)

	_canvas_bg = Control.new()
	_canvas_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas_bg.gui_input.connect(_on_canvas_input)
	_canvas_bg.resized.connect(_on_canvas_resized)
	viewport.add_child(_canvas_bg)

	_edges_layer = EdgesLayer.new()
	_edges_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_edges_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_edges_layer.clip_contents = false
	_canvas_bg.add_child(_edges_layer)

	_content = Control.new()
	_canvas_bg.add_child(_content)

	_detail = _build_detail_panel()
	root.add_child(_detail)

func build() -> void:
	for c in _content.get_children():
		c.queue_free()
	_node_widgets.clear()
	_node_labels.clear()
	_node_sublabels.clear()

	var nodes: Array = node_provider.call()
	for n in nodes:
		_create_node(n)

	refresh()

func refresh() -> void:
	var nodes: Array = node_provider.call()
	_nodes_by_id.clear()
	for n in nodes:
		_nodes_by_id[n["id"]] = n
		_apply_node_style(n)

	_rebuild_edges(nodes)
	_reposition_nodes()

	if _detail.visible and _nodes_by_id.has(_selected_id):
		_update_detail(_nodes_by_id[_selected_id])

func _create_node(n: Dictionary) -> void:
	var widget := NodeWidget.new()
	widget.mouse_filter = Control.MOUSE_FILTER_STOP
	widget.pressed.connect(_on_node_pressed)
	_content.add_child(widget)
	_node_widgets[n["id"]] = widget

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(label)
	_node_labels[n["id"]] = label

	var sub := Label.new()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", Palette.TEXT_3)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(sub)
	_node_sublabels[n["id"]] = sub

func _node_screen_pos(base: Vector2) -> Vector2:
	return base * zoom + pan_offset

func _reposition_nodes() -> void:
	for id in _nodes_by_id:
		var n: Dictionary = _nodes_by_id[id]
		var screen := _node_screen_pos(n["pos"])

		var widget: NodeWidget = _node_widgets[id]
		widget.pivot_offset = widget.size / 2.0
		widget.position = screen - widget.size / 2.0
		widget.scale = Vector2(zoom, zoom)

		var r := widget.size.x / 2.0

		var label: Label = _node_labels[id]
		label.size = Vector2(120, 20) * zoom
		label.position = screen + Vector2(-60 * zoom, r * zoom + 2 * zoom)

		var sub: Label = _node_sublabels[id]
		sub.size = Vector2(120, 16) * zoom
		sub.position = screen + Vector2(-60 * zoom, r * zoom + 18 * zoom)

func _apply_transform() -> void:
	_edges_layer.pan_offset = pan_offset
	_edges_layer.zoom = zoom
	_edges_layer.queue_redraw()
	_reposition_nodes()

const RARITY_NAMES := { "common": "Обычная", "rare": "Редкая", "legendary": "Легендарная" }
const RARITY_COLORS := { "common": Palette.TEXT_3, "rare": Palette.RARITY_RARE, "legendary": Palette.RARITY_LEGENDARY }

func _apply_node_style(n: Dictionary) -> void:
	var widget: NodeWidget = _node_widgets[n["id"]]
	widget.set_data(n)

	var state := int(n["state"])
	var label: Label = _node_labels[n["id"]]
	label.text = String(n["title"])
	match state:
		NodeState.OWNED:
			label.add_theme_color_override("font_color", n["color"])
		NodeState.AVAILABLE:
			label.add_theme_color_override("font_color", Palette.TEXT)
		_:
			label.add_theme_color_override("font_color", Palette.TEXT_3)

	var sub: Label = _node_sublabels[n["id"]]
	if n.has("level"):
		sub.text = "%d/%d" % [int(n["level"]), int(n.get("max_level", 1))]
		sub.visible = true
	else:
		sub.visible = false

func _rebuild_edges(nodes: Array) -> void:
	var by_id := {}
	for n in nodes:
		by_id[n["id"]] = n

	var edges := []
	for n in nodes:
		for p in n.get("requires", []):
			if by_id.has(p):
				var alpha := 0.9 if int(n["state"]) == NodeState.OWNED else 0.35
				edges.append({ "a": by_id[p]["pos"], "b": n["pos"], "color": Color(n["color"], alpha) })

	_edges_layer.edges = edges
	_edges_layer.pan_offset = pan_offset
	_edges_layer.zoom = zoom
	_edges_layer.queue_redraw()

func _on_canvas_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed and _detail.visible:
			_detail.visible = false
			_selected_id = ""
	elif event is InputEventMouseMotion and _dragging:
		pan_offset += event.relative
		_apply_transform()
	elif event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		var old_zoom := zoom
		zoom = clampf(zoom * (ZOOM_STEP if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / ZOOM_STEP), ZOOM_MIN, ZOOM_MAX)
		var m := _canvas_bg.get_local_mouse_position()
		pan_offset = m - (m - pan_offset) * (zoom / old_zoom)
		_apply_transform()

func _on_canvas_resized() -> void:
	if _initialized_pan:
		return
	_initialized_pan = true
	pan_offset = _canvas_bg.size / 2.0 + Vector2(0, _canvas_bg.size.y * 0.3)
	_apply_transform()

func _on_node_pressed(id: String) -> void:
	if not _nodes_by_id.has(id):
		return
	_selected_id = id
	_update_detail(_nodes_by_id[id])
	_detail.visible = true

func _on_close_pressed() -> void:
	_detail.visible = false
	_selected_id = ""

func _on_action_pressed() -> void:
	if _selected_id == "":
		return
	if action_handler.call(_selected_id):
		refresh()

func _build_detail_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(DETAIL_WIDTH, 0)
	panel.visible = false

	_detail_style = StyleBoxFlat.new()
	_detail_style.bg_color = Palette.SURFACE
	_detail_style.border_color = Palette.LINE
	_detail_style.set_border_width_all(2)
	_detail_style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", _detail_style)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 8)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)

	_detail_title = Label.new()
	_detail_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(_detail_title)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.pressed.connect(_on_close_pressed)
	header.add_child(close_btn)

	box.add_child(HSeparator.new())

	_detail_rarity = Label.new()
	_detail_rarity.add_theme_font_size_override("font_size", 12)
	box.add_child(_detail_rarity)

	_detail_desc = Label.new()
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc.add_theme_color_override("font_color", Palette.TEXT_2)
	box.add_child(_detail_desc)

	_detail_effect = Label.new()
	_detail_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_detail_effect)

	_detail_cost = Label.new()
	_detail_cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_cost.add_theme_color_override("font_color", Palette.COMPUTE)
	box.add_child(_detail_cost)

	_detail_req = Label.new()
	_detail_req.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_req.add_theme_color_override("font_color", Palette.TEXT_3)
	box.add_child(_detail_req)

	_detail_state = Label.new()
	box.add_child(_detail_state)

	_detail_action = Button.new()
	_detail_action.pressed.connect(_on_action_pressed)
	box.add_child(_detail_action)

	return panel

func _update_detail(n: Dictionary) -> void:
	var color: Color = n["color"]
	_detail_title.text = String(n["title"])
	_detail_title.add_theme_color_override("font_color", color)

	var rarity := String(n.get("rarity", "common"))
	_detail_rarity.text = "Редкость: %s" % String(RARITY_NAMES.get(rarity, "Обычная"))
	_detail_rarity.add_theme_color_override("font_color", RARITY_COLORS.get(rarity, Palette.TEXT_3))
	_detail_style.border_color = RARITY_COLORS.get(rarity, Palette.LINE) if rarity != "common" else color

	_detail_desc.text = String(n.get("desc", ""))
	_detail_effect.text = "Эффект: %s" % String(n.get("effect_text", "—"))
	_detail_cost.text = "Стоимость: %s" % String(n.get("cost_text", "—"))

	var state := int(n["state"])
	var req_text := String(n.get("req_text", ""))
	_detail_req.visible = state == NodeState.LOCKED and req_text != ""
	_detail_req.text = "Требуется: %s" % req_text

	match state:
		NodeState.OWNED:
			if n.has("level") and int(n["level"]) < int(n.get("max_level", 1)):
				_detail_state.text = "СОСТОЯНИЕ: В ПРОЦЕССЕ (%d/%d)" % [int(n["level"]), int(n.get("max_level", 1))]
				_detail_state.add_theme_color_override("font_color", color)
			else:
				_detail_state.text = "СОСТОЯНИЕ: МАКСИМУМ" if n.has("level") else "СОСТОЯНИЕ: ПОЛУЧЕНО"
				_detail_state.add_theme_color_override("font_color", Palette.OK)
		NodeState.AVAILABLE:
			_detail_state.text = "СОСТОЯНИЕ: ДОСТУПНО"
			_detail_state.add_theme_color_override("font_color", color)
		_:
			_detail_state.text = "СОСТОЯНИЕ: ЗАБЛОКИРОВАНО"
			_detail_state.add_theme_color_override("font_color", Palette.TEXT_3)

	var can_act := bool(n.get("can_act", state == NodeState.AVAILABLE))
	_detail_action.text = String(n.get("action_label", ""))
	_detail_action.disabled = not can_act
	_detail_action.modulate.a = 1.0 if can_act else 0.5
