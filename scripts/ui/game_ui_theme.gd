class_name GameUiTheme
extends RefCounted
## Shared HUD theme — panels, bars, labels, skill slots (Kenney + StyleBox).

const GOLD := Color(0.82, 0.68, 0.32, 1.0)
const GOLD_DIM := Color(0.62, 0.5, 0.24, 0.9)
const TEXT_PRIMARY := Color(0.94, 0.95, 0.98, 1.0)
const TEXT_MUTED := Color(0.68, 0.72, 0.78, 1.0)
const TEXT_GOLD := Color(0.95, 0.82, 0.45, 1.0)
const PANEL_BG := Color(0.05, 0.07, 0.11, 0.88)
const PANEL_BG_LIGHT := Color(0.08, 0.1, 0.15, 0.92)


static func apply_hud_label(label: Label, size: int = 14, color: Color = TEXT_PRIMARY) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)


static func apply_title_label(label: Label) -> void:
	apply_hud_label(label, 16, TEXT_GOLD)


static func make_panel_style(bg: Color = PANEL_BG, border: Color = GOLD_DIM, radius: int = 8) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	box.shadow_color = Color(0, 0, 0, 0.45)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 2)
	return box


static func make_skill_slot(active: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.1, 0.12, 0.18, 0.95) if not active else Color(0.16, 0.14, 0.08, 0.98)
	box.border_color = GOLD if active else Color(0.32, 0.36, 0.42, 0.95)
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.content_margin_left = 4
	box.content_margin_right = 4
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box


static func make_level_badge() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.12, 0.1, 0.06, 0.98)
	box.border_color = GOLD
	box.set_border_width_all(2)
	box.set_corner_radius_all(18)
	return box


static func style_bar(bar: TextureProgressBar, fill: Color, height: float = 12.0) -> void:
	if bar == null:
		return
	bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	bar.custom_minimum_size = Vector2(80, height)
	bar.show_percentage = false
	var track := KenneyUiPaths.load_tex(KenneyUiPaths.bar_track("Grey"))
	var chunk := KenneyUiPaths.load_tex(KenneyUiPaths.bar_fill("Yellow"))
	if track:
		bar.texture_under = track
	if chunk:
		bar.texture_progress = chunk
		bar.tint_progress = fill
	if bar.texture_under == null:
		bar.texture_under = KenneyUiPaths.solid_tex(Color(0.08, 0.09, 0.12, 0.95), Vector2i(256, 16))
	if bar.texture_progress == null:
		bar.texture_progress = KenneyUiPaths.solid_tex(fill, Vector2i(256, 16))


static func skill_slot_texture() -> Texture2D:
	var tex := KenneyUiPaths.load_tex(KenneyUiPaths.ROOT + "Grey/button_square_depth_border.svg")
	if tex == null:
		tex = KenneyUiPaths.load_tex(KenneyUiPaths.ROOT + "Extra/input_outline_square.svg")
	return tex
