class_name ResearchTreeScreen
extends Control

signal back_pressed

const NODE_SIZE := 56.0

var _tree_content: TreeCanvas
var _canvas_bg: Control
var _compute_label: Label
var _node_buttons := {}  # id -> Button
var _node_labels := {}   # id -> Label
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

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)

	layout.add_child(_build_header())

	var viewport := Control.new()
	viewport.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport.clip_contents = true
	layout.add_child(viewport)

	_canvas_bg = Control.new()
	_canvas_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas_bg.gui_input.connect(_on_canvas_input)
	_canvas_bg.resized.connect(_on_canvas_resized)
	viewport.add_child(_canvas_bg)

	_tree_content = TreeCanvas.new()
	_canvas_bg.add_child(_tree_content)

	_build_tree()

	Events.research_completed.connect(_on_research_completed)
	Events.resource_changed.connect(_on_resource_changed)
	visibility_changed.connect(_on_visibility_changed)

	_refresh_all()

func _build_header() -> Control:
	var panel := PanelContainer.new()

	var box := HBoxContainer.new()
	panel.add_child(box)

	var back_btn := Button.new()
	back_btn.text = "← НАЗАД"
	back_btn.pressed.connect(func(): back_pressed.emit())
	box.add_child(back_btn)

	var title := Label.new()
	title.text = "ДЕРЕВО ИССЛЕДОВАНИЙ"
	title.add_theme_color_override("font_color", Palette.AMBER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var compute_name := Label.new()
	compute_name.text = "ВЫЧИСЛЕНИЯ:"
	compute_name.add_theme_color_override("font_color", Palette.COMPUTE)
	box.add_child(compute_name)

	_compute_label = Label.new()
	box.add_child(_compute_label)

	return panel

func _build_tree() -> void:
	for r in ResearchDB.get_list():
		var pos: Vector2 = r["pos"]

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(NODE_SIZE, NODE_SIZE)
		btn.size = Vector2(NODE_SIZE, NODE_SIZE)
		btn.position = pos - Vector2(NODE_SIZE, NODE_SIZE) / 2.0
		btn.clip_text = true
		btn.pressed.connect(_on_node_pressed.bind(r["id"]))
		_tree_content.add_child(btn)
		_node_buttons[r["id"]] = btn

		var label := Label.new()
		label.position = pos + Vector2(-60, NODE_SIZE / 2.0 + 4)
		label.size = Vector2(120, 40)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 12)
		_tree_content.add_child(label)
		_node_labels[r["id"]] = label

func _on_canvas_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		_tree_content.position += event.relative

func _on_canvas_resized() -> void:
	if _initialized_pan:
		return
	_initialized_pan = true
	_tree_content.position = _canvas_bg.size / 2.0 + Vector2(0, _canvas_bg.size.y * 0.3)

func _on_node_pressed(id: String) -> void:
	if not Research.research(id):
		return
	var rname := String(Research.get_def(id)["name"])
	Events.log_message.emit("> ТЕХНОЛОГИЯ ВНЕДРЕНА: %s" % rname, "sys")
	_refresh_all()

func _on_research_completed(_id: String) -> void:
	_refresh_all()

func _on_resource_changed(_id: String, _value: float) -> void:
	_refresh_all()

func _on_visibility_changed() -> void:
	if visible:
		_refresh_all()

func _refresh_all() -> void:
	_compute_label.text = Format.num(GameState.get_resource("compute"))

	var branch_colors := {}
	for b in ResearchDB.get_branches():
		branch_colors[b["id"]] = b["color"]

	var defs := {}
	for r in ResearchDB.get_list():
		defs[r["id"]] = r

	var edges := []
	for r in ResearchDB.get_list():
		var branch_color: Color = branch_colors.get(r["branch"], Palette.TEXT_3)
		_refresh_node(r["id"], branch_color)
		for p in r.get("requires", []):
			if defs.has(p):
				var alpha := 0.9 if Research.is_owned(r["id"]) else 0.35
				edges.append({ "a": defs[p]["pos"], "b": r["pos"], "color": Color(branch_color, alpha) })

	_tree_content.edges = edges
	_tree_content.queue_redraw()

func _refresh_node(id: String, branch_color: Color) -> void:
	var def := Research.get_def(id)
	var btn: Button = _node_buttons[id]
	var label: Label = _node_labels[id]

	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(int(NODE_SIZE / 2.0))

	if def.get("stub", false):
		sb.bg_color = Palette.SURFACE
		sb.border_color = Palette.LINE
		sb.set_border_width_all(2)
		btn.text = "🔒"
		btn.disabled = true
		btn.modulate.a = 0.5
		label.add_theme_color_override("font_color", Palette.TEXT_3)
	elif Research.is_owned(id):
		sb.bg_color = branch_color
		btn.text = "✓"
		btn.disabled = true
		btn.modulate.a = 1.0
		label.add_theme_color_override("font_color", branch_color)
	elif Research.is_available(id):
		sb.bg_color = Palette.SURFACE_2
		sb.border_color = branch_color
		sb.set_border_width_all(3)
		btn.text = ""
		btn.disabled = false
		btn.modulate.a = 1.0 if Research.can_afford(id) else 0.6
		label.add_theme_color_override("font_color", Palette.TEXT)
	else:
		sb.bg_color = Palette.SURFACE
		sb.border_color = Palette.LINE
		sb.set_border_width_all(2)
		btn.text = ""
		btn.disabled = true
		btn.modulate.a = 0.5
		label.add_theme_color_override("font_color", Palette.TEXT_3)

	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		btn.add_theme_stylebox_override(state, sb)

	btn.tooltip_text = _tooltip_text(def)
	label.text = String(def.get("name", id))

func _tooltip_text(def: Dictionary) -> String:
	var lines := PackedStringArray()
	lines.append(String(def.get("name", "")))
	lines.append(String(def.get("desc", "")))
	var cost: Dictionary = def.get("cost", {})
	if not cost.is_empty():
		var parts := PackedStringArray()
		for res_id in cost.keys():
			parts.append("%s %s" % [Format.num(cost[res_id]), _res_short(res_id)])
		lines.append("Цена: " + ", ".join(parts))
	return "\n".join(lines)

func _res_short(res_id: String) -> String:
	var defs := ResourcesDB.get_defs()
	if defs.has(res_id):
		return String(defs[res_id]["short"])
	return res_id
