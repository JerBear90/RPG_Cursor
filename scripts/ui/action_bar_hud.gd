extends Node
class_name ActionBarHud
## Legacy bridge node — health/mana HUD sync is signal-driven via PlayerHud/VitalFrame.


func set_skill_highlight(_index: int, _active: bool) -> void:
	pass


func update_spell_slot(_spell_label: String) -> void:
	pass


func set_hp_values(_current: float, _maximum: float) -> void:
	pass


func set_mp_values(_current: float, _maximum: float) -> void:
	pass
