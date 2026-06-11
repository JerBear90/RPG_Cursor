class_name MinimapSettings
extends RefCounted
## Minimap display settings — future-ready, not exposed in menus yet.

enum MinimapRotationMode {
	ROTATE_WITH_PLAYER,
	NORTH_UP,
}

const VIEWPORT_LOW := 256
const VIEWPORT_NORMAL := 384
const VIEWPORT_HIGH := 512

static var rotation_mode: MinimapRotationMode = MinimapRotationMode.NORTH_UP
static var fog_of_war_enabled: bool = false
static var viewport_resolution: int = VIEWPORT_NORMAL
static var enemy_detection_radius: float = 36.0
static var marker_update_interval: float = 0.12
static var waypoint_reach_distance: float = 4.0
static var use_dev_test_markers: bool = OS.is_debug_build()
static var world_view_radius_scale: float = 0.5
static var minimap_world_radius: float = 50.0
