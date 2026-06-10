extends Control

@onready var solo_button: Button = %SoloButton
@onready var co_op_button: Button = %CoOpButton
@onready var continue_button: Button = %ContinueButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton

var _settings_panel: PanelContainer
var _settings_list: ItemList


func _ready() -> void:
	solo_button.pressed.connect(_on_solo)
	co_op_button.pressed.connect(_on_coop)
	continue_button.pressed.connect(_on_continue)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)
	_build_settings_panel()
	if SaveManager.has_save(0):
		continue_button.visible = true
		continue_button.grab_focus()
	else:
		continue_button.visible = false
		solo_button.grab_focus()


func _build_settings_panel() -> void:
	_settings_panel = PanelContainer.new()
	_settings_panel.visible = false
	_settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	_settings_panel.offset_left = -220
	_settings_panel.offset_top = -180
	_settings_panel.offset_right = 220
	_settings_panel.offset_bottom = 180
	add_child(_settings_panel)
	_settings_list = ItemList.new()
	_settings_list.custom_minimum_size = Vector2(400, 300)
	_settings_list.item_selected.connect(_on_settings_item_selected)
	_settings_panel.add_child(_settings_list)


func _populate_settings() -> void:
	_settings_list.clear()
	_settings_list.add_item("Close")
	_settings_list.add_item("Master Volume: %d%%" % int(AudioManager.master_volume * 100))
	_settings_list.add_item("Music Volume: %d%%" % int(AudioManager.music_volume * 100))
	_settings_list.add_item("SFX Volume: %d%%" % int(AudioManager.sfx_volume * 100))
	_settings_list.add_item("Camera Sensitivity: %.1f" % SettingsManager.camera_sensitivity)
	_settings_list.add_item("Difficulty: %s" % SettingsManager.difficulty.capitalize())
	_settings_list.add_item("VSync: %s" % ("On" if SettingsManager.vsync else "Off"))
	_settings_list.add_item("Frame Cap: %d" % SettingsManager.frame_cap)
	_settings_list.add_item("Invert Look Y: %s" % ("On" if SettingsManager.invert_look_y else "Off"))
	_settings_list.add_item("Invert Look X: %s" % ("On" if SettingsManager.invert_look_x else "Off"))
	_settings_list.add_item("Hold Sprint: %s" % ("On" if SettingsManager.hold_sprint else "Off"))
	_settings_list.add_item("Hold Block: %s" % ("On" if SettingsManager.hold_block else "Off"))
	_settings_list.add_item("Vibration: %s" % ("On" if SettingsManager.vibration else "Off"))
	_settings_list.add_item("Subtitles: %s" % ("On" if SettingsManager.subtitles else "Off"))
	_settings_list.add_item("UI Scale: %.2f" % SettingsManager.ui_scale)
	_settings_list.add_item("Reduce Camera Shake: %s" % ("On" if SettingsManager.reduce_camera_shake else "Off"))
	_settings_list.add_item("Motion Blur: %s" % ("On" if SettingsManager.motion_blur else "Off"))
	_settings_list.add_item("Brightness: %.1f" % SettingsManager.brightness)
	_settings_list.add_item("Apply Steam Deck Preset")


func _on_solo() -> void:
	GameManager.start_new_game(false)


func _on_coop() -> void:
	GameManager.start_new_game(true)
	AchievementManager.unlock("two_exiles_one_fate")


func _on_continue() -> void:
	GameManager.continue_game(0)


func _on_settings() -> void:
	_populate_settings()
	_settings_panel.visible = true
	_settings_list.grab_focus()


func _on_settings_item_selected(index: int) -> void:
	var text := _settings_list.get_item_text(index)
	if text == "Close":
		_settings_panel.visible = false
		settings_button.grab_focus()
		return
	if text.begins_with("Master Volume"):
		AudioManager.set_master_volume(fmod(AudioManager.master_volume + 0.1, 1.01))
	elif text.begins_with("Music Volume"):
		AudioManager.set_music_volume(fmod(AudioManager.music_volume + 0.1, 1.01))
	elif text.begins_with("SFX Volume"):
		AudioManager.set_sfx_volume(fmod(AudioManager.sfx_volume + 0.1, 1.01))
	elif text.begins_with("Camera Sensitivity"):
		SettingsManager.camera_sensitivity = clampf(SettingsManager.camera_sensitivity + 0.1, 0.3, 2.0)
	elif text.begins_with("Difficulty"):
		var tiers := ["easy", "normal", "hard"]
		var tier_idx := tiers.find(SettingsManager.difficulty)
		SettingsManager.difficulty = tiers[(tier_idx + 1) % tiers.size()]
	elif text.begins_with("VSync"):
		SettingsManager.vsync = not SettingsManager.vsync
	elif text.begins_with("Frame Cap"):
		var caps := [30, 40, 60, 120, 0]
		var cap_idx := caps.find(SettingsManager.frame_cap)
		SettingsManager.frame_cap = caps[(cap_idx + 1) % caps.size()]
	elif text.begins_with("Invert Look Y"):
		SettingsManager.invert_look_y = not SettingsManager.invert_look_y
	elif text.begins_with("Invert Look X"):
		SettingsManager.invert_look_x = not SettingsManager.invert_look_x
	elif text.begins_with("Hold Sprint"):
		SettingsManager.hold_sprint = not SettingsManager.hold_sprint
	elif text.begins_with("Hold Block"):
		SettingsManager.hold_block = not SettingsManager.hold_block
	elif text.begins_with("Vibration"):
		SettingsManager.vibration = not SettingsManager.vibration
	elif text.begins_with("Subtitles"):
		SettingsManager.subtitles = not SettingsManager.subtitles
	elif text.begins_with("UI Scale"):
		SettingsManager.ui_scale = clampf(SettingsManager.ui_scale + 0.05, 0.8, 1.5)
	elif text.begins_with("Reduce Camera Shake"):
		SettingsManager.reduce_camera_shake = not SettingsManager.reduce_camera_shake
	elif text.begins_with("Motion Blur"):
		SettingsManager.motion_blur = not SettingsManager.motion_blur
	elif text.begins_with("Brightness"):
		SettingsManager.brightness = clampf(SettingsManager.brightness + 0.1, 0.5, 1.5)
	elif text == "Apply Steam Deck Preset":
		SettingsManager.apply_steam_deck_preset()
	SettingsManager.apply_settings()
	SettingsManager.save_settings()
	_populate_settings()


func _on_quit() -> void:
	get_tree().quit()
