extends CanvasLayer
## In-game HUD plus controller-navigable overlay menus.

const InventoryPanelScene := preload("res://scripts/ui/inventory_panel.gd")
const SkillTreePanelScene := preload("res://scripts/ui/skill_tree_panel.gd")
const SpellWheelPanelScene := preload("res://scripts/ui/spell_wheel_panel.gd")
const MerchantShopPanelScene := preload("res://scripts/ui/merchant_shop_panel.gd")

@onready var health_bar: TextureProgressBar = %HealthBar
@onready var stamina_bar: TextureProgressBar = %StaminaBar
@onready var focus_bar: TextureProgressBar = %FocusBar
@onready var hunger_bar: TextureProgressBar = %HungerBar
@onready var thirst_bar: TextureProgressBar = %ThirstBar
@onready var level_label: Label = %LevelLabel
@onready var quest_label: Label = %QuestLabel
@onready var quest_title_label: Label = %QuestTitleLabel
@onready var quest_distance_label: Label = %QuestDistanceLabel
@onready var currency_label: Label = %CurrencyLabel
@onready var interact_prompt: Label = %InteractPrompt
@onready var boss_bar: TextureProgressBar = %BossHealthBar
@onready var spell_label: Label = %SpellLabel
@onready var execution_label: Label = %ExecutionLabel
@onready var map_stub_label: Label = %MapStubLabel
@onready var controls_hint_label: Label = %ControlsHintLabel
@onready var adrenaline_row: HBoxContainer = %AdrenalineRow

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
var _dialogue_panel: PanelContainer
var _dialogue_speaker: Label
var _dialogue_text: Label
var _menu_panel: PanelContainer
var _menu_title: Label
var _menu_list: ItemList
var _menu_hint: Label
var _inventory_panel: PanelContainer
var _skill_tree_panel: PanelContainer
var _spell_wheel_panel: Control
var _merchant_panel: PanelContainer


func _ready() -> void:
	add_to_group("game_hud")
	_setup_kenney_hud()
	_build_overlay_ui()
	_build_toast()
	QuestManager.tracked_quest_changed.connect(_update_quest)
	QuestManager.quest_updated.connect(func(_id): _update_quest(""))
	CurrencyManager.currency_changed.connect(_update_currency)
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	DialogueManager.dialogue_line_shown.connect(_on_dialogue_line)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	QuestManager.quest_rewarded.connect(_on_quest_rewarded)
	QuestManager.quest_completed.connect(_on_quest_completed)
	MapManager.map_updated.connect(_on_map_updated)
	GameManager.combat_state_changed.connect(_on_combat_state_changed)
	DungeonManager.dungeon_entered.connect(func(_layout): _update_map_stub())
	DungeonManager.dungeon_exited.connect(func(): _update_map_stub())
	CraftingManager.craft_completed.connect(func(recipe_id): show_toast("Crafted %s" % recipe_id.replace("_", " ")))
	CraftingManager.craft_failed.connect(func(reason): show_toast("Craft failed: %s" % reason))
	call_deferred("_bind_player")
	_update_quest("")
	_update_currency()
	_update_map_stub()
	boss_bar.visible = false
	execution_label.visible = false


func _process(delta: float) -> void:
	if _player and is_instance_valid(_player):
		_update_bars()
		_update_spell_label()
		_update_quest_distance()
	_update_boss_bar()
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and _toast_label:
			_toast_label.visible = false


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
	elif DialogueManager.is_active() and event.is_action_pressed("confirm"):
		DialogueManager.advance()
		get_viewport().set_input_as_handled()
	elif _active_menu != "" and event.is_action_pressed("cancel"):
		if _active_menu == "inventory":
			_close_inventory_panel()
		elif _active_menu == "skill_tree":
			_close_skill_tree_panel()
		elif _active_menu == "merchant":
			_close_merchant_panel()
		else:
			_close_menu()
		get_viewport().set_input_as_handled()
	elif _active_menu != "" and event.is_action_pressed("confirm"):
		_menu_confirm()
		get_viewport().set_input_as_handled()


func show_toast(text: String, duration: float = 3.0) -> void:
	_toast_label.text = text
	_toast_label.visible = true
	_toast_timer = duration


func set_interact_prompt(text: String) -> void:
	interact_prompt.text = text if text != "" else ""


func set_execution_prompt(visible: bool) -> void:
	execution_label.visible = visible


func track_boss(boss: Node) -> void:
	_tracked_boss = boss
	boss_bar.visible = true
	var boss_name := "Boss"
	if boss is EnemyBase:
		boss_name = (boss as EnemyBase).display_name
		boss_bar.tooltip_text = boss_name
	if _boss_name_label:
		_boss_name_label.text = boss_name
		_boss_name_label.visible = true
	if boss is BossController and not boss.phase_changed.is_connected(_on_boss_phase_changed):
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


func _setup_kenney_hud() -> void:
	var ring := get_node_or_null("HudRoot/TopRight/VBox/MapFrame/Ring") as TextureRect
	if ring:
		var circle := KenneyUiPaths.load_tex(KenneyUiPaths.circle_frame())
		if circle:
			ring.texture = circle
	_build_adrenaline_pips()
	controls_hint_label.text = "WASD Move  |  Shift Sprint  |  Mouse Look  |  E Interact"


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
		star.set_meta("filled_tex", filled)
		star.set_meta("empty_tex", empty)
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
		var filled: Texture2D = star.get_meta("filled_tex")
		var empty: Texture2D = star.get_meta("empty_tex")
		star.texture = filled if i < lit and filled else empty


func _update_quest_distance() -> void:
	if _player == null or quest_distance_label == null:
		return
	var best := INF
	for node in get_tree().get_nodes_in_group("quest_destination"):
		if node is Node3D:
			var d := _player.global_position.distance_to((node as Node3D).global_position)
			best = minf(best, d)
	if best >= INF:
		quest_distance_label.visible = false
		return
	quest_distance_label.visible = true
	quest_distance_label.text = "Objective %d m" % int(best)


func _build_overlay_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.55)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)

	_dialogue_panel = PanelContainer.new()
	_dialogue_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_dialogue_panel.offset_top = -160
	_dialogue_panel.visible = false
	add_child(_dialogue_panel)

	var dlg_vbox := VBoxContainer.new()
	_dialogue_panel.add_child(dlg_vbox)
	_dialogue_speaker = Label.new()
	_dialogue_speaker.add_theme_font_size_override("font_size", 22)
	dlg_vbox.add_child(_dialogue_speaker)
	_dialogue_text = Label.new()
	_dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_text.add_theme_font_size_override("font_size", 20)
	dlg_vbox.add_child(_dialogue_text)

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


func _build_toast() -> void:
	_toast_label = Label.new()
	_toast_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_toast_label.offset_top = 100
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 22)
	_toast_label.visible = false
	add_child(_toast_label)


func _bind_player() -> void:
	await get_tree().process_frame
	_bind_player_node(GameManager.get_player(0))


func _bind_player_node(player: Node) -> void:
	if player == null:
		return
	_player = player
	if player.has_node("HealthComponent"):
		var health := player.get_node("HealthComponent") as HealthComponent
		if not health.health_changed.is_connected(_on_health_changed):
			health.health_changed.connect(_on_health_changed)
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
		_update_level_label(stats)
	if player.has_node("Spellcaster"):
		var spellcaster := player.get_node("Spellcaster")
		if spellcaster.has_signal("spell_changed") and not spellcaster.spell_changed.is_connected(_on_spell_changed):
			spellcaster.spell_changed.connect(_on_spell_changed)


func _update_bars() -> void:
	if _player.has_node("SurvivalNeedsComponent"):
		var needs := _player.get_node("SurvivalNeedsComponent") as SurvivalNeedsComponent
		hunger_bar.value = needs.hunger
		thirst_bar.value = needs.thirst
	if _player.has_node("FocusComponent"):
		var focus := _player.get_node("FocusComponent") as FocusComponent
		focus_bar.max_value = focus.max_focus
		focus_bar.value = focus.current_focus
	if _player.has_node("StaminaComponent"):
		var stamina := _player.get_node("StaminaComponent") as StaminaComponent
		var pct := stamina.current_stamina / stamina.max_stamina if stamina.max_stamina > 0 else 0.0
		_update_adrenaline_pips(pct)


func _update_spell_label() -> void:
	if _player and _player.has_node("Spellcaster"):
		var sc := _player.get_node("Spellcaster")
		if sc.has_method("get_active_spell_label"):
			spell_label.text = "Spell: %s" % sc.get_active_spell_label()


func _on_boss_phase_changed(phase: int) -> void:
	show_toast("Boss enters phase %d!" % phase, 2.5)


func _update_boss_bar() -> void:
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


func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current


func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current


func _on_focus_changed(current: float, maximum: float) -> void:
	focus_bar.max_value = maximum
	focus_bar.value = current


func _on_level_changed(_level: int) -> void:
	if _player and _player.has_node("StatsComponent"):
		_update_level_label(_player.get_node("StatsComponent") as StatsComponent)


func _update_level_label(stats: StatsComponent) -> void:
	level_label.text = "Lv %d — %d skill pts" % [stats.level, stats.unspent_skill_points]


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
	_toast_label.text = "Achievement: %s" % AchievementManager.get_display_name(id)
	_toast_label.visible = true
	_toast_timer = 3.0


func _on_map_updated(_region_id: String) -> void:
	_update_map_stub()


func _update_map_stub() -> void:
	if _player == null:
		return
	var floor_text := DungeonManager.get_floor_display()
	if floor_text != "":
		map_stub_label.text = floor_text
		return
	var region := GameManager.current_region_id.replace("_", " ").capitalize()
	var pos_label := MapManager.get_map_position_label(_player.global_position)
	map_stub_label.text = "%s\n%s" % [region, pos_label]


func _update_quest(_id: String) -> void:
	if QuestManager.tracked_quest_id == "" or not QuestManager.active_quests.has(QuestManager.tracked_quest_id):
		quest_title_label.text = "No active quest"
		quest_label.text = "Explore the island and speak to survivors."
		return
	var qid: String = QuestManager.tracked_quest_id
	quest_title_label.text = qid.replace("_", " ").to_upper()
	var lines: PackedStringArray = []
	var objectives: Array = QuestManager.active_quests[qid]
	for obj in objectives:
		var prefix := "• " if not obj.completed else "✓ "
		var progress := "" if obj.completed else " (%d/%d)" % [obj.current, obj.target]
		lines.append("%s%s%s" % [prefix, obj.description, progress])
	quest_label.text = "\n".join(lines)


func _update_currency() -> void:
	currency_label.text = CurrencyManager.get_display_string()


func _on_inventory_changed() -> void:
	if _active_menu == "inventory" and _inventory_panel.visible:
		_inventory_panel.open(_player)


func _on_dialogue_line(speaker: String, text: String) -> void:
	if not SettingsManager.subtitles:
		return
	_dialogue_panel.visible = true
	_dialogue_speaker.text = speaker
	_dialogue_text.text = text


func _on_dialogue_ended() -> void:
	_dialogue_panel.visible = false


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


