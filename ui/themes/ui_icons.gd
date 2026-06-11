class_name UiIcons
extends RefCounted
## Centralized icon paths — replace with final art later.

const ROOT := "res://assets/ui/"
const PLACEHOLDER := "res://icon.svg"

static func quest_icon() -> String:
	return PLACEHOLDER

static func ability_icon(_ability_id: String = "") -> String:
	return PLACEHOLDER

static func map_player() -> String:
	return PLACEHOLDER

static func map_quest() -> String:
	return PLACEHOLDER

static func map_waystone() -> String:
	return PLACEHOLDER

static func load_icon(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		path = PLACEHOLDER
	return load(path) as Texture2D
