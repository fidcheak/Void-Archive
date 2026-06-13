class_name ThemeBuilder

static func mono_font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["JetBrains Mono", "Cascadia Code", "Consolas", "DejaVu Sans Mono", "monospace"])
	return f

static func build() -> Theme:
	var t := Theme.new()
	t.default_font = mono_font()
	t.default_font_size = 16
	t.set_color("font_color", "Label", Palette.TEXT)

	var panel := StyleBoxFlat.new()
	panel.bg_color = Palette.SURFACE
	panel.border_color = Palette.LINE
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(4)
	panel.content_margin_left = 12
	panel.content_margin_right = 12
	panel.content_margin_top = 8
	panel.content_margin_bottom = 8
	t.set_stylebox("panel", "PanelContainer", panel)
	return t
