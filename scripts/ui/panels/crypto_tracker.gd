class_name CryptoTracker
extends VBoxContainer

const COIN_SIZE := Vector2(48, 48)
const COIN_FONT_SIZE := 13

class CoinButton:
	extends Control

	signal pressed_coin

	var coin_color := Color.WHITE
	var ticker := ""

	var _ticker_label: Label

	func _ready() -> void:
		custom_minimum_size = COIN_SIZE
		mouse_filter = Control.MOUSE_FILTER_STOP
		clip_contents = false

		_ticker_label = Label.new()
		_ticker_label.text = ticker
		_ticker_label.add_theme_color_override("font_color", coin_color)
		_ticker_label.add_theme_font_size_override("font_size", COIN_FONT_SIZE)
		_ticker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_ticker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_ticker_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_ticker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_ticker_label)

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 2.0
		draw_circle(c, r, Palette.BG_DEEP)
		draw_arc(c, r, 0.0, TAU, 32, coin_color, 2.0)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pressed_coin.emit()

var _balance_labels := {}  # id -> Label
var _throttle_label: Label
var _acc := 0.0

func _ready() -> void:
	add_theme_constant_override("separation", 6)

	_throttle_label = Label.new()
	_throttle_label.add_theme_color_override("font_color", Palette.WARN)
	_throttle_label.add_theme_font_size_override("font_size", 10)
	_throttle_label.custom_minimum_size = Vector2(0, 14)
	_throttle_label.clip_text = true
	_throttle_label.modulate.a = 0.0
	add_child(_throttle_label)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	for c in CryptoDB.get_list():
		grid.add_child(_build_coin(c))
	add_child(grid)

	Events.tick.connect(_on_tick)

	_refresh()

func _build_coin(c: Dictionary) -> Control:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)

	var coin := CoinButton.new()
	coin.coin_color = c["color"]
	coin.ticker = c["short"]
	coin.pressed_coin.connect(_on_coin_pressed.bind(c["id"]))
	col.add_child(coin)

	var balance := Label.new()
	balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balance.add_theme_font_size_override("font_size", 10)
	balance.add_theme_color_override("font_color", Palette.TEXT_2)
	col.add_child(balance)

	_balance_labels[c["id"]] = balance
	return col

func _on_coin_pressed(id: String) -> void:
	var c := CryptoDB.get_def(id)
	var rig := MiningDB.get_rig("rig_" + id)
	var count := Mining.rig_count("rig_" + id)
	var upkeep := float(rig.get("compute_upkeep", 0.0)) * count

	var title := "%s (%s)" % [c.get("name", id), c.get("short", "")]
	var lines := [
		"Фармилок куплено: %d" % count,
		"Тратится вычислений: %s/сек" % Format.num(upkeep),
		"Всего: %s (%s)" % [Format.num(GameState.get_resource(id)), Format.rate(Mining.crypto_rate(id))],
	]
	DetailPopup.show_at(get_global_mouse_position(), title, lines, c.get("color", Palette.CRYPTO))

func _on_tick(delta: float) -> void:
	_acc += delta
	if _acc < 0.1: return
	_acc = 0.0
	_refresh()

func _refresh() -> void:
	visible = GameState.flags.get("crypto_unlocked", false)
	if not is_visible_in_tree():
		return
	if Mining.mining_ratio < 1.0:
		_throttle_label.text = "⚠ добыча снижена (%d%%)" % int(round(Mining.mining_ratio * 100.0))
		_throttle_label.modulate.a = 1.0
	else:
		_throttle_label.modulate.a = 0.0
	for id in _balance_labels.keys():
		_balance_labels[id].text = Format.num(GameState.get_resource(id))
