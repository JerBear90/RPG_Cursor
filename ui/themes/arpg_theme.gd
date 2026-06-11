class_name ArpgTheme
extends RefCounted
## Builds and applies the global ARPG Theme resource.

const THEME_PATH := "res://ui/themes/arpg_theme.tres"


static func get_theme() -> Theme:
	if ResourceLoader.exists(THEME_PATH):
		var existing := load(THEME_PATH) as Theme
		if existing:
			return existing
	return build()


static func build() -> Theme:
	var theme := Theme.new()
	theme.set_stylebox("panel", "PanelContainer", make_panel())
	theme.set_stylebox("panel", "Panel", make_panel())
	theme.set_stylebox("normal", "Button", make_button(false))
	theme.set_stylebox("hover", "Button", make_button(true))
	theme.set_stylebox("pressed", "Button", make_button(true, true))
	theme.set_stylebox("focus", "Button", make_button(true))
	theme.set_color("font_color", "Label", UiColors.TEXT_PRIMARY)
	theme.set_font_size("font_size", "Label", UiMetrics.FONT_MD)
	theme.set_constant("separation", "VBoxContainer", UiMetrics.SPACE_SM)
	theme.set_constant("separation", "HBoxContainer", UiMetrics.SPACE_SM)
	theme.set_constant("margin_left", "MarginContainer", UiMetrics.SPACE_MD)
	theme.set_constant("margin_top", "MarginContainer", UiMetrics.SPACE_MD)
	theme.set_constant("margin_right", "MarginContainer", UiMetrics.SPACE_MD)
	theme.set_constant("margin_bottom", "MarginContainer", UiMetrics.SPACE_MD)
	return theme


static func apply_to(node: Control) -> void:
	node.theme = get_theme()


static func make_panel(bg: Color = UiColors.PANEL_BG, border: Color = UiColors.BORDER_BRONZE, radius: int = UiMetrics.RADIUS_MD) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.shadow_color = UiColors.SHADOW
	box.shadow_size = 3
	box.shadow_offset = Vector2(0, 2)
	box.content_margin_left = UiMetrics.SPACE_MD
	box.content_margin_right = UiMetrics.SPACE_MD
	box.content_margin_top = UiMetrics.SPACE_SM
	box.content_margin_bottom = UiMetrics.SPACE_SM
	return box


static func make_inset_panel() -> StyleBoxFlat:
	var box := make_panel(UiColors.PANEL_INNER, UiColors.BORDER_MUTED, UiMetrics.RADIUS_SM)
	box.shadow_size = 0
	box.set_border_width_all(1)
	return box


static func make_button(hover: bool = false, pressed: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = UiColors.PANEL_BG_DEEP if not pressed else UiColors.PANEL_INNER
	if hover:
		box.border_color = UiColors.BORDER_GOLD
	else:
		box.border_color = UiColors.BORDER_MUTED
	box.set_border_width_all(1)
	box.set_corner_radius_all(UiMetrics.RADIUS_SM)
	box.content_margin_left = UiMetrics.SPACE_SM
	box.content_margin_right = UiMetrics.SPACE_SM
	box.content_margin_top = UiMetrics.SPACE_XS
	box.content_margin_bottom = UiMetrics.SPACE_XS
	return box


static func make_ability_slot(active: bool = false, disabled: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	if disabled:
		box.bg_color = Color(0.06, 0.07, 0.09, 0.75)
		box.border_color = UiColors.BORDER_MUTED
	elif active:
		box.bg_color = Color(0.14, 0.11, 0.06, 0.95)
		box.border_color = UiColors.BORDER_GOLD
	else:
		box.bg_color = Color(0.08, 0.09, 0.12, 0.92)
		box.border_color = UiColors.BORDER_BRONZE
	box.set_border_width_all(1)
	box.set_corner_radius_all(UiMetrics.RADIUS_SM)
	box.content_margin_left = 4
	box.content_margin_right = 4
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box


static func make_keycap() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.12, 0.13, 0.16, 0.95)
	box.border_color = UiColors.BORDER_BRONZE
	box.set_border_width_all(1)
	box.set_corner_radius_all(UiMetrics.RADIUS_SM)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box


static func style_progress_bar(bar: TextureProgressBar, fill: Color, height: float) -> void:
	if bar == null:
		return
	bar.custom_minimum_size = Vector2(48, height)
	bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	var track := _solid_tex(Color(0.08, 0.09, 0.11, 0.95), Vector2i(64, int(height)))
	var chunk := _solid_tex(fill, Vector2i(64, int(height)))
	bar.texture_under = track
	bar.texture_progress = chunk
	bar.tint_progress = Color.WHITE


static func style_label(label: Label, size: int = UiMetrics.FONT_MD, color: Color = UiColors.TEXT_PRIMARY) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)


static func _solid_tex(color: Color, size: Vector2i) -> Texture2D:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)
