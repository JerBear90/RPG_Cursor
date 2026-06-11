class_name UiColors
extends RefCounted
## Central palette for the dark survival-fantasy ARPG UI.

# Panels — charcoal with brown tint, ~85% opacity
const PANEL_BG := Color(0.07, 0.06, 0.05, 0.86)
const PANEL_BG_DEEP := Color(0.05, 0.05, 0.06, 0.90)
const PANEL_INNER := Color(0.09, 0.08, 0.07, 0.72)
const BAR_TRACK := Color(0.10, 0.10, 0.11, 0.95)

# Borders
const BORDER_BRONZE := Color(0.52, 0.42, 0.28, 0.90)
const BORDER_GOLD := Color(0.68, 0.54, 0.26, 0.95)
const BORDER_MUTED := Color(0.28, 0.28, 0.30, 0.80)
const BORDER_ACTIVE := Color(0.78, 0.62, 0.32, 1.0)

# Vitals — desaturated, not neon
const HEALTH_FILL := Color(0.52, 0.16, 0.14, 1.0)
const HEALTH_DAMAGE := Color(0.38, 0.10, 0.10, 0.85)
const HEALTH_FLASH := Color(0.68, 0.22, 0.18, 0.55)
const MANA_FILL := Color(0.28, 0.38, 0.52, 1.0)
const MANA_FLASH := Color(0.34, 0.46, 0.62, 0.55)
const STAMINA_FILL := Color(0.42, 0.48, 0.28, 1.0)
const XP_FILL := Color(0.62, 0.48, 0.22, 1.0)

# Text
const TEXT_PRIMARY := Color(0.90, 0.88, 0.84, 1.0)
const TEXT_SECONDARY := Color(0.58, 0.58, 0.56, 1.0)
const TEXT_MUTED := Color(0.44, 0.44, 0.46, 1.0)
const TEXT_QUEST := Color(0.88, 0.68, 0.28, 1.0)
const TEXT_WAYPOINT := Color(0.55, 0.72, 0.85, 1.0)
const TEXT_DANGER := Color(0.78, 0.40, 0.32, 1.0)
const TEXT_CURRENCY := Color(0.96, 0.86, 0.58, 1.0)
const TEXT_CURRENCY_GLOW := Color(0.88, 0.72, 0.36, 1.0)

# Accents
const SHADOW := Color(0.0, 0.0, 0.0, 0.50)
const OVERLAY_DARK := Color(0.04, 0.05, 0.06, 0.72)

# Map
const MAP_WATER := Color(0.05, 0.10, 0.18, 0.95)
const MAP_LAND := Color(0.14, 0.22, 0.12, 1.0)
const MAP_FOG := Color(0.06, 0.08, 0.10, 0.55)
