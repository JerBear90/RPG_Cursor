class_name CampSite
extends InteractableBase

signal camp_rest_started


func _ready() -> void:
	super._ready()
	prompt_text = "Make Camp"


func _on_interact(player: Node) -> void:
	if GameManager.in_combat:
		return
	if GameManager.active_player_count > 1:
		if not GameManager.all_players_near(global_position, 5.0):
			return
	_rest_player(player)
	camp_rest_started.emit()


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
