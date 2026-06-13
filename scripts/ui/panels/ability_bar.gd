class_name AbilityBar
extends PanelContainer

var _buttons := {}  # id -> Button

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var box := HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	for a in AbilitiesDB.get_list():
		var btn := Button.new()
		btn.visible = false
		btn.pressed.connect(_on_pressed.bind(a["id"]))
		box.add_child(btn)
		_buttons[a["id"]] = btn

	Events.tick.connect(_on_tick)
	Events.research_completed.connect(_on_research_completed)
	Events.ability_activated.connect(_on_ability_activated)

	_refresh()

func _on_pressed(id: String) -> void:
	if not Abilities.activate(id):
		return
	var aname := String(AbilitiesDB.get_def(id)["name"])
	Events.log_message.emit("> АКТИВИРОВАНО: %s" % aname, "alert")

func _on_research_completed(_id: String) -> void:
	_refresh()

func _on_ability_activated(_id: String) -> void:
	_refresh()

func _on_tick(_delta: float) -> void:
	_refresh()

func _refresh() -> void:
	for id in _buttons.keys():
		var btn: Button = _buttons[id]
		var def := AbilitiesDB.get_def(id)

		if not Abilities.is_unlocked(id):
			btn.visible = false
			continue
		btn.visible = true

		if Abilities.is_active(id):
			var left := float(GameState.active_abilities[id])
			btn.text = "АКТИВНО %ds" % int(ceil(left))
			btn.disabled = true
			btn.add_theme_color_override("font_color", Palette.SIGNAL)
		elif Abilities.cooldown_left(id) > 0.0:
			btn.text = "%ds" % int(ceil(Abilities.cooldown_left(id)))
			btn.disabled = true
			btn.remove_theme_color_override("font_color")
		else:
			btn.text = String(def["name"])
			btn.disabled = false
			btn.remove_theme_color_override("font_color")
