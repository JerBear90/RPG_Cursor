class_name CampSite
extends InteractableBase

signal camp_rest_started


func _ready() -> void:
	add_to_group("map_camp")
	super._ready()
	prompt_text = "Make Camp"


func _on_interact(player: Node) -> void:
	if GameManager.in_combat:
		return
	if GameManager.active_player_count > 1:
		if not GameManager.all_players_near(global_position, 5.0):
			DialogueManager.start_dialogue("camp_wait", [
				{"speaker": "Camp", "text": "Both exiles must be at the fire before you rest."},
			])
			return
	for p in GameManager.get_alive_players():
		_rest_player(p)
	camp_rest_started.emit()
	AudioManager.play_music("camp")


func _rest_player(player: Node) -> void:
	var health := player.get_node_or_null("HealthComponent") as HealthComponent
	var stamina := player.get_node_or_null("StaminaComponent") as StaminaComponent
	var needs := player.get_node_or_null("SurvivalNeedsComponent") as SurvivalNeedsComponent
	if health:
		health.heal(health.max_health * 0.5)
	if stamina:
		stamina.restore(stamina.max_stamina)
	if needs:
		needs.rest_at_camp()
