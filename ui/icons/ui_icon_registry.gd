class_name UiIconRegistry
extends RefCounted
## Central icon paths and procedural fallbacks — never returns a blank white texture.

const PATHS := {
	"health": "res://ui/icons/generated/health.png",
	"mana": "res://ui/icons/generated/mana.png",
	"stamina": "res://ui/icons/generated/stamina.png",
	"experience": "res://ui/icons/generated/experience.png",
	"interaction": "res://ui/icons/generated/interaction.png",
	"quest": "res://ui/icons/generated/quest.png",
	"currency": "res://ui/icons/generated/currency.png",
	"ability_default": "res://ui/icons/generated/ability_default.png",
	"ability_locked": "res://ui/icons/generated/ability_locked.png",
	"objective": "res://ui/icons/generated/objective.png",
	"notification": "res://ui/icons/generated/notification.png",
	"item_unknown": "res://ui/icons/generated/item_unknown.png",
}

const TINT_RULES := {
	"health": Color(1, 1, 1, 0.92),
	"mana": Color(1, 1, 1, 0.92),
	"stamina": Color(1, 1, 1, 0.90),
	"experience": Color(1, 1, 1, 0.92),
	"interaction": Color(1, 1, 1, 0.95),
	"quest": Color(1, 1, 1, 0.95),
	"currency": Color(1, 1, 1, 0.95),
	"ability_default": Color(1, 1, 1, 0.92),
	"ability_locked": Color(0.75, 0.75, 0.78, 0.85),
	"notification": Color(1, 1, 1, 0.95),
	"item_unknown": Color(1, 1, 1, 0.90),
}

const DISPLAY_SIZES := {
	"health": 28,
	"mana": 28,
	"stamina": 16,
	"experience": 16,
	"interaction": 18,
	"quest": 16,
	"currency": 16,
	"ability_default": 30,
	"ability_locked": 30,
	"notification": 24,
	"item_unknown": 24,
}

static var _cache: Dictionary = {}


static func path_for(key: String) -> String:
	return PATHS.get(key, PATHS.ability_default)


static func get_display_size(key: String) -> int:
	return DISPLAY_SIZES.get(key, 24)


static func get_tint(key: String) -> Color:
	return TINT_RULES.get(key, Color.WHITE)


static func get_icon(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var tex := _load_file(path_for(key))
	if tex == null:
		tex = _generate_glyph(key)
	_cache[key] = tex
	return tex


static func get_ability_icon(ability_id: String = "") -> Texture2D:
	if ability_id.is_empty():
		return get_icon("ability_default")
	var custom := "res://ui/icons/abilities/%s.png" % ability_id
	if ResourceLoader.exists(custom):
		var loaded := _load_file(custom)
		if loaded:
			return loaded
	return get_icon("ability_default")


static func _load_file(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var res := load(path)
	return res as Texture2D


static func _generate_glyph(key: String) -> Texture2D:
	var accent := UiColors.TEXT_SECONDARY
	var symbol := "?"
	match key:
		"health":
			accent = UiColors.HEALTH_FILL
			symbol = "+"
		"mana":
			accent = UiColors.MANA_FILL
			symbol = "◆"
		"stamina":
			accent = UiColors.STAMINA_FILL
			symbol = "»"
		"experience":
			accent = UiColors.XP_FILL
			symbol = "★"
		"interaction":
			accent = UiColors.TEXT_QUEST
			symbol = "E"
		"quest":
			accent = UiColors.TEXT_QUEST
			symbol = "!"
		"currency":
			accent = UiColors.TEXT_QUEST
			symbol = "¢"
		"ability_default":
			accent = UiColors.BORDER_BRONZE
			symbol = "⚔"
		"ability_locked":
			accent = UiColors.TEXT_MUTED
			symbol = "✕"
		"objective":
			accent = UiColors.TEXT_QUEST
			symbol = "▸"
		"notification", "item_unknown":
			accent = UiColors.TEXT_PRIMARY
			symbol = "i" if key == "notification" else "?"
	var size := 32
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.09, 0.10, 0.12, 0.98))
	for x in size:
		for y in size:
			if x == 0 or y == 0 or x == size - 1 or y == size - 1:
				img.set_pixel(x, y, UiColors.BORDER_MUTED)
	var cx := size / 2
	var cy := size / 2
	match symbol:
		"+":
			for i in range(10, 22):
				img.set_pixel(i, cy, accent)
				img.set_pixel(cx, i, accent)
		"◆":
			for i in range(-6, 7):
				img.set_pixel(cx + i, cy - absi(i) / 2, accent)
				img.set_pixel(cx + i, cy + absi(i) / 2, accent)
		"★":
			for dx in range(-3, 4):
				for dy in range(-3, 4):
					if absi(dx) + absi(dy) <= 4:
						img.set_pixel(cx + dx, cy + dy, accent)
		"!", "i", "E", "¢", "⚔", "✕", "▸", "»", "?":
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					if absi(dx) + absi(dy) <= 3:
						img.set_pixel(cx + dx, cy + dy, accent)
		_:
			img.set_pixel(cx, cy, accent)
	return ImageTexture.create_from_image(img)
