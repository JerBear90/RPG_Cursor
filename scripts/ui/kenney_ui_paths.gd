class_name KenneyUiPaths
extends RefCounted
## Kenney UI Pack (CC0) SVG paths — res://art/kenney/ui_pack/

const ROOT := "res://art/kenney/ui_pack/Vector/"


static func bar_track(folder: String = "Grey") -> String:
	return ROOT + folder + "/slide_horizontal_grey.svg"


static func bar_fill(folder: String) -> String:
	return ROOT + folder + "/slide_horizontal_color_section.svg"


static func panel_flat() -> String:
	return ROOT + "Grey/button_rectangle_depth_flat.svg"


static func panel_border() -> String:
	return ROOT + "Grey/button_rectangle_depth_border.svg"


static func circle_frame() -> String:
	return ROOT + "Grey/icon_outline_circle.svg"


static func star_filled() -> String:
	return ROOT + "Grey/star.svg"


static func star_empty() -> String:
	return ROOT + "Grey/star_outline.svg"


static func input_square() -> String:
	return ROOT + "Extra/input_square.svg"


static func load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is Texture2D:
			return res as Texture2D
	return _load_png_fallback(path)


static func _load_png_fallback(svg_path: String) -> Texture2D:
	var file_name := svg_path.get_file().get_basename()
	var folder := svg_path.get_base_dir().get_file()
	var png_root := "res://art/_downloads/kenney_ui-pack/PNG/Blue/Default/"
	var png_alt := png_root + file_name + ".png"
	if ResourceLoader.exists(png_alt):
		var res: Resource = load(png_alt)
		if res is Texture2D:
			return res as Texture2D
	# Common bar PNG names differ from SVG
	if file_name.contains("slide_horizontal"):
		for candidate in ["barBlue_horizontalMid", "barGreen_horizontalMid", "barRed_horizontalMid"]:
			var p: String = png_root + candidate + ".png"
			if ResourceLoader.exists(p):
				var res: Resource = load(p)
				if res is Texture2D:
					return res as Texture2D
	return null


static func solid_tex(color: Color, size: Vector2i = Vector2i(64, 16)) -> Texture2D:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)
