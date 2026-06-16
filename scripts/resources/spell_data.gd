class_name SpellData
extends Resource
## Data definition for a single spell.

@export var spell_id: String = ""
@export var display_name: String = ""
@export var school: String = "fire"
@export var description: String = ""
@export var spell_type: String = "projectile"  # projectile, area, cone
@export var focus_cost: float = 15.0
@export var cooldown: float = 1.0
@export var cast_time: float = 0.0
@export var range: float = 18.0
@export var damage: float = 10.0
@export var heal_amount: float = 0.0
@export var radius: float = 0.0
@export var speed: float = 18.0
@export var status_effect: String = ""
@export var status_tick_damage: float = 0.0
@export var status_tick_count: int = 0
@export var status_tick_interval: float = 1.0
@export var scaling_stat: String = "intelligence"
@export var required_level: int = 1
@export var required_skill_node: String = ""
@export var vfx_scene: PackedScene
@export var sfx_path: String = "spell"
@export var icon: Texture2D
@export var is_unlocked: bool = false
