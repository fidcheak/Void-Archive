extends Control

const CORE_SIZE := 240.0
const TERMINAL_HEIGHT := 180.0

var _core_rect: ColorRect
var _crt_material: ShaderMaterial
var _ops_screen: Control
var _tree_screen: ResearchTreeScreen
var _prestige_screen: PrestigeScreen

func _ready() -> void:
	theme = ThemeBuilder.build()

	get_window().min_size = Vector2i(960, 600)

	_ops_screen = Control.new()
	_ops_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_ops_screen)

	var bg := ColorRect.new()
	bg.color = Palette.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ops_screen.add_child(bg)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ops_screen.add_child(layout)

	var topbar := TopBar.new()
	layout.add_child(topbar)

	var corruption_bar := CorruptionBar.new()
	layout.add_child(corruption_bar)

	var banner_holder := CenterContainer.new()
	banner_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var anomaly_banner := AnomalyBanner.new()
	banner_holder.add_child(anomaly_banner)
	layout.add_child(banner_holder)

	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(middle)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_child(center)
	center.add_child(_build_core())

	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(440, 0)
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_child(side)

	var tree_button := Button.new()
	tree_button.text = "⌬ ДЕРЕВО ИССЛЕДОВАНИЙ"
	tree_button.pressed.connect(_on_tree_button_pressed)
	side.add_child(tree_button)

	var prestige_button := Button.new()
	prestige_button.text = "⟲ ВРЕМЕННАЯ ЛИНИЯ"
	prestige_button.pressed.connect(_on_prestige_button_pressed)
	side.add_child(prestige_button)

	var buildings_panel := BuildingsPanel.new()
	buildings_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(buildings_panel)

	var terminal := TerminalPanel.new()
	terminal.custom_minimum_size = Vector2(0, TERMINAL_HEIGHT)
	layout.add_child(terminal)

	_tree_screen = ResearchTreeScreen.new()
	_tree_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tree_screen.visible = false
	_tree_screen.back_pressed.connect(_on_tree_back_pressed)
	add_child(_tree_screen)

	_prestige_screen = PrestigeScreen.new()
	_prestige_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_prestige_screen.visible = false
	_prestige_screen.back_pressed.connect(_on_prestige_back_pressed)
	add_child(_prestige_screen)

	_build_crt_overlay()

	Events.tick.connect(_on_tick)

	SaveManager.load_game()

func _on_tree_button_pressed() -> void:
	_ops_screen.visible = false
	_tree_screen.visible = true

func _on_tree_back_pressed() -> void:
	_tree_screen.visible = false
	_ops_screen.visible = true

func _on_prestige_button_pressed() -> void:
	_ops_screen.visible = false
	_prestige_screen.visible = true

func _on_prestige_back_pressed() -> void:
	_prestige_screen.visible = false
	_ops_screen.visible = true

func _on_tick(_delta: float) -> void:
	_crt_material.set_shader_parameter("corruption", GameState.corruption)

func _build_core() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(CORE_SIZE, CORE_SIZE)

	_core_rect = ColorRect.new()
	_core_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_core_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/core.gdshader")
	_core_rect.material = mat
	holder.add_child(_core_rect)

	var btn := Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(s, empty)
	btn.pressed.connect(_on_core_pressed)
	holder.add_child(btn)

	return holder

func _build_crt_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/crt.gdshader")
	overlay.material = mat
	layer.add_child(overlay)
	_crt_material = mat

func _on_core_pressed() -> void:
	GameState.add_resource("data", 1.0)
	GameState.meta["total_clicks"] = int(GameState.meta.get("total_clicks", 0)) + 1
	Events.data_gained.emit(1.0)
	if int(GameState.meta["total_clicks"]) % 10 == 0:
		Events.log_message.emit("> ФРАГМЕНТ ИЗВЛЕЧЁН [%d]" % int(GameState.meta["total_clicks"]), "sys")

	var tw := create_tween()
	tw.tween_property(_core_rect, "scale", Vector2(1.06, 1.06), 0.06).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_core_rect, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R and event.ctrl_pressed and event.shift_pressed:
		SaveManager.wipe()
