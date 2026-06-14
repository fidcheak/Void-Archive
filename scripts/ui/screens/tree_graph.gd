class_name TreeGraph
extends Control

enum NodeState { OWNED, AVAILABLE, LOCKED }

const NODE_SIZE := 56.0
const DETAIL_WIDTH := 360.0

var node_provider: Callable     # () -> Array[узлов]
var action_handler: Callable    # (id: String) -> bool

var _content: TreeCanvas
var _canvas_bg: Control
var _detail: PanelContainer
var _detail_title: Label
var _detail_desc: Label
var _detail_effect: Label
var _detail_cost: Label
var _detail_req: Label
var _detail_state: Label
var _detail_action: Button

var _node_buttons := {}   # id -> Button
var _node_labels := {}    # id -> Label
var _nodes_by_id := {}     # id -> node dict
var _selected_id := ""
var _dragging := false
var _initialized_pan := false

class TreeCanvas extends Control:
	var edges: Array = []  # Array of { "a": Vector2, "b": Vector2, "color": Color }

	func _draw() -> void:
		for e in edges:
			draw_polyline(_bezier(e["a"], e["b"]), e["color"], 3.0, true)

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

	_canvas_bg = Control.new()
	_canvas_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas_bg.gui_input.connect(_on_canvas_input)
	_canvas_bg.resized.connect(_on_canvas_resized)
	viewport.add_child(_canvas_bg)

	_content = TreeCanvas.new()
	_canvas_bg.add_child(_content)

	_detail = _build_detail_panel()
	root.add_child(_detail)

func build() -> void:
	for c in _content.get_children():
		c.queue_free()
	_node_buttons.clear()
	_node_labels.clear()

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

	if _detail.visible and _nodes_by_id.has(_selected_id):
		_update_detail(_nodes_by_id[_selected_id])

func _create_node(n: Dictionary) -> void:
	var pos: Vector2 = n["pos"]

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(NODE_SIZE, NODE_SIZE)
	btn.size = Vector2(NODE_SIZE, NODE_SIZE)
	btn.position = pos - Vector2(NODE_SIZE, NODE_SIZE) / 2.0
	btn.clip_text = true
	btn.pressed.connect(_on_node_pressed.bind(n["id"]))
	_content.add_child(btn)
	_node_buttons[n["id"]] = btn

	var label := Label.new()
	label.position = pos + Vector2(-60, NODE_SIZE / 2.0 + 4)
	label.size = Vector2(120, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	_content.add_child(label)
	_node_labels[n["id"]] = label

func _apply_node_style(n: Dictionary) -> void:
	var btn: Button = _node_buttons[n["id"]]
	var label: Label = _node_labels[n["id"]]
	var color: Color = n["color"]

	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(int(NODE_SIZE / 2.0))

	match int(n["state"]):
		NodeState.OWNED:
			sb.bg_color = color
			btn.text = "✓"
			btn.modulate.a = 1.0
			label.add_theme_color_override("font_color", color)
		NodeState.AVAILABLE:
			sb.bg_color = Palette.SURFACE_2
			sb.border_color = color
			sb.set_border_width_all(3)
			btn.text = ""
			btn.modulate.a = 1.0
			label.add_theme_color_override("font_color", Palette.TEXT)
		_:
			sb.bg_color = Palette.SURFACE
			sb.border_color = Palette.LINE
			sb.set_border_width_all(2)
			btn.text = ""
			btn.modulate.a = 0.5
			label.add_theme_color_override("font_color", Palette.TEXT_3)

	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		btn.add_theme_stylebox_override(state, sb)

	label.text = String(n["title"])

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

	_content.edges = edges
	_content.queue_redraw()

func _on_canvas_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed and _detail.visible:
			_detail.visible = false
			_selected_id = ""
	elif event is InputEventMouseMotion and _dragging:
		_content.position += event.relative

func _on_canvas_resized() -> void:
	if _initialized_pan:
		return
	_initialized_pan = true
	_content.position = _canvas_bg.size / 2.0 + Vector2(0, _canvas_bg.size.y * 0.3)

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

	_detail_desc.text = String(n.get("desc", ""))
	_detail_effect.text = "Эффект: %s" % String(n.get("effect_text", "—"))
	_detail_cost.text = "Стоимость: %s" % String(n.get("cost_text", "—"))

	var state := int(n["state"])
	var req_text := String(n.get("req_text", ""))
	_detail_req.visible = state == NodeState.LOCKED and req_text != ""
	_detail_req.text = "Требуется: %s" % req_text

	match state:
		NodeState.OWNED:
			_detail_state.text = "СОСТОЯНИЕ: ПОЛУЧЕНО"
			_detail_state.add_theme_color_override("font_color", Palette.OK)
		NodeState.AVAILABLE:
			_detail_state.text = "СОСТОЯНИЕ: ДОСТУПНО"
			_detail_state.add_theme_color_override("font_color", color)
		_:
			_detail_state.text = "СОСТОЯНИЕ: ЗАБЛОКИРОВАНО"
			_detail_state.add_theme_color_override("font_color", Palette.TEXT_3)

	_detail_action.text = String(n.get("action_label", ""))
	_detail_action.disabled = state != NodeState.AVAILABLE
	_detail_action.modulate.a = 1.0 if state == NodeState.AVAILABLE else 0.5
