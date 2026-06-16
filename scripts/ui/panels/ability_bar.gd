class_name AbilityBar
extends VBoxContainer

const BUTTON_SIZE := 40.0

class AbilityButton:
	extends Control

	signal activate_pressed

	var ready_state := false
	var active_state := false
	var cooldown_fraction := 0.0
	var seconds_text := ""

	var _hovered := false
	var _pressed_down := false
	var _glyph_label: Label
	var _timer_label: Label

	func _ready() -> void:
		custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
		mouse_filter = Control.MOUSE_FILTER_STOP
		clip_contents = false

		_glyph_label = Label.new()
		_glyph_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_glyph_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_glyph_label.add_theme_font_size_override("font_size", 20)
		_glyph_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_glyph_label)

		_timer_label = Label.new()
		_timer_label.anchor_left = 0.0
		_timer_label.anchor_right = 1.0
		_timer_label.anchor_top = 0.6
		_timer_label.anchor_bottom = 1.0
		_timer_label.offset_left = 0.0
		_timer_label.offset_right = 0.0
		_timer_label.offset_top = 0.0
		_timer_label.offset_bottom = 0.0
		_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		_timer_label.add_theme_font_size_override("font_size", 12)
		_timer_label.add_theme_color_override("font_color", Palette.TEXT_2)
		_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_timer_label.visible = false
		add_child(_timer_label)

		mouse_entered.connect(func():
			_hovered = true
			queue_redraw())
		mouse_exited.connect(func():
			_hovered = false
			_pressed_down = false
			queue_redraw())

	func set_glyph(g: String) -> void:
		if _glyph_label:
			_glyph_label.text = g

	func refresh_display() -> void:
		_glyph_label.add_theme_color_override("font_color",
			Palette.TEXT if (ready_state or active_state) else Palette.TEXT_MUTE)
		var show_timer := cooldown_fraction > 0.0 and seconds_text != ""
		_timer_label.visible = show_timer
		if show_timer:
			_timer_label.text = seconds_text
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pressed_down = true
				queue_redraw()
			else:
				if _pressed_down and ready_state:
					activate_pressed.emit()
				_pressed_down = false
				queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 2.0
		if _pressed_down and ready_state:
			r -= 2.0

		if ready_state:
			draw_circle(c, r + 3.0, Color(Palette.AMBER_SOFT.r, Palette.AMBER_SOFT.g, Palette.AMBER_SOFT.b, 0.15))

		draw_circle(c, r, Palette.BG_PANEL_HI)

		var border_color := Palette.BORDER
		var border_width := 2.0
		if active_state:
			border_color = Palette.SIGNAL
			border_width = 3.0
		elif ready_state:
			border_color = Palette.AMBER_SOFT if _hovered else Palette.BORDER_HI
			border_width = 2.0
		draw_arc(c, r, 0.0, TAU, 48, border_color, border_width)

		if cooldown_fraction > 0.0:
			_draw_cooldown_sector(c, r)

	func _draw_cooldown_sector(c: Vector2, r: float) -> void:
		var points := PackedVector2Array()
		points.append(c)
		var start_angle := -PI / 2.0
		var end_angle := start_angle + TAU * cooldown_fraction
		var steps := maxi(2, int(48 * cooldown_fraction))
		for i in range(steps + 1):
			var t := start_angle + (end_angle - start_angle) * float(i) / float(steps)
			points.append(c + Vector2(cos(t), sin(t)) * r)
		draw_colored_polygon(points, Color(0.0, 0.0, 0.0, 0.55))

var _buttons := {}
var _acc := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 8)

	for a in AbilitiesDB.get_list():
		var col := VBoxContainer.new()
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 2)
		col.visible = false

		var btn := AbilityButton.new()
		btn.activate_pressed.connect(_on_pressed.bind(a["id"]))
		col.add_child(btn)

		var name_label := Label.new()
		name_label.text = String(a["name"])
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", Palette.TEXT_2)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(name_label)

		add_child(col)
		btn.set_glyph(_glyph_for(a))
		_buttons[a["id"]] = { "root": col, "button": btn }

	Events.tick.connect(_on_tick)
	Events.research_completed.connect(_on_research_completed)
	Events.ability_activated.connect(_on_ability_activated)

	_refresh()

func _glyph_for(def: Dictionary) -> String:
	var eff: Dictionary = def.get("effect", {})
	if eff.has("mult_production"):
		var res := String((eff["mult_production"] as Dictionary).keys()[0])
		return Labels.res_short(res).left(1)
	if eff.has("energy_add"):
		return Labels.res_short("energy").left(1)
	return "?"

func _on_pressed(id: String) -> void:
	if not Abilities.activate(id):
		return
	var aname := String(AbilitiesDB.get_def(id)["name"])
	Events.log_message.emit("> АКТИВИРОВАНО: %s" % aname, "alert")
	_refresh()

func _on_research_completed(_id: String) -> void:
	_refresh()

func _on_ability_activated(_id: String) -> void:
	_refresh()

func _on_tick(delta: float) -> void:
	_acc += delta
	if _acc < 0.1: return
	_acc = 0.0
	_refresh()

func _refresh() -> void:
	var any_unlocked := false
	for id in _buttons.keys():
		var row: Dictionary = _buttons[id]
		var root: VBoxContainer = row["root"]
		var btn: AbilityButton = row["button"]
		var def := AbilitiesDB.get_def(id)

		if not Abilities.is_unlocked(id):
			root.visible = false
			continue
		root.visible = true
		any_unlocked = true

		if Abilities.is_active(id):
			var left := float(GameState.active_abilities[id])
			btn.active_state = true
			btn.ready_state = false
			btn.cooldown_fraction = 0.0
			btn.seconds_text = "%ds" % int(ceil(left))
		elif Abilities.cooldown_left(id) > 0.0:
			var total := float(def.get("cooldown", 1.0))
			btn.active_state = false
			btn.ready_state = false
			btn.cooldown_fraction = clampf(Abilities.cooldown_left(id) / total, 0.0, 1.0)
			btn.seconds_text = "%ds" % int(ceil(Abilities.cooldown_left(id)))
		else:
			btn.active_state = false
			btn.ready_state = true
			btn.cooldown_fraction = 0.0
			btn.seconds_text = ""

		btn.refresh_display()

	visible = any_unlocked
