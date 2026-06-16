class_name CampSite
extends InteractableBase

const _RestartContext = preload("res://scripts/levels/level_restart_context.gd")
const _SpawnHelpers = preload("res://scripts/utilities/spawn_helpers.gd")

signal camp_rest_started

@export var town_inn_mode: bool = false
@export var checkpoint_marker_id: String = ""

var _resting: bool = false
var _pending_rest: bool = false


func _ready() -> void:
	add_to_group("map_camp")
	super._ready()
	prompt_text = "Make Camp"
	if not DialogueManager.dialogue_choice_selected.is_connected(_on_dialogue_choice):
		DialogueManager.dialogue_choice_selected.connect(_on_dialogue_choice)
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _on_interact(player: Node) -> void:
	if GameManager.in_combat:
		_show_camp_toast("Cannot rest during combat", NotificationToast.Priority.CRITICAL)
		return
	if _resting:
		return
	if player is PlayerController:
		GameManager.interacting_player_index = (player as PlayerController).player_index
	if GameManager.is_local_coop():
		if not GameManager.living_players_near(global_position, GameManager.COOP_CAMP_RADIUS):
			DialogueManager.start_dialogue("camp_wait", [
				{"speaker": "Camp", "text": "Both players must be near camp before you rest."},
			], [], {"from_interact": true, "interacting_player_index": GameManager.interacting_player_index})
			return
	_pending_rest = true
	DialogueManager.start_dialogue("camp_rest", [
		{"speaker": "Camp", "text": "Rest at the fire and recover your strength?"},
	], ["Rest", "Cancel"], {
		"from_interact": true,
		"confirm_label": "Rest",
		"cancel_label": "Cancel",
		"interacting_player_index": GameManager.interacting_player_index,
	})


func _on_dialogue_choice(index: int) -> void:
	if not _pending_rest or _resting:
		return
	_pending_rest = false
	if index != 0:
		return
	_perform_rest()


func _on_dialogue_ended() -> void:
	_pending_rest = false


func _perform_rest() -> void:
	_resting = true
	TutorialPromptManager.try_show("camp_rest")
	var had_downed := false
	for p in GameManager.get_all_registered_players():
		if GameManager.is_player_downed(p):
			had_downed = true
			break
	if had_downed and GameManager.is_local_coop():
		_show_camp_toast("Camp Rest: Reviving downed ally")
	GameManager.revive_all_dead_players(0.45)
	for p in GameManager.get_all_registered_players():
		_rest_player(p)
		_clear_player_states(p)
	var camp_pos := global_position + Vector3(1.5, 0.0, 0.0)
	if town_inn_mode:
		var cp_id := checkpoint_marker_id if checkpoint_marker_id != "" else "checkpoint_%s" % GameManager.current_region_id
		WorldStateManager.register_checkpoint(cp_id, GameManager.current_region_id, camp_pos)
		WorldStateManager.location_type = _RestartContext.LocationType.TOWN
		if GameManager.current_region_id == "ashfall_highlands":
			WorldStateManager.town_id = &"stonewatch"
		elif GameManager.current_region_id == "frostgrave_expanse":
			WorldStateManager.register_checkpoint("checkpoint_frostgrave", GameManager.current_region_id, camp_pos)
			WorldStateManager.location_type = _RestartContext.LocationType.TOWN
			WorldStateManager.town_id = &"frostwatch"
		elif GameManager.current_region_id == "shattered_coast":
			WorldStateManager.register_checkpoint("checkpoint_shattered_coast", GameManager.current_region_id, camp_pos)
			WorldStateManager.location_type = _RestartContext.LocationType.TOWN
			WorldStateManager.town_id = &"tidewatch"
		elif WorldStateManager.town_id == &"":
			WorldStateManager.town_id = StringName(GameManager.current_region_id)
	else:
		WorldStateManager.activate_camp(name, GameManager.current_region_id, camp_pos)
		if GameManager.current_region_id == "ashfall_highlands":
			WorldStateManager.register_checkpoint("checkpoint_ashfall", GameManager.current_region_id, camp_pos)
			WorldStateManager.location_type = _RestartContext.LocationType.TOWN
			WorldStateManager.town_id = &"stonewatch"
	if GameManager.current_region_id == "rotfen_marsh":
		if QuestManager.active_quests.has("into_rotfen"):
			QuestManager.advance_objective("into_rotfen", "reach_marshwatch", 1)
		if QuestManager.active_quests.has("the_missing_caravan"):
			QuestManager.advance_objective("the_missing_caravan", "return_scout", 1)
	camp_rest_started.emit()
	AudioManager.play_music("camp")
	await _reposition_party_after_rest()
	_show_camp_toast("Camp Rest Complete", NotificationToast.Priority.IMPORTANT)
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("_reset_coop_menu_state"):
			hud._reset_coop_menu_state()
			break
	_resting = false


func _reposition_party_after_rest() -> void:
	await _SpawnHelpers.place_party_at_marker(get_tree(), self)
	GameManager.refresh_coop_camera()


func _clear_player_states(player: Node) -> void:
	if player is PlayerController:
		var pc := player as PlayerController
		pc.current_state = PlayerController.State.IDLE
		pc.velocity = Vector3.ZERO
		GameManager.set_coop_player_prompt(pc.player_index, "")
	if player.has_node("Combat") and player.get_node("Combat").has_method("force_release_combat_state"):
		player.get_node("Combat").force_release_combat_state()


func _rest_player(player: Node) -> void:
	var rest_bonus := 1.0
	if player.has_node("SkillTree"):
		rest_bonus = (player.get_node("SkillTree") as Node).get_camp_rest_bonus_multiplier()
	var health := player.get_node_or_null("HealthComponent") as HealthComponent
	var stamina := player.get_node_or_null("StaminaComponent") as StaminaComponent
	var needs := player.get_node_or_null("SurvivalNeedsComponent") as SurvivalNeedsComponent
	if health:
		health.heal(health.max_health * 0.5 * rest_bonus)
	if stamina:
		stamina.restore(stamina.max_stamina)
	if player.has_node("FocusComponent"):
		var focus := player.get_node("FocusComponent") as FocusComponent
		focus.restore(focus.max_focus * rest_bonus)
	if needs:
		needs.rest_at_camp()
	if player.has_node("StatusEffectsComponent"):
		player.get_node("StatusEffectsComponent").call("clear_environmental")
	PetManager.recover_party_pet(true)


func _show_camp_toast(message: String, priority: int = NotificationToast.Priority.IMPORTANT) -> void:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast(message, 2.5, "", "notification", "", priority)
			return
