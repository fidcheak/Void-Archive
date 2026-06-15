class_name ThemeBuilder

static func mono_font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["JetBrains Mono", "Cascadia Code", "Consolas", "DejaVu Sans Mono", "monospace"])
	return f

static func build() -> Theme:
	var t := Theme.new()
	t.default_font = mono_font()
	t.default_font_size = 13
	t.set_color("font_color", "Label", Palette.TEXT)

	var panel := StyleBoxFlat.new()
	panel.bg_color = Palette.BG_PANEL
	panel.border_color = Palette.BORDER
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(0)
	panel.content_margin_left = 12
	panel.content_margin_right = 12
	panel.content_margin_top = 8
	panel.content_margin_bottom = 8
	t.set_stylebox("panel", "PanelContainer", panel)

	_build_button_styles(t)
	_build_tab_styles(t)
	_build_separator_style(t)
	_build_container_constants(t)

	return t

# ---- хелпер: обведённый модуль с заголовком (брутал-рамка + ЗАГЛАВНЫЙ заголовок) ----
# Возвращает { "panel": PanelContainer, "body": VBoxContainer } — содержимое добавляется в "body".
static func framed_module(title: String) -> Dictionary:
	var panel := PanelContainer.new()

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 8)
	panel.add_child(margin)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
	margin.add_child(body)

	if title != "":
		var header := Label.new()
		header.text = title.to_upper()
		header.add_theme_color_override("font_color", Palette.TEXT_DIM)
		header.add_theme_font_size_override("font_size", 11)
		body.add_child(header)
		body.add_child(HSeparator.new())

	return { "panel": panel, "body": body }

static func _build_button_styles(t: Theme) -> void:
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Palette.BG_PANEL_HI
	sb_normal.border_color = Palette.BORDER
	sb_normal.set_border_width_all(1)
	sb_normal.set_corner_radius_all(0)
	sb_normal.content_margin_left = 10
	sb_normal.content_margin_right = 10
	sb_normal.content_margin_top = 6
	sb_normal.content_margin_bottom = 6

	var sb_hover := sb_normal.duplicate()
	sb_hover.bg_color = Palette.BG_PANEL_HI.lightened(0.06)
	sb_hover.border_color = Palette.BORDER_HI

	var sb_pressed := sb_normal.duplicate()
	sb_pressed.bg_color = Palette.BG_DEEP
	sb_pressed.border_color = Palette.BORDER_HI

	var sb_disabled := sb_normal.duplicate()
	sb_disabled.bg_color = Palette.BG_PANEL
	sb_disabled.border_color = Palette.BORDER

	var sb_focus := sb_normal.duplicate()
	sb_focus.border_color = Palette.BORDER_HI

	t.set_stylebox("normal", "Button", sb_normal)
	t.set_stylebox("hover", "Button", sb_hover)
	t.set_stylebox("pressed", "Button", sb_pressed)
	t.set_stylebox("disabled", "Button", sb_disabled)
	t.set_stylebox("focus", "Button", sb_focus)
	t.set_color("font_color", "Button", Palette.TEXT)
	t.set_color("font_hover_color", "Button", Palette.TEXT)
	t.set_color("font_pressed_color", "Button", Palette.TEXT)
	t.set_color("font_disabled_color", "Button", Palette.TEXT_MUTE)

static func _build_tab_styles(t: Theme) -> void:
	var tab_selected := StyleBoxFlat.new()
	tab_selected.bg_color = Palette.BG_PANEL
	tab_selected.border_color = Palette.BORDER_HI
	tab_selected.set_border_width_all(1)
	tab_selected.border_width_bottom = 0
	tab_selected.set_corner_radius_all(0)
	tab_selected.content_margin_left = 12
	tab_selected.content_margin_right = 12
	tab_selected.content_margin_top = 6
	tab_selected.content_margin_bottom = 6

	var tab_unselected := tab_selected.duplicate()
	tab_unselected.bg_color = Palette.BG_PANEL_HI
	tab_unselected.border_color = Palette.BORDER

	var tab_hovered := tab_unselected.duplicate()
	tab_hovered.bg_color = Palette.BG_PANEL_HI.lightened(0.06)
	tab_hovered.border_color = Palette.BORDER_HI

	t.set_stylebox("tab_selected", "TabContainer", tab_selected)
	t.set_stylebox("tab_unselected", "TabContainer", tab_unselected)
	t.set_stylebox("tab_hovered", "TabContainer", tab_hovered)
	t.set_color("font_selected_color", "TabContainer", Palette.TEXT)
	t.set_color("font_unselected_color", "TabContainer", Palette.TEXT_DIM)
	t.set_font_size("font_size", "TabContainer", 12)

	var body := StyleBoxFlat.new()
	body.bg_color = Palette.BG_PANEL
	body.border_color = Palette.BORDER
	body.set_border_width_all(1)
	body.border_width_top = 0
	body.set_corner_radius_all(0)
	t.set_stylebox("panel", "TabContainer", body)

static func _build_separator_style(t: Theme) -> void:
	var sep := StyleBoxLine.new()
	sep.color = Palette.BORDER
	sep.thickness = 1
	t.set_stylebox("separator", "HSeparator", sep)

static func _build_container_constants(t: Theme) -> void:
	t.set_constant("separation", "VBoxContainer", 8)
	t.set_constant("separation", "HBoxContainer", 6)
