class_name CinderholdHealerStation
extends InteractableBase
## Brother Caldus — paid healing and desert ailment cleansing at Cinderhold.

@export var heal_amount: float = 50.0
@export var copper_cost: int = 18

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
	var line := "Restore health, hydration, and cleanse heat ailments for %d copper?" % copper_cost
	DialogueManager.start_dialogue("cinderhold_healer", [
		{"speaker": "Brother Caldus", "text": line},
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
		DialogueManager.start_dialogue("cinderhold_healer", [
			{"speaker": "Brother Caldus", "text": "Not enough copper for treatment."},
		], [], _INTERACT_OPTS)
		return
	CurrencyManager.spend_copper(copper_cost)
	for p in GameManager.get_alive_players():
		if p.has_node("HealthComponent"):
			(p.get_node("HealthComponent") as HealthComponent).heal(heal_amount)
		if p.has_node("SurvivalNeedsComponent"):
			var needs := p.get_node("SurvivalNeedsComponent") as SurvivalNeedsComponent
			needs.hunger = minf(needs.hunger + 15.0, needs.max_hunger)
			needs.thirst = minf(needs.thirst + 40.0, needs.max_thirst)
		if p.has_node("StatusEffectsComponent"):
			var status := p.get_node("StatusEffectsComponent") as StatusEffectsComponent
			status.clear_heat()
			status.clear_desert_exposure()
			status.restore_hydration(40.0)
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Brother Caldus restores your strength and hydration.")


func _on_dialogue_ended() -> void:
	_pending = false
