extends Control
class_name PlayerHud
## Production HUD shell — corner anchors in scene; Shell uses container fill only.

const AbilitySlotScene := preload("res://ui/components/ability_slot.tscn")
const InputLabels := preload("res://ui/themes/ui_input_labels.gd")
const ThinBarScene := preload("res://ui/components/thin_bar.gd")
const _StatusEffects = preload("res://scripts/combat/status_effects_component.gd")
const MINIMAP_LIVE_DIAG := false

const ABILITY_SLOT_DEFS: Array[Dictionary] = [
	{"action": "light_attack", "name": "Light Attack", "id": "light", "cost": -1},
	{"action": "heavy_attack", "name": "Heavy Attack", "id": "heavy", "cost": -1},
	{"action": "quick_spell", "name": "Quick Spell", "id": "spell", "cost": 8},
	{"action": "dodge", "name": "Dodge", "id": "dodge", "cost": -1},
	{"action": "block", "name": "Block", "id": "block", "cost": -1},
	{"action": "interact", "name": "Interact", "id": "interact", "cost": -1},
]

const _PlayerHealthDebug = preload("res://scripts/debug/player_health_debug.gd")

@onready var _safe: MarginContainer = %SafeArea
@onready var _shell: Control = %Shell
@onready var _skill_row: HBoxContainer = %SkillRow
@onready var _quest_tracker: QuestTrackerPanel = %QuestTracker
@onready var _interaction: InteractionPrompt = %InteractionPrompt
@onready var _toast: NotificationToast = %NotificationToast
@onready var _xp_bar: Control = %XpBar
@onready var _minimap_panel: PanelContainer = %MinimapPanel
@onready var health_frame: VitalFrame = %HealthOrb
@onready var mana_frame: VitalFrame = %ManaOrb

var health_component: HealthComponent
var _bound_health_component: HealthComponent
var _ability_slots: Array[AbilitySlot] = []
var minimap: Control
var _minimap_diag_style: StyleBoxFlat
var _bound_player: Node
var _health_bind_warned: bool = false
var _cold_bar: ThinBar
var _blight_bar: ThinBar
var _heat_bar: ThinBar
var _dehydration_bar: ThinBar
var _bound_status: _StatusEffects
var _blight_status: _StatusEffects
var _desert_status: _StatusEffects
var _dread_bar: ThinBar
var _shadow_bar: ThinBar
var _dominion_status: _StatusEffects
var _player2_status: _StatusEffects


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_root_full_rect()
	ArpgTheme.apply_to(self)
	_ensure_shell_container_fill()
	_bind_vitals()
	_style_hud()
	_hide_legacy_distance_label()
	call_deferred("_build_ability_slots")
	if _interaction:
		_interaction.hide_prompt()
	ensure_minimap_visible()
	call_deferred("ensure_minimap_visible")
	call_deferred("_align_bottom_vitals")
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)
	call_deferred("_apply_safe_margins")
	if InputManager.has_signal("device_changed") and not InputManager.device_changed.is_connected(_on_input_device_changed):
		InputManager.device_changed.connect(_on_input_device_changed)
	if InputManager.has_signal("bindings_changed") and not InputManager.bindings_changed.is_connected(_refresh_ability_binding_labels):
		InputManager.bindings_changed.connect(_refresh_ability_binding_labels)
	if not GameManager.player_spawned.is_connected(_on_game_player_spawned):
		GameManager.player_spawned.connect(_on_game_player_spawned)
	call_deferred("_try_bind_spawned_player")


func _on_game_player_spawned(player: Node, index: int) -> void:
	if index == 0:
		bind_player_health(player)


func _try_bind_spawned_player() -> void:
	var player := GameManager.get_player(0)
	if player and is_instance_valid(player):
		bind_player_health(player)


func _ensure_root_full_rect() -> void:
	layout_mode = 1
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	if _safe:
		_safe.layout_mode = 1
		_safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_safe.offset_left = 0.0
		_safe.offset_top = 0.0
		_safe.offset_right = 0.0
		_safe.offset_bottom = 0.0


func _ensure_shell_container_fill() -> void:
	if _shell == null:
		return
	_shell.layout_mode = 2
	_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_shell.custom_minimum_size = Vector2.ZERO
	_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _apply_safe_margins() -> void:
	if _safe == null:
		return
	var m := UiMetrics.SPACE_SAFE
	_safe.add_theme_constant_override("margin_left", m)
	_safe.add_theme_constant_override("margin_top", m)
	_safe.add_theme_constant_override("margin_right", m)
	_safe.add_theme_constant_override("margin_bottom", m)


func _hide_legacy_distance_label() -> void:
	var legacy := get_node_or_null("%QuestDistanceLabel") as Label
	if legacy:
		legacy.visible = false
		legacy.text = ""
		legacy.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _bind_vitals() -> void:
	_ensure_health_frame()
	if health_frame:
		health_frame.stat_kind = "health"
	if mana_frame:
		mana_frame.stat_kind = "mana"


func _ensure_health_frame() -> VitalFrame:
	if health_frame != null and is_instance_valid(health_frame):
		return health_frame
	health_frame = get_node_or_null("%HealthOrb") as VitalFrame
	if health_frame == null:
		health_frame = get_node_or_null(
			"SafeArea/Shell/BottomLeft/PlayerStats/HealthOrb"
		) as VitalFrame
	return health_frame


func _style_hud() -> void:
	var region := get_node_or_null("%RegionLabel") as Label
	var currency := get_node_or_null("%CurrencyLabel") as Label
	if region:
		ArpgTheme.style_label(region, UiMetrics.FONT_MD, UiColors.TEXT_PRIMARY)
		region.add_theme_color_override("font_shadow_color", UiColors.SHADOW)
		region.add_theme_constant_override("shadow_offset_x", 1)
		region.add_theme_constant_override("shadow_offset_y", 1)
	if currency:
		ArpgTheme.style_label(currency, UiMetrics.FONT_MD, UiColors.TEXT_CURRENCY)
		currency.add_theme_color_override("font_color", UiColors.TEXT_CURRENCY)
		currency.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
		currency.add_theme_constant_override("shadow_offset_x", 1)
		currency.add_theme_constant_override("shadow_offset_y", 1)
	var currency_plate := get_node_or_null("SafeArea/Shell/TopRight/RightSideContainer/RegionAndCurrency/CurrencyPlate") as PanelContainer
	if currency_plate:
		currency_plate.add_theme_stylebox_override(
			"panel",
			ArpgTheme.make_panel(UiColors.PANEL_BG_DEEP, UiColors.BORDER_GOLD, UiMetrics.RADIUS_SM)
		)
	var currency_icon := get_node_or_null("%CurrencyIcon") as TextureRect
	if currency_icon:
		currency_icon.texture = UiIconRegistry.get_icon("currency")
		currency_icon.custom_minimum_size = Vector2(18, 18)
		currency_icon.modulate = UiColors.TEXT_CURRENCY_GLOW
		currency_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		currency_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var top_right := get_node_or_null("SafeArea/Shell/TopRight") as Control
	if top_right:
		top_right.visible = true
	_style_bars()


func _style_bars() -> void:
	var specs := {
		"%HungerBar": [UiColors.STAMINA_FILL, 3.0],
		"%ThirstBar": [UiColors.MANA_FILL, 3.0],
		"%BossHealthBar": [UiColors.HEALTH_FILL, UiMetrics.BAR_HP],
	}
	for path_key in specs.keys():
		var bar := get_node_or_null(path_key) as ThinBar
		if bar:
			bar.set_bar_color(specs[path_key][0])
			bar.set_bar_height(specs[path_key][1])


func _build_ability_slots() -> void:
	if _skill_row == null:
		return
	for c in _skill_row.get_children():
		c.queue_free()
	_ability_slots.clear()
	for spec in ABILITY_SLOT_DEFS:
		var slot := AbilitySlotScene.instantiate() as AbilitySlot
		var action: String = spec.action
		var kb: String = InputLabels.get_primary_binding_text(StringName(action), InputManager.DEVICE_KEYBOARD)
		var pad: String = InputLabels.get_primary_binding_text(StringName(action), InputManager.DEVICE_GAMEPAD)
		slot.configure(spec.name, kb, spec.id, spec.cost, pad)
		_skill_row.add_child(slot)
		_ability_slots.append(slot)
	_refresh_ability_binding_labels()


func _on_input_device_changed(device: int) -> void:
	_refresh_ability_binding_labels(device)


func _refresh_ability_binding_labels(device: int = -1) -> void:
	var active_device := device if device >= 0 else InputManager.current_device
	for i in _ability_slots.size():
		var action: String = ABILITY_SLOT_DEFS[i].action
		var kb: String = InputLabels.get_primary_binding_text(StringName(action), InputManager.DEVICE_KEYBOARD)
		var pad: String = InputLabels.get_primary_binding_text(StringName(action), InputManager.DEVICE_GAMEPAD)
		_ability_slots[i].update_binding_labels(kb, pad, active_device)


func update_ability_slot(index: int, display_name: String, ability_id: String, mana_cost: int, action: String = "") -> void:
	if index < 0 or index >= _ability_slots.size():
		return
	var slot := _ability_slots[index]
	var act: String = action if action != "" else str(ABILITY_SLOT_DEFS[index].action)
	var kb: String = InputLabels.get_primary_binding_text(StringName(act), InputManager.DEVICE_KEYBOARD)
	var pad: String = InputLabels.get_primary_binding_text(StringName(act), InputManager.DEVICE_GAMEPAD)
	slot.configure(display_name, kb, ability_id, mana_cost, pad)


func set_slot_cooldown(index: int, ratio: float, seconds_left: float = -1.0) -> void:
	if index >= 0 and index < _ability_slots.size():
		_ability_slots[index].set_cooldown(ratio, seconds_left)


func set_slot_locked(index: int, locked: bool) -> void:
	if index >= 0 and index < _ability_slots.size():
		_ability_slots[index].set_locked(locked)


func set_slot_insufficient(index: int, insufficient: bool) -> void:
	if index >= 0 and index < _ability_slots.size():
		_ability_slots[index].set_insufficient_resource(insufficient)


func set_skill_highlight(index: int, active: bool) -> void:
	for i in _ability_slots.size():
		_ability_slots[i].set_active(i == index and active)
		_ability_slots[i].set_selected(i == index and active)


func update_spell_slot(spell_label: String, mana_cost: int = 8) -> void:
	update_ability_slot(2, spell_label if spell_label != "" else "Quick Spell", "spell", mana_cost, "quick_spell")


func set_hp_values(current: float, maximum: float, animate: bool = true) -> void:
	_PlayerHealthDebug.log_hud_update("set_hp_values", current, maximum)
	var frame := _ensure_health_frame()
	if frame:
		frame.set_values(current, maximum, animate)
	elif not _health_bind_warned:
		_health_bind_warned = true
		push_warning("PlayerHud: HealthOrb unavailable for HP sync.")


func bind_player_health(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		push_error("Health HUD binding failed: invalid player.")
		return
	var component := player.get_node_or_null("HealthComponent") as HealthComponent
	if component == null:
		component = player.find_child("HealthComponent", true, false) as HealthComponent
	if component == null:
		push_error("Health HUD binding failed: HealthComponent missing on %s" % player.get_path())
		return
	if is_instance_valid(_bound_health_component) and _bound_health_component != component:
		if _bound_health_component.health_changed.is_connected(_on_health_changed):
			_bound_health_component.health_changed.disconnect(_on_health_changed)
	_bound_player = player
	bind_health_component(component)
	_log_health_bind(player, component)


func _log_health_bind(player: Node, component: HealthComponent) -> void:
	if not _PlayerHealthDebug.DEBUG_PLAYER_HEALTH:
		return
	print(
		"=== HEALTH HUD BINDING ===\n"
		+ "Active player path: %s\n" % player.get_path()
		+ "Active player ID: %d\n" % player.get_instance_id()
		+ "Active HealthComponent path: %s\n" % component.get_path()
		+ "Active HealthComponent ID: %d\n" % component.get_instance_id()
		+ "HUD path: %s\n" % get_path()
		+ "VitalFrame path: %s\n" % (_ensure_health_frame().get_path() if _ensure_health_frame() else "<missing>")
		+ "HUD-bound health ID: %d\n" % component.get_instance_id()
		+ "Initial synchronized health: %s / %s\n" % [component.current_health, component.max_health]
		+ "=========================="
	)


func bind_health_component(component: HealthComponent) -> void:
	if component == null or not is_instance_valid(component):
		return
	if _bound_health_component == component:
		if not component.health_changed.is_connected(_on_health_changed):
			component.health_changed.connect(_on_health_changed)
		_sync_health_display()
		return
	_unbind_health_component()
	health_component = component
	_bound_health_component = component
	if not health_component.health_changed.is_connected(_on_health_changed):
		health_component.health_changed.connect(_on_health_changed)
	_on_health_changed(health_component.current_health, health_component.max_health)


func _sync_health_display() -> void:
	if health_component == null or not is_instance_valid(health_component):
		return
	set_hp_values(health_component.current_health, health_component.max_health, false)


func _unbind_health_component() -> void:
	if health_component != null and is_instance_valid(health_component):
		if health_component.health_changed.is_connected(_on_health_changed):
			health_component.health_changed.disconnect(_on_health_changed)
	health_component = null
	_bound_health_component = null


func get_bound_player_id() -> int:
	return _bound_player.get_instance_id() if _bound_player and is_instance_valid(_bound_player) else 0


func get_bound_health_id() -> int:
	return _bound_health_component.get_instance_id() if _bound_health_component and is_instance_valid(_bound_health_component) else 0


func get_displayed_health() -> Vector2:
	var frame := _ensure_health_frame()
	if frame == null:
		return Vector2(-1.0, -1.0)
	return Vector2(frame.pending_current, frame.pending_maximum)


func get_displayed_health_text() -> String:
	var frame := _ensure_health_frame()
	if frame == null:
		return ""
	return frame.get_display_text()


func bind_to_player(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return
	var rebinding := _bound_player != null and _bound_player != player
	if rebinding:
		_unbind_player()
	_bound_player = player
	bind_player_health(player)
	if player.has_node("FocusComponent"):
		var focus := player.get_node("FocusComponent") as FocusComponent
		if not focus.focus_changed.is_connected(_on_bound_focus_changed):
			focus.focus_changed.connect(_on_bound_focus_changed)
		set_mp_values(focus.current_focus, focus.max_focus)
	if player.has_node("StaminaComponent"):
		var stamina := player.get_node("StaminaComponent") as StaminaComponent
		if not stamina.stamina_changed.is_connected(_on_bound_stamina_changed):
			stamina.stamina_changed.connect(_on_bound_stamina_changed)
		set_stamina_values(stamina.current_stamina, stamina.max_stamina)
	if player.has_node("StatsComponent"):
		var stats := player.get_node("StatsComponent") as StatsComponent
		set_level(stats.level)
		set_xp_values(float(stats.experience), float(stats.get_exp_to_next_level()))
	_bind_cold_indicator(player)
	_bind_blight_indicator(player)
	_bind_desert_indicators(player)
	_bind_dominion_indicators(player)


func _bind_desert_indicators(player: Node) -> void:
	_unbind_desert_indicators()
	if not player.has_node("StatusEffectsComponent"):
		return
	var status := player.get_node("StatusEffectsComponent") as _StatusEffects
	if status == null:
		return
	_desert_status = status
	var needs_row := get_node_or_null("SafeArea/Shell/BottomLeft/PlayerStats/NeedsRow") as HBoxContainer
	if needs_row == null:
		return
	if _heat_bar == null:
		_heat_bar = ThinBarScene.new()
		_heat_bar.name = "HeatExposureBar"
		_heat_bar.visible = false
		_heat_bar.set_bar_color(Color(0.92, 0.48, 0.22))
		_heat_bar.set_bar_height(3.0)
		_heat_bar.tooltip_text = "Heat exposure"
		needs_row.add_child(_heat_bar)
	if _dehydration_bar == null:
		_dehydration_bar = ThinBarScene.new()
		_dehydration_bar.name = "DehydrationBar"
		_dehydration_bar.visible = false
		_dehydration_bar.set_bar_color(Color(0.55, 0.72, 0.92))
		_dehydration_bar.set_bar_height(3.0)
		_dehydration_bar.tooltip_text = "Dehydration"
		needs_row.add_child(_dehydration_bar)
	if not status.heat_buildup_changed.is_connected(_on_heat_buildup_changed):
		status.heat_buildup_changed.connect(_on_heat_buildup_changed)
	if not status.heat_applied.is_connected(_on_heat_applied):
		status.heat_applied.connect(_on_heat_applied)
	if not status.heat_cleared.is_connected(_on_heat_cleared):
		status.heat_cleared.connect(_on_heat_cleared)
	if not status.dehydration_buildup_changed.is_connected(_on_dehydration_buildup_changed):
		status.dehydration_buildup_changed.connect(_on_dehydration_buildup_changed)
	if not status.dehydration_applied.is_connected(_on_dehydration_applied):
		status.dehydration_applied.connect(_on_dehydration_applied)
	if not status.dehydration_cleared.is_connected(_on_dehydration_cleared):
		status.dehydration_cleared.connect(_on_dehydration_cleared)
	_on_heat_buildup_changed(status.heat_buildup, status.heat_threshold)
	_on_dehydration_buildup_changed(status.dehydration_buildup, status.dehydration_threshold)


func _unbind_desert_indicators() -> void:
	if _desert_status != null and is_instance_valid(_desert_status):
		if _desert_status.heat_buildup_changed.is_connected(_on_heat_buildup_changed):
			_desert_status.heat_buildup_changed.disconnect(_on_heat_buildup_changed)
		if _desert_status.heat_applied.is_connected(_on_heat_applied):
			_desert_status.heat_applied.disconnect(_on_heat_applied)
		if _desert_status.heat_cleared.is_connected(_on_heat_cleared):
			_desert_status.heat_cleared.disconnect(_on_heat_cleared)
		if _desert_status.dehydration_buildup_changed.is_connected(_on_dehydration_buildup_changed):
			_desert_status.dehydration_buildup_changed.disconnect(_on_dehydration_buildup_changed)
		if _desert_status.dehydration_applied.is_connected(_on_dehydration_applied):
			_desert_status.dehydration_applied.disconnect(_on_dehydration_applied)
		if _desert_status.dehydration_cleared.is_connected(_on_dehydration_cleared):
			_desert_status.dehydration_cleared.disconnect(_on_dehydration_cleared)
	_desert_status = null


func _on_heat_buildup_changed(current: float, threshold: float) -> void:
	if _heat_bar == null:
		return
	var in_desert := GameManager.current_region_id in ["ember_wastes", "pyreheart_ziggurat"]
	var should_show := in_desert and (current > 1.0 or (_desert_status != null and _desert_status.heat_active))
	_heat_bar.visible = should_show
	if not should_show:
		return
	var ratio := clampf(current / maxf(threshold, 1.0), 0.0, 1.0)
	_heat_bar.max_value = threshold
	_heat_bar.value = current
	if ratio >= 0.85:
		_heat_bar.set_bar_color(Color(0.95, 0.35, 0.18))
	elif ratio >= 0.55:
		_heat_bar.set_bar_color(Color(0.92, 0.48, 0.22))
	else:
		_heat_bar.set_bar_color(Color(0.85, 0.58, 0.28))


func _on_heat_applied() -> void:
	if _heat_bar:
		_heat_bar.set_bar_color(Color(0.98, 0.32, 0.15))
		_heat_bar.visible = true


func _on_heat_cleared() -> void:
	if _heat_bar and (_desert_status == null or _desert_status.heat_buildup <= 1.0):
		_heat_bar.visible = false
		_heat_bar.value = 0.0


func _on_dehydration_buildup_changed(current: float, threshold: float) -> void:
	if _dehydration_bar == null:
		return
	var in_desert := GameManager.current_region_id in ["ember_wastes", "pyreheart_ziggurat"]
	var should_show := in_desert and (current > 1.0 or (_desert_status != null and _desert_status.dehydration_active))
	_dehydration_bar.visible = should_show
	if not should_show:
		return
	var ratio := clampf(current / maxf(threshold, 1.0), 0.0, 1.0)
	_dehydration_bar.max_value = threshold
	_dehydration_bar.value = current
	if ratio >= 0.85:
		_dehydration_bar.set_bar_color(Color(0.45, 0.68, 0.95))
	elif ratio >= 0.55:
		_dehydration_bar.set_bar_color(Color(0.55, 0.72, 0.92))
	else:
		_dehydration_bar.set_bar_color(Color(0.62, 0.78, 0.88))


func _on_dehydration_applied() -> void:
	if _dehydration_bar:
		_dehydration_bar.set_bar_color(Color(0.4, 0.65, 0.98))
		_dehydration_bar.visible = true


func _on_dehydration_cleared() -> void:
	if _dehydration_bar and (_desert_status == null or _desert_status.dehydration_buildup <= 1.0):
		_dehydration_bar.visible = false
		_dehydration_bar.value = 0.0


func _bind_blight_indicator(player: Node) -> void:
	_unbind_blight_indicator()
	if not player.has_node("StatusEffectsComponent"):
		return
	var status := player.get_node("StatusEffectsComponent") as _StatusEffects
	if status == null:
		return
	_blight_status = status
	if _blight_bar == null:
		var needs_row := get_node_or_null("SafeArea/Shell/BottomLeft/PlayerStats/NeedsRow") as HBoxContainer
		if needs_row == null:
			return
		_blight_bar = ThinBarScene.new()
		_blight_bar.name = "BlightExposureBar"
		_blight_bar.visible = false
		_blight_bar.set_bar_color(Color(0.55, 0.82, 0.35))
		_blight_bar.set_bar_height(3.0)
		_blight_bar.tooltip_text = "Blight exposure"
		needs_row.add_child(_blight_bar)
	if not status.blight_buildup_changed.is_connected(_on_blight_buildup_changed):
		status.blight_buildup_changed.connect(_on_blight_buildup_changed)
	if not status.blight_applied.is_connected(_on_blight_applied):
		status.blight_applied.connect(_on_blight_applied)
	if not status.blight_cleared.is_connected(_on_blight_cleared):
		status.blight_cleared.connect(_on_blight_cleared)
	if not status.corruption_applied.is_connected(_on_corruption_applied):
		status.corruption_applied.connect(_on_corruption_applied)
	if not status.corruption_cleared.is_connected(_on_corruption_cleared):
		status.corruption_cleared.connect(_on_corruption_cleared)
	_on_blight_buildup_changed(status.blight_buildup, status.blight_threshold)


func _unbind_blight_indicator() -> void:
	if _blight_status != null and is_instance_valid(_blight_status):
		if _blight_status.blight_buildup_changed.is_connected(_on_blight_buildup_changed):
			_blight_status.blight_buildup_changed.disconnect(_on_blight_buildup_changed)
		if _blight_status.blight_applied.is_connected(_on_blight_applied):
			_blight_status.blight_applied.disconnect(_on_blight_applied)
		if _blight_status.blight_cleared.is_connected(_on_blight_cleared):
			_blight_status.blight_cleared.disconnect(_on_blight_cleared)
		if _blight_status.corruption_applied.is_connected(_on_corruption_applied):
			_blight_status.corruption_applied.disconnect(_on_corruption_applied)
		if _blight_status.corruption_cleared.is_connected(_on_corruption_cleared):
			_blight_status.corruption_cleared.disconnect(_on_corruption_cleared)
	_blight_status = null


func _on_blight_buildup_changed(current: float, threshold: float) -> void:
	if _blight_bar == null:
		return
	var in_blight := GameManager.current_region_id in ["blightreach", "blightspire_cathedral"]
	var should_show := in_blight and (current > 1.0 or (_blight_status != null and _blight_status.blight_exposure_active))
	_blight_bar.visible = should_show
	if not should_show:
		return
	var ratio := clampf(current / maxf(threshold, 1.0), 0.0, 1.0)
	_blight_bar.max_value = threshold
	_blight_bar.value = current
	if _blight_status != null and _blight_status.corruption_active:
		_blight_bar.set_bar_color(Color(0.72, 0.35, 0.92))
	elif ratio >= 0.85:
		_blight_bar.set_bar_color(Color(0.65, 0.9, 0.42))
	elif ratio >= 0.55:
		_blight_bar.set_bar_color(Color(0.55, 0.78, 0.38))
	else:
		_blight_bar.set_bar_color(Color(0.45, 0.65, 0.32))


func _on_blight_applied() -> void:
	if _blight_bar:
		_blight_bar.set_bar_color(Color(0.7, 0.92, 0.45))
		_blight_bar.visible = true


func _on_blight_cleared() -> void:
	if _blight_bar and (_blight_status == null or _blight_status.blight_buildup <= 1.0):
		_blight_bar.visible = false
		_blight_bar.value = 0.0


func _on_corruption_applied() -> void:
	if _blight_bar:
		_blight_bar.set_bar_color(Color(0.78, 0.4, 0.95))
		_blight_bar.visible = true


func _on_corruption_cleared() -> void:
	_on_blight_buildup_changed(_blight_status.blight_buildup if _blight_status else 0.0, _blight_status.blight_threshold if _blight_status else 100.0)


func bind_player2_status(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return
	if player.has_node("StatusEffectsComponent"):
		_player2_status = player.get_node("StatusEffectsComponent") as _StatusEffects


func _bind_dominion_indicators(player: Node) -> void:
	_unbind_dominion_indicators()
	if not player.has_node("StatusEffectsComponent"):
		return
	var status := player.get_node("StatusEffectsComponent") as _StatusEffects
	if status == null:
		return
	_dominion_status = status
	var needs_row := get_node_or_null("SafeArea/Shell/BottomLeft/PlayerStats/NeedsRow") as HBoxContainer
	if needs_row == null:
		return
	if _dread_bar == null:
		_dread_bar = ThinBarScene.new()
		_dread_bar.name = "DreadExposureBar"
		_dread_bar.visible = false
		_dread_bar.set_bar_color(Color(0.55, 0.42, 0.88))
		_dread_bar.set_bar_height(3.0)
		_dread_bar.tooltip_text = "Dread"
		needs_row.add_child(_dread_bar)
	if _shadow_bar == null:
		_shadow_bar = ThinBarScene.new()
		_shadow_bar.name = "ShadowExposureBar"
		_shadow_bar.visible = false
		_shadow_bar.set_bar_color(Color(0.32, 0.28, 0.62))
		_shadow_bar.set_bar_height(3.0)
		_shadow_bar.tooltip_text = "Shadow exposure"
		needs_row.add_child(_shadow_bar)
	if not status.dread_buildup_changed.is_connected(_on_dread_buildup_changed):
		status.dread_buildup_changed.connect(_on_dread_buildup_changed)
	if not status.dread_applied.is_connected(_on_dread_applied):
		status.dread_applied.connect(_on_dread_applied)
	if not status.dread_cleared.is_connected(_on_dread_cleared):
		status.dread_cleared.connect(_on_dread_cleared)
	if not status.shadow_buildup_changed.is_connected(_on_shadow_buildup_changed):
		status.shadow_buildup_changed.connect(_on_shadow_buildup_changed)
	if not status.shadow_applied.is_connected(_on_shadow_applied):
		status.shadow_applied.connect(_on_shadow_applied)
	if not status.shadow_cleared.is_connected(_on_shadow_cleared):
		status.shadow_cleared.connect(_on_shadow_cleared)
	_on_dread_buildup_changed(status.dread_buildup, status.dread_threshold)
	_on_shadow_buildup_changed(status.shadow_buildup, status.shadow_threshold)


func _unbind_dominion_indicators() -> void:
	if _dominion_status != null and is_instance_valid(_dominion_status):
		if _dominion_status.dread_buildup_changed.is_connected(_on_dread_buildup_changed):
			_dominion_status.dread_buildup_changed.disconnect(_on_dread_buildup_changed)
		if _dominion_status.dread_applied.is_connected(_on_dread_applied):
			_dominion_status.dread_applied.disconnect(_on_dread_applied)
		if _dominion_status.dread_cleared.is_connected(_on_dread_cleared):
			_dominion_status.dread_cleared.disconnect(_on_dread_cleared)
		if _dominion_status.shadow_buildup_changed.is_connected(_on_shadow_buildup_changed):
			_dominion_status.shadow_buildup_changed.disconnect(_on_shadow_buildup_changed)
		if _dominion_status.shadow_applied.is_connected(_on_shadow_applied):
			_dominion_status.shadow_applied.disconnect(_on_shadow_applied)
		if _dominion_status.shadow_cleared.is_connected(_on_shadow_cleared):
			_dominion_status.shadow_cleared.disconnect(_on_shadow_cleared)
	_dominion_status = null


func _in_dominion_region() -> bool:
	return GameManager.current_region_id in ["sunless_dominion", "eclipse_sanctum"] \
		or DungeonManager.current_dungeon_id == "eclipse_sanctum"


func _on_dread_buildup_changed(current: float, threshold: float) -> void:
	if _dread_bar == null:
		return
	var show := _in_dominion_region() and (current > 1.0 or (_dominion_status != null and _dominion_status.dread_active))
	_dread_bar.visible = show
	if not show:
		return
	var ratio := current / maxf(threshold, 1.0)
	_dread_bar.value = clampf(ratio * 100.0, 0.0, 100.0)
	if ratio >= 0.85:
		_dread_bar.set_bar_color(Color(0.78, 0.35, 0.95))
	elif ratio >= 0.55:
		_dread_bar.set_bar_color(Color(0.62, 0.42, 0.88))
	else:
		_dread_bar.set_bar_color(Color(0.55, 0.42, 0.88))


func _on_dread_applied() -> void:
	if _dread_bar:
		_dread_bar.set_bar_color(Color(0.78, 0.35, 0.95))
		_dread_bar.visible = true


func _on_dread_cleared() -> void:
	if _dread_bar and (_dominion_status == null or _dominion_status.dread_buildup <= 1.0):
		_dread_bar.visible = false
		_dread_bar.value = 0.0


func _on_shadow_buildup_changed(current: float, threshold: float) -> void:
	if _shadow_bar == null:
		return
	var show := _in_dominion_region() and (current > 1.0 or (_dominion_status != null and _dominion_status.shadow_active))
	_shadow_bar.visible = show
	if not show:
		return
	var ratio := current / maxf(threshold, 1.0)
	_shadow_bar.value = clampf(ratio * 100.0, 0.0, 100.0)


func _on_shadow_applied() -> void:
	if _shadow_bar:
		_shadow_bar.set_bar_color(Color(0.45, 0.32, 0.82))
		_shadow_bar.visible = true


func _on_shadow_cleared() -> void:
	if _shadow_bar and (_dominion_status == null or _dominion_status.shadow_buildup <= 1.0):
		_shadow_bar.visible = false
		_shadow_bar.value = 0.0


func _bind_cold_indicator(player: Node) -> void:
	_unbind_cold_indicator()
	_unbind_blight_indicator()
	if not player.has_node("StatusEffectsComponent"):
		return
	_bound_status = player.get_node("StatusEffectsComponent") as _StatusEffects
	if _bound_status == null:
		return
	if _cold_bar == null:
		var needs_row := get_node_or_null("SafeArea/Shell/BottomLeft/PlayerStats/NeedsRow") as HBoxContainer
		if needs_row == null:
			return
		_cold_bar = ThinBarScene.new()
		_cold_bar.name = "ColdExposureBar"
		_cold_bar.visible = false
		_cold_bar.set_bar_color(Color(0.45, 0.78, 1.0))
		_cold_bar.set_bar_height(3.0)
		_cold_bar.tooltip_text = "Cold exposure"
		needs_row.add_child(_cold_bar)
	if not _bound_status.cold_buildup_changed.is_connected(_on_cold_buildup_changed):
		_bound_status.cold_buildup_changed.connect(_on_cold_buildup_changed)
	if not _bound_status.cold_applied.is_connected(_on_cold_applied):
		_bound_status.cold_applied.connect(_on_cold_applied)
	if not _bound_status.cold_cleared.is_connected(_on_cold_cleared):
		_bound_status.cold_cleared.connect(_on_cold_cleared)
	_on_cold_buildup_changed(_bound_status.cold_buildup, _bound_status.cold_threshold)


func _unbind_cold_indicator() -> void:
	if _bound_status != null and is_instance_valid(_bound_status):
		if _bound_status.cold_buildup_changed.is_connected(_on_cold_buildup_changed):
			_bound_status.cold_buildup_changed.disconnect(_on_cold_buildup_changed)
		if _bound_status.cold_applied.is_connected(_on_cold_applied):
			_bound_status.cold_applied.disconnect(_on_cold_applied)
		if _bound_status.cold_cleared.is_connected(_on_cold_cleared):
			_bound_status.cold_cleared.disconnect(_on_cold_cleared)
	_bound_status = null


func _on_cold_buildup_changed(current: float, threshold: float) -> void:
	if _cold_bar == null:
		return
	var should_show := current > 1.0 or (_bound_status != null and _bound_status.cold_active)
	_cold_bar.visible = should_show
	if not should_show:
		return
	var ratio := clampf(current / maxf(threshold, 1.0), 0.0, 1.0)
	_cold_bar.max_value = threshold
	_cold_bar.value = current
	if ratio >= 0.85:
		_cold_bar.set_bar_color(Color(0.55, 0.85, 1.0))
	elif ratio >= 0.55:
		_cold_bar.set_bar_color(Color(0.45, 0.72, 0.98))
	else:
		_cold_bar.set_bar_color(Color(0.35, 0.58, 0.82))


func _on_cold_applied() -> void:
	if _cold_bar:
		_cold_bar.set_bar_color(Color(0.7, 0.92, 1.0))
		_cold_bar.visible = true


func _on_cold_cleared() -> void:
	if _cold_bar:
		_cold_bar.visible = false
		_cold_bar.value = 0.0


func _on_health_changed(current: float, maximum: float) -> void:
	_PlayerHealthDebug.log_hud_update("health_changed callback", current, maximum)
	set_hp_values(current, maximum, false)


func _on_bound_focus_changed(current: float, maximum: float) -> void:
	set_mp_values(current, maximum)


func _on_bound_stamina_changed(current: float, maximum: float) -> void:
	set_stamina_values(current, maximum)


func _unbind_player() -> void:
	_unbind_cold_indicator()
	_unbind_blight_indicator()
	_unbind_desert_indicators()
	_unbind_health_component()
	if _bound_player == null or not is_instance_valid(_bound_player):
		_bound_player = null
		return
	if _bound_player.has_node("FocusComponent"):
		var focus := _bound_player.get_node("FocusComponent") as FocusComponent
		if focus.focus_changed.is_connected(_on_bound_focus_changed):
			focus.focus_changed.disconnect(_on_bound_focus_changed)
	if _bound_player.has_node("StaminaComponent"):
		var stamina := _bound_player.get_node("StaminaComponent") as StaminaComponent
		if stamina.stamina_changed.is_connected(_on_bound_stamina_changed):
			stamina.stamina_changed.disconnect(_on_bound_stamina_changed)
	_bound_player = null


func set_mp_values(current: float, maximum: float) -> void:
	if mana_frame:
		mana_frame.set_values(current, maximum)


func set_stamina_values(current: float, maximum: float) -> void:
	if health_frame:
		health_frame.set_stamina_values(current, maximum)


func set_level(level: int) -> void:
	if health_frame:
		health_frame.set_level(level)


func set_xp_values(current: float, maximum: float) -> void:
	if _xp_bar and _xp_bar.has_method("set_values"):
		_xp_bar.set_values(current, maximum)


func flash_mana_insufficient() -> void:
	if mana_frame:
		mana_frame.flash_insufficient_resource()


func show_toast(
	text: String,
	duration: float = 3.0,
	description: String = "",
	icon_key: String = "notification",
	reward: String = "",
	priority: int = 1
) -> void:
	if _toast:
		_toast.show_message(text, duration, description, icon_key, reward, priority)


func set_interact_prompt(raw: String) -> void:
	if _interaction:
		if raw.is_empty():
			_interaction.hide_prompt()
		else:
			_interaction.parse_legacy_prompt(raw)


func set_execution_visible(show_exec: bool, text: String = "Hold charged attack — Execute") -> void:
	var lbl := get_node_or_null("%ExecutionLabel") as Label
	if lbl == null:
		return
	lbl.visible = show_exec
	if show_exec:
		lbl.text = text
		ArpgTheme.style_label(lbl, UiMetrics.FONT_SM, UiColors.TEXT_DANGER)


func update_quest(title: String, lines: PackedStringArray, distance: String = "", quest_type: String = "QUEST", _spell: String = "") -> void:
	if _quest_tracker:
		_quest_tracker.set_from_objective_lines(title, lines, distance, quest_type)
	_apply_top_right_height()


func clear_quest() -> void:
	if _quest_tracker:
		_quest_tracker.clear()
	_apply_top_right_height()


func bind_minimap(control: Control) -> void:
	minimap = control
	ensure_minimap_visible()


func ensure_minimap_visible() -> void:
	var minimap_panel := _minimap_panel if _minimap_panel else get_node_or_null("%MinimapPanel") as PanelContainer
	if minimap_panel == null:
		return
	minimap_panel.visible = true
	minimap_panel.show()
	minimap_panel.z_index = 100
	var map_sz := UiMetrics.get_minimap_size(get_viewport_rect().size.x)
	var map_h := UiMetrics.get_minimap_widget_height(get_viewport_rect().size.x)
	minimap_panel.custom_minimum_size = Vector2(map_sz, map_h)
	if MINIMAP_LIVE_DIAG:
		_apply_live_minimap_diag(minimap_panel)
	else:
		_clear_live_minimap_diag(minimap_panel)
		minimap_panel.add_theme_stylebox_override("panel", ArpgTheme.make_panel())
	var widget := get_node_or_null("%MinimapWidget") as Control
	if widget:
		widget.visible = true
		widget.show()
		widget.z_index = 101
	var top_right := get_node_or_null("SafeArea/Shell/TopRight") as Control
	if top_right:
		top_right.visible = true
	_apply_top_right_height()


func _apply_live_minimap_diag(panel: PanelContainer) -> void:
	if _minimap_diag_style == null:
		_minimap_diag_style = StyleBoxFlat.new()
		_minimap_diag_style.bg_color = Color(1.0, 0.0, 1.0, 0.88)
		_minimap_diag_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", _minimap_diag_style)
	var label := panel.get_node_or_null("LiveDiagLabel") as Label
	if label == null:
		label = Label.new()
		label.name = "LiveDiagLabel"
		label.text = "LIVE MINIMAP PANEL"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.z_index = 200
		panel.add_child(label)


func _clear_live_minimap_diag(panel: PanelContainer) -> void:
	var label := panel.get_node_or_null("LiveDiagLabel") as Label
	if label:
		label.queue_free()


func _on_viewport_resized() -> void:
	_apply_safe_margins()
	_apply_top_right_height()
	call_deferred("_align_bottom_vitals")


func _align_bottom_vitals() -> void:
	var bottom_left := get_node_or_null("SafeArea/Shell/BottomLeft") as Control
	var bottom_right := get_node_or_null("SafeArea/Shell/BottomRight") as Control
	var player_stats := get_node_or_null("SafeArea/Shell/BottomLeft/PlayerStats") as VBoxContainer
	var mana_stats := get_node_or_null("SafeArea/Shell/BottomRight/ManaStats") as VBoxContainer
	if player_stats:
		player_stats.alignment = BoxContainer.ALIGNMENT_END
	if mana_stats:
		mana_stats.alignment = BoxContainer.ALIGNMENT_END
	var column_h := _measure_vital_column_height()
	if column_h <= 0.0:
		return
	if bottom_left:
		bottom_left.offset_top = -column_h
	if bottom_right:
		bottom_right.offset_top = -column_h


func _measure_vital_column_height() -> float:
	var left_h := 0.0
	var health := get_node_or_null("%HealthOrb") as Control
	var needs := get_node_or_null("SafeArea/Shell/BottomLeft/PlayerStats/NeedsRow") as Control
	var mana := get_node_or_null("%ManaOrb") as Control
	if health:
		left_h += health.get_combined_minimum_size().y
	if needs and needs.visible:
		left_h += 6.0 + needs.get_combined_minimum_size().y
	var mana_h := mana.get_combined_minimum_size().y if mana else 0.0
	return maxf(left_h, mana_h)


func _apply_top_right_height() -> void:
	var top_right := get_node_or_null("SafeArea/Shell/TopRight") as Control
	if top_right == null:
		return
	var vp_w := get_viewport_rect().size.x
	var map_sz := UiMetrics.get_minimap_size(vp_w)
	var map_h := UiMetrics.get_minimap_widget_height(vp_w)
	var widget := get_node_or_null("%MinimapWidget") as Control
	if widget and widget.has_method("_apply_scale_for_viewport"):
		widget.call("_apply_scale_for_viewport")
		map_h = maxf(map_h, widget.custom_minimum_size.y)
	var minimap_panel := get_node_or_null("%MinimapPanel") as PanelContainer
	if minimap_panel:
		minimap_panel.custom_minimum_size = Vector2(map_sz, map_h)
	var region_block := get_node_or_null("SafeArea/Shell/TopRight/RightSideContainer/RegionAndCurrency") as Control
	var region_h := 48.0
	if region_block:
		region_h = maxf(region_block.get_combined_minimum_size().y, region_block.size.y)
	var stack_h := map_h + 10.0 + region_h
	var quest := get_node_or_null("%QuestTracker") as Control
	if quest:
		quest.custom_minimum_size.x = map_sz
		if quest.visible:
			stack_h += 10.0 + maxf(quest.size.y, quest.get_combined_minimum_size().y)
	var panel_w := map_sz
	if quest and quest.visible:
		panel_w = maxf(map_sz, quest.size.x)
	top_right.offset_left = -panel_w
	top_right.offset_bottom = stack_h
