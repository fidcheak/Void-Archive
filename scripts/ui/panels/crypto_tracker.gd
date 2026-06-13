class_name CryptoTracker
extends PanelContainer

var _expanded := false
var _toggle_button: Button
var _list: VBoxContainer
var _rows := {}  # id -> { "balance": Label, "rate": Label }

func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = 8.0
	offset_top = 80.0

	var box := VBoxContainer.new()
	add_child(box)

	_toggle_button = Button.new()
	_toggle_button.pressed.connect(_on_toggle_pressed)
	box.add_child(_toggle_button)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	box.add_child(_list)

	for c in CryptoDB.get_list():
		_list.add_child(_build_row(c))

	Events.tick.connect(_on_tick)

	_update_visibility()
	_refresh()

func _build_row(c: Dictionary) -> Control:
	var row := VBoxContainer.new()

	var name_label := Label.new()
	name_label.text = "%s (%s)" % [c["name"], c["short"]]
	name_label.add_theme_color_override("font_color", c["color"])
	row.add_child(name_label)

	var balance_label := Label.new()
	balance_label.add_theme_color_override("font_color", Palette.TEXT)
	row.add_child(balance_label)

	var rate_label := Label.new()
	rate_label.add_theme_color_override("font_color", Palette.TEXT_2)
	row.add_child(rate_label)

	row.add_child(HSeparator.new())

	_rows[c["id"]] = { "balance": balance_label, "rate": rate_label }
	return row

func _on_toggle_pressed() -> void:
	_expanded = not _expanded
	_update_visibility()

func _update_visibility() -> void:
	_list.visible = _expanded
	_toggle_button.text = "КРИПТА ◂" if _expanded else "КРИПТА ▸"

func _on_tick(_delta: float) -> void:
	_refresh()

func _refresh() -> void:
	for id in _rows.keys():
		var row: Dictionary = _rows[id]
		row["balance"].text = Format.num(GameState.get_resource(id))
		row["rate"].text = Format.rate(Mining.crypto_rate(id))
