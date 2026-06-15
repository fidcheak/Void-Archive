class_name AbilityBar
extends PanelContainer

const BUTTON_SIZE := 56.0

class AbilityButton:
	extends Control

	signal activate_pressed

	var glyph := ""
	var ready_state := false
	var active_state := false
	var cooldown_fraction := 0.0  # 1.0 = только начался откат, 0.0 = готово
	var seconds_text := ""

	var _hovered := false
	var _pressed_down := false

	func _ready() -> void:
		custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_entered.connect(func():
			_hovered = true
			queue_redraw())
		mouse_exited.connect(func():
			_hovered = false
			_pressed_down = false
			queue_redraw())

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

		var font := ThemeBuilder.mono_font()
		var glyph_color := Palette.TEXT if (ready_state or active_state) else Palette.TEXT_MUTE
		var fs := 22
		var ts := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(font, Vector2(c.x - ts.x * 0.5, c.y + ts.y * 0.3), glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, glyph_color)

		if cooldown_fraction > 0.0:
			_draw_cooldown_sector(c, r)
			if seconds_text != "":
				var fs2 := 12
				var ts2 := font.get_string_size(seconds_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs2)
				draw_string(font, Vector2(c.x - ts2.x * 0.5, c.y + r * 0.65 + ts2.y * 0.3), seconds_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs2, Palette.TEXT_2)

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

var _buttons := {}  # id -> AbilityButton
var _acc := 0.0

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var box := HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	add_child(box)

	for a in AbilitiesDB.get_list():
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 2)
		col.visible = false

		var btn := AbilityButton.new()
		btn.glyph = _glyph_for(a)
		btn.activate_pressed.connect(_on_pressed.bind(a["id"]))
		col.add_child(btn)

		var name_label := Label.new()
		name_label.text = String(a["name"])
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", Palette.TEXT_2)
		col.add_child(name_label)

		box.add_child(col)
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

		btn.queue_redraw()

	visible = any_unlocked
