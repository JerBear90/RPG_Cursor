class_name RegionContent
extends RefCounted
## Spawns enemies, chests, and props for travel regions at runtime.

const ENEMY_SCENES := {
	"forest_bandit": "res://scenes/enemies/forest_bandit.tscn",
	"shield_bandit": "res://scenes/enemies/shield_bandit.tscn",
	"bandit_archer": "res://scenes/enemies/bandit_archer.tscn",
	"bandit_captain": "res://scenes/enemies/bandit_captain.tscn",
	"hollow_warden": "res://scenes/enemies/hollow_grove_warden.tscn",
	"bog_stalker": "res://scenes/enemies/bog_stalker.tscn",
	"mire_hound": "res://scenes/enemies/mire_hound.tscn",
	"drowned_husk": "res://scenes/enemies/drowned_husk.tscn",
	"rotfen_cultist": "res://scenes/enemies/rotfen_cultist.tscn",
	"spore_brute": "res://scenes/enemies/spore_brute.tscn",
	"cinder_wolf": "res://scenes/enemies/cinder_wolf.tscn",
	"ash_raider": "res://scenes/enemies/ash_raider.tscn",
	"ash_raider_archer": "res://scenes/enemies/ash_raider_archer.tscn",
	"furnace_construct": "res://scenes/enemies/furnace_construct.tscn",
	"ash_wraith": "res://scenes/enemies/ash_wraith.tscn",
	"blackvein_miner": "res://scenes/enemies/blackvein_miner.tscn",
	"ironbound_elite": "res://scenes/enemies/ironbound_elite.tscn",
	"frostfang_wolf": "res://scenes/enemies/frostfang_wolf.tscn",
	"rimebound_raider": "res://scenes/enemies/rimebound_raider.tscn",
	"rimebound_archer": "res://scenes/enemies/rimebound_archer.tscn",
	"frozen_husk": "res://scenes/enemies/frozen_husk.tscn",
	"gravewind_wraith": "res://scenes/enemies/gravewind_wraith.tscn",
	"iceburrower": "res://scenes/enemies/iceburrower.tscn",
	"frostbound_giant": "res://scenes/enemies/frostbound_giant.tscn",
	"saltfang_hound": "res://scenes/enemies/saltfang_hound.tscn",
	"tide_reaver": "res://scenes/enemies/tide_reaver.tscn",
	"tide_reaver_archer": "res://scenes/enemies/tide_reaver_archer.tscn",
	"tide_reaver_bomber": "res://scenes/enemies/tide_reaver_bomber.tscn",
	"drowned_mariner": "res://scenes/enemies/drowned_mariner.tscn",
	"storm_wraith": "res://scenes/enemies/storm_wraith.tscn",
	"shellback_brute": "res://scenes/enemies/shellback_brute.tscn",
	"leviathan_cultist": "res://scenes/enemies/leviathan_cultist.tscn",
	"tidebound_colossus": "res://scenes/enemies/tidebound_colossus.tscn",
	"blight_hound": "res://scenes/enemies/blight_hound.tscn",
	"rootbound_raider": "res://scenes/enemies/rootbound_raider.tscn",
	"rootbound_archer": "res://scenes/enemies/rootbound_archer.tscn",
	"rootbound_bomber": "res://scenes/enemies/rootbound_bomber.tscn",
	"fungal_husk": "res://scenes/enemies/fungal_husk.tscn",
	"sporecaster": "res://scenes/enemies/sporecaster.tscn",
	"vine_stalker": "res://scenes/enemies/vine_stalker.tscn",
	"corruption_wraith": "res://scenes/enemies/corruption_wraith.tscn",
	"root_titan": "res://scenes/enemies/root_titan.tscn",
	"ashscale_hound": "res://scenes/enemies/ashscale_hound.tscn",
	"dune_raider": "res://scenes/enemies/dune_raider.tscn",
	"dune_raider_archer": "res://scenes/enemies/dune_raider_archer.tscn",
	"dune_raider_bomber": "res://scenes/enemies/dune_raider_bomber.tscn",
	"glass_husk": "res://scenes/enemies/glass_husk.tscn",
	"sand_wraith": "res://scenes/enemies/sand_wraith.tscn",
	"burrow_stalker": "res://scenes/enemies/burrow_stalker.tscn",
	"pyre_cultist": "res://scenes/enemies/pyre_cultist.tscn",
	"sunscar_behemoth": "res://scenes/enemies/sunscar_behemoth.tscn",
	"gloom_hound": "res://scenes/enemies/gloom_hound.tscn",
	"nightbound_raider": "res://scenes/enemies/nightbound_raider.tscn",
	"nightbound_raider_archer": "res://scenes/enemies/nightbound_raider_archer.tscn",
	"nightbound_raider_bomber": "res://scenes/enemies/nightbound_raider_bomber.tscn",
	"hollow_knight": "res://scenes/enemies/hollow_knight.tscn",
	"eclipse_cultist": "res://scenes/enemies/eclipse_cultist.tscn",
	"grave_wraith": "res://scenes/enemies/grave_wraith.tscn",
	"shadow_stalker": "res://scenes/enemies/shadow_stalker.tscn",
	"dominion_executioner": "res://scenes/enemies/dominion_executioner.tscn",
}

const CHEST_SCENE := "res://scenes/camps/camp_chest.tscn"
const HERB_SCENE := "res://scenes/resources/resource_herb.tscn"
const CRATE_SCENE := "res://scenes/destructibles/destructible_crate.tscn"
const WAYSTONE_SCENE := "res://scenes/interactables/waystone.tscn"
const CAMP_SCENE := "res://scenes/camps/camp_site.tscn"
const RELIQUARY_SCENE := "res://scenes/dungeons/reliquary_entrance.tscn"
const FOUNDRY_SCENE := "res://scenes/dungeons/foundry_entrance.tscn"
const PALEHEART_SCENE := "res://scenes/dungeons/paleheart_entrance.tscn"
const CITADEL_SCENE := "res://scenes/dungeons/drowned_citadel_entrance.tscn"
const CATHEDRAL_SCENE := "res://scenes/dungeons/blightspire_cathedral_entrance.tscn"
const PYREHEART_SCENE := "res://scenes/dungeons/pyreheart_ziggurat_entrance.tscn"
const ECLIPSE_SANCTUM_SCENE := "res://scenes/dungeons/eclipse_sanctum_entrance.tscn"
const DAWNWATCH_NPC_SCENE := "res://scenes/npcs/dawnwatch_npc.tscn"
const _ShallowWater := preload("res://scripts/environment/shallow_water_zone.gd")
const _PoisonZone := preload("res://scripts/environment/poison_zone.gd")
const _BoardwalkZone := preload("res://scripts/environment/boardwalk_zone.gd")
const _DeepWater := preload("res://scripts/environment/deep_water_blocker.gd")
const MERCHANT_SCENE := "res://scenes/npcs/silent_merchant.tscn"
const CINDERHOLD_NPC_SCENE := "res://scenes/npcs/cinderhold_npc.tscn"
const _QuestPoi := preload("res://scripts/interactables/quest_poi.gd")
const _HealerStation := preload("res://scripts/stations/healer_station.gd")
const _CinderholdHealer := preload("res://scripts/stations/cinderhold_healer_station.gd")
const _ResourceNode := preload("res://scripts/resources/resource_node.gd")
const _HeatZone := preload("res://scripts/environment/heat_zone.gd")
const _LavaHazard := preload("res://scripts/environment/lava_hazard.gd")
const _FallingRock := preload("res://scripts/environment/falling_rock_hazard.gd")
const _AshStorm := preload("res://scripts/environment/ash_storm_controller.gd")
const _Blizzard := preload("res://scripts/environment/blizzard_controller.gd")
const _ColdZone := preload("res://scripts/environment/cold_zone.gd")
const _DeepSnow := preload("res://scripts/environment/deep_snow_zone.gd")
const _IceZone := preload("res://scripts/environment/ice_zone.gd")
const _WarmShelter := preload("res://scripts/environment/warm_shelter_zone.gd")
const _FallingIce := preload("res://scripts/environment/falling_ice_hazard.gd")
const _CoastalStorm := preload("res://scripts/environment/coastal_storm_controller.gd")
const _WaveHazard := preload("res://scripts/environment/wave_hazard.gd")
const _WetRock := preload("res://scripts/environment/wet_rock_zone.gd")
const _CoastalShelter := preload("res://scripts/environment/coastal_shelter_zone.gd")
const _StormZone := preload("res://scripts/environment/storm_charged_zone.gd")
const _SaltZone := preload("res://scripts/environment/salt_corruption_zone.gd")
const _LightningZone := preload("res://scripts/environment/lightning_strike_zone.gd")
const _FutureBlightreachGate := preload("res://scripts/levels/future_blightreach_gate.gd")
const _FutureAstralRiftGate := preload("res://scripts/levels/future_astral_rift_gate.gd")
const _DawnwatchHealer := preload("res://scripts/stations/dawnwatch_healer_station.gd")
const _DreadZone := preload("res://scripts/environment/dread_zone.gd")
const _ShadowShelter := preload("res://scripts/environment/shadow_shelter_zone.gd")
const _ShadowPool := preload("res://scripts/environment/shadow_pool_zone.gd")
const _ShadowGround := preload("res://scripts/environment/shadow_ground_zone.gd")
const _EclipseStorm := preload("res://scripts/environment/eclipse_storm_controller.gd")
const _DesertShelter := preload("res://scripts/environment/desert_shelter_zone.gd")
const _Sandstorm := preload("res://scripts/environment/sandstorm_controller.gd")
const _GlassDune := preload("res://scripts/environment/glass_dune_zone.gd")
const _BlightZone := preload("res://scripts/environment/blight_zone.gd")
const _SporeCloud := preload("res://scripts/environment/spore_cloud_zone.gd")
const _BlightShelter := preload("res://scripts/environment/blight_shelter_zone.gd")
const _BlightSurge := preload("res://scripts/environment/blight_surge_controller.gd")
const _ToxicPool := preload("res://scripts/environment/toxic_pool_zone.gd")
const _CorruptionGrowth := preload("res://scripts/environment/corruption_growth.gd")


static func populate(level: Node3D) -> void:
	var region_id := _region_id(level)
	if region_id == "":
		return
	var enemies := _ensure_node(level, "Enemies")
	var interactables := _ensure_node(level, "Interactables")
	match region_id:
		"darkpine_forest":
			_spawn_prop(interactables, CRATE_SCENE, Vector3(-4, 0, 7))
			_spawn_prop(interactables, CRATE_SCENE, Vector3(-6, 0, 8))
			_spawn_prop(interactables, CRATE_SCENE, Vector3(-1, 0, 2))
			_spawn_destructible(interactables, "destructible_barrel", Vector3(5, 0, 6))
			_spawn_destructible(interactables, "destructible_barrel", Vector3(1, 0, 3))
			_spawn_destructible(interactables, "destructible_scrap", Vector3(-8, 0, 4))
			_spawn_destructible(interactables, "destructible_scrap", Vector3(-2, 0, 1))
			_spawn_destructible(interactables, "destructible_scrap", Vector3(0, 0, 4))
			_spawn_resource(interactables, "herb_bundle", Vector3(3, 0, 5), 2)
			_spawn_resource(interactables, "berries", Vector3(-2, 0, 9), 2)
			_spawn_resource(interactables, "stone", Vector3(8, 0, -3), 2)
			_spawn_resource(interactables, "fire_resin", Vector3(-5, 0, -4), 2, "", "darkpine_forest:fire_resin_01", true)
			_spawn_resource(interactables, "fire_resin", Vector3(-3, 0, -2), 1, "", "darkpine_forest:fire_resin_02", true)
			_spawn_resource(interactables, "crystal_shard", Vector3(-7, 0, 11), 1, "", "darkpine_forest:crystal_01", true)
			_spawn_resource(interactables, "crystal_shard", Vector3(-3, 0, 12), 1, "", "darkpine_forest:crystal_02", true)
			_spawn_resource(interactables, "crystal_shard", Vector3(-6, 0, 8), 1, "", "darkpine_forest:crystal_03", true)
			_spawn_tutorial_bandit(enemies, Vector3(6, 0.1, -3))
		"hearthhold_camp":
			_spawn_hearthhold_content(interactables)
		"rotfen_marsh":
			_spawn_rotfen_content(level, enemies, interactables)
		"ashfall_highlands":
			_spawn_ashfall_content(level, enemies, interactables)
		"frostgrave_expanse":
			_spawn_frostgrave_content(level, enemies, interactables)
		"shattered_coast":
			_spawn_shattered_coast_content(level, enemies, interactables)
		"blightreach":
			_spawn_blightreach_content(level, enemies, interactables)
		"ember_wastes":
			_spawn_ember_wastes_content(level, enemies, interactables)
		"sunless_dominion":
			_spawn_sunless_dominion_content(level, enemies, interactables)
		"ruined_watchtower":
			_spawn_enemy(enemies, "forest_bandit", Vector3(8, 0.1, -8))
			_spawn_enemy(enemies, "forest_bandit", Vector3(-7, 0.1, -10))
			_spawn_enemy(enemies, "bandit_archer", Vector3(10, 0.1, 4))
			_spawn_prop(interactables, CRATE_SCENE, Vector3(-3, 0, -6))
			_spawn_prop(interactables, HERB_SCENE, Vector3(4, 0, -4))
			_spawn_prop(interactables, CRATE_SCENE, Vector3(4, 0, -1))
			_spawn_prop(interactables, HERB_SCENE, Vector3(-3, 0, 3))
		"bandit_camp":
			_spawn_enemy(enemies, "shield_bandit", Vector3(10, 0.1, -8))
			_spawn_enemy(enemies, "forest_bandit", Vector3(-8, 0.1, -6))
			_spawn_enemy(enemies, "bandit_archer", Vector3(6, 0.1, 6))
			_spawn_enemy(enemies, "bandit_captain", Vector3(-10, 0.1, -12))
			_spawn_prop(interactables, CHEST_SCENE, Vector3(3, 0, -5))
			_spawn_prop(interactables, CRATE_SCENE, Vector3(-2, 0, -3))
			_spawn_prop(interactables, CHEST_SCENE, Vector3(9, 0, 4))
			_spawn_prop(interactables, CRATE_SCENE, Vector3(8, 0, 5))
		"crystal_cave":
			_spawn_enemy(enemies, "bandit_archer", Vector3(6, 0.1, -4))
			_spawn_enemy(enemies, "shield_bandit", Vector3(-5, 0.1, 6))
			_spawn_enemy(enemies, "forest_bandit", Vector3(0, 0.1, -10))
			_spawn_prop(interactables, CRATE_SCENE, Vector3(4, 0, 2))
			_spawn_prop(interactables, CRATE_SCENE, Vector3(-4, 0, 1))
			_spawn_resource(interactables, "crystal_shard", Vector3(2, 0, -2), 2, "", "crystal_cave:shard_01", true)
			_spawn_resource(interactables, "crystal_shard", Vector3(-2, 0, -4), 2, "", "crystal_cave:shard_02", true)
			_spawn_destructible(interactables, "destructible_crystal", Vector3(0, 0, 3))
		"hollow_grove_shrine":
			if not _has_enemy_id(enemies, "hollow_grove_warden"):
				_spawn_enemy(enemies, "hollow_warden", Vector3(0, 0.1, -16))
			_spawn_enemy(enemies, "forest_bandit", Vector3(12, 0.1, -8))
			_spawn_enemy(enemies, "shield_bandit", Vector3(-11, 0.1, -6))
			_spawn_prop(interactables, HERB_SCENE, Vector3(-6, 0, 4))
			_spawn_prop(interactables, HERB_SCENE, Vector3(7, 0, 3))
	register_map_pois(region_id)


static func register_map_pois(region_id: String) -> void:
	match region_id:
		"hearthhold_camp":
			MapManager.discover_location("hearthhold_merchant", "General Merchant", Vector3(10.5, 0, 2), "merchant", region_id)
			MapManager.discover_location("hearthhold_armorer", "Arms Dealer", Vector3(10.5, 0, -2), "merchant", region_id)
			MapManager.discover_location("hearthhold_blacksmith", "Blacksmith", Vector3(8, 0, -2), "blacksmith", region_id)
			MapManager.discover_location("hearthhold_crafting", "Crafting Workshop", Vector3(-8, 0, -2), "crafting", region_id)
			MapManager.discover_location("hearthhold_storage", "Storage", Vector3(-6, 0, 7), "storage", region_id)
			MapManager.discover_location("hearthhold_healer", "Infirmary", Vector3(-4, 0, -8), "healer", region_id)
			MapManager.discover_location("hearthhold_inn", "Inn Rest", Vector3(5.5, 0, 10.5), "rest", region_id)
			MapManager.discover_location("hearthhold_waystone", "Waystone Plaza", Vector3(-2, 0, 5), "waystone", region_id, true)
			MapManager.discover_location("hearthhold_quest_hall", "Quest Hall", Vector3(-6, 0, -8), "quest", region_id)
			MapManager.discover_location("hearthhold_darkpine_gate", "Darkpine Gate", Vector3(0, 0, -14), "gate", region_id)
			MapManager.discover_location("hearthhold_rotfen_gate", "Rotfen Gate", Vector3(0, 0, 14.5), "gate", region_id)
		"rotfen_marsh":
			MapManager.discover_location("marshwatch_camp", "Marshwatch Camp", Vector3(-8, 0, 4), "camp", region_id)
			MapManager.discover_location("rotfen_waystone", "Rotfen Waystone", Vector3(-6, 0, 6), "waystone", region_id, true)
			MapManager.discover_location("sunken_reliquary", "Sunken Reliquary", Vector3(0, 0, 28), "dungeon", region_id)
			MapManager.discover_location("rotfen_caravan_site", "Abandoned Caravan", Vector3(10, 0, 2), "quest", region_id)
			MapManager.discover_location("rotfen_shrine_zone", "Corrupted Shrine", Vector3(0, 0, 18), "quest", region_id)
			MapManager.discover_location("ashfall_route", "Ashfall Route", Vector3(14, 0, 22), "gate", region_id)
			MapManager.mark_region_dangerous(region_id)
		"ashfall_highlands":
			MapManager.discover_location("stonewatch_outpost", "Stonewatch Outpost", Vector3(0, 0, 0), "camp", region_id)
			MapManager.discover_location("ashfall_waystone", "Ashfall Waystone", Vector3(2, 0, 4), "waystone", region_id, true)
			MapManager.discover_location("blackvein_foundry", "Blackvein Foundry", Vector3(22, 0, 18), "dungeon", region_id)
			MapManager.discover_location("collapsed_rail", "Collapsed Rail Line", Vector3(8, 0, -12), "quest", region_id)
			MapManager.discover_location("ember_quarry", "Ember Quarry", Vector3(14, 0, 6), "resource", region_id)
			MapManager.discover_location("frostgrave_pass", "Frostgrave Pass", Vector3(30, 0, 0), "gate", region_id)
			MapManager.discover_location("ashfall_rotfen_gate", "Rotfen Pass", Vector3(-20, 0, -4), "gate", region_id)
			MapManager.mark_region_dangerous(region_id)
		"frostgrave_expanse":
			MapManager.discover_location("frostwatch_bastion", "Frostwatch Bastion", Vector3(0, 0, 0), "camp", region_id)
			MapManager.discover_location("frostgrave_waystone", "Frostgrave Waystone", Vector3(2, 0, 4), "waystone", region_id, true)
			MapManager.discover_location("paleheart_crypt", "Paleheart Crypt", Vector3(22, 0, 18), "dungeon", region_id)
			MapManager.discover_location("buried_village", "Buried Village", Vector3(10, 0, -10), "quest", region_id)
			MapManager.discover_location("shattered_glacier", "Shattered Glacier", Vector3(16, 0, 10), "resource", region_id)
			MapManager.discover_location("shattered_coast_gate", "Shattered Coast Gate", Vector3(30, 0, 0), "gate", region_id)
			MapManager.discover_location("ashfall_pass", "Ashfall Pass", Vector3(-18, 0, 0), "gate", region_id)
			MapManager.mark_region_dangerous(region_id)
		"shattered_coast":
			MapManager.discover_location("tidewatch_refuge", "Tidewatch Refuge", Vector3(0, 0, 0), "camp", region_id)
			MapManager.discover_location("shattered_coast_waystone", "Shattered Coast Waystone", Vector3(2, 0, 4), "waystone", region_id, true)
			MapManager.discover_location("drowned_citadel", "Drowned Citadel", Vector3(22, 0, 18), "dungeon", region_id)
			MapManager.discover_location("wreckshore", "Wreckshore", Vector3(-12, 0, -10), "quest", region_id)
			MapManager.discover_location("broken_harbor", "Broken Harbor", Vector3(12, 0, -8), "quest", region_id)
			MapManager.discover_location("drowned_village", "Drowned Village", Vector3(10, 0, 10), "quest", region_id)
			MapManager.discover_location("frostgrave_coast_gate", "Frostgrave Pass", Vector3(-20, 0, -4), "gate", region_id)
			MapManager.discover_location("blightreach_gate", "Blightreach Gate", Vector3(30, 0, 0), "gate", region_id)
			MapManager.mark_region_dangerous(region_id)
		"blightreach":
			MapManager.discover_location("blightreach_waystone", "Blightreach Waystone", Vector3(2, 0, 4), "waystone", region_id, true)
			MapManager.discover_location("blightspire_cathedral", "Blightspire Cathedral", Vector3(22, 0, 18), "dungeon", region_id)
			MapManager.mark_region_dangerous(region_id)
		"sunless_dominion":
			MapManager.discover_location("dawnwatch_camp", "Dawnwatch Camp", Vector3(0, 0, 2), "camp", region_id)
			MapManager.discover_location("sunless_dominion_waystone", "Sunless Dominion Waystone", Vector3(2, 0, 4), "waystone", region_id, true)
			MapManager.discover_location("eclipse_sanctum", "Eclipse Sanctum", Vector3(22, 0, 18), "dungeon", region_id)
			MapManager.discover_location("forsaken_hamlet", "Forsaken Hamlet", Vector3(-12, 0, -10), "quest", region_id)
			MapManager.discover_location("royal_graves", "Royal Graves", Vector3(14, 0, 6), "quest", region_id)
			MapManager.discover_location("dark_observatory", "Dark Observatory", Vector3(18, 0, 14), "quest", region_id)
			MapManager.discover_location("ember_wastes_dominion_gate", "Ember Wastes Gate", Vector3(-20, 0, -4), "gate", region_id)
			MapManager.discover_location("astral_rift_gate", "Astral Rift Gate", Vector3(30, 0, 0), "gate", region_id)
			MapManager.mark_region_dangerous(region_id)
		"ember_wastes":
			MapManager.discover_location("cinderhold_camp", "Cinderhold Outpost", Vector3(0, 0, 2), "camp", region_id)
			MapManager.discover_location("ember_wastes_waystone", "Ember Wastes Waystone", Vector3(2, 0, 4), "waystone", region_id, true)
			MapManager.discover_location("pyreheart_ziggurat", "Pyreheart Ziggurat", Vector3(22, 0, 18), "dungeon", region_id)
			MapManager.discover_location("glass_dune_site", "Glass Dune", Vector3(14, 0, 6), "quest", region_id)
			MapManager.discover_location("burning_obelisks", "Burning Obelisks", Vector3(-12, 0, -10), "quest", region_id)
			MapManager.discover_location("dry_road_trail", "The Dry Road", Vector3(8, 0, -12), "quest", region_id)
			MapManager.discover_location("blightreach_ember_gate", "Blightreach Gate", Vector3(-20, 0, -4), "gate", region_id)
			MapManager.discover_location("sunless_dominion_gate", "Sunless Dominion Gate", Vector3(30, 0, 0), "gate", region_id)
			MapManager.mark_region_dangerous(region_id)


static func _spawn_hearthhold_content(interactables: Node3D) -> void:
	_spawn_prop(interactables, CHEST_SCENE, Vector3(12, 0, 4))
	_spawn_prop(interactables, CRATE_SCENE, Vector3(12, 0, -2))
	_spawn_prop(interactables, CRATE_SCENE, Vector3(-7, 0, 8))
	var caravan := _QuestPoi.new()
	caravan.name = "DamagedCaravan"
	caravan.poi_id = "hearthhold_caravan"
	caravan.quest_id = "the_rot_below"
	caravan.objective_id = "inspect_caravan"
	caravan.speaker = "Damaged Caravan"
	caravan.inspect_text = "Wagon wheels sunk in mud. Claw marks score the wood — something came from the marsh."
	caravan.prompt_override = "Inspect caravan"
	caravan.position = Vector3(0, 0.1, -16)
	interactables.add_child(caravan)
	if interactables.get_node_or_null("Infirmary") == null:
		var healer := _HealerStation.new()
		healer.name = "Infirmary"
		healer.position = Vector3(-4, 0.1, -8)
		interactables.add_child(healer)


static func _spawn_rotfen_content(level: Node3D, enemies: Node3D, interactables: Node3D) -> void:
	_spawn_enemy(enemies, "bog_stalker", Vector3(4, 0.1, -8))
	_spawn_enemy(enemies, "mire_hound", Vector3(6, 0.1, -4))
	_spawn_enemy(enemies, "mire_hound", Vector3(8, 0.1, 0))
	_spawn_enemy(enemies, "drowned_husk", Vector3(2, 0.1, 12))
	_spawn_enemy(enemies, "rotfen_cultist", Vector3(-4, 0.1, 18))
	_spawn_enemy(enemies, "rotfen_cultist", Vector3(4, 0.1, 20))
	_spawn_enemy(enemies, "spore_brute", Vector3(10, 0.1, 16))
	if interactables.get_node_or_null("MarshwatchCamp") == null:
		var camp := _spawn_prop_node(CAMP_SCENE, Vector3(-8, 0, 4))
		if camp:
			camp.name = "MarshwatchCamp"
			interactables.add_child(camp)
	if interactables.get_node_or_null("RotfenWaystone") == null:
		var ws := _spawn_prop_node(WAYSTONE_SCENE, Vector3(-6, 0, 6))
		if ws:
			ws.name = "RotfenWaystone"
			ws.set("waystone_id", "rotfen_marsh")
			interactables.add_child(ws)
	if interactables.get_node_or_null("MarshScoutVendor") == null and ResourceLoader.exists(MERCHANT_SCENE):
		var vendor := _spawn_prop_node(MERCHANT_SCENE, Vector3(-9, 0.1, 3))
		if vendor:
			vendor.name = "MarshScoutVendor"
			vendor.set("npc_id", "marsh_scout_vendor")
			vendor.set("display_name", "Marsh Scout")
			vendor.set("is_merchant", true)
			interactables.add_child(vendor)
	_spawn_prop(interactables, CHEST_SCENE, Vector3(-10, 0, 5))
	_spawn_resource(interactables, "bog_herb", Vector3(5, 0, -6), 2)
	_spawn_resource(interactables, "bog_herb", Vector3(-3, 0, 8), 2)
	_spawn_resource(interactables, "poison_gland", Vector3(7, 0, 8), 1)
	_spawn_resource(interactables, "rotwood", Vector3(-2, 0, 10), 2)
	_spawn_resource(interactables, "mire_crystal", Vector3(12, 0, 14), 1, "", "rotfen_marsh:mire_crystal_01", true)
	_spawn_resource(interactables, "swamp_iron", Vector3(3, 0, 14), 1)
	var caravan := _QuestPoi.new()
	caravan.name = "AbandonedCaravan"
	caravan.poi_id = "rotfen_caravan"
	caravan.quest_id = "the_missing_caravan"
	caravan.objective_id = "reach_caravan"
	caravan.speaker = "Abandoned Caravan"
	caravan.inspect_text = "A ledger lies half-buried in the mud."
	caravan.prompt_override = "Search caravan"
	caravan.position = Vector3(10, 0.1, 2)
	interactables.add_child(caravan)
	var ledger := _QuestPoi.new()
	ledger.name = "CaravanLedger"
	ledger.poi_id = "caravan_ledger"
	ledger.quest_id = "the_missing_caravan"
	ledger.objective_id = "recover_ledger"
	ledger.speaker = "Ledger"
	ledger.inspect_text = "You recover the caravan ledger."
	ledger.prompt_override = "Take ledger"
	ledger.position = Vector3(10.5, 0.1, 2.2)
	interactables.add_child(ledger)
	for i in 3:
		var shrine := _QuestPoi.new()
		shrine.name = "RuinedShrine%d" % (i + 1)
		shrine.poi_id = "rotfen_shrine_%d" % (i + 1)
		shrine.quest_id = "the_sunken_bells"
		shrine.objective_id = "inspect_shrine"
		shrine.speaker = "Ruined Shrine"
		shrine.inspect_text = "A cracked bell hangs over stagnant water."
		shrine.prompt_override = "Investigate shrine"
		shrine.position = Vector3(-6 + i * 6, 0.1, 16 + i * 2)
		interactables.add_child(shrine)
	for i in 4:
		var growth := _QuestPoi.new()
		growth.name = "CorruptionGrowth%d" % (i + 1)
		growth.poi_id = "corruption_%d" % (i + 1)
		growth.quest_id = "destroy_corruption"
		growth.objective_id = "burn_growths"
		growth.speaker = "Corrupted Growth"
		growth.inspect_text = "You burn away the pulsing corruption."
		growth.prompt_override = "Destroy growth"
		growth.position = Vector3(-4 + i * 3, 0.1, 10 + i)
		interactables.add_child(growth)
	var scout := _QuestPoi.new()
	scout.name = "TrappedScout"
	scout.poi_id = "trapped_scout"
	scout.quest_id = "rescue_trapped_scout"
	scout.objective_id = "free_scout"
	scout.speaker = "Trapped Scout"
	scout.inspect_text = "You cut the scout free from the roots."
	scout.prompt_override = "Free scout"
	scout.position = Vector3(-12, 0.1, 10)
	interactables.add_child(scout)
	if interactables.get_node_or_null("ReliquaryEntrance") == null:
		var rel := _spawn_prop_node(RELIQUARY_SCENE, Vector3(0, 0, 28))
		if rel:
			rel.name = "ReliquaryEntrance"
			interactables.add_child(rel)
	_spawn_rotfen_environment(level)


static func _spawn_rotfen_environment(level: Node3D) -> void:
	var env := level.get_node_or_null("Environment") as Node3D
	if env == null:
		env = level
	var zones := Node3D.new()
	zones.name = "EnvironmentZones"
	env.add_child(zones)
	for z in range(-16, 26, 4):
		for x in [-6, 6, -10, 10]:
			if absf(x) <= 2 and z > -16:
				continue
			_add_shallow_pool(zones, Vector3(float(x), 0.05, float(z)), Vector3(5.5, 1.0, 3.5))
	for z in [12, 16, 20]:
		_add_poison_pool(zones, Vector3(-7, 0.05, float(z)), Vector3(4.0, 1.0, 3.0))
		_add_poison_pool(zones, Vector3(7, 0.05, float(z)), Vector3(4.0, 1.0, 3.0))
	_add_boardwalk_strip(zones, Vector3(0, 0.2, -18), Vector3(2.5, 1.0, 44))
	_add_boardwalk_strip(zones, Vector3(-8, 0.2, 0), Vector3(2.0, 1.0, 8))
	for pos in [Vector3(-14, -0.2, 8), Vector3(14, -0.2, 10), Vector3(-12, -0.2, 22)]:
		_add_deep_water(zones, pos, Vector3(6.0, 1.2, 5.0))


static func _add_shallow_pool(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var area := _ShallowWater.new()
	area.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	area.add_child(col)
	parent.add_child(area)


static func _add_poison_pool(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var area := _PoisonZone.new()
	area.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	area.add_child(col)
	parent.add_child(area)


static func _add_boardwalk_strip(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var area := _BoardwalkZone.new()
	area.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	area.add_child(col)
	parent.add_child(area)


static func _add_deep_water(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var body := _DeepWater.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)


static func _spawn_ashfall_content(level: Node3D, enemies: Node3D, interactables: Node3D) -> void:
	# Cinder Wolf Den (Burned Woodland)
	_spawn_enemy(enemies, "cinder_wolf", Vector3(-14, 0.1, -10))
	_spawn_enemy(enemies, "cinder_wolf", Vector3(-11, 0.1, -14))
	_spawn_enemy(enemies, "cinder_wolf", Vector3(-16, 0.1, -8))
	# Ash Raider camp (Collapsed Rail)
	_spawn_enemy(enemies, "ash_raider", Vector3(9, 0.1, -11))
	_spawn_enemy(enemies, "ash_raider", Vector3(11, 0.1, -14))
	_spawn_enemy(enemies, "ash_raider_archer", Vector3(7, 0.1, -13))
	# Furnace Construct site (Ember Quarry)
	_spawn_enemy(enemies, "furnace_construct", Vector3(14, 0.1, 6))
	_spawn_enemy(enemies, "blackvein_miner", Vector3(12, 0.1, 8))
	# Ash Wraith ruin
	_spawn_enemy(enemies, "ash_wraith", Vector3(-6, 0.1, 14))
	# Foundry approach
	_spawn_enemy(enemies, "ironbound_elite", Vector3(18, 0.1, 14))
	_spawn_enemy(enemies, "blackvein_miner", Vector3(20, 0.1, 16))
	_spawn_enemy(enemies, "ash_raider", Vector3(16, 0.1, 10))
	if interactables.get_node_or_null("StonewatchCamp") == null:
		var camp := _spawn_prop_node(CAMP_SCENE, Vector3(0, 0, 2))
		if camp:
			camp.name = "StonewatchCamp"
			camp.set("town_inn_mode", true)
			camp.set("checkpoint_marker_id", "checkpoint_ashfall")
			interactables.add_child(camp)
	if interactables.get_node_or_null("AshfallWaystone") == null:
		var ws := _spawn_prop_node(WAYSTONE_SCENE, Vector3(2, 0, 4))
		if ws:
			ws.name = "AshfallWaystone"
			ws.set("waystone_id", "ashfall_highlands")
			interactables.add_child(ws)
	if interactables.get_node_or_null("StonewatchMerchant") == null and ResourceLoader.exists(MERCHANT_SCENE):
		var vendor := _spawn_prop_node(MERCHANT_SCENE, Vector3(-3, 0.1, -1))
		if vendor:
			vendor.name = "StonewatchMerchant"
			vendor.set("npc_id", "stonewatch_merchant")
			vendor.set("display_name", "Merrin Slate")
			vendor.set("is_merchant", true)
			interactables.add_child(vendor)
	if interactables.get_node_or_null("StonewatchForge") == null and ResourceLoader.exists(MERCHANT_SCENE):
		var forge := _spawn_prop_node(MERCHANT_SCENE, Vector3(3, 0.1, -1))
		if forge:
			forge.name = "StonewatchForge"
			forge.set("npc_id", "stonewatch_forge")
			forge.set("display_name", "Hesta Coalhand")
			forge.set("is_merchant", true)
			interactables.add_child(forge)
	var commander := _QuestPoi.new()
	commander.name = "StonewatchCommander"
	commander.poi_id = "stonewatch_commander"
	commander.quest_id = "through_the_ash"
	commander.objective_id = "speak_commander"
	commander.speaker = "Commander Kael Rourke"
	commander.inspect_text = "Commander Rourke studies a soot-stained map. Blackvein must be stopped."
	commander.prompt_override = "Speak with Commander Rourke"
	commander.position = Vector3(0, 0.1, -4)
	interactables.add_child(commander)
	var injured := _QuestPoi.new()
	injured.name = "InjuredMinerJoren"
	injured.poi_id = "injured_miner_joren"
	injured.quest_id = "rescue_trapped_miners"
	injured.objective_id = "rescue_miners"
	injured.speaker = "Joren Vale"
	injured.inspect_text = "Joren Vale coughs through ash. He warns of molten channels below."
	injured.prompt_override = "Speak with Joren Vale"
	injured.position = Vector3(-5, 0.1, 1)
	interactables.add_child(injured)
	var rail := _QuestPoi.new()
	rail.name = "CollapsedRail"
	rail.poi_id = "collapsed_rail"
	rail.quest_id = "the_broken_rail"
	rail.objective_id = "investigate_rail"
	rail.speaker = "Collapsed Rail"
	rail.inspect_text = "Twisted rails vanish into a rockslide. Raiders lurk nearby."
	rail.prompt_override = "Investigate rail"
	rail.position = Vector3(8, 0.1, -12)
	interactables.add_child(rail)
	var manifest := _QuestPoi.new()
	manifest.name = "MiningManifest"
	manifest.poi_id = "mining_manifest"
	manifest.quest_id = "the_broken_rail"
	manifest.objective_id = "recover_manifests"
	manifest.speaker = "Manifest Crate"
	manifest.inspect_text = "You recover waterlogged mining manifests."
	manifest.prompt_override = "Recover manifests"
	manifest.position = Vector3(9, 0.1, -11)
	interactables.add_child(manifest)
	var route_clear := _QuestPoi.new()
	route_clear.name = "RailRouteClear"
	route_clear.poi_id = "rail_route_clear"
	route_clear.quest_id = "the_broken_rail"
	route_clear.objective_id = "clear_route"
	route_clear.speaker = "Cleared Track"
	route_clear.inspect_text = "You clear enough debris to reopen the rail route."
	route_clear.prompt_override = "Clear the route"
	route_clear.position = Vector3(10, 0.1, -10)
	interactables.add_child(route_clear)
	var blackvein := _QuestPoi.new()
	blackvein.name = "BlackveinSurvey"
	blackvein.poi_id = "blackvein_survey"
	blackvein.quest_id = "fires_below"
	blackvein.objective_id = "investigate_blackvein"
	blackvein.speaker = "Foundry Survey"
	blackvein.inspect_text = "Molten runoff marks a path toward the foundry."
	blackvein.prompt_override = "Survey foundry approach"
	blackvein.position = Vector3(16, 0.1, 8)
	interactables.add_child(blackvein)
	var wolf_den := _QuestPoi.new()
	wolf_den.name = "CinderWolfDen"
	wolf_den.poi_id = "cinder_wolf_den"
	wolf_den.quest_id = "clear_wolf_dens"
	wolf_den.objective_id = "clear_den"
	wolf_den.speaker = "Wolf Den"
	wolf_den.inspect_text = "You destroy the cinder wolf den."
	wolf_den.prompt_override = "Destroy den"
	wolf_den.position = Vector3(-13, 0.1, -12)
	interactables.add_child(wolf_den)
	var wolf_den2 := _QuestPoi.new()
	wolf_den2.name = "CinderWolfDen2"
	wolf_den2.poi_id = "cinder_wolf_den_2"
	wolf_den2.quest_id = "clear_wolf_dens"
	wolf_den2.objective_id = "clear_den"
	wolf_den2.speaker = "Wolf Den"
	wolf_den2.inspect_text = "You collapse a second cinder wolf den."
	wolf_den2.prompt_override = "Destroy den"
	wolf_den2.position = Vector3(-15, 0.1, -8)
	interactables.add_child(wolf_den2)
	var machine_parts := _QuestPoi.new()
	machine_parts.name = "LostMachineParts"
	machine_parts.poi_id = "lost_machine_parts"
	machine_parts.quest_id = "recover_machine_parts"
	machine_parts.objective_id = "recover_parts"
	machine_parts.speaker = "Machine Scrap"
	machine_parts.inspect_text = "Salvaged machine parts from the quarry wreckage."
	machine_parts.prompt_override = "Recover parts"
	machine_parts.position = Vector3(11, 0.1, 5)
	interactables.add_child(machine_parts)
	var machine_parts2 := _QuestPoi.new()
	machine_parts2.name = "LostMachineParts2"
	machine_parts2.poi_id = "lost_machine_parts_2"
	machine_parts2.quest_id = "recover_machine_parts"
	machine_parts2.objective_id = "recover_parts"
	machine_parts2.speaker = "Machine Scrap"
	machine_parts2.inspect_text = "More machine parts salvaged from the rail wreck."
	machine_parts2.prompt_override = "Recover parts"
	machine_parts2.position = Vector3(9, 0.1, -9)
	interactables.add_child(machine_parts2)
	var machine_parts3 := _QuestPoi.new()
	machine_parts3.name = "LostMachineParts3"
	machine_parts3.poi_id = "lost_machine_parts_3"
	machine_parts3.quest_id = "recover_machine_parts"
	machine_parts3.objective_id = "recover_parts"
	machine_parts3.speaker = "Machine Scrap"
	machine_parts3.inspect_text = "A crate of gears and pistons from the quarry."
	machine_parts3.prompt_override = "Recover parts"
	machine_parts3.position = Vector3(15, 0.1, 7)
	interactables.add_child(machine_parts3)
	var heat_vent := _QuestPoi.new()
	heat_vent.name = "UnstableHeatVent"
	heat_vent.poi_id = "unstable_heat_vent"
	heat_vent.quest_id = "shut_down_vents"
	heat_vent.objective_id = "shut_vent"
	heat_vent.speaker = "Heat Vent"
	heat_vent.inspect_text = "You shut down the unstable heat vent."
	heat_vent.prompt_override = "Shut down vent"
	heat_vent.position = Vector3(5, 0.1, 10)
	interactables.add_child(heat_vent)
	var heat_vent2 := _QuestPoi.new()
	heat_vent2.name = "UnstableHeatVent2"
	heat_vent2.poi_id = "unstable_heat_vent_2"
	heat_vent2.quest_id = "shut_down_vents"
	heat_vent2.objective_id = "shut_vent"
	heat_vent2.speaker = "Heat Vent"
	heat_vent2.inspect_text = "You seal the second unstable heat vent."
	heat_vent2.prompt_override = "Shut down vent"
	heat_vent2.position = Vector3(13, 0.1, 9)
	interactables.add_child(heat_vent2)
	if interactables.get_node_or_null("FoundryEntrance") == null and ResourceLoader.exists(FOUNDRY_SCENE):
		var rel := _spawn_prop_node(FOUNDRY_SCENE, Vector3(22, 0, 18))
		if rel:
			rel.name = "FoundryEntrance"
			interactables.add_child(rel)
	_spawn_resource(interactables, "cinder_ore", Vector3(10, 0, 4), 2, "pickaxe")
	_spawn_resource(interactables, "cinder_ore", Vector3(12, 0, 6), 2, "pickaxe")
	_spawn_resource(interactables, "ashwood", Vector3(-10, 0, 6), 2)
	_spawn_resource(interactables, "blackvein_iron", Vector3(18, 0, 12), 1)
	_spawn_resource(interactables, "machine_scrap", Vector3(7, 0, -8), 1)
	_spawn_resource(interactables, "ember_crystal", Vector3(13, 0, 7), 1, "", "ashfall_highlands:ember_crystal_01", true)
	_spawn_resource(interactables, "volcanic_glass", Vector3(6, 0, 12), 1)
	if level.get_node_or_null("AshStormController") == null:
		var storm := _AshStorm.new()
		storm.name = "AshStormController"
		level.add_child(storm)
	_spawn_ashfall_environment(level)


static func _spawn_ashfall_environment(level: Node3D) -> void:
	var env := level.get_node_or_null("Environment") as Node3D
	if env == null:
		env = level
	var zones := env.get_node_or_null("AshfallEnvironmentZones") as Node3D
	if zones == null:
		zones = Node3D.new()
		zones.name = "AshfallEnvironmentZones"
		env.add_child(zones)
	var shelter := Area3D.new()
	shelter.name = "StonewatchShelter"
	shelter.position = Vector3(0, 1, 0)
	shelter.add_to_group("storm_shelter")
	var scol := CollisionShape3D.new()
	var sshape := BoxShape3D.new()
	sshape.size = Vector3(16, 4, 16)
	scol.shape = sshape
	shelter.add_child(scol)
	zones.add_child(shelter)
	for pos in [Vector3(12, 0.05, 4), Vector3(8, 0.05, 8), Vector3(15, 0.05, 12)]:
		var heat := _HeatZone.new()
		heat.position = pos
		var hcol := CollisionShape3D.new()
		var hshape := BoxShape3D.new()
		hshape.size = Vector3(5, 2, 5)
		hcol.shape = hshape
		heat.add_child(hcol)
		zones.add_child(heat)
	for pos in [Vector3(11, 0, 9), Vector3(14, 0, 11)]:
		var lava := _LavaHazard.new()
		lava.position = pos
		zones.add_child(lava)
	for pos in [Vector3(8, 0, -13), Vector3(17, 0, 13), Vector3(-12, 0, -11)]:
		var rock := _FallingRock.new()
		rock.position = pos
		zones.add_child(rock)


static func _spawn_frostgrave_content(level: Node3D, enemies: Node3D, interactables: Node3D) -> void:
	_spawn_enemy(enemies, "frostfang_wolf", Vector3(-14, 0.1, -10))
	_spawn_enemy(enemies, "frostfang_wolf", Vector3(-11, 0.1, -14))
	_spawn_enemy(enemies, "frostfang_wolf", Vector3(-16, 0.1, -8))
	_spawn_enemy(enemies, "rimebound_raider", Vector3(9, 0.1, -11))
	_spawn_enemy(enemies, "rimebound_raider", Vector3(11, 0.1, -14))
	_spawn_enemy(enemies, "rimebound_archer", Vector3(7, 0.1, -13))
	_spawn_enemy(enemies, "frozen_husk", Vector3(14, 0.1, 6))
	_spawn_enemy(enemies, "gravewind_wraith", Vector3(-6, 0.1, 14))
	_spawn_enemy(enemies, "iceburrower", Vector3(12, 0.1, 8))
	_spawn_enemy(enemies, "frostbound_giant", Vector3(18, 0.1, 14))
	_spawn_enemy(enemies, "rimebound_raider", Vector3(16, 0.1, 10))
	if interactables.get_node_or_null("FrostwatchCamp") == null:
		var camp := _spawn_prop_node(CAMP_SCENE, Vector3(0, 0, 2))
		if camp:
			camp.name = "FrostwatchCamp"
			camp.set("town_inn_mode", true)
			camp.set("checkpoint_marker_id", "checkpoint_frostgrave")
			interactables.add_child(camp)
	if interactables.get_node_or_null("FrostgraveWaystone") == null:
		var ws := _spawn_prop_node(WAYSTONE_SCENE, Vector3(2, 0, 4))
		if ws:
			ws.name = "FrostgraveWaystone"
			ws.set("waystone_id", "frostgrave_expanse")
			interactables.add_child(ws)
	if interactables.get_node_or_null("FrostwatchMerchant") == null and ResourceLoader.exists(MERCHANT_SCENE):
		var vendor := _spawn_prop_node(MERCHANT_SCENE, Vector3(-3, 0.1, -1))
		if vendor:
			vendor.name = "FrostwatchMerchant"
			vendor.set("npc_id", "frostwatch_merchant")
			vendor.set("display_name", "Elen Marr")
			vendor.set("is_merchant", true)
			interactables.add_child(vendor)
	if interactables.get_node_or_null("FrostwatchForge") == null and ResourceLoader.exists(MERCHANT_SCENE):
		var forge := _spawn_prop_node(MERCHANT_SCENE, Vector3(3, 0.1, -1))
		if forge:
			forge.name = "FrostwatchForge"
			forge.set("npc_id", "frostwatch_forge")
			forge.set("display_name", "Orik Frosthand")
			forge.set("is_merchant", true)
			interactables.add_child(forge)
	if interactables.get_node_or_null("FrostwatchHealer") == null:
		var healer := _HealerStation.new()
		healer.name = "FrostwatchHealer"
		healer.position = Vector3(-5, 0.1, 1)
		interactables.add_child(healer)
	var commander := _QuestPoi.new()
	commander.name = "FrostwatchCommander"
	commander.poi_id = "frostwatch_commander"
	commander.quest_id = "into_the_white"
	commander.objective_id = "speak_commander"
	commander.speaker = "Commander Ysra Vale"
	commander.inspect_text = "Commander Vale watches the white horizon. Paleheart must be stopped."
	commander.prompt_override = "Speak with Commander Ysra Vale"
	commander.position = Vector3(0, 0.1, -4)
	interactables.add_child(commander)
	var hunter := _QuestPoi.new()
	hunter.name = "HunterRell"
	hunter.poi_id = "hunter_rell"
	hunter.quest_id = "rescue_lost_hunter"
	hunter.objective_id = "rescue_hunter"
	hunter.speaker = "Hunter Rell"
	hunter.inspect_text = "Rell tracks frost beasts through the tundra."
	hunter.prompt_override = "Speak with Hunter Rell"
	hunter.position = Vector3(5, 0.1, 1)
	interactables.add_child(hunter)
	var village := _QuestPoi.new()
	village.name = "BuriedVillage"
	village.poi_id = "buried_village"
	village.quest_id = "the_buried_village"
	village.objective_id = "investigate_village"
	village.speaker = "Buried Village"
	village.inspect_text = "Snow-buried homes and raider tracks mark the lost settlement."
	village.prompt_override = "Investigate village"
	village.position = Vector3(10, 0.1, -10)
	interactables.add_child(village)
	var records := _QuestPoi.new()
	records.name = "SurvivorRecords"
	records.poi_id = "survivor_records"
	records.quest_id = "the_buried_village"
	records.objective_id = "recover_records"
	records.speaker = "Frozen Records"
	records.inspect_text = "You recover waterlogged survivor records."
	records.prompt_override = "Recover records"
	records.position = Vector3(10.5, 0.1, -9)
	interactables.add_child(records)
	var survivor := _QuestPoi.new()
	survivor.name = "BuriedSurvivor"
	survivor.poi_id = "buried_survivor"
	survivor.quest_id = "the_buried_village"
	survivor.objective_id = "rescue_survivors"
	survivor.speaker = "Frozen Survivor"
	survivor.inspect_text = "You pull a frostbitten survivor from the rubble and guide them toward Frostwatch."
	survivor.prompt_override = "Rescue survivor"
	survivor.position = Vector3(9.5, 0.1, -11)
	interactables.add_child(survivor)
	for i in 3:
		var grave := _QuestPoi.new()
		grave.name = "GraveSite%d" % (i + 1)
		grave.poi_id = "grave_site_%d" % (i + 1)
		grave.quest_id = "gravewind_rising"
		grave.objective_id = "investigate_graves"
		grave.speaker = "Grave Site"
		grave.inspect_text = "Frost-crusted grave markers hum with gravewind."
		grave.prompt_override = "Investigate grave"
		grave.position = Vector3(-8 + i * 4, 0.1, 12 + i)
		interactables.add_child(grave)
	for i in 3:
		var cache := _QuestPoi.new()
		cache.name = "SupplyCache%d" % (i + 1)
		cache.poi_id = "supply_cache_%d" % (i + 1)
		cache.quest_id = "recover_supply_caches"
		cache.objective_id = "recover_caches"
		cache.speaker = "Frozen Cache"
		cache.inspect_text = "You recover a supply crate buried in the snow."
		cache.prompt_override = "Recover cache"
		cache.position = Vector3(-4 + i * 5, 0.1, 8 + i * 2)
		interactables.add_child(cache)
	var seal_poi := _QuestPoi.new()
	seal_poi.name = "RitualSeals"
	seal_poi.poi_id = "ritual_seals"
	seal_poi.quest_id = "gravewind_rising"
	seal_poi.objective_id = "recover_seals"
	seal_poi.speaker = "Ritual Seals"
	seal_poi.inspect_text = "You recover the ritual seals from the gravewind site."
	seal_poi.prompt_override = "Recover seals"
	seal_poi.position = Vector3(6, 0.1, 14)
	interactables.add_child(seal_poi)
	if interactables.get_node_or_null("PaleheartEntrance") == null and ResourceLoader.exists(PALEHEART_SCENE):
		var crypt := _spawn_prop_node(PALEHEART_SCENE, Vector3(22, 0, 18))
		if crypt:
			crypt.name = "PaleheartEntrance"
			interactables.add_child(crypt)
	_spawn_resource(interactables, "rime_ore", Vector3(10, 0, 4), 2)
	_spawn_resource(interactables, "frostwood", Vector3(-10, 0, 6), 2)
	_spawn_resource(interactables, "black_ice", Vector3(18, 0, 12), 1)
	_spawn_resource(interactables, "glacial_crystal", Vector3(13, 0, 7), 1, "", "frostgrave_expanse:glacial_crystal_01", true)
	_spawn_resource(interactables, "grave_dust", Vector3(6, 0, 12), 1)
	if level.get_node_or_null("BlizzardController") == null:
		var blizzard := _Blizzard.new()
		blizzard.name = "BlizzardController"
		level.add_child(blizzard)
	_spawn_frostgrave_environment(level)


static func _spawn_frostgrave_environment(level: Node3D) -> void:
	var env := level.get_node_or_null("Environment") as Node3D
	if env == null:
		env = level
	var zones := env.get_node_or_null("FrostgraveEnvironmentZones") as Node3D
	if zones == null:
		zones = Node3D.new()
		zones.name = "FrostgraveEnvironmentZones"
		env.add_child(zones)
	var shelter := _WarmShelter.new()
	shelter.name = "FrostwatchShelter"
	shelter.position = Vector3(0, 1, 0)
	var scol := CollisionShape3D.new()
	var sshape := BoxShape3D.new()
	sshape.size = Vector3(16, 4, 16)
	scol.shape = sshape
	shelter.add_child(scol)
	zones.add_child(shelter)
	for pos in [Vector3(12, 0.05, 4), Vector3(-8, 0.05, 10), Vector3(16, 0.05, 12)]:
		var cold := _ColdZone.new()
		cold.position = pos
		var ccol := CollisionShape3D.new()
		var cshape := BoxShape3D.new()
		cshape.size = Vector3(6, 2, 6)
		ccol.shape = cshape
		cold.add_child(ccol)
		zones.add_child(cold)
	for pos in [Vector3(8, 0, 6), Vector3(-6, 0, 8)]:
		var snow := _DeepSnow.new()
		snow.position = pos
		var ncol := CollisionShape3D.new()
		var nshape := BoxShape3D.new()
		nshape.size = Vector3(8, 1, 8)
		ncol.shape = nshape
		snow.add_child(ncol)
		zones.add_child(snow)
	for pos in [Vector3(14, 0, 10), Vector3(11, 0, 9)]:
		var ice := _IceZone.new()
		ice.position = pos
		var icol := CollisionShape3D.new()
		var ishape := BoxShape3D.new()
		ishape.size = Vector3(5, 0.5, 5)
		icol.shape = ishape
		ice.add_child(icol)
		zones.add_child(ice)
	for pos in [Vector3(8, 0, -13), Vector3(17, 0, 13), Vector3(-12, 0, -11)]:
		var icefall := _FallingIce.new()
		icefall.position = pos
		zones.add_child(icefall)


static func _spawn_shattered_coast_content(level: Node3D, enemies: Node3D, interactables: Node3D) -> void:
	_spawn_enemy(enemies, "saltfang_hound", Vector3(-14, 0.1, -10))
	_spawn_enemy(enemies, "saltfang_hound", Vector3(-11, 0.1, -12))
	_spawn_enemy(enemies, "saltfang_hound", Vector3(-13, 0.1, -8))
	_spawn_enemy(enemies, "tide_reaver", Vector3(-10, 0.1, -9))
	_spawn_enemy(enemies, "tide_reaver_archer", Vector3(-8, 0.1, -11))
	_spawn_enemy(enemies, "tide_reaver_bomber", Vector3(-12, 0.1, -7))
	_spawn_enemy(enemies, "drowned_mariner", Vector3(10, 0.1, 10))
	_spawn_enemy(enemies, "drowned_mariner", Vector3(12, 0.1, 8))
	_spawn_enemy(enemies, "storm_wraith", Vector3(16, 0.1, 4))
	_spawn_enemy(enemies, "leviathan_cultist", Vector3(18, 0.1, 14))
	_spawn_enemy(enemies, "shellback_brute", Vector3(14, 0.1, -6))
	_spawn_enemy(enemies, "tidebound_colossus", Vector3(20, 0.1, 16))
	if interactables.get_node_or_null("TidewatchCamp") == null:
		var camp := _spawn_prop_node(CAMP_SCENE, Vector3(0, 0, 2))
		if camp:
			camp.name = "TidewatchCamp"
			camp.set("town_inn_mode", true)
			camp.set("checkpoint_marker_id", "checkpoint_shattered_coast")
			interactables.add_child(camp)
	if interactables.get_node_or_null("ShatteredCoastWaystone") == null:
		var ws := _spawn_prop_node(WAYSTONE_SCENE, Vector3(2, 0, 4))
		if ws:
			ws.name = "ShatteredCoastWaystone"
			ws.set("waystone_id", "shattered_coast")
			interactables.add_child(ws)
	if interactables.get_node_or_null("TidewatchMerchant") == null and ResourceLoader.exists(MERCHANT_SCENE):
		var vendor := _spawn_prop_node(MERCHANT_SCENE, Vector3(-3, 0.1, -1))
		if vendor:
			vendor.name = "TidewatchMerchant"
			vendor.set("npc_id", "tidewatch_merchant")
			vendor.set("display_name", "Maela Shore")
			vendor.set("is_merchant", true)
			interactables.add_child(vendor)
	if interactables.get_node_or_null("TidewatchForge") == null and ResourceLoader.exists(MERCHANT_SCENE):
		var forge := _spawn_prop_node(MERCHANT_SCENE, Vector3(3, 0.1, -1))
		if forge:
			forge.name = "TidewatchForge"
			forge.set("npc_id", "tidewatch_forge")
			forge.set("display_name", "Garrick Hull")
			forge.set("is_merchant", true)
			interactables.add_child(forge)
	if interactables.get_node_or_null("TidewatchHealer") == null:
		var healer := _HealerStation.new()
		healer.name = "TidewatchHealer"
		healer.position = Vector3(-5, 0.1, 1)
		interactables.add_child(healer)
	var commander := _QuestPoi.new()
	commander.name = "TidewatchCommander"
	commander.poi_id = "tidewatch_commander"
	commander.quest_id = "into_the_storm"
	commander.objective_id = "speak_admiral"
	commander.speaker = "Admiral Serah Vane"
	commander.inspect_text = "Admiral Vane watches the storm-wracked horizon. The Drowned Citadel must fall."
	commander.prompt_override = "Speak with Admiral Serah Vane"
	commander.position = Vector3(0, 0.1, -4)
	interactables.add_child(commander)
	var scout := _QuestPoi.new()
	scout.name = "ScoutLysa"
	scout.poi_id = "scout_lysa"
	scout.quest_id = "rescue_stranded_scout"
	scout.objective_id = "rescue_scout"
	scout.speaker = "Scout Lysa Marr"
	scout.inspect_text = "Lysa Marr maps the wreckshore and tidal caves."
	scout.prompt_override = "Speak with Scout Lysa Marr"
	scout.position = Vector3(5, 0.1, 1)
	interactables.add_child(scout)
	for i in 3:
		var wreck := _QuestPoi.new()
		wreck.name = "Shipwreck%d" % (i + 1)
		wreck.poi_id = "shipwreck_%d" % (i + 1)
		wreck.quest_id = "wrecks_on_the_shore"
		wreck.objective_id = "investigate_wrecks"
		wreck.speaker = "Shipwreck"
		wreck.inspect_text = "Broken hull timbers and salt-stained cargo mark another lost vessel."
		wreck.prompt_override = "Investigate wreck"
		wreck.position = Vector3(-12 + i * 2, 0.1, -10 + i)
		interactables.add_child(wreck)
	for i in 3:
		var manifest := _QuestPoi.new()
		manifest.name = "ShippingManifest%d" % (i + 1)
		manifest.poi_id = "shipping_manifest_%d" % (i + 1)
		manifest.quest_id = "wrecks_on_the_shore"
		manifest.objective_id = "recover_manifests"
		manifest.speaker = "Shipping Manifest"
		manifest.inspect_text = "You recover a waterlogged shipping manifest."
		manifest.prompt_override = "Recover manifest"
		manifest.position = Vector3(-11 + i * 2, 0.1, -9 + i)
		interactables.add_child(manifest)
	var village := _QuestPoi.new()
	village.name = "DrownedVillage"
	village.poi_id = "drowned_village_poi"
	village.quest_id = "the_drowned_village"
	village.objective_id = "enter_village"
	village.speaker = "Drowned Village"
	village.inspect_text = "Flooded homes and drowned lanterns mark the lost settlement."
	village.prompt_override = "Enter drowned village"
	village.position = Vector3(10, 0.1, 10)
	interactables.add_child(village)
	var records := _QuestPoi.new()
	records.name = "SurvivorRecordsCoast"
	records.poi_id = "coast_survivor_records"
	records.quest_id = "the_drowned_village"
	records.objective_id = "recover_records"
	records.speaker = "Survivor Records"
	records.inspect_text = "You recover salt-stained survivor records."
	records.prompt_override = "Recover records"
	records.position = Vector3(10.5, 0.1, 9)
	interactables.add_child(records)
	var survivor := _QuestPoi.new()
	survivor.name = "DrownedSurvivor"
	survivor.poi_id = "drowned_survivor"
	survivor.quest_id = "the_drowned_village"
	survivor.objective_id = "rescue_survivors"
	survivor.speaker = "Trapped Survivor"
	survivor.inspect_text = "You guide a soaked survivor toward Tidewatch."
	survivor.prompt_override = "Rescue survivor"
	survivor.position = Vector3(9.5, 0.1, 11)
	interactables.add_child(survivor)
	for i in 3:
		var shrine := _QuestPoi.new()
		shrine.name = "StormShrine%d" % (i + 1)
		shrine.poi_id = "storm_shrine_%d" % (i + 1)
		shrine.quest_id = "stormcallers"
		shrine.objective_id = "investigate_shrines"
		shrine.speaker = "Storm Shrine"
		shrine.inspect_text = "Crackling storm wards pulse over ancient maritime stone."
		shrine.prompt_override = "Investigate shrine"
		shrine.position = Vector3(14 + i * 3, 0.1, 4 + i * 2)
		interactables.add_child(shrine)
	for i in 3:
		var seal := _QuestPoi.new()
		seal.name = "StormSeal%d" % (i + 1)
		seal.poi_id = "storm_seal_%d" % (i + 1)
		seal.quest_id = "stormcallers"
		seal.objective_id = "recover_seals"
		seal.speaker = "Storm Seal"
		seal.inspect_text = "You recover a storm seal from the shrine."
		seal.prompt_override = "Recover seal"
		seal.position = Vector3(15 + i * 3, 0.1, 5 + i * 2)
		interactables.add_child(seal)
	if interactables.get_node_or_null("DrownedCitadelEntrance") == null and ResourceLoader.exists(CITADEL_SCENE):
		var citadel := _spawn_prop_node(CITADEL_SCENE, Vector3(22, 0, 18))
		if citadel:
			citadel.name = "DrownedCitadelEntrance"
			interactables.add_child(citadel)
	_spawn_resource(interactables, "driftwood", Vector3(-8, 0, 6), 2)
	_spawn_resource(interactables, "salt_iron", Vector3(10, 0, 4), 2)
	_spawn_resource(interactables, "stormglass", Vector3(16, 0, 6), 1)
	_spawn_resource(interactables, "kelp_fiber", Vector3(8, 0, -6), 2)
	_spawn_resource(interactables, "barnacle_plate", Vector3(14, 0, -4), 1)
	_spawn_resource(interactables, "drowned_relic", Vector3(11, 0, 12), 1)
	_spawn_resource(interactables, "leviathan_bone", Vector3(19, 0, 15), 1)
	if level.get_node_or_null("CoastalStormController") == null:
		var storm := _CoastalStorm.new()
		storm.name = "CoastalStormController"
		level.add_child(storm)
	_spawn_shattered_coast_environment(level)


static func _spawn_shattered_coast_environment(level: Node3D) -> void:
	var env := level.get_node_or_null("Environment") as Node3D
	if env == null:
		env = level
	var zones := env.get_node_or_null("ShatteredCoastEnvironmentZones") as Node3D
	if zones == null:
		zones = Node3D.new()
		zones.name = "ShatteredCoastEnvironmentZones"
		env.add_child(zones)
	var shelter := _CoastalShelter.new()
	shelter.name = "TidewatchShelter"
	shelter.position = Vector3(0, 1, 0)
	var scol := CollisionShape3D.new()
	var sshape := BoxShape3D.new()
	sshape.size = Vector3(16, 4, 16)
	scol.shape = sshape
	shelter.add_child(scol)
	zones.add_child(shelter)
	for pos in [Vector3(-14, 0.05, -10), Vector3(-10, 0.05, -8), Vector3(12, 0.05, -7)]:
		var wave := _WaveHazard.new()
		wave.position = pos
		var wcol := CollisionShape3D.new()
		var wshape := BoxShape3D.new()
		wshape.size = Vector3(5, 1.5, 4)
		wcol.shape = wshape
		wave.add_child(wcol)
		zones.add_child(wave)
	for pos in [Vector3(-12, 0, -9), Vector3(14, 0, 5), Vector3(18, 0, 12)]:
		var wet := _WetRock.new()
		wet.position = pos
		var wetcol := CollisionShape3D.new()
		var wetshape := BoxShape3D.new()
		wetshape.size = Vector3(6, 0.5, 6)
		wetcol.shape = wetshape
		wet.add_child(wetcol)
		zones.add_child(wet)
	for pos in [Vector3(16, 0, 4), Vector3(15, 0, 6)]:
		var storm := _StormZone.new()
		storm.position = pos
		var stcol := CollisionShape3D.new()
		var stshape := BoxShape3D.new()
		stshape.size = Vector3(5, 2, 5)
		stcol.shape = stshape
		storm.add_child(stcol)
		zones.add_child(storm)
	for pos in [Vector3(10, 0, 10), Vector3(20, 0, 17)]:
		var salt := _SaltZone.new()
		salt.position = pos
		var saltcol := CollisionShape3D.new()
		var saltshape := BoxShape3D.new()
		saltshape.size = Vector3(7, 2, 7)
		saltcol.shape = saltshape
		salt.add_child(saltcol)
		zones.add_child(salt)
	for pos in [Vector3(17, 0, 3), Vector3(13, 0, 7)]:
		var bolt := _LightningZone.new()
		bolt.position = pos
		var bcol := CollisionShape3D.new()
		var bshape := BoxShape3D.new()
		bshape.size = Vector3(4, 3, 4)
		bcol.shape = bshape
		bolt.add_child(bcol)
		zones.add_child(bolt)
	var deep := _DeepWater.new()
	deep.name = "OceanBoundary"
	deep.position = Vector3(0, -0.5, 0)
	zones.add_child(deep)


static func _spawn_ember_wastes_content(level: Node3D, enemies: Node3D, interactables: Node3D) -> void:
	_spawn_enemy(enemies, "ashscale_hound", Vector3(-14, 0.1, -10))
	_spawn_enemy(enemies, "ashscale_hound", Vector3(-12, 0.1, -8))
	_spawn_enemy(enemies, "dune_raider", Vector3(-11, 0.1, -9))
	_spawn_enemy(enemies, "dune_raider_archer", Vector3(-9, 0.1, -10))
	_spawn_enemy(enemies, "dune_raider_bomber", Vector3(-13, 0.1, -7))
	_spawn_enemy(enemies, "glass_husk", Vector3(12, 0.1, 8))
	_spawn_enemy(enemies, "sand_wraith", Vector3(14, 0.1, 6))
	_spawn_enemy(enemies, "burrow_stalker", Vector3(10, 0.1, 10))
	_spawn_enemy(enemies, "pyre_cultist", Vector3(18, 0.1, 14))
	_spawn_enemy(enemies, "sunscar_behemoth", Vector3(20, 0.1, 16))
	if interactables.get_node_or_null("CinderholdCamp") == null:
		var camp := _spawn_prop_node(CAMP_SCENE, Vector3(0, 0, 2))
		if camp:
			camp.name = "CinderholdCamp"
			camp.set("town_inn_mode", true)
			camp.set("checkpoint_marker_id", "checkpoint_ember_wastes")
			interactables.add_child(camp)
	if interactables.get_node_or_null("EmberWastesWaystone") == null:
		var ws := _spawn_prop_node(WAYSTONE_SCENE, Vector3(2, 0, 4))
		if ws:
			ws.name = "EmberWastesWaystone"
			ws.set("waystone_id", "ember_wastes")
			interactables.add_child(ws)
	if interactables.get_node_or_null("CinderholdWarden") == null and ResourceLoader.exists(CINDERHOLD_NPC_SCENE):
		var warden := _spawn_prop_node(CINDERHOLD_NPC_SCENE, Vector3(0, 0.1, -4))
		if warden:
			warden.name = "CinderholdWarden"
			warden.set("npc_id", "warden_ilyra_voss")
			warden.set("display_name", "Warden Ilyra Voss")
			warden.set("is_quest_giver", true)
			interactables.add_child(warden)
	if interactables.get_node_or_null("CinderholdMerchant") == null and ResourceLoader.exists(CINDERHOLD_NPC_SCENE):
		var vendor := _spawn_prop_node(CINDERHOLD_NPC_SCENE, Vector3(-3, 0.1, -1))
		if vendor:
			vendor.name = "CinderholdMerchant"
			vendor.set("npc_id", "nima_dareth")
			vendor.set("display_name", "Nima Dareth")
			vendor.set("is_merchant", true)
			interactables.add_child(vendor)
	if interactables.get_node_or_null("CinderholdSunforge") == null and ResourceLoader.exists(CINDERHOLD_NPC_SCENE):
		var smith := _spawn_prop_node(CINDERHOLD_NPC_SCENE, Vector3(4, 0.1, 1))
		if smith:
			smith.name = "CinderholdSunforge"
			smith.set("npc_id", "dagan_sunforge")
			smith.set("display_name", "Dagan Sunforge")
			smith.set("is_merchant", true)
			interactables.add_child(smith)
	if interactables.get_node_or_null("CinderholdApothecary") == null and ResourceLoader.exists(CINDERHOLD_NPC_SCENE):
		var apoth := _spawn_prop_node(CINDERHOLD_NPC_SCENE, Vector3(3, 0.1, -1))
		if apoth:
			apoth.name = "CinderholdApothecary"
			apoth.set("npc_id", "doctor_sol_marr")
			apoth.set("display_name", "Doctor Sol Marr")
			interactables.add_child(apoth)
	if interactables.get_node_or_null("CinderholdHealer") == null:
		var healer := _CinderholdHealer.new()
		healer.name = "CinderholdHealer"
		healer.position = Vector3(-5, 0.1, 1)
		interactables.add_child(healer)
	if interactables.get_node_or_null("CinderholdScout") == null and ResourceLoader.exists(CINDERHOLD_NPC_SCENE):
		var scout := _spawn_prop_node(CINDERHOLD_NPC_SCENE, Vector3(5, 0.1, 1))
		if scout:
			scout.name = "CinderholdScout"
			scout.set("npc_id", "scout_kera_ash")
			scout.set("display_name", "Scout Kera Ash")
			scout.set("is_quest_giver", true)
			interactables.add_child(scout)
	var dry_road := _QuestPoi.new()
	dry_road.name = "DryRoadTrail"
	dry_road.poi_id = "dry_road_trail"
	dry_road.quest_id = "the_dry_road"
	dry_road.objective_id = "investigate_trail"
	dry_road.speaker = "The Dry Road"
	dry_road.inspect_text = "A sun-baked trail winds through shattered sandstone and bleached bone."
	dry_road.prompt_override = "Investigate trail"
	dry_road.position = Vector3(8, 0.1, -12)
	interactables.add_child(dry_road)
	var route_clear := _QuestPoi.new()
	route_clear.name = "DryRoadClear"
	route_clear.poi_id = "dry_road_clear"
	route_clear.quest_id = "the_dry_road"
	route_clear.objective_id = "clear_obstacles"
	route_clear.speaker = "Cleared Trail"
	route_clear.inspect_text = "You clear enough debris to reopen the dry road."
	route_clear.prompt_override = "Clear obstacles"
	route_clear.position = Vector3(9, 0.1, -11)
	interactables.add_child(route_clear)
	var glass_dune := _QuestPoi.new()
	glass_dune.name = "GlassDuneSite"
	glass_dune.poi_id = "glass_dune_site"
	glass_dune.quest_id = "glass_beneath_the_sand"
	glass_dune.objective_id = "investigate_dune"
	glass_dune.speaker = "Glass Dune"
	glass_dune.inspect_text = "Heat-warped glass glitters beneath wind-scoured sand."
	glass_dune.prompt_override = "Investigate glass dune"
	glass_dune.position = Vector3(14, 0.1, 6)
	interactables.add_child(glass_dune)
	for i in 3:
		var fragment := _QuestPoi.new()
		fragment.name = "GlassFragment%d" % (i + 1)
		fragment.poi_id = "glass_fragment_%d" % (i + 1)
		fragment.quest_id = "glass_beneath_the_sand"
		fragment.objective_id = "recover_fragments"
		fragment.speaker = "Glass Fragment"
		fragment.inspect_text = "You recover a shard of buried volcanic glass."
		fragment.prompt_override = "Recover fragment"
		fragment.position = Vector3(13 + i, 0.1, 5 + i)
		interactables.add_child(fragment)
	for i in 3:
		var obelisk := _QuestPoi.new()
		obelisk.name = "BurningObelisk%d" % (i + 1)
		obelisk.poi_id = "burning_obelisk_%d" % (i + 1)
		obelisk.quest_id = "the_burning_obelisks"
		obelisk.objective_id = "investigate_obelisks"
		obelisk.speaker = "Burning Obelisk"
		obelisk.inspect_text = "An ancient obelisk radiates stored solar heat."
		obelisk.prompt_override = "Investigate obelisk"
		obelisk.position = Vector3(-12 + i * 2, 0.1, -10 + i)
		interactables.add_child(obelisk)
	var obelisk_fragment := _QuestPoi.new()
	obelisk_fragment.name = "AncientObeliskFragment"
	obelisk_fragment.poi_id = "ancient_obelisk_fragment_poi"
	obelisk_fragment.quest_id = "the_burning_obelisks"
	obelisk_fragment.objective_id = "recover_fragment"
	obelisk_fragment.speaker = "Obelisk Fragment"
	obelisk_fragment.inspect_text = "You recover an ancient obelisk fragment from the buried altar."
	obelisk_fragment.prompt_override = "Recover fragment"
	obelisk_fragment.position = Vector3(-10, 0.1, -8)
	interactables.add_child(obelisk_fragment)
	for i in 2:
		var den := _QuestPoi.new()
		den.name = "AshscaleDen%d" % (i + 1)
		den.poi_id = "ashscale_den_%d" % (i + 1)
		den.quest_id = "hunt_ashscale_packs"
		den.objective_id = "clear_den"
		den.speaker = "Ashscale Den"
		den.inspect_text = "You collapse an ashscale hound den."
		den.prompt_override = "Destroy den"
		den.position = Vector3(-13 - i, 0.1, -11 + i)
		interactables.add_child(den)
	var caravan := _QuestPoi.new()
	caravan.name = "StrandedCaravan"
	caravan.poi_id = "stranded_caravan"
	caravan.quest_id = "rescue_stranded_caravan"
	caravan.objective_id = "rescue_caravan"
	caravan.speaker = "Stranded Caravan"
	caravan.inspect_text = "You guide the stranded caravan back to Cinderhold."
	caravan.prompt_override = "Rescue caravan"
	caravan.position = Vector3(6, 0.1, -6)
	interactables.add_child(caravan)
	if interactables.get_node_or_null("PyreheartEntrance") == null and ResourceLoader.exists(PYREHEART_SCENE):
		var ziggurat := _spawn_prop_node(PYREHEART_SCENE, Vector3(22, 0, 18))
		if ziggurat:
			ziggurat.name = "PyreheartEntrance"
			interactables.add_child(ziggurat)
	_spawn_resource(interactables, "scorched_sand", Vector3(-8, 0, 6), 2)
	_spawn_resource(interactables, "sunstone_shard", Vector3(10, 0, 4), 2)
	_spawn_resource(interactables, "glass_fragment", Vector3(12, 0, -6), 2)
	_spawn_resource(interactables, "pyre_dust", Vector3(14, 0, 4), 1)
	_spawn_resource(interactables, "cactus_fiber", Vector3(8, 0, -6), 1)
	_spawn_resource(interactables, "ancient_obelisk_fragment", Vector3(16, 0, 6), 1)
	if level.get_node_or_null("SandstormController") == null:
		var storm := _Sandstorm.new()
		storm.name = "SandstormController"
		level.add_child(storm)
	_spawn_ember_wastes_environment(level)


static func _spawn_ember_wastes_environment(level: Node3D) -> void:
	var env := level.get_node_or_null("Environment") as Node3D
	if env == null:
		env = level
	var zones := env.get_node_or_null("EmberWastesEnvironmentZones") as Node3D
	if zones == null:
		zones = Node3D.new()
		zones.name = "EmberWastesEnvironmentZones"
		env.add_child(zones)
	var shelter := _DesertShelter.new()
	shelter.name = "CinderholdShelter"
	shelter.position = Vector3(0, 1, 0)
	var scol := CollisionShape3D.new()
	var sshape := BoxShape3D.new()
	sshape.size = Vector3(14, 4, 14)
	scol.shape = sshape
	shelter.add_child(scol)
	zones.add_child(shelter)
	for pos in [Vector3(-13, 0.05, -9), Vector3(15, 0.05, 7), Vector3(19, 0.05, 15)]:
		var heat := _HeatZone.new()
		heat.position = pos
		var hcol := CollisionShape3D.new()
		var hshape := BoxShape3D.new()
		hshape.size = Vector3(6, 2, 6)
		hcol.shape = hshape
		heat.add_child(hcol)
		zones.add_child(heat)
	var glass := _GlassDune.new()
	glass.name = "GlassDuneZone"
	glass.position = Vector3(14, 0.5, 6)
	var gcol := CollisionShape3D.new()
	var gshape := SphereShape3D.new()
	gshape.radius = 4.0
	gcol.shape = gshape
	glass.add_child(gcol)
	zones.add_child(glass)


static func _spawn_sunless_dominion_content(level: Node3D, enemies: Node3D, interactables: Node3D) -> void:
	_spawn_enemy(enemies, "gloom_hound", Vector3(-14, 0.1, -10))
	_spawn_enemy(enemies, "gloom_hound", Vector3(-12, 0.1, -8))
	_spawn_enemy(enemies, "nightbound_raider", Vector3(-11, 0.1, -9))
	_spawn_enemy(enemies, "nightbound_raider_archer", Vector3(-9, 0.1, -10))
	_spawn_enemy(enemies, "nightbound_raider_bomber", Vector3(-13, 0.1, -7))
	_spawn_enemy(enemies, "grave_wraith", Vector3(12, 0.1, 8))
	_spawn_enemy(enemies, "shadow_stalker", Vector3(14, 0.1, 6))
	_spawn_enemy(enemies, "hollow_knight", Vector3(10, 0.1, 10))
	_spawn_enemy(enemies, "eclipse_cultist", Vector3(18, 0.1, 14))
	_spawn_enemy(enemies, "dominion_executioner", Vector3(20, 0.1, 16))
	if interactables.get_node_or_null("DawnwatchCamp") == null:
		var camp := _spawn_prop_node(CAMP_SCENE, Vector3(0, 0, 2))
		if camp:
			camp.name = "DawnwatchCamp"
			camp.set("town_inn_mode", true)
			camp.set("checkpoint_marker_id", "checkpoint_sunless_dominion")
			interactables.add_child(camp)
	if interactables.get_node_or_null("SunlessDominionWaystone") == null:
		var ws := _spawn_prop_node(WAYSTONE_SCENE, Vector3(2, 0, 4))
		if ws:
			ws.name = "SunlessDominionWaystone"
			ws.set("waystone_id", "sunless_dominion")
			interactables.add_child(ws)
	if interactables.get_node_or_null("DawnwatchCommander") == null and ResourceLoader.exists(DAWNWATCH_NPC_SCENE):
		var commander := _spawn_prop_node(DAWNWATCH_NPC_SCENE, Vector3(0, 0.1, -4))
		if commander:
			commander.name = "DawnwatchCommander"
			commander.set("npc_id", "commander_alaric_vane")
			commander.set("display_name", "Commander Alaric Vane")
			commander.set("is_quest_giver", true)
			interactables.add_child(commander)
	if interactables.get_node_or_null("DawnwatchMerchant") == null and ResourceLoader.exists(DAWNWATCH_NPC_SCENE):
		var vendor := _spawn_prop_node(DAWNWATCH_NPC_SCENE, Vector3(-3, 0.1, -1))
		if vendor:
			vendor.name = "DawnwatchMerchant"
			vendor.set("npc_id", "mira_sol")
			vendor.set("display_name", "Mira Sol")
			vendor.set("is_merchant", true)
			interactables.add_child(vendor)
	if interactables.get_node_or_null("DawnwatchNightforge") == null and ResourceLoader.exists(DAWNWATCH_NPC_SCENE):
		var smith := _spawn_prop_node(DAWNWATCH_NPC_SCENE, Vector3(4, 0.1, 1))
		if smith:
			smith.name = "DawnwatchNightforge"
			smith.set("npc_id", "selene_nightforge")
			smith.set("display_name", "Selene Nightforge")
			smith.set("is_merchant", true)
			interactables.add_child(smith)
	if interactables.get_node_or_null("DawnwatchApothecary") == null and ResourceLoader.exists(DAWNWATCH_NPC_SCENE):
		var apoth := _spawn_prop_node(DAWNWATCH_NPC_SCENE, Vector3(3, 0.1, -1))
		if apoth:
			apoth.name = "DawnwatchApothecary"
			apoth.set("npc_id", "doctor_corvin_hale")
			apoth.set("display_name", "Doctor Corvin Hale")
			interactables.add_child(apoth)
	if interactables.get_node_or_null("DawnwatchHealer") == null:
		var healer := _DawnwatchHealer.new()
		healer.name = "DawnwatchHealer"
		healer.position = Vector3(-5, 0.1, 1)
		interactables.add_child(healer)
	if interactables.get_node_or_null("DawnwatchScout") == null and ResourceLoader.exists(DAWNWATCH_NPC_SCENE):
		var scout := _spawn_prop_node(DAWNWATCH_NPC_SCENE, Vector3(5, 0.1, 1))
		if scout:
			scout.name = "DawnwatchScout"
			scout.set("npc_id", "scout_nyra_vale")
			scout.set("display_name", "Scout Nyra Vale")
			scout.set("is_quest_giver", true)
			interactables.add_child(scout)
	var hamlet := _QuestPoi.new()
	hamlet.name = "ForsakenHamlet"
	hamlet.poi_id = "forsaken_hamlet"
	hamlet.quest_id = "the_forsaken_hamlet"
	hamlet.objective_id = "investigate_hamlet"
	hamlet.speaker = "Forsaken Hamlet"
	hamlet.inspect_text = "Collapsed homes and nightbound tracks mark the lost settlement."
	hamlet.prompt_override = "Investigate hamlet"
	hamlet.position = Vector3(-12, 0.1, -10)
	interactables.add_child(hamlet)
	var records := _QuestPoi.new()
	records.name = "HamletRecords"
	records.poi_id = "hamlet_records"
	records.quest_id = "the_forsaken_hamlet"
	records.objective_id = "recover_records"
	records.speaker = "Survivor Records"
	records.inspect_text = "You recover ledgers describing the hamlet's fall to shadow."
	records.prompt_override = "Recover records"
	records.position = Vector3(-11, 0.1, -9)
	interactables.add_child(records)
	var survivor := _QuestPoi.new()
	survivor.name = "HamletSurvivor"
	survivor.poi_id = "hamlet_survivor"
	survivor.quest_id = "the_forsaken_hamlet"
	survivor.objective_id = "rescue_survivors"
	survivor.speaker = "Trapped Survivor"
	survivor.inspect_text = "You guide a frightened survivor back toward Dawnwatch."
	survivor.prompt_override = "Rescue survivor"
	survivor.position = Vector3(-10.5, 0.1, -11)
	interactables.add_child(survivor)
	for i in 3:
		var grave := _QuestPoi.new()
		grave.name = "RoyalGrave%d" % (i + 1)
		grave.poi_id = "royal_grave_%d" % (i + 1)
		grave.quest_id = "graves_without_rest"
		grave.objective_id = "investigate_graves"
		grave.speaker = "Royal Grave"
		grave.inspect_text = "Moon-crusted grave markers hum with gravewind."
		grave.prompt_override = "Investigate grave"
		grave.position = Vector3(-8 + i * 4, 0.1, 12 + i)
		interactables.add_child(grave)
	var seal_poi := _QuestPoi.new()
	seal_poi.name = "WardSeals"
	seal_poi.poi_id = "ward_seals"
	seal_poi.quest_id = "graves_without_rest"
	seal_poi.objective_id = "recover_seals"
	seal_poi.speaker = "Ward Seals"
	seal_poi.inspect_text = "You recover the ward seals from the royal graves."
	seal_poi.prompt_override = "Recover seals"
	seal_poi.position = Vector3(6, 0.1, 14)
	interactables.add_child(seal_poi)
	var observatory := _QuestPoi.new()
	observatory.name = "DarkObservatory"
	observatory.poi_id = "dark_observatory"
	observatory.quest_id = "the_dark_observatory"
	observatory.objective_id = "investigate_observatory"
	observatory.speaker = "Dark Observatory"
	observatory.inspect_text = "Cracked lenses and eclipse cult wards crown the eastern bluff."
	observatory.prompt_override = "Investigate observatory"
	observatory.position = Vector3(18, 0.1, 14)
	interactables.add_child(observatory)
	var shard_poi := _QuestPoi.new()
	shard_poi.name = "EclipseShardPoi"
	shard_poi.poi_id = "eclipse_shard_poi"
	shard_poi.quest_id = "the_dark_observatory"
	shard_poi.objective_id = "recover_eclipse_shard"
	shard_poi.speaker = "Eclipse Shard"
	shard_poi.inspect_text = "You recover the eclipse shard from the observatory altar."
	shard_poi.prompt_override = "Recover shard"
	shard_poi.position = Vector3(19, 0.1, 15)
	interactables.add_child(shard_poi)
	for i in 3:
		var relic := _QuestPoi.new()
		relic.name = "RoyalRelic%d" % (i + 1)
		relic.poi_id = "royal_relic_%d" % (i + 1)
		relic.quest_id = "recover_royal_relics"
		relic.objective_id = "recover_relics"
		relic.speaker = "Royal Relic"
		relic.inspect_text = "You recover a relic from the forsaken hamlet ruins."
		relic.prompt_override = "Recover relic"
		relic.position = Vector3(-11 + i, 0.1, -8 + i)
		interactables.add_child(relic)
	for i in 2:
		var den := _QuestPoi.new()
		den.name = "GloomHoundDen%d" % (i + 1)
		den.poi_id = "gloom_hound_den_%d" % (i + 1)
		den.quest_id = "destroy_gloom_hound_dens"
		den.objective_id = "clear_den"
		den.speaker = "Gloom Hound Den"
		den.inspect_text = "You collapse a gloom hound den."
		den.prompt_override = "Destroy den"
		den.position = Vector3(-13 - i, 0.1, -11 + i)
		interactables.add_child(den)
	for i in 2:
		var well := _QuestPoi.new()
		well.name = "ShadowWell%d" % (i + 1)
		well.poi_id = "shadow_well_%d" % (i + 1)
		well.quest_id = "purify_shadow_wells"
		well.objective_id = "purify_wells"
		well.speaker = "Shadow Well"
		well.inspect_text = "You purify the corrupted shadow well."
		well.prompt_override = "Purify well"
		well.position = Vector3(8 + i * 3, 0.1, -6 + i * 2)
		interactables.add_child(well)
	var patrol := _QuestPoi.new()
	patrol.name = "LostPatrol"
	patrol.poi_id = "lost_patrol"
	patrol.quest_id = "rescue_lost_patrol"
	patrol.objective_id = "rescue_patrol"
	patrol.speaker = "Lost Patrol"
	patrol.inspect_text = "You guide the lost patrol back to Dawnwatch."
	patrol.prompt_override = "Rescue patrol"
	patrol.position = Vector3(6, 0.1, -6)
	interactables.add_child(patrol)
	if interactables.get_node_or_null("EclipseSanctumEntrance") == null and ResourceLoader.exists(ECLIPSE_SANCTUM_SCENE):
		var sanctum := _spawn_prop_node(ECLIPSE_SANCTUM_SCENE, Vector3(22, 0, 18))
		if sanctum:
			sanctum.name = "EclipseSanctumEntrance"
			interactables.add_child(sanctum)
	var rift_gate := _FutureAstralRiftGate.new()
	rift_gate.name = "AstralRiftGate"
	rift_gate.position = Vector3(30, 0.1, 0)
	interactables.add_child(rift_gate)
	_spawn_resource(interactables, "silverwood", Vector3(-8, 0, 6), 2)
	_spawn_resource(interactables, "moonstone", Vector3(10, 0, 4), 2)
	_spawn_resource(interactables, "umbral_ore", Vector3(12, 0, -6), 2)
	_spawn_resource(interactables, "nightglass", Vector3(14, 0, 4), 1)
	_spawn_resource(interactables, "grave_dust", Vector3(8, 0, -6), 1)
	_spawn_resource(interactables, "shadow_hide", Vector3(16, 0, 6), 1)
	if level.get_node_or_null("EclipseStormController") == null:
		var storm := _EclipseStorm.new()
		storm.name = "EclipseStormController"
		level.add_child(storm)
	_spawn_sunless_dominion_environment(level)


static func _spawn_sunless_dominion_environment(level: Node3D) -> void:
	var env := level.get_node_or_null("Environment") as Node3D
	if env == null:
		env = level
	var zones := env.get_node_or_null("SunlessDominionEnvironmentZones") as Node3D
	if zones == null:
		zones = Node3D.new()
		zones.name = "SunlessDominionEnvironmentZones"
		env.add_child(zones)
	var shelter := _ShadowShelter.new()
	shelter.name = "DawnwatchShelter"
	shelter.position = Vector3(0, 1, 0)
	var scol := CollisionShape3D.new()
	var sshape := BoxShape3D.new()
	sshape.size = Vector3(14, 4, 14)
	scol.shape = sshape
	shelter.add_child(scol)
	zones.add_child(shelter)
	for pos in [Vector3(-13, 0.05, -9), Vector3(15, 0.05, 7), Vector3(19, 0.05, 15)]:
		var dread := _DreadZone.new()
		dread.position = pos
		var dcol := CollisionShape3D.new()
		var dshape := BoxShape3D.new()
		dshape.size = Vector3(6, 2, 6)
		dcol.shape = dshape
		dread.add_child(dcol)
		zones.add_child(dread)
	for pos in [Vector3(9, 0.5, -5), Vector3(11, 0.5, 5), Vector3(13, 0.5, 8)]:
		var pool := _ShadowPool.new()
		pool.position = pos
		var pcol := CollisionShape3D.new()
		var pshape := SphereShape3D.new()
		pshape.radius = 3.5
		pcol.shape = pshape
		pool.add_child(pcol)
		zones.add_child(pool)
	for pos in [Vector3(8, 0, 6), Vector3(-6, 0, 8)]:
		var ground := _ShadowGround.new()
		ground.position = pos
		var gcol := CollisionShape3D.new()
		var gshape := BoxShape3D.new()
		gshape.size = Vector3(8, 1, 8)
		gcol.shape = gshape
		ground.add_child(gcol)
		zones.add_child(ground)


static func _spawn_blightreach_content(level: Node3D, enemies: Node3D, interactables: Node3D) -> void:
	_spawn_enemy(enemies, "blight_hound", Vector3(-14, 0.1, -10))
	_spawn_enemy(enemies, "blight_hound", Vector3(-12, 0.1, -8))
	_spawn_enemy(enemies, "blight_hound", Vector3(-10, 0.1, -11))
	_spawn_enemy(enemies, "rootbound_raider", Vector3(-11, 0.1, -9))
	_spawn_enemy(enemies, "rootbound_archer", Vector3(-9, 0.1, -10))
	_spawn_enemy(enemies, "rootbound_bomber", Vector3(-13, 0.1, -7))
	_spawn_enemy(enemies, "fungal_husk", Vector3(12, 0.1, 8))
	_spawn_enemy(enemies, "sporecaster", Vector3(14, 0.1, 6))
	_spawn_enemy(enemies, "vine_stalker", Vector3(10, 0.1, 10))
	_spawn_enemy(enemies, "corruption_wraith", Vector3(18, 0.1, 14))
	_spawn_enemy(enemies, "root_titan", Vector3(20, 0.1, 16))
	if interactables.get_node_or_null("LastwallCamp") == null:
		var camp := _spawn_prop_node(CAMP_SCENE, Vector3(0, 0, 2))
		if camp:
			camp.name = "LastwallCamp"
			camp.set("town_inn_mode", true)
			camp.set("checkpoint_marker_id", "checkpoint_blightreach")
			interactables.add_child(camp)
	if interactables.get_node_or_null("BlightreachWaystone") == null:
		var ws := _spawn_prop_node(WAYSTONE_SCENE, Vector3(2, 0, 4))
		if ws:
			ws.name = "BlightreachWaystone"
			ws.set("waystone_id", "blightreach")
			interactables.add_child(ws)
	if interactables.get_node_or_null("LastwallMerchant") == null and ResourceLoader.exists(MERCHANT_SCENE):
		var vendor := _spawn_prop_node(MERCHANT_SCENE, Vector3(-3, 0.1, -1))
		if vendor:
			vendor.name = "LastwallMerchant"
			vendor.set("npc_id", "lastwall_merchant")
			vendor.set("display_name", "Tessa Thorn")
			vendor.set("is_merchant", true)
			interactables.add_child(vendor)
	if interactables.get_node_or_null("LastwallApothecary") == null and ResourceLoader.exists(MERCHANT_SCENE):
		var apoth := _spawn_prop_node(MERCHANT_SCENE, Vector3(3, 0.1, -1))
		if apoth:
			apoth.name = "LastwallApothecary"
			apoth.set("npc_id", "lastwall_apothecary")
			apoth.set("display_name", "Doctor Eldric Venn")
			apoth.set("is_merchant", true)
			interactables.add_child(apoth)
	if interactables.get_node_or_null("LastwallBlightsmith") == null and ResourceLoader.exists(MERCHANT_SCENE):
		var smith := _spawn_prop_node(MERCHANT_SCENE, Vector3(4, 0.1, 1))
		if smith:
			smith.name = "LastwallBlightsmith"
			smith.set("npc_id", "lastwall_blightsmith")
			smith.set("display_name", "Garran Rootbreaker")
			smith.set("is_merchant", true)
			interactables.add_child(smith)
	if interactables.get_node_or_null("LastwallHealer") == null:
		var healer := _HealerStation.new()
		healer.name = "LastwallHealer"
		healer.position = Vector3(-5, 0.1, 1)
		interactables.add_child(healer)
	var warden := _QuestPoi.new()
	warden.name = "WardenMaraKest"
	warden.poi_id = "warden_mara_kest"
	warden.quest_id = "into_the_blight"
	warden.objective_id = "speak_warden"
	warden.speaker = "Warden Mara Kest"
	warden.inspect_text = "Mara Kest coordinates Lastwall's defense against the spreading blight."
	warden.prompt_override = "Speak with Warden Mara Kest"
	warden.position = Vector3(0, 0.1, -4)
	interactables.add_child(warden)
	var scout := _QuestPoi.new()
	scout.name = "ScoutOrris"
	scout.poi_id = "scout_orris"
	scout.quest_id = "recover_research_notes"
	scout.objective_id = "recover_notes"
	scout.speaker = "Scout Orris"
	scout.inspect_text = "Orris maps blighted landmarks and survivor trails."
	scout.prompt_override = "Speak with Scout Orris"
	scout.position = Vector3(5, 0.1, 1)
	interactables.add_child(scout)
	var filter_poi := _QuestPoi.new()
	filter_poi.name = "SporeFilterPoi"
	filter_poi.poi_id = "spore_filter_poi"
	filter_poi.quest_id = "spores_in_the_wind"
	filter_poi.objective_id = "obtain_filter"
	filter_poi.speaker = "Doctor Eldric Venn"
	filter_poi.inspect_text = "Doctor Venn provides a fitted spore filter for field work."
	filter_poi.prompt_override = "Obtain spore filter"
	filter_poi.position = Vector3(3, 0.1, -1)
	interactables.add_child(filter_poi)
	for i in 3:
		var farm := _QuestPoi.new()
		farm.name = "WitheredFarm%d" % (i + 1)
		farm.poi_id = "withered_farm_%d" % (i + 1)
		farm.quest_id = "the_withered_fields"
		farm.objective_id = "investigate_farms"
		farm.speaker = "Abandoned Farm"
		farm.inspect_text = "Rotting crops and broken fences mark another lost holding."
		farm.prompt_override = "Investigate farm"
		farm.position = Vector3(-12 + i * 2, 0.1, -9 + i)
		interactables.add_child(farm)
	var records := _QuestPoi.new()
	records.name = "SurvivorRecords"
	records.poi_id = "survivor_records"
	records.quest_id = "the_withered_fields"
	records.objective_id = "recover_records"
	records.speaker = "Survivor Records"
	records.inspect_text = "You recover ledgers describing the blight's spread."
	records.prompt_override = "Recover records"
	records.position = Vector3(-10, 0.1, -8)
	interactables.add_child(records)
	for i in 3:
		var spore := _QuestPoi.new()
		spore.name = "SporeZone%d" % (i + 1)
		spore.poi_id = "spore_zone_%d" % (i + 1)
		spore.quest_id = "spores_in_the_wind"
		spore.objective_id = "investigate_spores"
		spore.speaker = "Spore Zone"
		spore.inspect_text = "Thick spore clouds drift through the corrupted trees."
		spore.prompt_override = "Investigate spore zone"
		spore.position = Vector3(8 + i * 3, 0.1, -6 + i * 2)
		interactables.add_child(spore)
	for i in 3:
		var sample := _QuestPoi.new()
		sample.name = "FungalSample%d" % (i + 1)
		sample.poi_id = "fungal_sample_%d" % (i + 1)
		sample.quest_id = "spores_in_the_wind"
		sample.objective_id = "recover_samples"
		sample.speaker = "Fungal Cluster"
		sample.inspect_text = "You collect a fungal sample for Doctor Venn."
		sample.prompt_override = "Collect sample"
		sample.position = Vector3(10 + i * 2, 0.1, 4 + i)
		interactables.add_child(sample)
	var abbey := _QuestPoi.new()
	abbey.name = "FallenAbbey"
	abbey.poi_id = "fallen_abbey"
	abbey.quest_id = "the_fallen_abbey"
	abbey.objective_id = "reach_abbey"
	abbey.speaker = "Fallen Abbey"
	abbey.inspect_text = "Ancient abbey ruins choke on living roots and violet light."
	abbey.prompt_override = "Reach the Fallen Abbey"
	abbey.position = Vector3(18, 0.1, 14)
	interactables.add_child(abbey)
	for i in 3:
		var brazier := _QuestPoi.new()
		brazier.name = "AbbeyBrazier%d" % (i + 1)
		brazier.poi_id = "abbey_brazier_%d" % (i + 1)
		brazier.quest_id = "the_fallen_abbey"
		brazier.objective_id = "restore_braziers"
		brazier.speaker = "Purification Brazier"
		brazier.inspect_text = "You restore a purification brazier at the abbey."
		brazier.prompt_override = "Restore brazier"
		brazier.position = Vector3(17 + i, 0.1, 13 + i)
		interactables.add_child(brazier)
	var seal_poi := _QuestPoi.new()
	seal_poi.name = "BlightspireSealPoi"
	seal_poi.poi_id = "blightspire_seal_poi"
	seal_poi.quest_id = "the_fallen_abbey"
	seal_poi.objective_id = "recover_seal"
	seal_poi.speaker = "Blightspire Seal"
	seal_poi.inspect_text = "You recover the Blightspire seal from the abbey altar."
	seal_poi.prompt_override = "Recover seal"
	seal_poi.position = Vector3(19, 0.1, 15)
	interactables.add_child(seal_poi)
	if interactables.get_node_or_null("BlightspireCathedralEntrance") == null and ResourceLoader.exists(CATHEDRAL_SCENE):
		var cathedral := _spawn_prop_node(CATHEDRAL_SCENE, Vector3(22, 0, 18))
		if cathedral:
			cathedral.name = "BlightspireCathedralEntrance"
			interactables.add_child(cathedral)
	for i in 3:
		var growth := _CorruptionGrowth.new()
		growth.name = "CorruptionGrowth%d" % (i + 1)
		growth.position = Vector3(-11 + i * 2, 0, -7 + i)
		growth.quest_objective_id = "destroy_growths"
		interactables.add_child(growth)
	_spawn_resource(interactables, "blightwood", Vector3(-8, 0, 6), 2)
	_spawn_resource(interactables, "sporecap", Vector3(10, 0, 4), 2)
	_spawn_resource(interactables, "corrupted_fiber", Vector3(12, 0, -6), 2)
	_spawn_resource(interactables, "root_iron", Vector3(14, 0, 4), 1)
	_spawn_resource(interactables, "viridian_crystal", Vector3(16, 0, 6), 1, "", "blightreach:viridian_crystal_01", true)
	_spawn_resource(interactables, "purified_resin", Vector3(8, 0, -6), 1)
	_spawn_resource(interactables, "corrupted_roots", Vector3(10, 0, 2), 2, "", "blightreach:corrupted_root_01", true)
	_spawn_resource(interactables, "fungal_gland", Vector3(11, 0, 12), 1)
	_spawn_resource(interactables, "ancient_bark", Vector3(17, 0, 13), 1)
	if level.get_node_or_null("BlightSurgeController") == null:
		var surge := _BlightSurge.new()
		surge.name = "BlightSurgeController"
		level.add_child(surge)
	_spawn_blightreach_environment(level)


static func _spawn_blightreach_environment(level: Node3D) -> void:
	var env := level.get_node_or_null("Environment") as Node3D
	if env == null:
		env = level
	var zones := env.get_node_or_null("BlightreachEnvironmentZones") as Node3D
	if zones == null:
		zones = Node3D.new()
		zones.name = "BlightreachEnvironmentZones"
		env.add_child(zones)
	var shelter := _BlightShelter.new()
	shelter.name = "LastwallShelter"
	shelter.position = Vector3(0, 1, 0)
	var scol := CollisionShape3D.new()
	var sshape := BoxShape3D.new()
	sshape.size = Vector3(14, 4, 14)
	scol.shape = sshape
	shelter.add_child(scol)
	zones.add_child(shelter)
	for pos in [Vector3(-13, 0.05, -9), Vector3(15, 0.05, 7), Vector3(19, 0.05, 15)]:
		var blight := _BlightZone.new()
		blight.position = pos
		var bcol := CollisionShape3D.new()
		var bshape := BoxShape3D.new()
		bshape.size = Vector3(6, 2, 6)
		bcol.shape = bshape
		blight.add_child(bcol)
		zones.add_child(blight)
	for pos in [Vector3(9, 0.5, -5), Vector3(11, 0.5, 5), Vector3(13, 0.5, 8)]:
		var spore := _SporeCloud.new()
		spore.position = pos
		var spcol := CollisionShape3D.new()
		var spshape := SphereShape3D.new()
		spshape.radius = 3.5
		spcol.shape = spshape
		spore.add_child(spcol)
		zones.add_child(spore)
	for pos in [Vector3(-8, -0.1, 12), Vector3(16, -0.1, 2)]:
		var pool := _ToxicPool.new()
		pool.position = pos
		var pcol := CollisionShape3D.new()
		var pshape := BoxShape3D.new()
		pshape.size = Vector3(4, 0.5, 4)
		pcol.shape = pshape
		pool.add_child(pcol)
		zones.add_child(pool)


static func start_region_quests(region_id: String) -> void:
	match region_id:
		"hearthhold_camp":
			if "the_rot_below" not in QuestManager.completed_quests and not QuestManager.active_quests.has("the_rot_below"):
				if "find_wolf_crest" in QuestManager.completed_quests or WaystoneManager.hearthhold_unlocked:
					QuestManager.start_quest("the_rot_below")
		"rotfen_marsh":
			if QuestManager.completed_quests.has("into_rotfen"):
				if not QuestManager.active_quests.has("the_missing_caravan") and "the_missing_caravan" not in QuestManager.completed_quests:
					QuestManager.start_quest("the_missing_caravan")
				if not QuestManager.active_quests.has("gather_bog_herbs") and "gather_bog_herbs" not in QuestManager.completed_quests:
					QuestManager.start_quest("gather_bog_herbs")
				if not QuestManager.active_quests.has("destroy_corruption") and "destroy_corruption" not in QuestManager.completed_quests:
					QuestManager.start_quest("destroy_corruption")
				if not QuestManager.active_quests.has("rescue_trapped_scout") and "rescue_trapped_scout" not in QuestManager.completed_quests:
					QuestManager.start_quest("rescue_trapped_scout")
				if not QuestManager.active_quests.has("hunt_spore_brute") and "hunt_spore_brute" not in QuestManager.completed_quests:
					QuestManager.start_quest("hunt_spore_brute")
		"ashfall_highlands":
			if QuestManager.active_quests.has("through_the_ash"):
				QuestManager.advance_objective("through_the_ash", "enter_ashfall", 1)
				QuestManager.advance_objective("through_the_ash", "reach_stonewatch", 1)
			elif "through_the_ash" not in QuestManager.completed_quests and QuestManager.completed_quests.has("depths_of_reliquary"):
				QuestManager.start_quest("through_the_ash")
			if "the_broken_rail" not in QuestManager.completed_quests and not QuestManager.active_quests.has("the_broken_rail"):
				if "through_the_ash" in QuestManager.completed_quests:
					QuestManager.start_quest("the_broken_rail")
			if not QuestManager.active_quests.has("gather_cinder_ore") and "gather_cinder_ore" not in QuestManager.completed_quests:
				QuestManager.start_quest("gather_cinder_ore")
			if not QuestManager.active_quests.has("rescue_trapped_miners") and "rescue_trapped_miners" not in QuestManager.completed_quests:
				QuestManager.start_quest("rescue_trapped_miners")
			if not QuestManager.active_quests.has("clear_wolf_dens") and "clear_wolf_dens" not in QuestManager.completed_quests:
				QuestManager.start_quest("clear_wolf_dens")
			if not QuestManager.active_quests.has("recover_machine_parts") and "recover_machine_parts" not in QuestManager.completed_quests:
				QuestManager.start_quest("recover_machine_parts")
			if not QuestManager.active_quests.has("shut_down_vents") and "shut_down_vents" not in QuestManager.completed_quests:
				QuestManager.start_quest("shut_down_vents")
			if "through_the_ash" in QuestManager.completed_quests:
				if not QuestManager.active_quests.has("hunt_ironbound_elite") and "hunt_ironbound_elite" not in QuestManager.completed_quests:
					QuestManager.start_quest("hunt_ironbound_elite")
		"frostgrave_expanse":
			if QuestManager.active_quests.has("into_the_white"):
				QuestManager.advance_objective("into_the_white", "enter_frostgrave", 1)
				QuestManager.advance_objective("into_the_white", "reach_frostwatch", 1)
			elif "into_the_white" not in QuestManager.completed_quests and QuestManager.completed_quests.has("heart_of_blackvein"):
				QuestManager.start_quest("into_the_white")
			if not QuestManager.active_quests.has("gather_rime_ore") and "gather_rime_ore" not in QuestManager.completed_quests:
				QuestManager.start_quest("gather_rime_ore")
			if not QuestManager.active_quests.has("hunt_frostfang_packs") and "hunt_frostfang_packs" not in QuestManager.completed_quests:
				QuestManager.start_quest("hunt_frostfang_packs")
			if not QuestManager.active_quests.has("rescue_lost_hunter") and "rescue_lost_hunter" not in QuestManager.completed_quests:
				QuestManager.start_quest("rescue_lost_hunter")
			if not QuestManager.active_quests.has("destroy_black_ice") and "destroy_black_ice" not in QuestManager.completed_quests:
				QuestManager.start_quest("destroy_black_ice")
			if not QuestManager.active_quests.has("hunt_frostbound_giant") and "hunt_frostbound_giant" not in QuestManager.completed_quests:
				QuestManager.start_quest("hunt_frostbound_giant")
			if not QuestManager.active_quests.has("recover_supply_caches") and "recover_supply_caches" not in QuestManager.completed_quests:
				QuestManager.start_quest("recover_supply_caches")
		"shattered_coast":
			if QuestManager.active_quests.has("into_the_storm"):
				QuestManager.advance_objective("into_the_storm", "enter_coast", 1)
				QuestManager.advance_objective("into_the_storm", "reach_tidewatch", 1)
			elif "into_the_storm" not in QuestManager.completed_quests and "the_pale_heart" in QuestManager.completed_quests:
				QuestManager.start_quest("into_the_storm")
			if not QuestManager.active_quests.has("gather_stormglass") and "gather_stormglass" not in QuestManager.completed_quests:
				QuestManager.start_quest("gather_stormglass")
			if not QuestManager.active_quests.has("hunt_shellback_brutes") and "hunt_shellback_brutes" not in QuestManager.completed_quests:
				QuestManager.start_quest("hunt_shellback_brutes")
			if not QuestManager.active_quests.has("recover_lost_cargo") and "recover_lost_cargo" not in QuestManager.completed_quests:
				QuestManager.start_quest("recover_lost_cargo")
			if not QuestManager.active_quests.has("rescue_stranded_scout") and "rescue_stranded_scout" not in QuestManager.completed_quests:
				QuestManager.start_quest("rescue_stranded_scout")
			if not QuestManager.active_quests.has("destroy_storm_shrines") and "destroy_storm_shrines" not in QuestManager.completed_quests:
				QuestManager.start_quest("destroy_storm_shrines")
			if not QuestManager.active_quests.has("hunt_tidebound_colossus") and "hunt_tidebound_colossus" not in QuestManager.completed_quests:
				QuestManager.start_quest("hunt_tidebound_colossus")
			if not QuestManager.active_quests.has("recover_leviathan_bones") and "recover_leviathan_bones" not in QuestManager.completed_quests:
				QuestManager.start_quest("recover_leviathan_bones")
		"sunless_dominion":
			if QuestManager.active_quests.has("into_the_dominion"):
				QuestManager.advance_objective("into_the_dominion", "enter_sunless_dominion", 1)
				QuestManager.advance_objective("into_the_dominion", "reach_dawnwatch", 1)
			elif "into_the_dominion" not in QuestManager.completed_quests and "heart_of_the_wastes" in QuestManager.completed_quests:
				QuestManager.start_quest("into_the_dominion")
			if not QuestManager.active_quests.has("gather_moonstone") and "gather_moonstone" not in QuestManager.completed_quests:
				QuestManager.start_quest("gather_moonstone")
			if not QuestManager.active_quests.has("rescue_lost_patrol") and "rescue_lost_patrol" not in QuestManager.completed_quests:
				QuestManager.start_quest("rescue_lost_patrol")
			if not QuestManager.active_quests.has("destroy_gloom_hound_dens") and "destroy_gloom_hound_dens" not in QuestManager.completed_quests:
				QuestManager.start_quest("destroy_gloom_hound_dens")
			if not QuestManager.active_quests.has("recover_royal_relics") and "recover_royal_relics" not in QuestManager.completed_quests:
				QuestManager.start_quest("recover_royal_relics")
			if not QuestManager.active_quests.has("defeat_dominion_executioner") and "defeat_dominion_executioner" not in QuestManager.completed_quests:
				QuestManager.start_quest("defeat_dominion_executioner")
			if not QuestManager.active_quests.has("purify_shadow_wells") and "purify_shadow_wells" not in QuestManager.completed_quests:
				QuestManager.start_quest("purify_shadow_wells")
			if not QuestManager.active_quests.has("collect_nightglass") and "collect_nightglass" not in QuestManager.completed_quests:
				QuestManager.start_quest("collect_nightglass")
		"ember_wastes":
			if QuestManager.active_quests.has("into_the_ember"):
				QuestManager.advance_objective("into_the_ember", "enter_ember_wastes", 1)
				QuestManager.advance_objective("into_the_ember", "reach_cinderhold", 1)
			elif "into_the_ember" not in QuestManager.completed_quests and "heart_of_the_blight" in QuestManager.completed_quests:
				QuestManager.start_quest("into_the_ember")
			if not QuestManager.active_quests.has("the_dry_road") and "the_dry_road" not in QuestManager.completed_quests:
				if "into_the_ember" in QuestManager.completed_quests:
					QuestManager.start_quest("the_dry_road")
			if not QuestManager.active_quests.has("glass_beneath_the_sand") and "glass_beneath_the_sand" not in QuestManager.completed_quests:
				QuestManager.start_quest("glass_beneath_the_sand")
			if not QuestManager.active_quests.has("gather_scorched_sand") and "gather_scorched_sand" not in QuestManager.completed_quests:
				QuestManager.start_quest("gather_scorched_sand")
			if not QuestManager.active_quests.has("hunt_ashscale_packs") and "hunt_ashscale_packs" not in QuestManager.completed_quests:
				QuestManager.start_quest("hunt_ashscale_packs")
			if not QuestManager.active_quests.has("rescue_stranded_caravan") and "rescue_stranded_caravan" not in QuestManager.completed_quests:
				QuestManager.start_quest("rescue_stranded_caravan")
			if not QuestManager.active_quests.has("harvest_sunstone") and "harvest_sunstone" not in QuestManager.completed_quests:
				QuestManager.start_quest("harvest_sunstone")
			if not QuestManager.active_quests.has("defeat_sunscar_behemoth") and "defeat_sunscar_behemoth" not in QuestManager.completed_quests:
				QuestManager.start_quest("defeat_sunscar_behemoth")
		"blightreach":
			if QuestManager.active_quests.has("into_the_blight"):
				QuestManager.advance_objective("into_the_blight", "enter_blightreach", 1)
				QuestManager.advance_objective("into_the_blight", "reach_lastwall", 1)
			elif "into_the_blight" not in QuestManager.completed_quests and "the_sunken_crown" in QuestManager.completed_quests:
				QuestManager.start_quest("into_the_blight")
			if not QuestManager.active_quests.has("gather_sporecaps") and "gather_sporecaps" not in QuestManager.completed_quests:
				QuestManager.start_quest("gather_sporecaps")
			if not QuestManager.active_quests.has("rescue_infected_survivors") and "rescue_infected_survivors" not in QuestManager.completed_quests:
				QuestManager.start_quest("rescue_infected_survivors")
			if not QuestManager.active_quests.has("destroy_blight_hound_dens") and "destroy_blight_hound_dens" not in QuestManager.completed_quests:
				QuestManager.start_quest("destroy_blight_hound_dens")
			if not QuestManager.active_quests.has("recover_research_notes") and "recover_research_notes" not in QuestManager.completed_quests:
				QuestManager.start_quest("recover_research_notes")
			if not QuestManager.active_quests.has("defeat_root_titan") and "defeat_root_titan" not in QuestManager.completed_quests:
				QuestManager.start_quest("defeat_root_titan")
			if not QuestManager.active_quests.has("clear_corrupted_wells") and "clear_corrupted_wells" not in QuestManager.completed_quests:
				QuestManager.start_quest("clear_corrupted_wells")
			if not QuestManager.active_quests.has("harvest_viridian_crystal") and "harvest_viridian_crystal" not in QuestManager.completed_quests:
				QuestManager.start_quest("harvest_viridian_crystal")
		"ruined_watchtower":
			if "watchtower_sweep" not in QuestManager.completed_quests:
				QuestManager.start_quest("watchtower_sweep")
		"bandit_camp":
			if "raid_bandit_camp" not in QuestManager.completed_quests:
				QuestManager.start_quest("raid_bandit_camp")
		"crystal_cave":
			if "crystal_echoes" not in QuestManager.completed_quests:
				QuestManager.start_quest("crystal_echoes")
		"hollow_grove_shrine":
			if "defeat_warden" not in QuestManager.completed_quests and not QuestManager.active_quests.has("defeat_warden"):
				if "merchant_errand" in QuestManager.completed_quests:
					QuestManager.start_quest("defeat_warden")


static func on_enemy_killed(region_id: String, enemy_id: String) -> void:
	if region_id == "ruined_watchtower" and QuestManager.active_quests.has("watchtower_sweep"):
		QuestManager.advance_objective("watchtower_sweep", "clear_hostiles", 1)
	if region_id == "bandit_camp":
		if enemy_id == "bandit_captain" and QuestManager.active_quests.has("raid_bandit_camp"):
			QuestManager.advance_objective("raid_bandit_camp", "kill_captain", 1)
		elif QuestManager.active_quests.has("raid_bandit_camp"):
			QuestManager.advance_objective("raid_bandit_camp", "clear_camp", 1)
	NpcMissionHooks.on_enemy_killed(enemy_id)
	if region_id == "crystal_cave" and QuestManager.active_quests.has("crystal_echoes"):
		QuestManager.advance_objective("crystal_echoes", "clear_crystal", 1)
	if enemy_id == "hollow_grove_warden" and QuestManager.active_quests.has("defeat_warden"):
		QuestManager.advance_objective("defeat_warden", "kill_warden", 1)
		InventoryManager.add_item("grove_heart", 1)
	if region_id == "rotfen_marsh":
		if enemy_id in ["mire_hound", "bog_stalker"] and QuestManager.active_quests.has("the_missing_caravan"):
			QuestManager.advance_objective("the_missing_caravan", "defeat_hounds", 1)
		if enemy_id == "rotfen_cultist" and QuestManager.active_quests.has("the_sunken_bells"):
			QuestManager.advance_objective("the_sunken_bells", "defeat_cultists", 1)
			QuestManager.advance_objective("the_sunken_bells", "recover_seals", 1)
		if enemy_id == "spore_brute" and QuestManager.active_quests.has("hunt_spore_brute"):
			QuestManager.advance_objective("hunt_spore_brute", "kill_brute", 1)
	if region_id == "ashfall_highlands":
		if enemy_id in ["ash_raider", "ash_raider_archer"] and QuestManager.active_quests.has("the_broken_rail"):
			QuestManager.advance_objective("the_broken_rail", "defeat_raiders", 1)
		if enemy_id == "furnace_construct" and QuestManager.active_quests.has("fires_below"):
			QuestManager.advance_objective("fires_below", "defeat_construct", 1)
		if enemy_id == "ironbound_elite" and QuestManager.active_quests.has("hunt_ironbound_elite"):
			QuestManager.advance_objective("hunt_ironbound_elite", "slay_elite", 1)
	if region_id == "frostgrave_expanse":
		if enemy_id in ["rimebound_raider", "rimebound_archer"] and QuestManager.active_quests.has("the_buried_village"):
			QuestManager.advance_objective("the_buried_village", "defeat_raiders", 1)
		if enemy_id == "gravewind_wraith" and QuestManager.active_quests.has("gravewind_rising"):
			QuestManager.advance_objective("gravewind_rising", "defeat_wraiths", 1)
		if enemy_id == "frostfang_wolf" and QuestManager.active_quests.has("hunt_frostfang_packs"):
			QuestManager.advance_objective("hunt_frostfang_packs", "clear_packs", 1)
		if enemy_id == "frostbound_giant" and QuestManager.active_quests.has("hunt_frostbound_giant"):
			QuestManager.advance_objective("hunt_frostbound_giant", "slay_giant", 1)
	if region_id == "shattered_coast":
		if enemy_id in ["tide_reaver", "tide_reaver_archer", "tide_reaver_bomber"] and QuestManager.active_quests.has("wrecks_on_the_shore"):
			QuestManager.advance_objective("wrecks_on_the_shore", "defeat_reavers", 1)
		if enemy_id == "drowned_mariner" and QuestManager.active_quests.has("the_drowned_village"):
			QuestManager.advance_objective("the_drowned_village", "defeat_mariners", 1)
		if enemy_id in ["storm_wraith", "leviathan_cultist"] and QuestManager.active_quests.has("stormcallers"):
			QuestManager.advance_objective("stormcallers", "defeat_wraiths", 1)
		if enemy_id == "shellback_brute" and QuestManager.active_quests.has("hunt_shellback_brutes"):
			QuestManager.advance_objective("hunt_shellback_brutes", "slay_brutes", 1)
		if enemy_id == "tidebound_colossus" and QuestManager.active_quests.has("hunt_tidebound_colossus"):
			QuestManager.advance_objective("hunt_tidebound_colossus", "slay_colossus", 1)
	if region_id == "ember_wastes":
		if enemy_id == "ashscale_hound" and QuestManager.active_quests.has("hunt_ashscale_packs"):
			QuestManager.advance_objective("hunt_ashscale_packs", "clear_den", 1)
		if enemy_id in ["dune_raider", "dune_raider_archer", "dune_raider_bomber"] and QuestManager.active_quests.has("the_dry_road"):
			QuestManager.advance_objective("the_dry_road", "defeat_raiders", 1)
		if enemy_id == "glass_husk" and QuestManager.active_quests.has("glass_beneath_the_sand"):
			QuestManager.advance_objective("glass_beneath_the_sand", "defeat_glass_husks", 1)
		if enemy_id == "pyre_cultist" and QuestManager.active_quests.has("the_burning_obelisks"):
			QuestManager.advance_objective("the_burning_obelisks", "defeat_cultists", 1)
		if enemy_id == "sunscar_behemoth" and QuestManager.active_quests.has("defeat_sunscar_behemoth"):
			QuestManager.advance_objective("defeat_sunscar_behemoth", "slay_behemoth", 1)
	if region_id == "sunless_dominion":
		if enemy_id == "gloom_hound" and QuestManager.active_quests.has("destroy_gloom_hound_dens"):
			QuestManager.advance_objective("destroy_gloom_hound_dens", "clear_den", 1)
		if enemy_id in ["nightbound_raider", "nightbound_raider_archer", "nightbound_raider_bomber"] and QuestManager.active_quests.has("the_forsaken_hamlet"):
			QuestManager.advance_objective("the_forsaken_hamlet", "defeat_raiders", 1)
		if enemy_id == "grave_wraith" and QuestManager.active_quests.has("graves_without_rest"):
			QuestManager.advance_objective("graves_without_rest", "defeat_wraiths", 1)
		if enemy_id == "eclipse_cultist" and QuestManager.active_quests.has("the_dark_observatory"):
			QuestManager.advance_objective("the_dark_observatory", "defeat_cultists", 1)
		if enemy_id == "dominion_executioner" and QuestManager.active_quests.has("defeat_dominion_executioner"):
			QuestManager.advance_objective("defeat_dominion_executioner", "slay_executioner", 1)
	if region_id == "blightreach":
		if enemy_id == "blight_hound" and QuestManager.active_quests.has("destroy_blight_hound_dens"):
			QuestManager.advance_objective("destroy_blight_hound_dens", "clear_dens", 1)
		if enemy_id in ["rootbound_raider", "rootbound_archer", "rootbound_bomber"] and QuestManager.active_quests.has("the_withered_fields"):
			QuestManager.advance_objective("the_withered_fields", "defeat_raiders", 1)
		if enemy_id == "sporecaster" and QuestManager.active_quests.has("spores_in_the_wind"):
			QuestManager.advance_objective("spores_in_the_wind", "defeat_sporecasters", 1)
		if enemy_id == "corruption_wraith" and QuestManager.active_quests.has("the_fallen_abbey"):
			QuestManager.advance_objective("the_fallen_abbey", "defeat_wraiths", 1)
		if enemy_id == "root_titan" and QuestManager.active_quests.has("defeat_root_titan"):
			QuestManager.advance_objective("defeat_root_titan", "slay_titan", 1)


static func on_resource_gathered(resource_id: String) -> void:
	if resource_id == "bog_herb" and QuestManager.active_quests.has("gather_bog_herbs"):
		QuestManager.advance_objective("gather_bog_herbs", "collect_herbs", 1)
	if resource_id == "cinder_ore" and QuestManager.active_quests.has("gather_cinder_ore"):
		QuestManager.advance_objective("gather_cinder_ore", "collect_ore", 1)
	if resource_id == "rime_ore" and QuestManager.active_quests.has("gather_rime_ore"):
		QuestManager.advance_objective("gather_rime_ore", "collect_ore", 1)
	if resource_id == "black_ice" and QuestManager.active_quests.has("destroy_black_ice"):
		QuestManager.advance_objective("destroy_black_ice", "destroy_ice", 1)
	if resource_id == "stormglass" and QuestManager.active_quests.has("gather_stormglass"):
		QuestManager.advance_objective("gather_stormglass", "collect_glass", 1)
	if resource_id == "leviathan_bone" and QuestManager.active_quests.has("recover_leviathan_bones"):
		QuestManager.advance_objective("recover_leviathan_bones", "recover_bones", 1)
	if resource_id == "driftwood" and QuestManager.active_quests.has("recover_lost_cargo"):
		QuestManager.advance_objective("recover_lost_cargo", "recover_cargo", 1)
	if resource_id == "sporecap" and QuestManager.active_quests.has("gather_sporecaps"):
		QuestManager.advance_objective("gather_sporecaps", "collect_sporecaps", 1)
	if resource_id == "viridian_crystal" and QuestManager.active_quests.has("harvest_viridian_crystal"):
		QuestManager.advance_objective("harvest_viridian_crystal", "harvest_crystal", 1)
	if resource_id == "scorched_sand" and QuestManager.active_quests.has("gather_scorched_sand"):
		QuestManager.advance_objective("gather_scorched_sand", "collect_sand", 1)
	if resource_id == "sunstone_shard" and QuestManager.active_quests.has("harvest_sunstone"):
		QuestManager.advance_objective("harvest_sunstone", "harvest_shard", 1)
	if resource_id == "glass_fragment" and QuestManager.active_quests.has("glass_beneath_the_sand"):
		QuestManager.advance_objective("glass_beneath_the_sand", "recover_fragments", 1)
	if resource_id == "moonstone" and QuestManager.active_quests.has("gather_moonstone"):
		QuestManager.advance_objective("gather_moonstone", "collect_moonstone", 1)
	if resource_id == "nightglass" and QuestManager.active_quests.has("collect_nightglass"):
		QuestManager.advance_objective("collect_nightglass", "collect_nightglass", 1)


static func _region_id(level: Node3D) -> String:
	if level.has_method("_get_region_id"):
		return level._get_region_id()
	if "region_id" in level:
		return str(level.region_id)
	return GameManager.current_region_id


static func _ensure_node(level: Node3D, node_name: String) -> Node3D:
	var existing := level.get_node_or_null(node_name) as Node3D
	if existing:
		return existing
	var node := Node3D.new()
	node.name = node_name
	level.add_child(node)
	return node


static func _spawn_enemy(parent: Node3D, key: String, pos: Vector3) -> void:
	var path: String = ENEMY_SCENES.get(key, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var scene: PackedScene = load(path)
	var enemy: Node3D = scene.instantiate()
	enemy.global_position = pos
	parent.add_child(enemy)


static func _spawn_tutorial_bandit(parent: Node3D, pos: Vector3) -> void:
	var path: String = ENEMY_SCENES.get("forest_bandit", "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var scene: PackedScene = load(path)
	var enemy: Node3D = scene.instantiate()
	enemy.global_position = pos
	if enemy.get("max_health") != null:
		enemy.max_health = 35.0
	if enemy.get("damage") != null:
		enemy.damage = 5.0
	if enemy.get("enemy_level") != null:
		enemy.enemy_level = 1
	if enemy.get("display_name") != null:
		enemy.display_name = "Raider Trainee"
	if enemy.get("detection_range") != null:
		enemy.detection_range = 6.0
	parent.add_child(enemy)


static func _spawn_prop(parent: Node3D, scene_path: String, pos: Vector3) -> void:
	var node := _spawn_prop_node(scene_path, pos)
	if node:
		parent.add_child(node)


static func _spawn_prop_node(scene_path: String, pos: Vector3) -> Node3D:
	if not ResourceLoader.exists(scene_path):
		return null
	var scene: PackedScene = load(scene_path)
	var prop: Node3D = scene.instantiate()
	prop.global_position = pos
	return prop


static func _spawn_resource(
	parent: Node3D,
	resource_id: String,
	pos: Vector3,
	amount: int,
	tool: String = "",
	persistence_id: String = "",
	persist_depletion: bool = false,
	node_kind: String = ""
) -> void:
	var node := _ResourceNode.new()
	node.resource_id = resource_id
	node.yield_amount = amount
	node.requires_tool = tool
	node.persistence_id = persistence_id
	node.persist_depletion = persist_depletion
	if node_kind != "":
		node.node_kind = node_kind
	node.position = pos
	parent.add_child(node)


static func _spawn_destructible(parent: Node3D, drop_table_id: String, pos: Vector3, health: float = 28.0) -> void:
	var prop := _spawn_prop_node(CRATE_SCENE, pos)
	parent.add_child(prop)
	if prop == null:
		return
	if prop is DestructibleObject:
		var dest := prop as DestructibleObject
		dest.resource_id = ""
		dest.resource_yield = 0
		dest.drop_table_id = drop_table_id
		dest.health = health


static func _has_enemy_id(parent: Node3D, enemy_id: String) -> bool:
	for child in parent.get_children():
		if "enemy_id" in child and str(child.enemy_id) == enemy_id:
			return true
	return false
