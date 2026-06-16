class_name ItemUiTheme
extends RefCounted
## Colors and labels for inventory item buttons.

const TYPE_COLORS := {
	"weapon": Color(0.85, 0.45, 0.35),
	"armor": Color(0.45, 0.65, 0.95),
	"consumable": Color(0.45, 0.85, 0.5),
	"material": Color(0.7, 0.7, 0.75),
	"quest": Color(0.95, 0.85, 0.35),
}

const TYPE_ICONS := {
	"weapon": "⚔",
	"armor": "🛡",
	"consumable": "✚",
	"material": "◆",
	"quest": "★",
}


static func get_type_color(item_id: String) -> Color:
	var item_type: String = str(ItemDatabase.get_item(item_id).get("type", "material"))
	return TYPE_COLORS.get(item_type, Color(0.6, 0.6, 0.65))


static func format_item_button(item_id: String, quantity: int = 1) -> String:
	var data := ItemDatabase.get_item(item_id)
	var item_type: String = str(data.get("type", "material"))
	var icon: String = TYPE_ICONS.get(item_type, "•")
	var name := item_id.replace("_", " ").capitalize()
	if quantity > 1:
		return "%s %s\nx%d" % [icon, name, quantity]
	return "%s %s" % [icon, name]


static func style_item_button(btn: Button, item_id: String, selected: bool) -> void:
	var base := get_type_color(item_id)
	var bg := base.darkened(0.55) if not selected else base.darkened(0.25)
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal", _flat_style(bg))
	btn.add_theme_stylebox_override("hover", _flat_style(bg.lightened(0.12)))
	btn.add_theme_stylebox_override("pressed", _flat_style(base.darkened(0.15)))
	if selected:
		btn.add_theme_stylebox_override("normal", _flat_style(base.lightened(0.1), 2))


static func _flat_style(color: Color, border: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(6)
	if border > 0:
		box.border_width_bottom = border
		box.border_width_top = border
		box.border_width_left = border
		box.border_width_right = border
		box.border_color = Color.WHITE
	return box
