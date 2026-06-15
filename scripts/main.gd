extends Control

const CORE_SIZE := 240.0
const TERMINAL_HEIGHT := 180.0

var _core_rect: ColorRect
var _crt_material: ShaderMaterial
var _ops_screen: Control
var _tree_screen: ResearchTreeScreen
var _prestige_screen: PrestigeScreen
var _mining_screen: MiningScreen
var _floating: FloatingText

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
	topbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topbar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	layout.add_child(topbar)
	topbar.add_nav_button("⌬", "Дерево исследований", _on_tree_button_pressed)
	topbar.add_nav_button("⟲", "Временная линия", _on_prestige_button_pressed)

	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(middle)

	# слот крипты всегда зарезервирован (300px) — даже когда крипта скрыта,
	# чтобы её появление/исчезновение не двигало правую панель
	var crypto_slot := Control.new()
	crypto_slot.custom_minimum_size = Vector2(300, 0)
	crypto_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_child(crypto_slot)

	var crypto_tracker := CryptoTracker.new()
	crypto_tracker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crypto_tracker.mining_pressed.connect(_on_mining_button_pressed)
	crypto_slot.add_child(crypto_tracker)

	var center_col := VBoxContainer.new()
	center_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_child(center_col)

	var anomaly_banner := AnomalyBanner.new()
	center_col.add_child(anomaly_banner)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_col.add_child(center)
	center.add_child(_build_core())

	var ability_bar := AbilityBar.new()
	center_col.add_child(ability_bar)

	var click_panel := ClickPanel.new()
	click_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center_col.add_child(click_panel)

	var corruption_bar := CorruptionBar.new()
	center_col.add_child(corruption_bar)

	var build_area := HBoxContainer.new()
	build_area.custom_minimum_size = Vector2(620, 0)
	build_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_child(build_area)

	var machine_roster := MachineRoster.new()
	build_area.add_child(machine_roster)
	_ops_screen.add_child(machine_roster.detail_overlay)

	var buildings_panel := BuildingsPanel.new()
	build_area.add_child(buildings_panel)

	var terminal := TerminalPanel.new()
	terminal.custom_minimum_size = Vector2(0, TERMINAL_HEIGHT)
	terminal.size_flags_vertical = Control.SIZE_SHRINK_END
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

	_mining_screen = MiningScreen.new()
	_mining_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mining_screen.visible = false
	_mining_screen.back_pressed.connect(_on_mining_back_pressed)
	add_child(_mining_screen)

	_floating = FloatingText.new()
	_floating.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_floating.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ops_screen.add_child(_floating)

	_build_crt_overlay()

	Events.tick.connect(_on_tick)
	Events.click_performed.connect(_on_click_performed)

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

func _on_mining_button_pressed() -> void:
	if not GameState.flags.get("crypto_unlocked", false): return
	_ops_screen.visible = false
	_mining_screen.visible = true

func _on_mining_back_pressed() -> void:
	_mining_screen.visible = false
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

func _core_global_center() -> Vector2:
	return _core_rect.get_global_rect().get_center()

func _on_click_performed(amount: float, is_auto: bool) -> void:
	if not _ops_screen.is_visible_in_tree():
		return
	if is_auto:
		var c := _core_global_center() + Vector2(randf_range(-20.0, 20.0), randf_range(-10.0, 10.0))
		_floating.spawn("+" + Format.num(amount), c)

func _on_core_pressed() -> void:
	var amt := Clicker.do_click()
	GameState.meta["total_clicks"] = int(GameState.meta.get("total_clicks", 0)) + 1
	Events.data_gained.emit(amt)
	if int(GameState.meta["total_clicks"]) % 10 == 0:
		Events.log_message.emit("> ФРАГМЕНТ ИЗВЛЕЧЁН [%d]" % int(GameState.meta["total_clicks"]), "sys")

	_floating.spawn("+" + Format.num(amt), get_global_mouse_position())

	var tw := create_tween()
	tw.tween_property(_core_rect, "scale", Vector2(1.06, 1.06), 0.06).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_core_rect, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R and event.ctrl_pressed and event.shift_pressed:
		SaveManager.wipe()
