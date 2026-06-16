class_name CathedralSporeVent
extends Area3D
## Spore vent hazard — telegraphed poison/spore buildup.

const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")
const _DamageData := preload("res://scripts/combat/damage_data.gd")

@export var vent_id: String = ""
@export var pulse_interval: float = 4.5
@export var damage: float = 5.0

var _timer: float = 2.0
var _disabled: bool = false


func _ready() -> void:
	add_to_group("cathedral_spore_vent")
	if vent_id == "library" and CathedralState.brazier_b:
		_disabled = true
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.5, 2.0, 2.5)
	col.shape = box
	add_child(col)
	body_entered.connect(_on_enter)


func disable_vent() -> void:
	_disabled = true
	visible = false
	monitoring = false


func _process(delta: float) -> void:
	if _disabled:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = pulse_interval
		_pulse()


func _pulse() -> void:
	AudioManager.play_sfx("spore_vent")
	for body in get_overlapping_bodies():
		_apply(body)


func _on_enter(body: Node3D) -> void:
	if _disabled or not body.is_in_group("player"):
		return
	_apply(body)


func _apply(body: Node3D) -> void:
	if body.has_node("StatusEffectsComponent"):
		var status := body.get_node("StatusEffectsComponent") as _StatusEffects
		status.set_in_spore_zone(true)
		status.add_blight_buildup(5.0)
	if body.has_node("HealthComponent"):
		body.get_node("HealthComponent").apply_damage(_DamageData.create_physical(damage, null))
