class_name DawnwatchHealerStation
extends InteractableBase
## Father Lucen — paid healing and dominion ailment cleansing at Dawnwatch.

@export var heal_amount: float = 50.0
@export var copper_cost: int = 20

const _INTERACT_OPTS := {"from_interact": true}

var _pending: bool = false


func _ready() -> void:
	super._ready()
	prompt_text = "Seek healing"
	add_to_group("map_healer")
	if not DialogueManager.dialogue_choice_selected.is_connected(_on_dialogue_choice):
		DialogueManager.dialogue_choice_selected.connect(_on_dialogue_choice)
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _on_interact(_player: Node) -> void:
	_pending = true
	var line := "Restore health and cleanse dread and shadow ailments for %d copper?" % copper_cost
	DialogueManager.start_dialogue("dawnwatch_healer", [
		{"speaker": "Father Lucen", "text": line},
	], ["Treat", "Cancel"], {
		"from_interact": true,
		"confirm_label": "Treat",
		"cancel_label": "Cancel",
	})


func _on_dialogue_choice(index: int) -> void:
	if not _pending:
		return
	_pending = false
	if index != 0:
		return
	if not CurrencyManager.can_afford_copper(copper_cost):
		DialogueManager.start_dialogue("dawnwatch_healer", [
			{"speaker": "Father Lucen", "text": "Not enough copper for treatment."},
		], [], _INTERACT_OPTS)
		return
	CurrencyManager.spend_copper(copper_cost)
	for p in GameManager.get_alive_players():
		if p.has_node("HealthComponent"):
			(p.get_node("HealthComponent") as HealthComponent).heal(heal_amount)
		if p.has_node("StatusEffectsComponent"):
			var status := p.get_node("StatusEffectsComponent") as StatusEffectsComponent
			status.clear_dominion_exposure()
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Father Lucen restores your strength and clears the shadow.")


func _on_dialogue_ended() -> void:
	_pending = false
