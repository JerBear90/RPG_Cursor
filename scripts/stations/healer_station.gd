class_name HealerStation
extends InteractableBase
## Paid healing and poison cleansing at Hearthhold infirmary.

@export var heal_amount: float = 50.0
@export var copper_cost: int = 15

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
	var speaker := "Sister Caia"
	var template := "Restore health and cleanse poison for %d copper?"
	if GameManager.current_region_id == "frostgrave_expanse":
		speaker = "Sister Caia"
		template = "Restore health and cleanse frostbite for %d copper?"
	elif GameManager.current_region_id == "shattered_coast":
		speaker = "Brother Orren"
		template = "Restore health and cleanse coastal exposure for %d copper?"
	elif GameManager.current_region_id == "blightreach":
		speaker = "Sister Valea"
		template = "Restore health and cleanse blight exposure for %d copper?"
	var line := template % copper_cost
	DialogueManager.start_dialogue("healer_station", [
		{"speaker": speaker, "text": line},
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
		DialogueManager.start_dialogue("healer_station", [
			{"speaker": "Infirmary", "text": "Not enough copper for treatment."},
		], [], _INTERACT_OPTS)
		return
	CurrencyManager.spend_copper(copper_cost)
	for p in GameManager.get_alive_players():
		if p.has_node("HealthComponent"):
			(p.get_node("HealthComponent") as HealthComponent).heal(heal_amount)
		if p.has_node("SurvivalNeedsComponent"):
			var needs := p.get_node("SurvivalNeedsComponent") as SurvivalNeedsComponent
			needs.hunger = minf(needs.hunger + 15.0, needs.max_hunger)
			needs.thirst = minf(needs.thirst + 15.0, needs.max_thirst)
		if p.has_node("StatusEffectsComponent"):
			(p.get_node("StatusEffectsComponent") as StatusEffectsComponent).clear_environmental()


func _on_dialogue_ended() -> void:
	_pending = false
