extends CanvasLayer
## In-game HUD plus controller-navigable overlay menus.

@onready var health_bar: ProgressBar = %HealthBar
@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var hunger_bar: ProgressBar = %HungerBar
@onready var thirst_bar: ProgressBar = %ThirstBar
@onready var quest_label: Label = %QuestLabel
@onready var currency_label: Label = %CurrencyLabel
@onready var interact_prompt: Label = %InteractPrompt
@onready var boss_bar: ProgressBar = %BossHealthBar
@onready var spell_label: Label = %SpellLabel
@onready var execution_label: Label = %ExecutionLabel
@onready var map_stub_label: Label = %MapStubLabel

var _player: Node
var _tracked_boss: Node = null
var _active_menu: String = ""
var _crafting_station_id: String = ""
var _spell_wheel_spells: Array[String] = []
var _toast_label: Label
var _toast_timer: float = 0.0

var _overlay: ColorRect
var _dialogue_panel: PanelContainer
var _dialogue_speaker: Label
var _dialogue_text: Label
var _menu_panel: PanelContainer
var _menu_title: Label
var _menu_list: ItemList
var _menu_hint: Label


func _ready() -> void:
	add_to_group("game_hud")
	_build_overlay_ui()
	_build_toast()
	QuestManager.tracked_quest_changed.connect(_update_quest)
	QuestManager.quest_updated.connect(func(_id): _update_quest(""))
	CurrencyManager.currency_changed.connect(_update_currency)
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	DialogueManager.dialogue_line_shown.connect(_on_dialogue_line)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	MapManager.map_updated.connect(_on_map_updated)
	DungeonManager.dungeon_entered.connect(func(_layout): _update_map_stub())
	DungeonManager.dungeon_exited.connect(func(): _update_map_stub())
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
			_close_menu()
		elif _active_menu == "":
			_open_inventory_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_map"):
		if _active_menu == "map":
			_close_menu()
		elif _active_menu == "":
			_open_map_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_skill_tree"):
		if _active_menu == "skill_tree":
			_close_menu()
		elif _active_menu == "":
			_open_skill_tree_menu()
		get_viewport().set_input_as_handled()
	elif DialogueManager.is_active() and event.is_action_pressed("confirm"):
		DialogueManager.advance()
		get_viewport().set_input_as_handled()
	elif _active_menu != "" and event.is_action_pressed("cancel"):
		_close_menu()
		get_viewport().set_input_as_handled()
	elif _active_menu != "" and event.is_action_pressed("confirm"):
		_menu_confirm()
		get_viewport().set_input_as_handled()


func set_interact_prompt(text: String) -> void:
	interact_prompt.text = text if text != "" else ""


func set_execution_prompt(visible: bool) -> void:
	execution_label.visible = visible


func track_boss(boss: Node) -> void:
	_tracked_boss = boss
	boss_bar.visible = true
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


func open_merchant_menu() -> void:
	_populate_merchant_list()
	_show_menu("merchant", "Silent Merchant")


func open_spell_wheel_menu(spells: Array[String], selected_index: int) -> void:
	_spell_wheel_spells = spells
	_menu_list.clear()
	for i in spells.size():
		var prefix := "> " if i == selected_index else "  "
		_menu_list.add_item("%s%s" % [prefix, spells[i].replace("_", " ").capitalize()])
		_menu_list.set_item_metadata(i, i)
	_show_menu("spell_wheel", "Spell Wheel")


func close_spell_wheel_menu() -> void:
	if _active_menu == "spell_wheel":
		_close_menu()


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
	if player.has_node("Spellcaster"):
		var spellcaster := player.get_node("Spellcaster")
		if spellcaster.has_signal("spell_changed") and not spellcaster.spell_changed.is_connected(_on_spell_changed):
			spellcaster.spell_changed.connect(_on_spell_changed)


func _update_bars() -> void:
	if _player.has_node("SurvivalNeedsComponent"):
		var needs := _player.get_node("SurvivalNeedsComponent") as SurvivalNeedsComponent
		hunger_bar.value = needs.hunger
		thirst_bar.value = needs.thirst


func _update_spell_label() -> void:
	if _player and _player.has_node("Spellcaster"):
		var sc := _player.get_node("Spellcaster")
		if sc.has_method("get_active_spell_label"):
			spell_label.text = "Spell: %s" % sc.get_active_spell_label()


func _update_boss_bar() -> void:
	if _tracked_boss == null or not is_instance_valid(_tracked_boss):
		boss_bar.visible = false
		return
	if _tracked_boss.has_node("HealthComponent"):
		var health := _tracked_boss.get_node("HealthComponent") as HealthComponent
		boss_bar.max_value = health.max_health
		boss_bar.value = health.current_health


func _on_boss_health_changed(current: float, _maximum: float) -> void:
	boss_bar.value = current
	if current <= 0.0:
		boss_bar.visible = false
		_tracked_boss = null


func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current


func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current


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
	var pos := MapManager.player_positions[0] if MapManager.player_positions.size() > 0 else Vector2.ZERO
	map_stub_label.text = "Map: %s  Pos: (%.0f, %.0f)" % [
		GameManager.current_region_id.replace("_", " ").capitalize(),
		pos.x, pos.y,
	]


func _update_quest(_id: String) -> void:
	var text := QuestManager.get_tracked_objective_text()
	quest_label.text = "Tracked: %s" % text if text != "" else "Tracked: —"


func _update_currency() -> void:
	currency_label.text = CurrencyManager.get_display_string()


func _on_inventory_changed() -> void:
	if _active_menu == "inventory":
		_populate_inventory_list()


func _on_dialogue_line(speaker: String, text: String) -> void:
	_dialogue_panel.visible = true
	_dialogue_speaker.text = speaker
	_dialogue_text.text = text


func _on_dialogue_ended() -> void:
	_dialogue_panel.visible = false


func _open_pause_menu() -> void:
	_menu_list.clear()
	_menu_list.add_item("Resume")
	_menu_list.add_item("Save Game")
	_menu_list.add_item("Quit to Menu")
	_show_menu("pause", "Paused")


func _open_inventory_menu() -> void:
	_populate_inventory_list()
	_show_menu("inventory", "Inventory")


func _open_waystone_menu() -> void:
	_menu_list.clear()
	_menu_list.add_item("Close")
	for dest in WaystoneManager.discovered:
		var label := dest.replace("_", " ").capitalize()
		var idx := _menu_list.add_item("Travel: %s" % label)
		_menu_list.set_item_metadata(idx, dest)
	if _menu_list.item_count <= 1:
		_menu_list.add_item("(No waystones discovered yet)")
	_show_menu("waystone", "Waystone Travel")


func _open_map_menu() -> void:
	_menu_list.clear()
	_menu_list.add_item("Close")
	for region_id in MapManager.regions.keys():
		var state: int = MapManager.regions[region_id]
		var state_name: String = MapManager.RegionState.keys()[state]
		if state == MapManager.RegionState.UNDISCOVERED:
			state_name = "???"
		_menu_list.add_item("%s — %s" % [region_id.replace("_", " ").capitalize(), state_name])
	var pos := MapManager.player_positions[0] if MapManager.player_positions.size() > 0 else Vector2.ZERO
	_menu_list.add_item("Player position: (%.0f, %.0f)" % [pos.x, pos.y])
	_show_menu("map", "World Map")


func _open_skill_tree_menu() -> void:
	_menu_list.clear()
	if _player == null or not _player.has_node("SkillTree"):
		_menu_list.add_item("(No skill tree)")
		_show_menu("skill_tree", "Skill Tree")
		return
	var tree := _player.get_node("SkillTree")
	var points := 0
	if _player.has_node("StatsComponent"):
		points = (_player.get_node("StatsComponent") as StatsComponent).unspent_skill_points
	_menu_list.add_item("Skill Points: %d" % points)
	for node_id in tree.get_all_node_ids():
		var prefix := "[X] " if node_id in tree.unlocked_nodes else "[ ] "
		_menu_list.add_item("%s%s" % [prefix, tree.get_node_display(node_id)])
		_menu_list.set_item_metadata(_menu_list.item_count - 1, node_id)
	_show_menu("skill_tree", "Skill Tree")


func _populate_inventory_list() -> void:
	_menu_list.clear()
	for entry in InventoryManager.items:
		_menu_list.add_item("%s x%d" % [entry.id, entry.quantity])
	if _menu_list.item_count == 0:
		_menu_list.add_item("(Empty)")


func _populate_crafting_list() -> void:
	_menu_list.clear()
	for recipe_id in CraftingManager.known_recipes:
		var check := CraftingManager.can_craft(recipe_id, _crafting_station_id)
		var status: String = "OK" if check.ok else str(check.reason)
		_menu_list.add_item("%s — %s" % [recipe_id, status])


func _populate_merchant_list() -> void:
	_menu_list.clear()
	_menu_list.add_item("Buy Dried Rations (10 copper)")
	_menu_list.add_item("Buy Bandage (15 copper)")
	_menu_list.add_item("Sell Wood x1 (2 copper)")
	_menu_list.add_item("Sell Cloth Scrap x1 (3 copper)")


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
		"inventory":
			pass
		"waystone":
			_handle_waystone_selection(text)
		"crafting":
			_handle_crafting_selection(text)
		"merchant":
			_handle_merchant_selection(text)
		"map":
			_close_menu()
		"skill_tree":
			_handle_skill_tree_selection(index)
		"spell_wheel":
			_handle_spell_wheel_selection(index)


func _on_menu_item_selected(_index: int) -> void:
	pass


func _handle_pause_selection(text: String) -> void:
	if text == "Resume":
		_close_menu()
	elif text == "Save Game":
		SaveManager.save_game(0)
		_close_menu()
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


func _handle_skill_tree_selection(index: int) -> void:
	var text := _menu_list.get_item_text(index)
	if text.begins_with("Skill Points") or text.begins_with("[X]"):
		return
	if _player == null or not _player.has_node("SkillTree"):
		return
	var node_id: String = _menu_list.get_item_metadata(index)
	var tree := _player.get_node("SkillTree")
	if tree.unlock_node(node_id):
		_open_skill_tree_menu()


func _handle_spell_wheel_selection(index: int) -> void:
	if _player and _player.has_node("Spellcaster"):
		var sc := _player.get_node("Spellcaster")
		if sc.has_method("select_spell_from_wheel"):
			sc.select_spell_from_wheel(index)


func _handle_crafting_selection(text: String) -> void:
	if text.begins_with("("):
		return
	var recipe_id := text.split(" — ")[0]
	if CraftingManager.craft(recipe_id, _crafting_station_id):
		_populate_crafting_list()


func _handle_merchant_selection(text: String) -> void:
	if text.begins_with("Buy Dried Rations"):
		if CurrencyManager.spend_copper(10):
			InventoryManager.add_item("dried_rations", 1)
	elif text.begins_with("Buy Bandage"):
		if CurrencyManager.spend_copper(15):
			InventoryManager.add_item("bandage", 1)
	elif text.begins_with("Sell Wood"):
		if InventoryManager.remove_item("wood", 1):
			CurrencyManager.add_copper(2)
	elif text.begins_with("Sell Cloth"):
		if InventoryManager.remove_item("cloth_scrap", 1):
			CurrencyManager.add_copper(3)
	_populate_merchant_list()
