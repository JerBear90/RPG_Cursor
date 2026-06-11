class_name UiMetrics
extends RefCounted
## Spacing, sizing, and typography constants (8px grid).

const SPACE_XS := 4
const SPACE_SM := 8
const SPACE_MD := 16
const SPACE_LG := 24
const SPACE_XL := 32
const SPACE_SAFE := 32

const RADIUS_SM := 4
const RADIUS_MD := 6
const RADIUS_LG := 8

const FONT_META := 13
const FONT_SM := 14
const FONT_MD := 16
const FONT_LG := 18
const FONT_TITLE := 20

const VITAL_FRAME_WIDTH := 220
const ICON_VITAL := 28
const ICON_SLOT := 30
const ICON_TOAST := 24
const ABILITY_SLOT_SIZE := 48
const ABILITY_SLOT_COUNT := 6
const MINIMAP_SIZE := 140
const MINIMAP_READOUT_HEIGHT := 16
const MINIMAP_FRAME_PAD := 6
const MINIMAP_MAX_WIDTH := 180
const QUEST_PANEL_MAX_WIDTH := 160


static func get_minimap_size(viewport_width: float) -> float:
	if viewport_width <= 1280.0:
		return 120.0
	if viewport_width <= 1920.0:
		return 140.0
	return 160.0


static func get_minimap_widget_height(viewport_width: float) -> float:
	return get_minimap_size(viewport_width) + MINIMAP_READOUT_HEIGHT
const TOAST_MAX_WIDTH := 420

const BAR_HP := 6.0
const BAR_STAMINA := 4.0
const BAR_XP := 6.0
const BAR_MANA := 5.0
