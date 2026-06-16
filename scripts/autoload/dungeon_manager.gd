extends Node

## Tracks dungeon runs, return positions, and entry/exit flow.



signal dungeon_entered(layout: Dictionary)

signal dungeon_cleared()

signal dungeon_exited()



const DUNGEON_SCENES: Dictionary = {

	"abandoned_mine": "res://scenes/dungeons/procedural_dungeon.tscn",

	"sunken_reliquary": "res://scenes/dungeons/sunken_reliquary/sunken_reliquary.tscn",

	"blackvein_foundry": "res://scenes/dungeons/blackvein_foundry/blackvein_foundry.tscn",

	"paleheart_crypt": "res://scenes/dungeons/paleheart_crypt/paleheart_crypt.tscn",

	"drowned_citadel": "res://scenes/dungeons/drowned_citadel/drowned_citadel.tscn",

	"blightspire_cathedral": "res://scenes/dungeons/blightspire_cathedral/blightspire_cathedral.tscn",

	"pyreheart_ziggurat": "res://scenes/dungeons/pyreheart_ziggurat/pyreheart_ziggurat.tscn",

	"eclipse_sanctum": "res://scenes/dungeons/eclipse_sanctum/eclipse_sanctum.tscn",

}

const DUNGEON_SCENE := "res://scenes/dungeons/procedural_dungeon.tscn"
const _SpawnHelpers = preload("res://scripts/utilities/spawn_helpers.gd")
const _ReliquaryGenerator = preload("res://scripts/dungeons/reliquary_generator.gd")
const _FoundryGenerator = preload("res://scripts/dungeons/foundry_generator.gd")
const _CryptGenerator = preload("res://scripts/dungeons/crypt_generator.gd")
const _CitadelGenerator = preload("res://scripts/dungeons/citadel_generator.gd")
const _CathedralGenerator = preload("res://scripts/dungeons/cathedral_generator.gd")
const _PyreheartGenerator = preload("res://scripts/dungeons/pyreheart_generator.gd")
const _EclipseGenerator = preload("res://scripts/dungeons/eclipse_generator.gd")



var in_dungeon: bool = false

var depth: int = 0

var seed: int = 0

var dungeon_name: String = ""

var tier: int = 1

var layout: Dictionary = {}

var current_dungeon_id: String = "abandoned_mine"



var return_scene_path: String = ""

var return_position: Vector3 = Vector3.ZERO

var entrance_region_id: String = "darkpine_forest"

var boss_defeated: bool = false





func reset_for_new_game() -> void:

	in_dungeon = false

	depth = 0

	seed = 0

	dungeon_name = ""

	layout = {}

	return_scene_path = ""

	return_position = Vector3.ZERO

	boss_defeated = false

	current_dungeon_id = "abandoned_mine"





func get_active_scene() -> String:

	return DUNGEON_SCENES.get(current_dungeon_id, DUNGEON_SCENE)





func can_enter(players_near_entrance: bool) -> bool:

	if in_dungeon:

		return false

	return players_near_entrance or GameManager.get_alive_players().size() == 1





func enter_dungeon(from_region: String, return_scene: String, return_pos: Vector3) -> void:

	if in_dungeon:

		return

	current_dungeon_id = "abandoned_mine"

	entrance_region_id = from_region

	return_scene_path = return_scene

	return_position = return_pos

	if String(WorldStateManager.exterior_entrance_id) == "":

		WorldStateManager.set_exterior_entrance("exterior_abandoned_mine", from_region, return_pos)

	depth += 1

	seed = randi()

	tier = mini(depth, 3)

	layout = DungeonGenerator.generate(seed, tier)

	dungeon_name = layout.get("name", "Unknown Depths")

	in_dungeon = true

	boss_defeated = false

	WorldStateManager.dungeon_id = &"abandoned_mine"

	MapManager.discover_region("procedural_dungeon")

	MapManager.add_icon("dungeon", Vector2.ZERO, dungeon_name)

	QuestManager.start_quest("clear_dungeon")

	dungeon_entered.emit(layout)

	SceneTransitionManager.change_scene(get_active_scene())





func enter_reliquary(from_region: String, return_scene: String, return_pos: Vector3) -> void:

	if in_dungeon:

		return

	current_dungeon_id = "sunken_reliquary"

	entrance_region_id = from_region

	return_scene_path = return_scene

	return_position = return_pos

	WorldStateManager.set_exterior_entrance("exterior_sunken_reliquary", from_region, return_pos)

	if ReliquaryState.boss_defeated_persistent:

		boss_defeated = true

	else:

		boss_defeated = false

	seed = ReliquaryState.dungeon_seed if ReliquaryState.dungeon_seed != 0 else randi()
	if ReliquaryState.dungeon_seed == 0:
		ReliquaryState.dungeon_seed = seed

	layout = _ReliquaryGenerator.generate(seed)

	dungeon_name = "Sunken Reliquary"

	in_dungeon = true

	WorldStateManager.dungeon_id = &"sunken_reliquary"

	MapManager.discover_region("sunken_reliquary")

	MapManager.add_icon("dungeon", Vector2.ZERO, dungeon_name)

	dungeon_entered.emit(layout)

	SceneTransitionManager.change_scene(get_active_scene())





func enter_foundry(from_region: String, return_scene: String, return_pos: Vector3) -> void:

	if in_dungeon:

		return

	current_dungeon_id = "blackvein_foundry"

	entrance_region_id = from_region

	return_scene_path = return_scene

	return_position = return_pos

	WorldStateManager.set_exterior_entrance("exterior_blackvein_foundry", from_region, return_pos)

	if FoundryState.boss_defeated_persistent:

		boss_defeated = true

	else:

		boss_defeated = false

	seed = FoundryState.dungeon_seed if FoundryState.dungeon_seed != 0 else randi()

	if FoundryState.dungeon_seed == 0:

		FoundryState.dungeon_seed = seed

	layout = _FoundryGenerator.generate(seed)

	dungeon_name = "Blackvein Foundry"

	in_dungeon = true

	WorldStateManager.dungeon_id = &"blackvein_foundry"

	MapManager.discover_region("blackvein_foundry")

	MapManager.add_icon("dungeon", Vector2.ZERO, dungeon_name)

	if not QuestManager.active_quests.has("heart_of_blackvein") and "heart_of_blackvein" not in QuestManager.completed_quests:

		QuestManager.start_quest("heart_of_blackvein")

	dungeon_entered.emit(layout)

	SceneTransitionManager.change_scene(get_active_scene())





func enter_crypt(from_region: String, return_scene: String, return_pos: Vector3) -> void:

	if in_dungeon:

		return

	current_dungeon_id = "paleheart_crypt"

	entrance_region_id = from_region

	return_scene_path = return_scene

	return_position = return_pos

	WorldStateManager.set_exterior_entrance("exterior_paleheart_crypt", from_region, return_pos)

	if CryptState.boss_defeated_persistent:

		boss_defeated = true

	else:

		boss_defeated = false

	seed = CryptState.dungeon_seed if CryptState.dungeon_seed != 0 else randi()

	if CryptState.dungeon_seed == 0:

		CryptState.dungeon_seed = seed

	layout = _CryptGenerator.generate(seed)

	dungeon_name = "Paleheart Crypt"

	in_dungeon = true

	WorldStateManager.dungeon_id = &"paleheart_crypt"

	MapManager.discover_region("paleheart_crypt")

	MapManager.add_icon("dungeon", Vector2.ZERO, dungeon_name)

	if not QuestManager.active_quests.has("gravewind_rising") and "gravewind_rising" not in QuestManager.completed_quests:

		QuestManager.start_quest("gravewind_rising")

	dungeon_entered.emit(layout)

	SceneTransitionManager.change_scene(get_active_scene())





func enter_citadel(from_region: String, return_scene: String, return_pos: Vector3) -> void:

	if in_dungeon:

		return

	current_dungeon_id = "drowned_citadel"

	entrance_region_id = from_region

	return_scene_path = return_scene

	return_position = return_pos

	WorldStateManager.set_exterior_entrance("exterior_drowned_citadel", from_region, return_pos)

	if CitadelState.boss_defeated_persistent:

		boss_defeated = true

	else:

		boss_defeated = false

	seed = CitadelState.dungeon_seed if CitadelState.dungeon_seed != 0 else randi()

	if CitadelState.dungeon_seed == 0:

		CitadelState.dungeon_seed = seed

	layout = _CitadelGenerator.generate(seed)

	dungeon_name = "Drowned Citadel"

	in_dungeon = true

	WorldStateManager.dungeon_id = &"drowned_citadel"

	MapManager.discover_region("drowned_citadel")

	MapManager.add_icon("dungeon", Vector2.ZERO, dungeon_name)

	dungeon_entered.emit(layout)

	SceneTransitionManager.change_scene(get_active_scene())





func enter_cathedral(from_region: String, return_scene: String, return_pos: Vector3) -> void:

	if in_dungeon:

		return

	current_dungeon_id = "blightspire_cathedral"

	entrance_region_id = from_region

	return_scene_path = return_scene

	return_position = return_pos

	WorldStateManager.set_exterior_entrance("exterior_blightspire_cathedral", from_region, return_pos)

	boss_defeated = false

	seed = CathedralState.dungeon_seed if CathedralState.dungeon_seed != 0 else randi()

	if CathedralState.dungeon_seed == 0:

		CathedralState.dungeon_seed = seed

	layout = _CathedralGenerator.generate(seed)

	dungeon_name = "Blightspire Cathedral"

	in_dungeon = true

	WorldStateManager.dungeon_id = &"blightspire_cathedral"

	MapManager.discover_region("blightspire_cathedral")

	MapManager.add_icon("dungeon", Vector2.ZERO, dungeon_name)

	dungeon_entered.emit(layout)

	SceneTransitionManager.change_scene(get_active_scene())





func enter_pyreheart(from_region: String, return_scene: String, return_pos: Vector3) -> void:

	if in_dungeon:

		return

	current_dungeon_id = "pyreheart_ziggurat"

	entrance_region_id = from_region

	return_scene_path = return_scene

	return_position = return_pos

	WorldStateManager.set_exterior_entrance("exterior_pyreheart_ziggurat", from_region, return_pos)

	boss_defeated = false

	seed = PyreheartState.dungeon_seed if PyreheartState.dungeon_seed != 0 else randi()

	if PyreheartState.dungeon_seed == 0:

		PyreheartState.dungeon_seed = seed

	layout = _PyreheartGenerator.generate(seed)

	dungeon_name = "Pyreheart Ziggurat"

	in_dungeon = true

	WorldStateManager.dungeon_id = &"pyreheart_ziggurat"

	MapManager.discover_region("pyreheart_ziggurat")

	MapManager.add_icon("dungeon", Vector2.ZERO, dungeon_name)

	dungeon_entered.emit(layout)

	SceneTransitionManager.change_scene(get_active_scene())





func enter_eclipse_sanctum(from_region: String, return_scene: String, return_pos: Vector3) -> void:

	if in_dungeon:

		return

	current_dungeon_id = "eclipse_sanctum"

	entrance_region_id = from_region

	return_scene_path = return_scene

	return_position = return_pos

	WorldStateManager.set_exterior_entrance("exterior_eclipse_sanctum", from_region, return_pos)

	boss_defeated = false

	seed = EclipseSanctumState.dungeon_seed if EclipseSanctumState.dungeon_seed != 0 else randi()

	if EclipseSanctumState.dungeon_seed == 0:

		EclipseSanctumState.dungeon_seed = seed

	layout = _EclipseGenerator.generate(seed)

	dungeon_name = "Eclipse Sanctum"

	in_dungeon = true

	WorldStateManager.dungeon_id = &"eclipse_sanctum"

	MapManager.discover_region("eclipse_sanctum")

	MapManager.add_icon("dungeon", Vector2.ZERO, dungeon_name)

	dungeon_entered.emit(layout)

	SceneTransitionManager.change_scene(get_active_scene())





func on_boss_defeated() -> void:

	if boss_defeated:

		return

	boss_defeated = true

	QuestManager.advance_objective("clear_dungeon", "defeat_boss", 1)

	AchievementManager.unlock("dungeon_delver")

	DialogueManager.start_dialogue("dungeon_victory", [

		{"speaker": "Echo", "text": "The crypt falls silent. Treasure awaits — find the exit seal."},

	])

	dungeon_cleared.emit()





func on_reliquary_boss_defeated() -> void:

	if boss_defeated:

		return

	boss_defeated = true

	ReliquaryState.boss_defeated_persistent = true

	ReliquaryState.save_state()

	QuestManager.complete_quest("depths_of_reliquary")

	if not QuestManager.completed_quests.has("through_the_ash"):

		QuestManager.start_quest("through_the_ash")

	DialogueManager.start_dialogue("reliquary_victory", [

		{"speaker": "Bellkeeper", "text": "The drowned bell falls silent. The Marsh Sigil is yours — Ashfall awaits."},

	])

	dungeon_cleared.emit()





func on_foundry_boss_defeated() -> void:

	if boss_defeated:

		return

	boss_defeated = true

	FoundryState.boss_defeated_persistent = true

	FoundryState.save_state()

	QuestManager.complete_quest("heart_of_blackvein")

	if QuestManager.active_quests.has("fires_below"):

		QuestManager.advance_objective("fires_below", "unlock_exterior", 1)

		QuestManager.complete_quest("fires_below")

	DialogueManager.start_dialogue("foundry_victory", [

		{"speaker": "Crucible", "text": "The Iron Crucible falls silent. The Foundry Core is yours — Frostgrave awaits beyond the pass."},

	])

	dungeon_cleared.emit()





func on_crypt_boss_defeated() -> void:

	if boss_defeated:

		return

	boss_defeated = true

	CryptState.boss_defeated_persistent = true

	CryptState.save_state()

	QuestManager.complete_quest("the_pale_heart")

	DialogueManager.start_dialogue("crypt_victory", [

		{"speaker": "Hollow King", "text": "The Hollow King falls silent. The Paleheart Relic is yours — the Shattered Coast awaits beyond the frost."},

	])

	dungeon_cleared.emit()




func on_citadel_boss_defeated() -> void:

	if CitadelState.boss_defeated_persistent:

		return

	boss_defeated = true

	CitadelState.boss_defeated_persistent = true

	CitadelState.save_state()

	QuestManager.complete_quest("the_sunken_crown")

	DialogueManager.start_dialogue("citadel_victory", [

		{"speaker": "Tidebound Sovereign", "text": "The Tidebound Sovereign falls silent. The Tidebound Crown is yours — the road to Blightreach awaits beyond the storm."},

	])

	dungeon_cleared.emit()




func on_cathedral_boss_defeated() -> void:

	if CathedralState.boss_defeated_persistent:

		return

	boss_defeated = true

	CathedralState.boss_defeated_persistent = true

	CathedralState.save_state()

	DialogueManager.start_dialogue("cathedral_victory", [

		{"speaker": "The Blightheart", "text": "The Blightheart falls silent. Its core is yours — the road to the Ember Wastes stirs beyond Blightreach."},

	])

	dungeon_cleared.emit()




func on_pyreheart_boss_defeated() -> void:

	if PyreheartState.boss_defeated_persistent:

		return

	boss_defeated = true

	PyreheartState.boss_defeated_persistent = true

	PyreheartState.save_state()

	DialogueManager.start_dialogue("pyreheart_victory", [

		{"speaker": "The Solar Tyrant", "text": "The Solar Tyrant falls silent. The Solar Heart Core is yours — the road to the Sunless Dominion stirs beyond the dunes."},

	])

	dungeon_cleared.emit()




func exit_dungeon() -> void:

	if not in_dungeon:

		return

	var scene_path := return_scene_path

	var ext_id := String(WorldStateManager.exterior_entrance_id)

	if ext_id == "":

		match current_dungeon_id:

			"abandoned_mine": ext_id = "exterior_abandoned_mine"

			"blackvein_foundry": ext_id = "exterior_blackvein_foundry"

			"paleheart_crypt": ext_id = "exterior_paleheart_crypt"

			"drowned_citadel": ext_id = "exterior_drowned_citadel"

			"blightspire_cathedral": ext_id = "exterior_blightspire_cathedral"

			"pyreheart_ziggurat": ext_id = "exterior_pyreheart_ziggurat"

			"eclipse_sanctum": ext_id = "exterior_eclipse_sanctum"

			_: ext_id = "exterior_sunken_reliquary"

	in_dungeon = false

	if not ReliquaryState.boss_defeated_persistent and not FoundryState.boss_defeated_persistent and not CryptState.boss_defeated_persistent and not CitadelState.boss_defeated_persistent and not CathedralState.boss_defeated_persistent and not PyreheartState.boss_defeated_persistent and not EclipseSanctumState.boss_defeated_persistent:

		boss_defeated = false

	GameManager.in_boss_fight = false

	GameManager.pending_spawn_id = ext_id

	WorldStateManager.begin_exterior_return(entrance_region_id)

	current_dungeon_id = "abandoned_mine"

	dungeon_exited.emit()

	SceneTransitionManager.change_scene(scene_path)





func reload_dungeon_preserve_seed() -> void:

	if seed == 0:

		seed = randi()

	if current_dungeon_id == "sunken_reliquary":

		layout = _ReliquaryGenerator.generate(seed)

	elif current_dungeon_id == "blackvein_foundry":

		layout = _FoundryGenerator.generate(seed)

	elif current_dungeon_id == "paleheart_crypt":

		layout = _CryptGenerator.generate(seed)

	elif current_dungeon_id == "drowned_citadel":

		layout = _CitadelGenerator.generate(seed)

	elif current_dungeon_id == "blightspire_cathedral":

		layout = _CathedralGenerator.generate(seed)

	elif current_dungeon_id == "pyreheart_ziggurat":

		layout = _PyreheartGenerator.generate(seed)

	elif current_dungeon_id == "eclipse_sanctum":

		layout = _EclipseGenerator.generate(seed)

	else:

		layout = DungeonGenerator.generate(seed, tier)

	in_dungeon = true

	if not ReliquaryState.boss_defeated_persistent and not FoundryState.boss_defeated_persistent and not CryptState.boss_defeated_persistent and not CitadelState.boss_defeated_persistent and not CathedralState.boss_defeated_persistent and not PyreheartState.boss_defeated_persistent and not EclipseSanctumState.boss_defeated_persistent:

		boss_defeated = false





func get_floor_display() -> String:

	if not in_dungeon:

		return ""

	return "%s — %s" % [dungeon_name, current_dungeon_id.replace("_", " ").capitalize()]





func serialize() -> Dictionary:

	return {

		"depth": depth,

		"in_dungeon": in_dungeon,

		"dungeon_name": dungeon_name,

		"current_dungeon_id": current_dungeon_id,

		"seed": seed,

	}





func deserialize(data: Dictionary) -> void:

	depth = int(data.get("depth", 0))

	in_dungeon = false

	dungeon_name = data.get("dungeon_name", "")

	current_dungeon_id = data.get("current_dungeon_id", "abandoned_mine")

	seed = int(data.get("seed", 0))


