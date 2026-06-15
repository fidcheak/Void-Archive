class_name CryptoTracker
extends VBoxContainer

const COIN_SIZE := Vector2(40, 40)
const COIN_FONT_SIZE := 11

class CoinButton:
	extends Control

	signal pressed_coin

	var coin_color := Color.WHITE
	var ticker := ""

	func _ready() -> void:
		custom_minimum_size = COIN_SIZE
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 2.0
		draw_circle(c, r, Palette.BG_DEEP)
		draw_arc(c, r, 0.0, TAU, 32, coin_color, 2.0)
		var font := ThemeBuilder.mono_font()
		var text_size := font.get_string_size(ticker, HORIZONTAL_ALIGNMENT_CENTER, -1, COIN_FONT_SIZE)
		draw_string(font, Vector2(c.x - text_size.x * 0.5, c.y + text_size.y * 0.3), ticker, HORIZONTAL_ALIGNMENT_CENTER, -1, COIN_FONT_SIZE, coin_color)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pressed_coin.emit()

var _balance_labels := {}  # id -> Label
var _throttle_label: Label
var _acc := 0.0

var _popup_scrim: Control
var _popup_panel: PanelContainer
var _popup_title: Label
var _popup_rigs: Label
var _popup_upkeep: Label
var _popup_balance: Label
var _popup_rate: Label
var _popup_id := ""

func _ready() -> void:
	add_theme_constant_override("separation", 6)

	_throttle_label = Label.new()
	_throttle_label.add_theme_color_override("font_color", Palette.WARN)
	_throttle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_throttle_label.add_theme_font_size_override("font_size", 10)
	_throttle_label.visible = false
	add_child(_throttle_label)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	for c in CryptoDB.get_list():
		grid.add_child(_build_coin(c))
	add_child(grid)

	_build_popup()

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

func _build_popup() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)

	_popup_scrim = Control.new()
	_popup_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_popup_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_popup_scrim.gui_input.connect(_on_scrim_input)
	_popup_scrim.visible = false
	layer.add_child(_popup_scrim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup_scrim.add_child(center)

	_popup_panel = PanelContainer.new()
	_popup_panel.custom_minimum_size = Vector2(260, 0)
	_popup_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(_popup_panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 10)
	_popup_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)

	_popup_title = Label.new()
	_popup_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_popup_title)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.pressed.connect(_close_popup)
	header.add_child(close_btn)

	box.add_child(HSeparator.new())

	_popup_rigs = Label.new()
	box.add_child(_popup_rigs)

	_popup_upkeep = Label.new()
	_popup_upkeep.add_theme_color_override("font_color", Palette.TEXT_2)
	box.add_child(_popup_upkeep)

	_popup_balance = Label.new()
	box.add_child(_popup_balance)

	_popup_rate = Label.new()
	_popup_rate.add_theme_color_override("font_color", Palette.TEXT_2)
	box.add_child(_popup_rate)

func _on_coin_pressed(id: String) -> void:
	_popup_id = id
	_refresh_popup()
	_popup_scrim.visible = true

func _on_scrim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_popup()

func _close_popup() -> void:
	_popup_scrim.visible = false
	_popup_id = ""

func _refresh_popup() -> void:
	if _popup_id == "": return
	var c := CryptoDB.get_def(_popup_id)
	var rig := MiningDB.get_rig("rig_" + _popup_id)
	var count := Mining.rig_count("rig_" + _popup_id)
	var upkeep := float(rig.get("compute_upkeep", 0.0)) * count

	_popup_title.text = "%s (%s)" % [c.get("name", _popup_id), c.get("short", "")]
	_popup_title.add_theme_color_override("font_color", c.get("color", Palette.CRYPTO))
	_popup_rigs.text = "Фармилок куплено: %d" % count
	_popup_upkeep.text = "Тратится вычислений: %s/сек" % Format.num(upkeep)
	_popup_balance.text = "Всего: %s" % Format.num(GameState.get_resource(_popup_id))
	_popup_rate.text = "Добыча: %s" % Format.rate(Mining.crypto_rate(_popup_id))

func _on_tick(delta: float) -> void:
	_acc += delta
	if _acc < 0.1: return
	_acc = 0.0
	_refresh()

func _refresh() -> void:
	visible = GameState.flags.get("crypto_unlocked", false)
	if not is_visible_in_tree():
		_close_popup()
		return
	if Mining.mining_ratio < 1.0:
		_throttle_label.text = "⚠ добыча снижена (%d%%)" % int(round(Mining.mining_ratio * 100.0))
		_throttle_label.visible = true
	else:
		_throttle_label.visible = false
	for id in _balance_labels.keys():
		_balance_labels[id].text = Format.num(GameState.get_resource(id))
	if _popup_scrim.visible:
		_refresh_popup()
