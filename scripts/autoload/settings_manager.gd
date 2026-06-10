extends Node
## Gameplay, video, audio, and accessibility settings.

const CONFIG_PATH := "user://settings.cfg"

var difficulty: String = "normal"
var camera_sensitivity: float = 1.0
var invert_look_y: bool = false
var invert_look_x: bool = false
var vibration: bool = true
var ui_scale: float = 1.0
var subtitles: bool = true
var reduce_camera_shake: bool = false
var hold_sprint: bool = false
var hold_block: bool = true
var frame_cap: int = 60
var vsync: bool = true
var texture_quality: int = 1
var shadow_quality: int = 1
var effects_quality: int = 1
var motion_blur: bool = false
var brightness: float = 1.0
var colorblind_mode: int = 0


func _ready() -> void:
	load_settings()
	apply_settings()


func apply_settings() -> void:
	InputManager.camera_sensitivity = camera_sensitivity
	InputManager.invert_look_y = invert_look_y
	InputManager.invert_look_x = invert_look_x
	AudioManager.master_volume = 1.0
	if frame_cap > 0:
		Engine.max_fps = frame_cap
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("gameplay", "difficulty", difficulty)
	cfg.set_value("gameplay", "camera_sensitivity", camera_sensitivity)
	cfg.set_value("gameplay", "invert_look_y", invert_look_y)
	cfg.set_value("gameplay", "invert_look_x", invert_look_x)
	cfg.set_value("gameplay", "vibration", vibration)
	cfg.set_value("gameplay", "hold_sprint", hold_sprint)
	cfg.set_value("gameplay", "hold_block", hold_block)
	cfg.set_value("video", "frame_cap", frame_cap)
	cfg.set_value("video", "vsync", vsync)
	cfg.set_value("video", "texture_quality", texture_quality)
	cfg.set_value("video", "shadow_quality", shadow_quality)
	cfg.set_value("video", "effects_quality", effects_quality)
	cfg.set_value("video", "motion_blur", motion_blur)
	cfg.set_value("video", "brightness", brightness)
	cfg.set_value("accessibility", "ui_scale", ui_scale)
	cfg.set_value("accessibility", "subtitles", subtitles)
	cfg.set_value("accessibility", "reduce_camera_shake", reduce_camera_shake)
	cfg.set_value("accessibility", "colorblind_mode", colorblind_mode)
	cfg.save(CONFIG_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	difficulty = cfg.get_value("gameplay", "difficulty", difficulty)
	camera_sensitivity = cfg.get_value("gameplay", "camera_sensitivity", camera_sensitivity)
	invert_look_y = cfg.get_value("gameplay", "invert_look_y", invert_look_y)
	invert_look_x = cfg.get_value("gameplay", "invert_look_x", invert_look_x)
	vibration = cfg.get_value("gameplay", "vibration", vibration)
	hold_sprint = cfg.get_value("gameplay", "hold_sprint", hold_sprint)
	hold_block = cfg.get_value("gameplay", "hold_block", hold_block)
	frame_cap = cfg.get_value("video", "frame_cap", frame_cap)
	vsync = cfg.get_value("video", "vsync", vsync)
	ui_scale = cfg.get_value("accessibility", "ui_scale", ui_scale)
	subtitles = cfg.get_value("accessibility", "subtitles", subtitles)


func apply_steam_deck_preset() -> void:
	frame_cap = 40
	ui_scale = 1.15
	camera_sensitivity = 0.85
	apply_settings()
	save_settings()


func serialize() -> Dictionary:
	return {
		"difficulty": difficulty,
		"camera_sensitivity": camera_sensitivity,
		"ui_scale": ui_scale,
		"frame_cap": frame_cap,
	}
