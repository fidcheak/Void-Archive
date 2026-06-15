class_name CryptoTracker
extends PanelContainer

signal mining_pressed

var _rows := {}  # id -> { "balance": Label, "rate": Label }
var _acc := 0.0
var _throttle_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(240, 0)
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 8)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var header := Label.new()
	header.text = "КРИПТА"
	header.add_theme_color_override("font_color", Palette.CRYPTO)
	box.add_child(header)

	_throttle_label = Label.new()
	_throttle_label.add_theme_color_override("font_color", Palette.WARN)
	_throttle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_throttle_label.visible = false
	box.add_child(_throttle_label)

	box.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	box.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	for c in CryptoDB.get_list():
		list.add_child(_build_row(c))

	var mining_btn := Button.new()
	mining_btn.text = "⛏ КРИПТО-ФЕРМА"
	mining_btn.pressed.connect(func(): mining_pressed.emit())
	box.add_child(mining_btn)

	Events.tick.connect(_on_tick)

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

func _on_tick(delta: float) -> void:
	_acc += delta
	if _acc < 0.1: return
	_acc = 0.0
	_refresh()

func _refresh() -> void:
	visible = GameState.flags.get("crypto_unlocked", false)
	if not is_visible_in_tree(): return
	if Mining.mining_ratio < 1.0:
		_throttle_label.text = "⚠ добыча снижена (%d%%)" % int(round(Mining.mining_ratio * 100.0))
		_throttle_label.visible = true
	else:
		_throttle_label.visible = false
	for id in _rows.keys():
		var row: Dictionary = _rows[id]
		row["balance"].text = Format.num(GameState.get_resource(id))
		row["rate"].text = Format.rate(Mining.crypto_rate(id))
