class_name TerminalPanel
extends PanelContainer

const MAX_LINES := 80

var _log: RichTextLabel

func _ready() -> void:
	clip_contents = true

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_active = true
	_log.scroll_following = true
	_log.fit_content = false
	_log.clip_contents = true
	_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_log)

	Events.log_message.connect(add_line)

	add_line("> ИНИЦИАЛИЗАЦИЯ АРХИВА...", "sys")
	add_line("> ОБНАРУЖЕН ПОВРЕЖДЁННЫЙ УЗЕЛ", "sys")
	add_line("> ОЖИДАНИЕ ВВОДА ОПЕРАТОРА", "sys")

func add_line(text: String, type := "sys") -> void:
	var color := Palette.TEXT_2
	match type:
		"alert":
			color = Palette.DANGER
		"warn":
			color = Palette.WARN
		_:
			color = Palette.TEXT_2
	_log.append_text("[color=#%s]%s[/color]\n" % [color.to_html(false), text])
	if _log.get_line_count() > MAX_LINES:
		_log.remove_paragraph(0)
