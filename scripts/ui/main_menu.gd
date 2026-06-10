extends Control

@onready var solo_button: Button = %SoloButton
@onready var co_op_button: Button = %CoOpButton
@onready var continue_button: Button = %ContinueButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	solo_button.pressed.connect(_on_solo)
	co_op_button.pressed.connect(_on_coop)
	continue_button.pressed.connect(_on_continue)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)
	if SaveManager.has_save(0):
		continue_button.visible = true
		continue_button.grab_focus()
	else:
		continue_button.visible = false
		solo_button.grab_focus()


func _on_solo() -> void:
	GameManager.start_new_game(false)


func _on_coop() -> void:
	GameManager.start_new_game(true)
	AchievementManager.unlock("two_exiles_one_fate")


func _on_continue() -> void:
	GameManager.continue_game(0)


func _on_settings() -> void:
	SettingsManager.apply_steam_deck_preset()


func _on_quit() -> void:
	get_tree().quit()
