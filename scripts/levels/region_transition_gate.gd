class_name RegionTransitionGate
extends InteractableBase
## Reusable bidirectional region gate with optional quest lock and confirmation.

@export var transition_id: String = ""
@export var source_region_id: String = "darkpine_forest"
@export var destination_region_id: String = "hearthhold_camp"
@export var destination_scene_path: String = ""
@export var destination_spawn_id: String = ""
@export var required_quest_id: String = ""
@export var required_quest_state: String = "active"
@export var recommended_level: int = 0
@export var confirmation_required: bool = true
@export var locked_message: String = "The path is blocked."
@export var prompt_override: String = ""

var _pending_confirm: bool = false
var _entering: bool = false


func _ready() -> void:
	super._ready()
	add_to_group("region_transition_gate")
	if destination_scene_path == "":
		destination_scene_path = "res://scenes/levels/%s/%s.tscn" % [destination_region_id, destination_region_id]
	if prompt_override != "":
		prompt_text = prompt_override
	elif prompt_text == "Interact":
		prompt_text = "Travel to %s" % destination_region_id.replace("_", " ").capitalize()
	if not DialogueManager.dialogue_choice_selected.is_connected(_on_dialogue_choice):
		DialogueManager.dialogue_choice_selected.connect(_on_dialogue_choice)
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _on_interact(player: Node) -> void:
	if _entering or RegionTransitionManager.is_transition_in_progress():
		return
	if player is PlayerController:
		GameManager.interacting_player_index = (player as PlayerController).player_index
	if GameManager.is_local_coop() and not GameManager.living_players_near(global_position, 6.0):
		var leader := player if player is Node3D else GameManager.get_player(0)
		var yaw := (leader as Node3D).rotation.y if leader is Node3D else 0.0
		GameManager.pull_distant_companions(global_position, yaw, 6.0)
		if not GameManager.living_players_near(global_position, 8.0):
			DialogueManager.start_dialogue("region_gate_wait", [
				{"speaker": "Travel", "text": "Both living exiles must reach the gate before traveling."},
			], [], {"from_interact": true, "interacting_player_index": GameManager.interacting_player_index})
			return
	if not _is_unlocked():
		DialogueManager.start_dialogue("region_gate_locked", [
			{"speaker": "Path", "text": locked_message},
		], [], {"from_interact": true})
		return
	if recommended_level > 0 and _player_level(player) < recommended_level:
		DialogueManager.start_dialogue("region_gate_warning", [
			{
				"speaker": "Path",
				"text": "Recommended level %d.\nProceed anyway?" % recommended_level,
			},
		], ["Proceed", "Cancel"], {"from_interact": true, "confirm_label": "Proceed", "cancel_label": "Cancel"})
		_pending_confirm = true
		return
	if confirmation_required:
		_pending_confirm = true
		DialogueManager.start_dialogue("region_gate_confirm", [
			{
				"speaker": "Travel",
				"text": "Leave %s and travel to %s?" % [
					source_region_id.replace("_", " ").capitalize(),
					destination_region_id.replace("_", " ").capitalize(),
				],
			},
		], ["Travel", "Cancel"], {"from_interact": true, "confirm_label": "Travel", "cancel_label": "Cancel"})
		return
	_begin_transition()


func _on_dialogue_choice(index: int) -> void:
	if not _pending_confirm or _entering:
		return
	_pending_confirm = false
	if index != 0:
		return
	_begin_transition()


func _on_dialogue_ended() -> void:
	_pending_confirm = false


func _begin_transition() -> void:
	if _entering:
		return
	_entering = true
	if GameManager.is_local_coop():
		var leader := GameManager.get_player(0)
		var yaw: float = (leader as Node3D).rotation.y if leader is Node3D else 0.0
		GameManager.pull_distant_companions(global_position, yaw, 6.0)
	await RegionTransitionManager.request_region_transition(
		source_region_id,
		destination_region_id,
		transition_id,
		destination_scene_path,
		destination_spawn_id
	)
	_entering = false


func _is_unlocked() -> bool:
	if transition_id == "shattered_coast_to_blightreach":
		return "the_sunken_crown" in QuestManager.completed_quests \
			and InventoryManager.has_item("tidebound_crown")
	if transition_id == "blightreach_to_ember_wastes":
		return "heart_of_the_blight" in QuestManager.completed_quests \
			and InventoryManager.has_item("ember_wastes_pass")
	if transition_id == "ember_wastes_to_sunless_dominion":
		return "heart_of_the_wastes" in QuestManager.completed_quests \
			and InventoryManager.has_item("sunless_dominion_pass")
	if required_quest_id == "":
		return true
	match required_quest_state:
		"completed":
			if required_quest_id in QuestManager.completed_quests:
				return true
		"active":
			if QuestManager.active_quests.has(required_quest_id):
				return true
		_:
			return true
	if transition_id in ["rotfen_to_ashfall", "ashfall_to_rotfen"]:
		return InventoryManager.has_item("marsh_sigil") \
			or "depths_of_reliquary" in QuestManager.completed_quests
	if transition_id == "ashfall_to_frostgrave":
		return "heart_of_blackvein" in QuestManager.completed_quests \
			or InventoryManager.has_item("frostgrave_pass")
	if transition_id == "frostgrave_to_shattered_coast":
		return "the_pale_heart" in QuestManager.completed_quests \
			and InventoryManager.has_item("paleheart_relic")
	if transition_id == "shattered_coast_to_blightreach":
		return "the_sunken_crown" in QuestManager.completed_quests \
			and InventoryManager.has_item("tidebound_crown")
	return false


func _player_level(player: Node) -> int:
	if player and player.has_node("StatsComponent"):
		return int(player.get_node("StatsComponent").level)
	return 1
