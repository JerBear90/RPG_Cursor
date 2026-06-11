extends Control
class_name PlayerHud
## Production HUD shell — corner anchors in scene; Shell uses container fill only.

const AbilitySlotScene := preload("res://ui/components/ability_slot.tscn")
const InputLabels := preload("res://ui/themes/ui_input_labels.gd")
const MINIMAP_LIVE_DIAG := false

const ABILITY_SLOT_DEFS: Array[Dictionary] = [
	{"action": "light_attack", "name": "Light Attack", "id": "light", "cost": -1},
	{"action": "heavy_attack", "name": "Heavy Attack", "id": "heavy", "cost": -1},
	{"action": "quick_spell", "name": "Quick Spell", "id": "spell", "cost": 8},
	{"action": "dodge", "name": "Dodge", "id": "dodge", "cost": -1},
	{"action": "block", "name": "Block", "id": "block", "cost": -1},
	{"action": "interact", "name": "Interact", "id": "interact", "cost": -1},
]

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
		var kb: String = InputLabels.get_action_label(action, true)
		var pad: String = InputLabels.get_action_label(action, false)
		slot.configure(spec.name, kb, spec.id, spec.cost, pad)
		if action == "block" and kb == "":
			slot.set_locked(true)
		_skill_row.add_child(slot)
		_ability_slots.append(slot)


func update_ability_slot(index: int, display_name: String, ability_id: String, mana_cost: int, action: String = "") -> void:
	if index < 0 or index >= _ability_slots.size():
		return
	var slot := _ability_slots[index]
	var act: String = action if action != "" else str(ABILITY_SLOT_DEFS[index].action)
	var kb: String = InputLabels.get_action_label(act, true)
	var pad: String = InputLabels.get_action_label(act, false)
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
	var frame := _ensure_health_frame()
	if frame:
		frame.set_values(current, maximum, animate)
	elif not _health_bind_warned:
		_health_bind_warned = true
		push_warning("PlayerHud: HealthOrb unavailable for HP sync.")


func bind_player_health(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return
	_bound_player = player
	var component := player.get_node_or_null("HealthComponent") as HealthComponent
	if component == null:
		push_error("Cannot bind HUD: active player has no HealthComponent")
		return
	bind_health_component(component)


func bind_health_component(component: HealthComponent) -> void:
	if component == null or not is_instance_valid(component):
		return
	if _bound_health_component == component:
		_sync_health_display()
		return
	_unbind_health_component()
	health_component = component
	_bound_health_component = component
	if not health_component.health_changed.is_connected(_on_health_changed):
		health_component.health_changed.connect(_on_health_changed)
	_sync_health_display()


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


func _on_health_changed(current: float, maximum: float) -> void:
	set_hp_values(current, maximum, false)


func _on_bound_focus_changed(current: float, maximum: float) -> void:
	set_mp_values(current, maximum)


func _on_bound_stamina_changed(current: float, maximum: float) -> void:
	set_stamina_values(current, maximum)


func _unbind_player() -> void:
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


func show_toast(text: String, duration: float = 3.0, description: String = "", icon_key: String = "notification") -> void:
	if _toast:
		_toast.show_message(text, duration, description, icon_key)


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
