class_name MapIcon
extends RefCounted
## Map marker type constants and colors.

enum IconType {
	PLAYER_P1,
	PLAYER_P2,
	PET,
	WAYSTONE,
	NPC,
	OBJECTIVE_ACTIVE,
	MISSION_AVAILABLE,
	MISSION_TURN_IN,
	BOSS,
	REGION_EXIT,
	CAMP,
	RESOURCE,
	BASE_STATION,
	BUILDING,
	GENERIC,
}

const TYPE_LABELS: Dictionary = {
	IconType.PLAYER_P1: "Player 1",
	IconType.PLAYER_P2: "Player 2",
	IconType.PET: "Pet",
	IconType.WAYSTONE: "Waystone",
	IconType.NPC: "NPC",
	IconType.OBJECTIVE_ACTIVE: "Objective",
	IconType.MISSION_AVAILABLE: "Mission",
	IconType.MISSION_TURN_IN: "Turn In",
	IconType.BOSS: "Boss",
	IconType.REGION_EXIT: "Exit",
	IconType.CAMP: "Camp",
	IconType.RESOURCE: "Resource",
	IconType.BASE_STATION: "Station",
	IconType.BUILDING: "Building",
	IconType.GENERIC: "Marker",
}

const TYPE_COLORS: Dictionary = {
	IconType.PLAYER_P1: Color(0.35, 0.75, 1.0),
	IconType.PLAYER_P2: Color(0.45, 1.0, 0.55),
	IconType.PET: Color(0.85, 0.65, 0.35),
	IconType.WAYSTONE: Color(0.55, 0.75, 1.0),
	IconType.NPC: Color(0.9, 0.82, 0.55),
	IconType.OBJECTIVE_ACTIVE: Color(1.0, 0.85, 0.25),
	IconType.MISSION_AVAILABLE: Color(0.7, 0.9, 0.5),
	IconType.MISSION_TURN_IN: Color(0.4, 1.0, 0.65),
	IconType.BOSS: Color(1.0, 0.35, 0.35),
	IconType.REGION_EXIT: Color(0.75, 0.75, 0.85),
	IconType.CAMP: Color(0.65, 0.55, 0.4),
	IconType.RESOURCE: Color(0.55, 0.85, 0.55),
	IconType.BASE_STATION: Color(0.75, 0.6, 0.45),
	IconType.BUILDING: Color(0.6, 0.6, 0.65),
	IconType.GENERIC: Color(0.8, 0.8, 0.8),
}


static func get_color(icon_type: int, downed: bool = false) -> Color:
	if downed:
		return Color(1.0, 0.45, 0.2)
	return TYPE_COLORS.get(icon_type, Color.WHITE)


static func get_label(icon_type: int) -> String:
	return str(TYPE_LABELS.get(icon_type, "Marker"))
