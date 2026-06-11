class_name EnemyHealthBar
extends Node3D
## World-space HP bar above an enemy; hidden until first damage.

@export var head_offset: float = 2.15
@export var bar_width: float = 1.1
@export var bar_height: float = 0.12

var _sprite: Sprite3D
var _viewport: SubViewport
var _fill: ColorRect
var _revealed: bool = false


func _ready() -> void:
	position = Vector3(0.0, head_offset, 0.0)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(160, 20)
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewport.add_child(root)

	var track := ColorRect.new()
	track.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	track.color = Color(0.06, 0.06, 0.08, 0.95)
	root.add_child(track)

	_fill = ColorRect.new()
	_fill.anchor_top = 0.0
	_fill.anchor_bottom = 1.0
	_fill.anchor_left = 0.0
	_fill.anchor_right = 0.0
	_fill.offset_left = 1.0
	_fill.offset_top = 1.0
	_fill.offset_bottom = -1.0
	_fill.color = Color(0.85, 0.14, 0.1)
	root.add_child(_fill)

	_sprite = Sprite3D.new()
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.texture = _viewport.get_texture()
	_sprite.pixel_size = bar_width / 160.0
	_sprite.no_depth_test = true
	_sprite.render_priority = 10
	add_child(_sprite)
	visible = false


func bind(health: HealthComponent) -> void:
	if not health.health_changed.is_connected(_on_health_changed):
		health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.current_health, health.max_health)


func _on_health_changed(current: float, maximum: float) -> void:
	if maximum <= 0.0:
		return
	var ratio := clampf(current / maximum, 0.0, 1.0)
	_fill.offset_right = 158.0 * ratio
	if not _revealed and current < maximum:
		_reveal()
	if _revealed and current <= 0.0:
		visible = false


func _reveal() -> void:
	_revealed = true
	visible = true
