class_name SkillNodeData
extends Resource
## Single skill-tree node definition.

@export var node_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var branch: String = ""
@export var required_level: int = 1
@export var required_previous_node: String = ""
@export var cost: int = 1
@export var max_rank: int = 1
@export var stat_bonus: Dictionary = {}
@export var unlock_spell_id: String = ""
@export var unlock_ability_id: String = ""
@export var passive_effect: String = ""
@export var passive_value_per_rank: float = 0.0
@export var icon: Texture2D
@export var position: Vector2 = Vector2.ZERO
@export var requires: Array[String] = []
