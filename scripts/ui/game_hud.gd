extends CanvasLayer
## In-game HUD plus controller-navigable overlay menus.

const InventoryPanelScene := preload("res://scripts/ui/inventory_panel.gd")
const SkillTreePanelScene := preload("res://scripts/ui/skill_tree_panel.gd")
const SpellWheelPanelScene := preload("res://scripts/ui/spell_wheel_panel.gd")
const MerchantShopPanelScene := preload("res://scripts/ui/merchant_shop_panel.gd")
const PetWheelPanelScene := preload("res://scripts/ui/pet_wheel_panel.gd")
const _ItemUiTheme = preload("res://scripts/ui/item_ui_theme.gd")
const MinimapScene = preload("res://ui/map/minimap.tscn")
const ActionBarHud = preload("res://scripts/ui/action_bar_hud.gd")
const DialoguePanelScene = preload("res://ui/dialogue/dialogue_panel.tscn")
const ResourceGainToastScript = preload("res://ui/hud/resource_gain_toast.gd")
const XpGainToastScript = preload("res://ui/hud/xp_gain_toast.gd")

var xp_bar: Control
var hunger_bar: TextureProgressBar
var thirst_bar: TextureProgressBar
var level_label: Label
var quest_label: Label
var quest_title_label: Label
var quest_distance_label: Label
var currency_label: Label
var interact_prompt: Label
var boss_bar: TextureProgressBar
var spell_label: Label
var execution_label: Label
var region_label: Label
var controls_hint_label: Label
var adrenaline_row: HBoxContainer

var _hud_nodes_resolved: bool = false

var _player: Node
var _tracked_boss: Node = null
var _active_menu: String = ""
var _crafting_station_id: String = ""
var _merchant_npc_id: String = "silent_merchant"
var _merchant_anger_state: String = "calm"
var _spell_wheel_spells: Array[String] = []
var _boss_name_label: Label
var _toast_label: Label
var _toast_timer: float = 0.0
var _adrenaline_stars: Array[TextureRect] = []

var _overlay: ColorRect
var _dialogue_ui: DialoguePanel
var _death_overlay: ColorRect
var _death_title: Label
var _death_countdown: Label
var _resource_gain: ResourceGainToast
var _xp_gain: XpGainToast
var _death_active: bool = false
var _menu_panel: PanelContainer
var _menu_title: Label
var _menu_list: ItemList
var _menu_hint: Label
var _inventory_panel: PanelContainer
var _skill_tree_panel: PanelContainer
var _spell_wheel_panel: Control
var _merchant_panel: PanelContainer
var _pet_wheel_panel: Control
var _p2_vitals_label: Label
var _player2: Node
var _minimap: Minimap
var _action_bar: ActionBarHud
var _player_hud: PlayerHud


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	add_to_group("game_hud")
	_player_hud = get_node_or_null("HudRoot") as PlayerHud
	_resolve_hud_nodes()
	_apply_hud_layout()
	_setup_arpg_hud()
	_build_overlay_ui()
	QuestManager.tracked_quest_changed.connect(_update_quest)
	QuestManager.quest_updated.connect(func(_id): _update_quest(""))
	CurrencyManager.currency_changed.connect(_update_currency)
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	DialogueManager.dialogue_line_shown.connect(_on_dialogue_line)
	DialogueManager.dialogue_choices_shown.connect(_on_dialogue_choices)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	ResourceFeedbackManager.resources_obtained.connect(_on_resources_obtained)
	CombatExperienceManager.combat_xp_gained.connect(_on_combat_xp_gained)
	if not GameManager.player_died.is_connected(_on_player_died):
		GameManager.player_died.connect(_on_player_died)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	QuestManager.quest_rewarded.connect(_on_quest_rewarded)
	QuestManager.quest_completed.connect(_on_quest_completed)
	MapManager.map_updated.connect(_on_map_updated)
	GameManager.combat_state_changed.connect(_on_combat_state_changed)
	DungeonManager.dungeon_entered.connect(func(_layout): _update_map_stub(); _rebind_hud_player())
	DungeonManager.dungeon_exited.connect(func(): _update_map_stub(); _rebind_hud_player())
	GameManager.region_changed.connect(func(_id): _rebind_hud_player())
	CraftingManager.craft_completed.connect(func(recipe_id): show_toast("Crafted %s" % recipe_id.replace("_", " ")))
	CraftingManager.craft_failed.connect(func(reason): show_toast("Craft failed: %s" % reason))
	call_deferred("_bind_player")
	if not GameManager.player_spawned.is_connected(_on_player_spawned):
		GameManager.player_spawned.connect(_on_player_spawned)
	call_deferred("_setup_minimap")
	_update_quest("")
	_update_currency()
	_update_map_stub()
	if boss_bar:
		boss_bar.visible = false
	if execution_label:
		execution_label.visible = false
	call_deferred("_ensure_gameplay_ready")
	call_deferred("_monitor_minimap_boot")


func _resolve_hud_nodes() -> void:
	if _player_hud == null:
		return
	xp_bar = _player_hud.get_node_or_null("%XpBar") as Control
	hunger_bar = _player_hud.get_node_or_null("%HungerBar") as TextureProgressBar
	thirst_bar = _player_hud.get_node_or_null("%ThirstBar") as TextureProgressBar
	level_label = _player_hud.get_node_or_null("%LevelLabel") as Label
	quest_label = _player_hud.get_node_or_null("%QuestLabel") as Label
	quest_title_label = _player_hud.get_node_or_null("%QuestTitleLabel") as Label
	quest_distance_label = _player_hud.get_node_or_null("%QuestDistanceLabel") as Label
	currency_label = _player_hud.get_node_or_null("%CurrencyLabel") as Label
	interact_prompt = _player_hud.get_node_or_null("%InteractPrompt") as Label
	boss_bar = _player_hud.get_node_or_null("%BossHealthBar") as TextureProgressBar
	spell_label = _player_hud.get_node_or_null("%SpellLabel") as Label
	execution_label = _player_hud.get_node_or_null("%ExecutionLabel") as Label
	region_label = _player_hud.get_node_or_null("%RegionLabel") as Label
	controls_hint_label = _player_hud.get_node_or_null("%ControlsHintLabel") as Label
	adrenaline_row = _player_hud.get_node_or_null("%AdrenalineRow") as HBoxContainer
	_hud_nodes_resolved = true


func _monitor_minimap_boot() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	if _player_hud:
		_player_hud.ensure_minimap_visible()
	_setup_minimap()


func _ensure_gameplay_ready() -> void:
	_active_menu = ""
	if _overlay:
		_overlay.visible = false
	if _menu_panel:
		_menu_panel.visible = false
	if get_tree().paused and not DialogueManager.is_active():
		get_tree().paused = false
		GameManager.is_paused = false


func _process(delta: float) -> void:
	if _player and is_instance_valid(_player):
		_update_bars()
		_update_spell_label()
		_update_ability_hud()
		_update_quest_distance()
	_update_boss_bar()
	_update_p2_vitals()
	if _toast_timer > 0.0:
		_toast_timer -= delta


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _active_menu == "pause":
			_close_menu()
		elif _active_menu == "" and not DialogueManager.is_active():
			_open_pause_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_inventory"):
		if _active_menu == "inventory":
			_close_inventory_panel()
		elif _active_menu == "":
			_open_inventory_panel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_map"):
		if _active_menu == "map":
			_close_menu()
		elif _active_menu == "":
			_open_map_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_skill_tree"):
		if _active_menu == "skill_tree":
			_close_skill_tree_panel()
		elif _active_menu == "":
			_open_skill_tree_panel()
		get_viewport().set_input_as_handled()
	elif _active_menu == "spell_wheel":
		if event.is_action_pressed("cycle_quick_left"):
			_cycle_spell_wheel(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("cycle_quick_right"):
			_cycle_spell_wheel(1)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_quest_tracker"):
		if _active_menu == "quests":
			_close_menu()
		elif _active_menu == "":
			_open_quest_journal_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_pet_wheel"):
		if _active_menu == "pet_wheel":
			_close_pet_wheel()
		elif _active_menu == "" and PetManager.has_pet("ash_hound"):
			_open_pet_wheel()
		get_viewport().set_input_as_handled()
	elif _active_menu == "pet_wheel":
		if event.is_action_pressed("cycle_quick_left"):
			_pet_wheel_panel.cycle_selection(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("cycle_quick_right"):
			_pet_wheel_panel.cycle_selection(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("confirm"):
			_pet_wheel_panel.confirm_selection()
			get_viewport().set_input_as_handled()
	elif DialogueManager.is_active():
		if event.is_action_pressed("confirm") and DialogueManager.can_accept_advance():
			DialogueManager.advance()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("cancel"):
			DialogueManager.cancel()
			get_viewport().set_input_as_handled()
	elif _active_menu != "" and event.is_action_pressed("cancel"):
		if _active_menu == "inventory":
			_close_inventory_panel()
		elif _active_menu == "skill_tree":
			_close_skill_tree_panel()
		elif _active_menu == "merchant":
			_close_merchant_panel()
		elif _active_menu == "pet_wheel":
			_close_pet_wheel()
		else:
			_close_menu()
		get_viewport().set_input_as_handled()
	elif _active_menu != "" and event.is_action_pressed("confirm"):
		_menu_confirm()
		get_viewport().set_input_as_handled()


func show_toast(text: String, duration: float = 3.0, description: String = "", icon_key: String = "notification") -> void:
	if _player_hud:
		_player_hud.show_toast(text, duration, description, icon_key)


func set_interact_prompt(text: String) -> void:
	if _player_hud:
		_player_hud.set_interact_prompt(text)
	elif interact_prompt:
		interact_prompt.text = text if text != "" else ""


func set_execution_prompt(visible: bool) -> void:
	if _player_hud:
		_player_hud.set_execution_visible(visible)
	elif execution_label:
		execution_label.visible = visible


func track_boss(boss: Node) -> void:
	_tracked_boss = boss
	boss_bar.visible = true
	var boss_name := "Boss"
	if "display_name" in boss:
		boss_name = str(boss.display_name)
		boss_bar.tooltip_text = boss_name
	if _boss_name_label:
		_boss_name_label.text = boss_name
		_boss_name_label.visible = true
	if boss.has_signal("phase_changed") and not boss.phase_changed.is_connected(_on_boss_phase_changed):
		boss.phase_changed.connect(_on_boss_phase_changed)
	if boss.has_node("HealthComponent"):
		var health := boss.get_node("HealthComponent") as HealthComponent
		boss_bar.max_value = health.max_health
		boss_bar.value = health.current_health
		if not health.health_changed.is_connected(_on_boss_health_changed):
			health.health_changed.connect(_on_boss_health_changed)


func open_waystone_menu() -> void:
	_open_waystone_menu()


func open_crafting_menu(station_id: String) -> void:
	_crafting_station_id = station_id
	_populate_crafting_list()
	_show_menu("crafting", "Crafting — %s" % station_id.capitalize())


func open_merchant_menu(npc_id: String = "silent_merchant", anger_state: String = "calm") -> void:
	_merchant_npc_id = npc_id
	_merchant_anger_state = anger_state
	_open_merchant_panel()


func open_spell_wheel_menu(spells: Array[String], selected_index: int) -> void:
	_spell_wheel_spells = spells
	_active_menu = "spell_wheel"
	_overlay.visible = true
	_spell_wheel_panel.show_wheel(spells, selected_index)


func close_spell_wheel_menu() -> void:
	if _active_menu == "spell_wheel":
		_active_menu = ""
		_overlay.visible = false
		_spell_wheel_panel.hide_wheel()


func open_mask_menu(player: Node) -> void:
	_player = player if player else _player
	_populate_mask_list()
	_show_menu("masks", "Memory Masks")


func _open_pet_wheel() -> void:
	_active_menu = "pet_wheel"
	_overlay.visible = true
	_pet_wheel_panel.show_wheel(0)


func _close_pet_wheel() -> void:
	if _active_menu == "pet_wheel":
		_active_menu = ""
		_overlay.visible = false
		_pet_wheel_panel.hide_wheel()


func _on_pet_command_selected(command_id: String) -> void:
	var idx := 0
	if _player and _player is PlayerController:
		idx = (_player as PlayerController).player_index
	PetManager.set_pet_command(idx, command_id)
	show_toast("Ash Hound: %s" % command_id.capitalize())
	_close_pet_wheel()


func _populate_mask_list() -> void:
	_menu_list.clear()
	_menu_list.add_item("Close")
	_menu_list.add_item("Unequip mask")
	MaskManager.sync_unlocks_from_quests()
	for mask_id in MaskManager.get_available_masks():
		var prefix := "★ " if MaskManager.equipped_mask == mask_id else ""
		var row := _menu_list.add_item(prefix + MaskManager.MASKS[mask_id].name)
		_menu_list.set_item_metadata(row, mask_id)


func _handle_mask_selection(index: int) -> void:
	var text := _menu_list.get_item_text(index)
	if text == "Close":
		_close_menu()
		return
	if text == "Unequip mask":
		MaskManager.equip_mask("", _player)
		show_toast("Mask unequipped")
		_close_menu()
		return
	var mask_id: Variant = _menu_list.get_item_metadata(index)
	if mask_id != null and typeof(mask_id) == TYPE_STRING:
		MaskManager.equip_mask(mask_id, _player)
		show_toast("Equipped %s" % MaskManager.MASKS[mask_id].name)
	_close_menu()


func _open_inventory_panel() -> void:
	if _player == null:
		return
	_active_menu = "inventory"
	_overlay.visible = true
	_menu_panel.visible = false
	get_tree().paused = true
	_inventory_panel.open(_player)


func _close_inventory_panel() -> void:
	_inventory_panel.close()
	_on_panel_closed()


func _open_skill_tree_panel() -> void:
	if _player == null:
		return
	_active_menu = "skill_tree"
	_overlay.visible = true
	_menu_panel.visible = false
	get_tree().paused = true
	_skill_tree_panel.open(_player)


func _close_skill_tree_panel() -> void:
	_skill_tree_panel.close()
	_on_panel_closed()


func _open_merchant_panel() -> void:
	_active_menu = "merchant"
	_overlay.visible = true
	_menu_panel.visible = false
	get_tree().paused = true
	_merchant_panel.open(_merchant_npc_id, _merchant_anger_state)


func _close_merchant_panel() -> void:
	_merchant_panel.close()
	_on_panel_closed()


func _on_panel_closed() -> void:
	if _active_menu in ["inventory", "skill_tree", "merchant"]:
		_active_menu = ""
		_overlay.visible = false
		get_tree().paused = false


func _on_spell_wheel_selected(index: int) -> void:
	_handle_spell_wheel_selection(index)


func _cycle_spell_wheel(direction: int) -> void:
	if _spell_wheel_spells.is_empty():
		return
	var current := 0
	if _player and _player.has_node("Spellcaster"):
		current = _player.get_node("Spellcaster").quick_spell_index
	var next := (current + direction) % _spell_wheel_spells.size()
	if next < 0:
		next += _spell_wheel_spells.size()
	_spell_wheel_panel.update_selection(next)
	if _player and _player.has_node("Spellcaster"):
		_player.get_node("Spellcaster").select_spell_from_wheel(next)


func _setup_arpg_hud() -> void:
	_action_bar = get_node_or_null("HudRoot/BottomBridge") as ActionBarHud
	_ensure_vitals_bars()
	_setup_minimap()
	_style_hud_labels()
	_build_adrenaline_pips()
	_build_p2_vitals()
	var currency_icon := get_node_or_null("HudRoot/SafeArea/Shell/TopRight/RightSideContainer/RegionAndCurrency/CurrencyRow/CurrencyIcon") as TextureRect
	if currency_icon:
		currency_icon.texture = UiIconRegistry.get_icon("currency")
		currency_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		currency_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _style_hud_labels() -> void:
	if boss_bar is ThinBar:
		(boss_bar as ThinBar).set_bar_color(UiColors.HEALTH_FILL)
		(boss_bar as ThinBar).set_bar_height(UiMetrics.BAR_HP)
	elif boss_bar:
		ArpgTheme.style_progress_bar(boss_bar, UiColors.HEALTH_FILL, UiMetrics.BAR_HP)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		call_deferred("_apply_hud_layout")


func _apply_hud_layout() -> void:
	if _player_hud:
		_player_hud._apply_safe_margins()


func _setup_minimap() -> void:
	var widget := get_node_or_null("HudRoot/SafeArea/Shell/TopRight/RightSideContainer/MinimapPanel/MinimapWidget") as Minimap
	if widget == null:
		var panel := get_node_or_null("HudRoot/SafeArea/Shell/TopRight/RightSideContainer/MinimapPanel") as PanelContainer
		if panel:
			widget = panel.get_node_or_null("MinimapWidget") as Minimap
			if widget == null:
				widget = MinimapScene.instantiate() as Minimap
				widget.name = "MinimapWidget"
				panel.add_child(widget)
	_minimap = widget
	var minimap_panel := get_node_or_null("HudRoot/SafeArea/Shell/TopRight/RightSideContainer/MinimapPanel") as Control
	if minimap_panel:
		minimap_panel.visible = true
		minimap_panel.show()
	if _player and _player is Node3D and _minimap:
		_minimap.bind_player(_player as Node3D)
	if _player_hud and _minimap:
		_player_hud.bind_minimap(_minimap)
	if _minimap:
		_minimap.refresh_landmarks()


func _ensure_vitals_bars() -> void:
	var bars: Array[TextureProgressBar] = [hunger_bar, thirst_bar, boss_bar]
	var specs := {
		hunger_bar: [UiColors.STAMINA_FILL, 3.0],
		thirst_bar: [UiColors.MANA_FILL, 3.0],
		boss_bar: [UiColors.HEALTH_FILL, UiMetrics.BAR_HP],
	}
	for bar in bars:
		if bar == null:
			continue
		if bar is ThinBar:
			(bar as ThinBar).set_bar_color(specs[bar][0])
			(bar as ThinBar).set_bar_height(specs[bar][1])
		else:
			ArpgTheme.style_progress_bar(bar, specs[bar][0], specs[bar][1])


func _add_vital_bar_labels() -> void:
	pass


func _build_p2_vitals() -> void:
	var top_left := get_node_or_null("HudRoot/TopLeft/VitalsPanel/Margin/VBox") as VBoxContainer
	if top_left == null:
		return
	_p2_vitals_label = Label.new()
	_p2_vitals_label.name = "P2VitalsLabel"
	_p2_vitals_label.add_theme_font_size_override("font_size", 14)
	_p2_vitals_label.text = ""
	top_left.add_child(_p2_vitals_label)


func _on_player_spawned(player: Node, index: int) -> void:
	if index == 0:
		_bind_player_node(player)
	elif index == 1:
		_player2 = player
		if player.has_node("HealthComponent"):
			var health := player.get_node("HealthComponent") as HealthComponent
			if not health.health_changed.is_connected(_on_p2_health_changed):
				health.health_changed.connect(_on_p2_health_changed)


func _on_p2_health_changed(current: float, maximum: float) -> void:
	_update_p2_vitals()


func _update_p2_vitals() -> void:
	if _p2_vitals_label == null:
		return
	if _player2 == null or not is_instance_valid(_player2):
		_p2_vitals_label.text = ""
		return
	var hp := 0.0
	var hp_max := 100.0
	var st := 0.0
	var st_max := 100.0
	if _player2.has_node("HealthComponent"):
		var health := _player2.get_node("HealthComponent") as HealthComponent
		hp = health.current_health
		hp_max = health.max_health
	if _player2.has_node("StaminaComponent"):
		var stamina := _player2.get_node("StaminaComponent") as StaminaComponent
		st = stamina.current_stamina
		st_max = stamina.max_stamina
	_p2_vitals_label.text = "P2  HP %d/%d  ST %d/%d" % [int(hp), int(hp_max), int(st), int(st_max)]


func _build_adrenaline_pips() -> void:
	if adrenaline_row == null:
		return
	for child in adrenaline_row.get_children():
		child.queue_free()
	_adrenaline_stars.clear()
	var filled := KenneyUiPaths.load_tex(KenneyUiPaths.star_filled())
	var empty := KenneyUiPaths.load_tex(KenneyUiPaths.star_empty())
	for i in 3:
		var star := TextureRect.new()
		star.custom_minimum_size = Vector2(20, 20)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.texture = empty if empty else filled
		if filled:
			star.set_meta("filled_tex", filled)
		if empty:
			star.set_meta("empty_tex", empty)
		else:
			star.set_meta("empty_tex", KenneyUiPaths.solid_tex(Color(0.35, 0.35, 0.4)))
		if not filled:
			star.set_meta("filled_tex", KenneyUiPaths.solid_tex(Color(0.95, 0.78, 0.2)))
		adrenaline_row.add_child(star)
		_adrenaline_stars.append(star)


func _update_adrenaline_pips(stamina_percent: float) -> void:
	var lit := 0
	if stamina_percent > 0.66:
		lit = 3
	elif stamina_percent > 0.33:
		lit = 2
	elif stamina_percent > 0.05:
		lit = 1
	for i in _adrenaline_stars.size():
		var star := _adrenaline_stars[i]
		if not star.has_meta("filled_tex") or not star.has_meta("empty_tex"):
			continue
		var filled: Texture2D = star.get_meta("filled_tex")
		var empty: Texture2D = star.get_meta("empty_tex")
		star.texture = filled if i < lit and filled else empty if empty else filled


func _update_quest_distance() -> void:
	if _player == null:
		return
	var best := INF
	for node in get_tree().get_nodes_in_group("quest_destination"):
		if _player is Node3D and node is Node3D:
			var d: float = (_player as Node3D).global_position.distance_to((node as Node3D).global_position)
			best = minf(best, d)
	var dist_text := ""
	if best < INF:
		dist_text = "%d m" % int(best)
	if quest_distance_label:
		quest_distance_label.visible = false
	var tracker := get_node_or_null("HudRoot/SafeArea/Shell/TopRight/RightSideContainer/QuestTracker") as QuestTrackerPanel
	if tracker and QuestManager.tracked_quest_id != "":
		var title := QuestManager.tracked_quest_id.replace("_", " ").capitalize()
		var quest_type := "MAIN QUEST" if QuestManager.tracked_quest_id.contains("main") or QuestManager.tracked_quest_id.contains("ashes") else "QUEST"
		var lines := _quest_objective_lines()
		tracker.set_from_objective_lines(title, lines, dist_text, quest_type)
	elif _player_hud and QuestManager.tracked_quest_id != "":
		var title := QuestManager.tracked_quest_id.replace("_", " ").capitalize()
		var quest_type := "MAIN QUEST" if QuestManager.tracked_quest_id.contains("main") or QuestManager.tracked_quest_id.contains("ashes") else "QUEST"
		_player_hud.update_quest(title, _quest_objective_lines(), dist_text, quest_type)


func _build_overlay_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.55)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	move_child(_overlay, 0)

	_dialogue_ui = DialoguePanelScene.instantiate() as DialoguePanel
	add_child(_dialogue_ui)
	move_child(_dialogue_ui, get_child_count() - 1)

	_death_overlay = ColorRect.new()
	_death_overlay.color = Color(0.02, 0.02, 0.03, 0.0)
	_death_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_overlay.visible = false
	_death_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_death_overlay)
	var death_box := VBoxContainer.new()
	death_box.set_anchors_preset(Control.PRESET_CENTER)
	death_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_death_overlay.add_child(death_box)
	_death_title = Label.new()
	_death_title.text = "YOU DIED"
	_death_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ArpgTheme.style_label(_death_title, UiMetrics.FONT_TITLE, UiColors.TEXT_DANGER)
	death_box.add_child(_death_title)
	_death_countdown = Label.new()
	_death_countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ArpgTheme.style_label(_death_countdown, UiMetrics.FONT_LG, UiColors.TEXT_PRIMARY)
	death_box.add_child(_death_countdown)

	_resource_gain = ResourceGainToastScript.new()
	_resource_gain.name = "ResourceGainContainer"
	_resource_gain.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_resource_gain.offset_left = -320.0
	_resource_gain.offset_top = -120.0
	_resource_gain.offset_right = -32.0
	_resource_gain.offset_bottom = 120.0
	add_child(_resource_gain)

	_xp_gain = XpGainToastScript.new()
	_xp_gain.name = "XpGainContainer"
	_xp_gain.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_xp_gain.offset_left = -320.0
	_xp_gain.offset_top = -180.0
	_xp_gain.offset_right = -32.0
	_xp_gain.offset_bottom = -40.0
	add_child(_xp_gain)

	_menu_panel = PanelContainer.new()
	_menu_panel.set_anchors_preset(Control.PRESET_CENTER)
	_menu_panel.offset_left = -280
	_menu_panel.offset_top = -220
	_menu_panel.offset_right = 280
	_menu_panel.offset_bottom = 220
	_menu_panel.visible = false
	add_child(_menu_panel)

	var menu_vbox := VBoxContainer.new()
	_menu_panel.add_child(menu_vbox)
	_menu_title = Label.new()
	_menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_title.add_theme_font_size_override("font_size", 24)
	menu_vbox.add_child(_menu_title)
	_menu_list = ItemList.new()
	_menu_list.custom_minimum_size = Vector2(520, 300)
	_menu_list.item_selected.connect(_on_menu_item_selected)
	menu_vbox.add_child(_menu_list)
	_menu_hint = Label.new()
	_menu_hint.text = "A: Select   B: Close"
	_menu_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_vbox.add_child(_menu_hint)

	_boss_name_label = Label.new()
	_boss_name_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_boss_name_label.offset_top = 40
	_boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name_label.add_theme_font_size_override("font_size", 20)
	_boss_name_label.visible = false
	add_child(_boss_name_label)

	_inventory_panel = InventoryPanelScene.new()
	_inventory_panel.visible = false
	_inventory_panel.set_anchors_preset(Control.PRESET_CENTER)
	_inventory_panel.closed.connect(_on_panel_closed)
	add_child(_inventory_panel)

	_skill_tree_panel = SkillTreePanelScene.new()
	_skill_tree_panel.visible = false
	_skill_tree_panel.set_anchors_preset(Control.PRESET_CENTER)
	_skill_tree_panel.closed.connect(_on_panel_closed)
	add_child(_skill_tree_panel)

	_spell_wheel_panel = SpellWheelPanelScene.new()
	_spell_wheel_panel.visible = false
	_spell_wheel_panel.spell_selected.connect(_on_spell_wheel_selected)
	add_child(_spell_wheel_panel)

	_merchant_panel = MerchantShopPanelScene.new()
	_merchant_panel.visible = false
	_merchant_panel.set_anchors_preset(Control.PRESET_CENTER)
	_merchant_panel.closed.connect(_on_panel_closed)
	add_child(_merchant_panel)

	_pet_wheel_panel = PetWheelPanelScene.new()
	_pet_wheel_panel.visible = false
	_pet_wheel_panel.command_selected.connect(_on_pet_command_selected)
	add_child(_pet_wheel_panel)


func _build_toast() -> void:
	pass


func _bind_player() -> void:
	# Player usually arrives via GameManager.player_spawned after terrain spawn.
	# This loop covers edge cases where the player already exists when the HUD wakes up.
	for _attempt in 60:
		await get_tree().process_frame
		var player := GameManager.get_player(0)
		if player:
			_bind_player_node(player)
			return
	_bind_player_node(GameManager.get_player(0))


func _bind_player_node(player: Node) -> void:
	if player == null:
		return
	_player = player
	bind_production_player(player)
	if player.has_node("StaminaComponent"):
		var stamina := player.get_node("StaminaComponent") as StaminaComponent
		if not stamina.stamina_changed.is_connected(_on_stamina_changed):
			stamina.stamina_changed.connect(_on_stamina_changed)
	if player.has_node("FocusComponent"):
		var focus := player.get_node("FocusComponent") as FocusComponent
		if not focus.focus_changed.is_connected(_on_focus_changed):
			focus.focus_changed.connect(_on_focus_changed)
	if player.has_node("StatsComponent"):
		var stats := player.get_node("StatsComponent") as StatsComponent
		if not stats.level_changed.is_connected(_on_level_changed):
			stats.level_changed.connect(_on_level_changed)
		if not stats.stat_changed.is_connected(_on_stats_changed):
			stats.stat_changed.connect(_on_stats_changed)
		if not stats.experience_changed.is_connected(_on_experience_changed):
			stats.experience_changed.connect(_on_experience_changed)
		_update_level_label(stats)
		_update_xp_bar(stats)
	if player.has_node("Spellcaster"):
		var spellcaster := player.get_node("Spellcaster")
		if spellcaster.has_signal("spell_changed") and not spellcaster.spell_changed.is_connected(_on_spell_changed):
			spellcaster.spell_changed.connect(_on_spell_changed)
		if spellcaster.has_signal("cast_failed") and not spellcaster.cast_failed.is_connected(_on_spell_cast_failed):
			spellcaster.cast_failed.connect(_on_spell_cast_failed)
	_update_bars()
	if player.has_node("StaminaComponent"):
		var stamina := player.get_node("StaminaComponent") as StaminaComponent
		_on_stamina_changed(stamina.current_stamina, stamina.max_stamina)
	if player.has_node("FocusComponent"):
		var focus := player.get_node("FocusComponent") as FocusComponent
		_on_focus_changed(focus.current_focus, focus.max_focus)
	if _minimap and player is Node3D:
		_minimap.bind_player(player as Node3D)


func bind_production_player(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return
	if _player_hud:
		_player_hud.bind_to_player(player)
	else:
		push_error("GameHUD: HudRoot PlayerHud missing — cannot bind health")


func _rebind_hud_player() -> void:
	var player := _player if _player and is_instance_valid(_player) else GameManager.get_player(0)
	if player:
		bind_production_player(player)


func _update_bars() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _player.has_node("SurvivalNeedsComponent"):
		var needs := _player.get_node("SurvivalNeedsComponent") as SurvivalNeedsComponent
		hunger_bar.value = needs.hunger
		thirst_bar.value = needs.thirst
	if _player.has_node("FocusComponent"):
		var focus := _player.get_node("FocusComponent") as FocusComponent
		if _action_bar:
			_action_bar.set_mp_values(focus.current_focus, focus.max_focus)
	if _player.has_node("StaminaComponent"):
		var stamina := _player.get_node("StaminaComponent") as StaminaComponent
		var pct := stamina.current_stamina / stamina.max_stamina if stamina.max_stamina > 0 else 0.0
		_update_adrenaline_pips(pct)
	if _player.has_node("StatsComponent"):
		_update_xp_bar(_player.get_node("StatsComponent") as StatsComponent)


func _update_spell_label() -> void:
	if _player and _player.has_node("Spellcaster"):
		var sc := _player.get_node("Spellcaster")
		if sc.has_method("get_active_spell_label"):
			var label_text: String = str(sc.get_active_spell_label())
			var mana_cost := 8
			if sc.has_method("get_spell_focus_cost") and sc.has_method("get_active_spell_id"):
				mana_cost = sc.get_spell_focus_cost(sc.get_active_spell_id())
			if spell_label:
				spell_label.text = "Spell: %s" % label_text
			if _player_hud:
				_player_hud.update_spell_slot(label_text, mana_cost)
				_player_hud.set_skill_highlight(2, true)
				for i in [0, 1, 3, 4, 5]:
					if i != 2:
						_player_hud.set_skill_highlight(i, false)
			elif _action_bar:
				_action_bar.update_spell_slot(label_text)
				_action_bar.set_skill_highlight(2, true)


func _update_ability_hud() -> void:
	if _player_hud == null or _player == null or not _player.has_node("Spellcaster"):
		return
	var sc := _player.get_node("Spellcaster")
	if not sc.has_method("get_active_spell_id"):
		return
	var spell_id: String = sc.get_active_spell_id()
	var ratio := 0.0
	var remaining := 0.0
	if sc.has_method("get_cooldown_ratio"):
		ratio = sc.get_cooldown_ratio(spell_id)
	if sc.has_method("get_cooldown_remaining"):
		remaining = sc.get_cooldown_remaining(spell_id)
	_player_hud.set_slot_cooldown(2, ratio, remaining)
	if _player.has_node("FocusComponent"):
		var focus := _player.get_node("FocusComponent") as FocusComponent
		var cost: int = sc.get_spell_focus_cost(spell_id) if sc.has_method("get_spell_focus_cost") else 0
		_player_hud.set_slot_insufficient(2, focus.current_focus < float(cost) and ratio <= 0.0)


func _on_spell_cast_failed(reason: String) -> void:
	if reason == "focus" and _player_hud:
		_player_hud.flash_mana_insufficient()
		_player_hud.set_slot_insufficient(2, true)


func _on_boss_phase_changed(phase: int) -> void:
	show_toast("Boss enters phase %d!" % phase, 2.5)


func _update_boss_bar() -> void:
	if boss_bar == null:
		return
	if _tracked_boss == null or not is_instance_valid(_tracked_boss):
		boss_bar.visible = false
		if _boss_name_label:
			_boss_name_label.visible = false
		return
	if _tracked_boss.has_node("HealthComponent"):
		var health := _tracked_boss.get_node("HealthComponent") as HealthComponent
		boss_bar.max_value = health.max_health
		boss_bar.value = health.current_health


func _on_boss_health_changed(current: float, _maximum: float) -> void:
	boss_bar.value = current
	if current <= 0.0:
		boss_bar.visible = false
		if _boss_name_label:
			_boss_name_label.visible = false
		_tracked_boss = null


func _on_stamina_changed(current: float, maximum: float) -> void:
	if _player_hud:
		_player_hud.set_stamina_values(current, maximum)
	var pct := current / maximum if maximum > 0.0 else 0.0
	_update_adrenaline_pips(pct)


func _on_focus_changed(current: float, maximum: float) -> void:
	if _player_hud:
		_player_hud.set_mp_values(current, maximum)
	elif _action_bar:
		_action_bar.set_mp_values(current, maximum)


func _on_level_changed(level: int) -> void:
	if _player and _player.has_node("StatsComponent"):
		var stats := _player.get_node("StatsComponent") as StatsComponent
		_update_level_label(stats)
		_update_xp_bar(stats)
		show_toast("Level Up!", 2.5, "Reached level %d" % level, "experience")


func _on_experience_changed(_current: int, _required: int) -> void:
	if _player and _player.has_node("StatsComponent"):
		_update_xp_bar(_player.get_node("StatsComponent") as StatsComponent)


func _on_combat_xp_gained(amount: int, label: String, is_kill: bool) -> void:
	if _xp_gain:
		_xp_gain.show_xp(amount, label, is_kill)
	if _player and _player.has_node("StatsComponent"):
		_update_xp_bar(_player.get_node("StatsComponent") as StatsComponent)


func _on_stats_changed() -> void:
	if _player and _player.has_node("StatsComponent"):
		_update_xp_bar(_player.get_node("StatsComponent") as StatsComponent)


func _update_xp_bar(stats: StatsComponent) -> void:
	if stats == null:
		return
	var needed := stats.get_exp_to_next_level()
	if _player_hud:
		_player_hud.set_xp_values(float(stats.experience), float(needed))
	elif xp_bar and xp_bar.has_method("set_values"):
		xp_bar.set_values(float(stats.experience), float(needed))


func _update_level_label(stats: StatsComponent) -> void:
	if _player_hud:
		_player_hud.set_level(stats.level)
	if level_label:
		level_label.text = str(stats.level)


func _on_quest_rewarded(quest_id: String, summary: String) -> void:
	show_toast("Quest complete: %s (%s)" % [quest_id.replace("_", " ").capitalize(), summary], 4.0)


func _on_quest_completed(quest_id: String) -> void:
	_update_quest(quest_id)


func _on_combat_state_changed(in_combat: bool) -> void:
	if in_combat:
		AudioManager.play_music("combat")
	else:
		AudioManager.play_music("ambient")


func _on_spell_changed(_spell_id: String) -> void:
	_update_spell_label()


func _on_achievement_unlocked(id: String) -> void:
	show_toast("Achievement Unlocked", 3.5, AchievementManager.get_display_name(id), "experience")


func _on_map_updated(_region_id: String) -> void:
	_update_map_stub()
	if _minimap:
		_minimap.refresh_landmarks()


func _update_map_stub() -> void:
	var region := GameManager.current_region_id.replace("_", " ").capitalize()
	var floor_text := DungeonManager.get_floor_display()
	var label_text := region
	if floor_text != "":
		label_text = floor_text
	if region_label:
		region_label.text = label_text


func _update_quest(_id: String) -> void:
	var tracker := get_node_or_null("HudRoot/SafeArea/Shell/TopRight/RightSideContainer/QuestTracker") as QuestTrackerPanel
	if QuestManager.tracked_quest_id == "" or not QuestManager.active_quests.has(QuestManager.tracked_quest_id):
		if tracker:
			tracker.clear()
		elif _player_hud:
			_player_hud.clear_quest()
		if quest_title_label:
			quest_title_label.text = ""
		if quest_label:
			quest_label.text = ""
		return
	var qid: String = QuestManager.tracked_quest_id
	var title := qid.replace("_", " ").capitalize()
	var quest_type := "MAIN QUEST" if qid.contains("main") or qid.contains("ashes") else "QUEST"
	var lines := _quest_objective_lines()
	if quest_title_label:
		quest_title_label.text = title
	if quest_label:
		quest_label.text = "\n".join(lines)
	if tracker:
		tracker.set_from_objective_lines(title, lines, "", quest_type)
	elif _player_hud:
		_player_hud.update_quest(title, lines, "", quest_type)


func _quest_objective_lines() -> PackedStringArray:
	var lines: PackedStringArray = []
	if QuestManager.tracked_quest_id == "" or not QuestManager.active_quests.has(QuestManager.tracked_quest_id):
		return lines
	var objectives: Array = QuestManager.active_quests[QuestManager.tracked_quest_id]
	for obj in objectives:
		var prefix := "• " if not obj.completed else "✓ "
		var progress := "" if obj.completed else " (%d/%d)" % [obj.current, obj.target]
		lines.append("%s%s%s" % [prefix, obj.description, progress])
	return lines


func _update_currency() -> void:
	if currency_label:
		currency_label.text = CurrencyManager.get_display_string()
	elif _player_hud:
		var label := _player_hud.get_node_or_null("%CurrencyLabel") as Label
		if label:
			label.text = CurrencyManager.get_display_string()


func _on_inventory_changed() -> void:
	if _active_menu == "inventory" and _inventory_panel.visible:
		_inventory_panel.open(_player)


func _on_dialogue_started(_npc_id: String) -> void:
	set_interact_prompt("")
	set_execution_prompt(false)


func _on_dialogue_line(speaker: String, text: String) -> void:
	if _dialogue_ui:
		_dialogue_ui.show_line(speaker, text)


func _on_dialogue_choices(options: Array[String]) -> void:
	if _dialogue_ui:
		_dialogue_ui.show_choices(options)


func _on_dialogue_ended() -> void:
	if _dialogue_ui:
		_dialogue_ui.hide_panel()


func _fade_to_black(duration: float = 0.35) -> void:
	if _overlay == null:
		await get_tree().create_timer(duration).timeout
		return
	_overlay.color = Color(0, 0, 0, 0.0)
	_overlay.visible = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, duration)
	await tween.finished


func _fade_from_black(duration: float = 0.35) -> void:
	if _overlay == null:
		return
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 0.0, duration)
	await tween.finished
	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_resources_obtained(rewards: Dictionary) -> void:
	if _resource_gain:
		_resource_gain.show_rewards(rewards)


func _on_player_died(_player: Node, _index: int) -> void:
	if _active_menu != "":
		_close_menu()
	if DialogueManager.is_active():
		DialogueManager.cancel()
	set_interact_prompt("")
	set_execution_prompt(false)


func begin_death_sequence() -> void:
	if _death_active:
		return
	_death_active = true
	_death_overlay.visible = true
	_death_title.modulate.a = 0.0
	_death_countdown.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_death_overlay, "color:a", 0.72, 0.3)
	await get_tree().create_timer(0.3).timeout
	_death_title.modulate.a = 1.0
	_death_countdown.text = "Respawning in 2"
	_death_countdown.modulate.a = 1.0
	await get_tree().create_timer(1.0).timeout
	_death_countdown.text = "Respawning in 1"
	await get_tree().create_timer(1.0).timeout


func finish_death_sequence() -> void:
	if _death_overlay:
		var tween := create_tween()
		tween.tween_property(_death_overlay, "color:a", 0.0, 0.35)
		await tween.finished
		_death_overlay.visible = false
	_death_active = false


func _open_pause_menu() -> void:
	_menu_list.clear()
	_menu_list.add_item("Resume")
	_menu_list.add_item("Save Game")
	_menu_list.add_item("Settings")
	_menu_list.add_item("Quit to Menu")
	_show_menu("pause", "Paused")


func _open_quest_journal_menu() -> void:
	_menu_list.clear()
	_menu_list.add_item("Close")
	for quest_id in QuestManager.get_active_quest_list():
		var prefix := "> " if quest_id == QuestManager.tracked_quest_id else "  "
		var idx := _menu_list.add_item("%s%s" % [prefix, QuestManager.get_quest_summary(quest_id)])
		_menu_list.set_item_metadata(idx, quest_id)
	if _menu_list.item_count <= 1:
		_menu_list.add_item("(No active quests)")
	_show_menu("quests", "Quest Journal")


func _open_settings_menu() -> void:
	_menu_list.clear()
	_menu_list.add_item("Close")
	_menu_list.add_item("Master Volume: %d%%" % int(AudioManager.master_volume * 100))
	_menu_list.add_item("Music Volume: %d%%" % int(AudioManager.music_volume * 100))
	_menu_list.add_item("SFX Volume: %d%%" % int(AudioManager.sfx_volume * 100))
	_menu_list.add_item("Sensitivity: %.1f" % SettingsManager.camera_sensitivity)
	_menu_list.add_item("Difficulty: %s" % SettingsManager.difficulty.capitalize())
	_menu_list.add_item("VSync: %s" % ("On" if SettingsManager.vsync else "Off"))
	_menu_list.add_item("Frame Cap: %d" % SettingsManager.frame_cap)
	_menu_list.add_item("Invert Look Y: %s" % ("On" if SettingsManager.invert_look_y else "Off"))
	_menu_list.add_item("Invert Look X: %s" % ("On" if SettingsManager.invert_look_x else "Off"))
	_menu_list.add_item("Hold Sprint: %s" % ("On" if SettingsManager.hold_sprint else "Off"))
	_menu_list.add_item("Hold Block: %s" % ("On" if SettingsManager.hold_block else "Off"))
	_menu_list.add_item("Vibration: %s" % ("On" if SettingsManager.vibration else "Off"))
	_menu_list.add_item("Subtitles: %s" % ("On" if SettingsManager.subtitles else "Off"))
	_menu_list.add_item("UI Scale: %.2f" % SettingsManager.ui_scale)
	_menu_list.add_item("Reduce Camera Shake: %s" % ("On" if SettingsManager.reduce_camera_shake else "Off"))
	_menu_list.add_item("Motion Blur: %s" % ("On" if SettingsManager.motion_blur else "Off"))
	_menu_list.add_item("Brightness: %.1f" % SettingsManager.brightness)
	_menu_list.add_item("Steam Deck Preset")
	_show_menu("settings", "Settings")


func _open_waystone_menu() -> void:
	_menu_list.clear()
	_menu_list.add_item("Close")
	for dest in WaystoneManager.discovered:
		if dest == GameManager.current_region_id:
			continue
		if dest == "hearthhold_camp" and not WaystoneManager.hearthhold_unlocked:
			continue
		if not ResourceLoader.exists("res://scenes/levels/%s/%s.tscn" % [dest, dest]):
			continue
		var label := dest.replace("_", " ").capitalize()
		var idx := _menu_list.add_item("Travel: %s" % label)
		_menu_list.set_item_metadata(idx, dest)
	if _menu_list.item_count <= 1:
		_menu_list.add_item("(No destinations available)")
	_show_menu("waystone", "Waystone Travel")


func _open_map_menu() -> void:
	_menu_list.clear()
	_menu_list.add_item("Close")
	_menu_list.add_item("--- Active Quests ---")
	for quest_id in QuestManager.get_active_quest_list():
		_menu_list.add_item(QuestManager.get_quest_summary(quest_id))
	_menu_list.add_item("--- Regions ---")
	for region_id in MapManager.regions.keys():
		var state: int = MapManager.regions[region_id]
		var state_name: String = MapManager.RegionState.keys()[state]
		if state == MapManager.RegionState.UNDISCOVERED:
			state_name = "???"
		var layout := MapManager.get_region_layout(region_id)
		var suffix := ""
		if layout.get("kind") == "island":
			suffix = " [Island]"
		elif layout.get("kind") == "camp":
			suffix = " [Camp]"
		_menu_list.add_item("%s%s — %s" % [region_id.replace("_", " ").capitalize(), suffix, state_name])
	if _player:
		_menu_list.add_item("Position: %s" % MapManager.get_map_position_label(_player.global_position))
	var region_id := GameManager.current_region_id
	if region_id != "":
		_menu_list.add_item("--- Fog (@=you . =explored ? =unknown) ---")
		for line in MapManager.get_fog_grid_lines(region_id):
			_menu_list.add_item(line)
		for icon in MapManager.icons:
			if icon.get("label", "") != "":
				_menu_list.add_item("Icon: %s" % icon.label)
	_show_menu("map", "World Map")


func _populate_crafting_list() -> void:
	_menu_list.clear()
	for recipe_id in CraftingManager.known_recipes:
		if CraftingManager.get_recipe_station(recipe_id) != _crafting_station_id:
			continue
		var check := CraftingManager.can_craft(recipe_id, _crafting_station_id)
		var status: String = "OK" if check.ok else str(check.reason)
		_menu_list.add_item("%s — %s" % [recipe_id, status])
	if BaseManager.can_upgrade(_crafting_station_id):
		var uidx := _menu_list.add_item("Upgrade station")
		_menu_list.set_item_metadata(uidx, _crafting_station_id)


func _show_menu(menu_id: String, title: String) -> void:
	_active_menu = menu_id
	_menu_title.text = title
	_menu_panel.visible = true
	_overlay.visible = true
	if menu_id != "spell_wheel":
		get_tree().paused = true
	_menu_list.grab_focus()
	if _menu_list.item_count > 0:
		_menu_list.select(0)


func _close_menu() -> void:
	_active_menu = ""
	_menu_panel.visible = false
	_overlay.visible = false
	get_tree().paused = false


func _menu_confirm() -> void:
	if _menu_list.item_count == 0:
		return
	var idx := _menu_list.get_selected_items()
	var index := idx[0] if idx.size() > 0 else 0
	var text := _menu_list.get_item_text(index)
	match _active_menu:
		"pause":
			_handle_pause_selection(text)
		"storage":
			_handle_storage_selection(index)
		"upgrade":
			_handle_upgrade_selection(index)
		"waystone":
			_handle_waystone_selection(text)
		"crafting":
			_handle_crafting_selection(text)
		"map":
			_close_menu()
		"quests":
			_handle_quest_journal_selection(index)
		"settings":
			_handle_settings_selection(text)
		"spell_wheel":
			_handle_spell_wheel_selection(index)
		"masks":
			_handle_mask_selection(index)


func _on_menu_item_selected(_index: int) -> void:
	pass


func _handle_pause_selection(text: String) -> void:
	if text == "Resume":
		_close_menu()
	elif text == "Save Game":
		SaveManager.save_game(0)
		show_toast("Game saved to slot 1")
		_close_menu()
	elif text == "Settings":
		_close_menu()
		_open_settings_menu()
	elif text == "Quit to Menu":
		get_tree().paused = false
		SceneTransitionManager.change_scene("res://scenes/main_menu/main_menu.tscn")


func _handle_waystone_selection(text: String) -> void:
	if text == "Close" or text.begins_with("("):
		_close_menu()
		return
	if not text.begins_with("Travel: "):
		return
	var sel := _menu_list.get_selected_items()
	var index := sel[0] if sel.size() > 0 else -1
	var dest_id: String = _menu_list.get_item_metadata(index) if index >= 0 else ""
	if dest_id == "":
		return
	_close_menu()
	WaystoneManager.fast_travel(dest_id)


func _handle_quest_journal_selection(index: int) -> void:
	if _menu_list.get_item_text(index) == "Close":
		_close_menu()
		return
	var quest_id: Variant = _menu_list.get_item_metadata(index)
	if quest_id != null and typeof(quest_id) == TYPE_STRING:
		QuestManager.track_quest(quest_id)
		_open_quest_journal_menu()


func _handle_settings_selection(text: String) -> void:
	if text == "Close":
		_close_menu()
		return
	if text.begins_with("Master Volume"):
		AudioManager.set_master_volume(fmod(AudioManager.master_volume + 0.1, 1.01))
	elif text.begins_with("Music Volume"):
		AudioManager.set_music_volume(fmod(AudioManager.music_volume + 0.1, 1.01))
	elif text.begins_with("SFX Volume"):
		AudioManager.set_sfx_volume(fmod(AudioManager.sfx_volume + 0.1, 1.01))
	elif text.begins_with("Sensitivity"):
		SettingsManager.camera_sensitivity = clampf(SettingsManager.camera_sensitivity + 0.1, 0.3, 2.0)
	elif text.begins_with("Difficulty"):
		var tiers := ["easy", "normal", "hard"]
		var idx := tiers.find(SettingsManager.difficulty)
		SettingsManager.difficulty = tiers[(idx + 1) % tiers.size()]
	elif text.begins_with("VSync"):
		SettingsManager.vsync = not SettingsManager.vsync
	elif text.begins_with("Frame Cap"):
		var caps := [30, 40, 60, 120, 0]
		var cap_idx := caps.find(SettingsManager.frame_cap)
		SettingsManager.frame_cap = caps[(cap_idx + 1) % caps.size()]
	elif text.begins_with("Invert Look Y"):
		SettingsManager.invert_look_y = not SettingsManager.invert_look_y
	elif text.begins_with("Invert Look X"):
		SettingsManager.invert_look_x = not SettingsManager.invert_look_x
	elif text.begins_with("Hold Sprint"):
		SettingsManager.hold_sprint = not SettingsManager.hold_sprint
	elif text.begins_with("Hold Block"):
		SettingsManager.hold_block = not SettingsManager.hold_block
	elif text.begins_with("Vibration"):
		SettingsManager.vibration = not SettingsManager.vibration
	elif text.begins_with("Subtitles"):
		SettingsManager.subtitles = not SettingsManager.subtitles
	elif text.begins_with("UI Scale"):
		SettingsManager.ui_scale = clampf(SettingsManager.ui_scale + 0.05, 0.8, 1.5)
		_apply_hud_layout()
	elif text.begins_with("Reduce Camera Shake"):
		SettingsManager.reduce_camera_shake = not SettingsManager.reduce_camera_shake
	elif text.begins_with("Motion Blur"):
		SettingsManager.motion_blur = not SettingsManager.motion_blur
	elif text.begins_with("Brightness"):
		SettingsManager.brightness = clampf(SettingsManager.brightness + 0.1, 0.5, 1.5)
	elif text == "Steam Deck Preset":
		SettingsManager.apply_steam_deck_preset()
	SettingsManager.apply_settings()
	SettingsManager.save_settings()
	_open_settings_menu()


func _handle_spell_wheel_selection(index: int) -> void:
	if _player and _player.has_node("Spellcaster"):
		var sc := _player.get_node("Spellcaster")
		if sc.has_method("select_spell_from_wheel"):
			sc.select_spell_from_wheel(index)


func _handle_crafting_selection(text: String) -> void:
	if text == "Upgrade station":
		var sel := _menu_list.get_selected_items()
		var index := sel[0] if sel.size() > 0 else -1
		var station_id: String = _menu_list.get_item_metadata(index) if index >= 0 else _crafting_station_id
		if BaseManager.upgrade_station(station_id):
			_populate_crafting_list()
		return
	if text.begins_with("("):
		return
	var recipe_id := text.split(" — ")[0]
	if CraftingManager.craft(recipe_id, _crafting_station_id):
		_populate_crafting_list()


func open_upgrade_menu(station_id: String) -> void:
	_menu_list.clear()
	_menu_list.add_item("Close")
	var level := BaseManager.get_station_level(station_id)
	_menu_list.add_item("%s — Level %d" % [station_id.capitalize(), level])
	if BaseManager.can_upgrade(station_id):
		var idx := _menu_list.add_item("Upgrade %s" % station_id.capitalize())
		_menu_list.set_item_metadata(idx, station_id)
	else:
		_menu_list.add_item("(Max level or missing materials)")
	_show_menu("upgrade", "Station Upgrade")


func open_storage_menu() -> void:
	_menu_list.clear()
	_menu_list.add_item("Close")
	_menu_list.add_item("--- Deposit (inventory → base) ---")
	for entry in InventoryManager.items:
		var idx := _menu_list.add_item("Deposit %s x%d" % [entry.id, entry.quantity])
		_menu_list.set_item_metadata(idx, {"action": "deposit", "id": entry.id, "qty": entry.quantity})
	_menu_list.add_item("--- Withdraw (base → inventory) ---")
	for entry in InventoryManager.base_storage:
		var widx := _menu_list.add_item("Withdraw %s x%d" % [entry.id, entry.quantity])
		_menu_list.set_item_metadata(widx, {"action": "withdraw", "id": entry.id, "qty": entry.quantity})
	if _menu_list.item_count <= 1:
		_menu_list.add_item("(Storage empty)")
	_show_menu("storage", "Item Box")


func _handle_upgrade_selection(index: int) -> void:
	var station_id: Variant = _menu_list.get_item_metadata(index)
	if station_id == null or typeof(station_id) != TYPE_STRING:
		return
	if BaseManager.upgrade_station(station_id):
		open_upgrade_menu(station_id)


func _handle_storage_selection(index: int) -> void:
	var meta: Variant = _menu_list.get_item_metadata(index)
	if meta == null or typeof(meta) != TYPE_DICTIONARY:
		return
	var data: Dictionary = meta
	match data.get("action"):
		"deposit":
			InventoryManager.deposit_to_base(data.id, mini(data.qty, 1))
		"withdraw":
			InventoryManager.withdraw_from_base(data.id, mini(data.qty, 1))
	open_storage_menu()


