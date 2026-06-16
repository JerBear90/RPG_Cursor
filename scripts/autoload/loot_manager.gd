extends Node
## Loot rolls and drop spawning.

const LOOT_PICKUP_SCENE := preload("res://scenes/pickups/loot_pickup.tscn")
const CURRENCY_PICKUP_SCENE := preload("res://scenes/pickups/currency_pickup.tscn")

var _pool: Array[Node] = []


func drop_loot_table(table_id: String, position: Vector3) -> void:
	var drops := _roll_table(table_id)
	for drop in drops:
		_spawn_drop(drop, position + Vector3(randf_range(-0.5, 0.5), 0.5, randf_range(-0.5, 0.5)))


func drop_item(item_id: String, position: Vector3, quantity: int = 1) -> void:
	_spawn_drop({"type": "item", "id": item_id, "quantity": quantity}, position)


func drop_currency(copper: int, position: Vector3) -> void:
	if copper <= 0:
		return
	_spawn_drop({"type": "currency", "copper": copper}, position)


func _roll_table(table_id: String) -> Array:
	match table_id:
		"forest_bandit":
			var drops: Array = []
			if randf() < 0.6:
				drops.append({"type": "item", "id": "cloth_scrap", "quantity": randi_range(1, 3)})
			if randf() < 0.3:
				drops.append({"type": "currency", "copper": randi_range(2, 8)})
			if randf() < 0.1:
				drops.append({"type": "item", "id": "iron_scrap", "quantity": 1})
			return drops
		"boss_warden":
			return [
				{"type": "currency", "copper": 200},
				{"type": "item", "id": "grove_heart", "quantity": 1},
				{"type": "item", "id": "epic_blade", "quantity": 1},
				{"type": "item", "id": "gem_amethyst", "quantity": 1},
			]
		"destructible_crate":
			var drops: Array = []
			drops.append({"type": "item", "id": "wood", "quantity": randi_range(1, 3)})
			if randf() < 0.45:
				drops.append({"type": "item", "id": "nails", "quantity": randi_range(0, 2)})
			if randf() < 0.35:
				drops.append({"type": "currency", "copper": randi_range(0, 8)})
			if randf() < 0.12:
				drops.append({"type": "item", "id": "dried_rations", "quantity": 1})
			if randf() < 0.04:
				drops.append({"type": "item", "id": _random_common_gem(), "quantity": 1})
			return drops
		"destructible_barrel":
			var barrel: Array = [{"type": "item", "id": "wood", "quantity": randi_range(1, 2)}]
			if randf() < 0.4:
				barrel.append({"type": "item", "id": "waterskin", "quantity": 1})
			if randf() < 0.35:
				barrel.append({"type": "item", "id": "cloth_scrap", "quantity": 1})
			if randf() < 0.3:
				barrel.append({"type": "currency", "copper": randi_range(0, 5)})
			return barrel
		"destructible_furniture":
			return [
				{"type": "item", "id": "wood", "quantity": randi_range(2, 4)},
				{"type": "item", "id": "cloth_scrap", "quantity": randi_range(0, 2)},
				{"type": "item", "id": "nails", "quantity": randi_range(0, 2)},
			]
		"destructible_scrap":
			var scrap: Array = [{"type": "item", "id": "iron_scrap", "quantity": randi_range(2, 4)}]
			if randf() < 0.4:
				scrap.append({"type": "item", "id": "wire", "quantity": randi_range(0, 2)})
			if randf() < 0.35:
				scrap.append({"type": "item", "id": "bolts", "quantity": randi_range(0, 3)})
			if randf() < 0.08:
				scrap.append({"type": "item", "id": "weapon_parts", "quantity": 1})
			return scrap
		"destructible_bone":
			var bone: Array = [{"type": "item", "id": "bone", "quantity": randi_range(1, 4)}]
			if randf() < 0.35:
				bone.append({"type": "item", "id": "hide", "quantity": 1})
			if randf() < 0.05:
				bone.append({"type": "item", "id": "charm_fragment", "quantity": 1})
			return bone
		"destructible_crystal":
			var crystal_drops: Array = [
				{"type": "item", "id": "crystal_shard", "quantity": randi_range(1, 3)},
				{"type": "item", "id": "crystal_dust", "quantity": randi_range(0, 1)},
			]
			if randf() < 0.12:
				crystal_drops.append({"type": "item", "id": _random_common_gem(), "quantity": 1})
			return crystal_drops
		"destructible_corrupted_root":
			var roots: Array = [{"type": "item", "id": "corrupted_roots", "quantity": randi_range(1, 3)}]
			if randf() < 0.25:
				roots.append({"type": "item", "id": "poison_gland", "quantity": 1})
			if randf() < 0.4:
				roots.append({"type": "item", "id": "fiber", "quantity": randi_range(0, 2)})
			return roots
		"destructible_rock":
			return [{"type": "item", "id": "stone", "quantity": randi_range(1, 3)}]
		"dungeon_boss":
			return [
				{"type": "currency", "copper": 120},
				{"type": "item", "id": "wolf_crest", "quantity": 1},
				{"type": "item", "id": "iron_scrap", "quantity": randi_range(2, 4)},
			]
		"dungeon_treasure":
			return [
				{"type": "currency", "copper": 80},
				{"type": "item", "id": "epic_blade", "quantity": 1},
				{"type": "item", "id": "cloth_scrap", "quantity": randi_range(3, 6)},
			]
		"drowned_bellkeeper":
			if ReliquaryState.boss_defeated_persistent:
				return [{"type": "currency", "copper": randi_range(5, 15)}]
			return [
				{"type": "currency", "copper": randi_range(80, 140)},
				{"type": "item", "id": "mire_crystal", "quantity": 2},
				{"type": "item", "id": "upgrade_material", "quantity": 1},
			]
		"bog_stalker":
			var stalker_drops: Array = [{"type": "currency", "copper": randi_range(3, 10)}]
			if randf() < 0.5:
				stalker_drops.append({"type": "item", "id": "poison_gland", "quantity": 1})
			if randf() < 0.35:
				stalker_drops.append({"type": "item", "id": "bog_herb", "quantity": randi_range(1, 2)})
			return stalker_drops
		"mire_hound":
			var hound_drops: Array = [{"type": "currency", "copper": randi_range(2, 8)}]
			if randf() < 0.4:
				hound_drops.append({"type": "item", "id": "cloth_scrap", "quantity": randi_range(1, 2)})
			return hound_drops
		"drowned_husk":
			var husk_drops: Array = [{"type": "currency", "copper": randi_range(8, 18)}]
			if randf() < 0.45:
				husk_drops.append({"type": "item", "id": "drowned_scrap", "quantity": randi_range(1, 2)})
			if randf() < 0.25:
				husk_drops.append({"type": "item", "id": "ancient_bone", "quantity": 1})
			return husk_drops
		"rotfen_cultist":
			var cult_drops: Array = [{"type": "currency", "copper": randi_range(6, 14)}]
			if randf() < 0.4:
				cult_drops.append({"type": "item", "id": "corrupted_fiber", "quantity": randi_range(1, 2)})
			return cult_drops
		"spore_brute":
			return [
				{"type": "currency", "copper": randi_range(40, 80)},
				{"type": "item", "id": "mire_crystal", "quantity": 1},
				{"type": "item", "id": "poison_gland", "quantity": randi_range(2, 3)},
			]
		"cinder_wolf":
			var wolf_drops: Array = [{"type": "currency", "copper": randi_range(4, 12)}]
			if randf() < 0.45:
				wolf_drops.append({"type": "item", "id": "burned_hide", "quantity": 1})
			if randf() < 0.25:
				wolf_drops.append({"type": "item", "id": "ashwood", "quantity": randi_range(1, 2)})
			return wolf_drops
		"ash_raider":
			var raider_drops: Array = [{"type": "currency", "copper": randi_range(6, 16)}]
			if randf() < 0.5:
				raider_drops.append({"type": "item", "id": "cloth_scrap", "quantity": randi_range(1, 2)})
			if randf() < 0.2:
				raider_drops.append({"type": "item", "id": "cinder_ore", "quantity": 1})
			return raider_drops
		"ash_raider_archer":
			var archer_drops: Array = [{"type": "currency", "copper": randi_range(5, 14)}]
			if randf() < 0.4:
				archer_drops.append({"type": "item", "id": "cloth_scrap", "quantity": 1})
			return archer_drops
		"furnace_construct":
			return [
				{"type": "currency", "copper": randi_range(25, 50)},
				{"type": "item", "id": "furnace_core", "quantity": 1},
				{"type": "item", "id": "machine_scrap", "quantity": randi_range(1, 2)},
			]
		"ash_wraith":
			return [
				{"type": "currency", "copper": randi_range(12, 28)},
				{"type": "item", "id": "ember_crystal", "quantity": randi_range(1, 2)},
			]
		"blackvein_miner":
			var miner_drops: Array = [{"type": "currency", "copper": randi_range(8, 18)}]
			if randf() < 0.55:
				miner_drops.append({"type": "item", "id": "cinder_ore", "quantity": randi_range(1, 2)})
			if randf() < 0.3:
				miner_drops.append({"type": "item", "id": "blackvein_iron", "quantity": 1})
			return miner_drops
		"ironbound_elite":
			return [
				{"type": "currency", "copper": randi_range(50, 90)},
				{"type": "item", "id": "blackvein_iron", "quantity": randi_range(2, 3)},
				{"type": "item", "id": "upgrade_material", "quantity": 1},
			]
		"iron_crucible":
			if FoundryState.boss_defeated_persistent:
				return [{"type": "currency", "copper": randi_range(10, 25)}]
			return [
				{"type": "currency", "copper": randi_range(120, 200)},
				{"type": "item", "id": "foundry_core", "quantity": 1},
				{"type": "item", "id": "frostgrave_pass", "quantity": 1},
				{"type": "item", "id": "blackvein_iron", "quantity": randi_range(3, 5)},
			]
		"frostfang_wolf":
			var wolf_drops: Array = [{"type": "currency", "copper": randi_range(4, 12)}]
			if randf() < 0.45:
				wolf_drops.append({"type": "item", "id": "frozen_hide", "quantity": 1})
			if randf() < 0.2:
				wolf_drops.append({"type": "item", "id": "frostwood", "quantity": randi_range(1, 2)})
			return wolf_drops
		"rimebound_raider", "rimebound_archer":
			var raider_drops: Array = [{"type": "currency", "copper": randi_range(6, 16)}]
			if randf() < 0.45:
				raider_drops.append({"type": "item", "id": "cloth_scrap", "quantity": randi_range(1, 2)})
			if randf() < 0.25:
				raider_drops.append({"type": "item", "id": "rime_ore", "quantity": 1})
			return raider_drops
		"frozen_husk":
			return [
				{"type": "currency", "copper": randi_range(10, 22)},
				{"type": "item", "id": "grave_dust", "quantity": randi_range(1, 2)},
			]
		"gravewind_wraith":
			return [
				{"type": "currency", "copper": randi_range(14, 30)},
				{"type": "item", "id": "grave_dust", "quantity": randi_range(1, 2)},
				{"type": "item", "id": "paleheart_shard", "quantity": 1},
			]
		"iceburrower":
			return [
				{"type": "currency", "copper": randi_range(8, 18)},
				{"type": "item", "id": "frozen_hide", "quantity": 1},
			]
		"frostbound_giant":
			return [
				{"type": "currency", "copper": randi_range(55, 95)},
				{"type": "item", "id": "glacial_crystal", "quantity": randi_range(2, 3)},
				{"type": "item", "id": "black_ice", "quantity": randi_range(1, 2)},
				{"type": "item", "id": "paleheart_shard", "quantity": 1},
			]
		"hollow_king":
			if CryptState.boss_defeated_persistent:
				return [{"type": "currency", "copper": randi_range(10, 25)}]
			return [
				{"type": "currency", "copper": randi_range(130, 210)},
				{"type": "item", "id": "paleheart_shard", "quantity": randi_range(2, 4)},
			]
		"saltfang_hound":
			var hound_drops: Array = [{"type": "currency", "copper": randi_range(5, 14)}]
			if randf() < 0.45:
				hound_drops.append({"type": "item", "id": "driftwood", "quantity": randi_range(1, 2)})
			if randf() < 0.25:
				hound_drops.append({"type": "item", "id": "salt_iron", "quantity": 1})
			return hound_drops
		"tide_reaver", "tide_reaver_bomber":
			var reaver_drops: Array = [{"type": "currency", "copper": randi_range(8, 18)}]
			if randf() < 0.45:
				reaver_drops.append({"type": "item", "id": "kelp_fiber", "quantity": randi_range(1, 2)})
			if randf() < 0.25:
				reaver_drops.append({"type": "item", "id": "salt_iron", "quantity": 1})
			return reaver_drops
		"tide_reaver_archer":
			var archer_drops: Array = [{"type": "currency", "copper": randi_range(7, 16)}]
			if randf() < 0.4:
				archer_drops.append({"type": "item", "id": "stormglass", "quantity": 1})
			if randf() < 0.2:
				archer_drops.append({"type": "item", "id": "kelp_fiber", "quantity": 1})
			return archer_drops
		"drowned_mariner":
			return [
				{"type": "currency", "copper": randi_range(12, 26)},
				{"type": "item", "id": "drowned_relic", "quantity": randi_range(1, 2)},
			]
		"storm_wraith":
			return [
				{"type": "currency", "copper": randi_range(14, 28)},
				{"type": "item", "id": "stormglass", "quantity": randi_range(1, 2)},
			]
		"shellback_brute":
			return [
				{"type": "currency", "copper": randi_range(50, 85)},
				{"type": "item", "id": "barnacle_plate", "quantity": randi_range(1, 2)},
				{"type": "item", "id": "leviathan_bone", "quantity": 1},
			]
		"leviathan_cultist":
			return [
				{"type": "currency", "copper": randi_range(18, 34)},
				{"type": "item", "id": "leviathan_bone", "quantity": randi_range(1, 2)},
				{"type": "item", "id": "abyssal_pearl", "quantity": 1},
			]
		"tidebound_colossus":
			return [
				{"type": "currency", "copper": randi_range(70, 110)},
				{"type": "item", "id": "abyssal_pearl", "quantity": randi_range(1, 2)},
				{"type": "item", "id": "barnacle_plate", "quantity": randi_range(1, 2)},
			]
		"tidebound_sovereign":
			if CitadelState.boss_defeated_persistent:
				return [{"type": "currency", "copper": randi_range(10, 25)}]
			return [
				{"type": "currency", "copper": randi_range(140, 220)},
				{"type": "item", "id": "stormglass", "quantity": randi_range(2, 4)},
				{"type": "item", "id": "abyssal_pearl", "quantity": 1},
			]
		"blight_hound":
			var hound: Array = [{"type": "currency", "copper": randi_range(5, 14)}]
			if randf() < 0.4:
				hound.append({"type": "item", "id": "corrupted_fiber", "quantity": 1})
			return hound
		"rootbound_raider", "rootbound_bomber":
			var raider: Array = [{"type": "currency", "copper": randi_range(8, 18)}]
			if randf() < 0.35:
				raider.append({"type": "item", "id": "blightwood", "quantity": randi_range(1, 2)})
			return raider
		"rootbound_archer":
			return [
				{"type": "currency", "copper": randi_range(7, 16)},
				{"type": "item", "id": "root_iron", "quantity": 1},
			]
		"fungal_husk":
			return [
				{"type": "currency", "copper": randi_range(14, 28)},
				{"type": "item", "id": "fungal_gland", "quantity": randi_range(1, 2)},
			]
		"sporecaster":
			return [
				{"type": "currency", "copper": randi_range(12, 24)},
				{"type": "item", "id": "sporecap", "quantity": randi_range(1, 2)},
			]
		"vine_stalker":
			return [
				{"type": "currency", "copper": randi_range(10, 22)},
				{"type": "item", "id": "corrupted_fiber", "quantity": randi_range(1, 2)},
			]
		"corruption_wraith":
			return [
				{"type": "currency", "copper": randi_range(16, 30)},
				{"type": "item", "id": "ancient_bark", "quantity": 1},
			]
		"root_titan":
			return [
				{"type": "currency", "copper": randi_range(80, 120)},
				{"type": "item", "id": "viridian_crystal", "quantity": randi_range(1, 2)},
				{"type": "item", "id": "purified_resin", "quantity": 1},
			]
		"blighted_cleric":
			return [
				{"type": "currency", "copper": randi_range(14, 26)},
				{"type": "item", "id": "sporecap", "quantity": randi_range(1, 2)},
			]
		"rootbound_cathedral_guard":
			return [
				{"type": "currency", "copper": randi_range(12, 24)},
				{"type": "item", "id": "root_iron", "quantity": randi_range(1, 2)},
			]
		"blightheart":
			if CathedralState.boss_defeated_persistent:
				return [{"type": "currency", "copper": randi_range(10, 25)}]
			return [
				{"type": "currency", "copper": randi_range(130, 210)},
				{"type": "item", "id": "viridian_crystal", "quantity": randi_range(1, 2)},
				{"type": "item", "id": "purified_resin", "quantity": randi_range(1, 2)},
			]
		"ashscale_hound":
			return [
				{"type": "currency", "copper": randi_range(8, 16)},
				{"type": "item", "id": "scorched_sand", "quantity": randi_range(1, 2)},
			]
		"dune_raider":
			return [
				{"type": "currency", "copper": randi_range(10, 20)},
				{"type": "item", "id": "pyre_dust", "quantity": randi_range(1, 2)},
			]
		"dune_raider_bomber":
			return [
				{"type": "currency", "copper": randi_range(10, 20)},
				{"type": "item", "id": "pyre_dust", "quantity": randi_range(1, 2)},
			]
		"glass_husk":
			return [
				{"type": "currency", "copper": randi_range(12, 22)},
				{"type": "item", "id": "glass_fragment", "quantity": randi_range(1, 2)},
			]
		"sand_wraith":
			return [
				{"type": "currency", "copper": randi_range(12, 24)},
				{"type": "item", "id": "pyre_dust", "quantity": 1},
			]
		"burrow_stalker":
			return [
				{"type": "currency", "copper": randi_range(14, 26)},
				{"type": "item", "id": "scorched_sand", "quantity": randi_range(1, 2)},
			]
		"pyre_cultist":
			return [
				{"type": "currency", "copper": randi_range(14, 26)},
				{"type": "item", "id": "pyre_dust", "quantity": randi_range(1, 2)},
			]
		"sunscar_behemoth":
			return [
				{"type": "currency", "copper": randi_range(80, 120)},
				{"type": "item", "id": "sunstone_shard", "quantity": randi_range(1, 2)},
				{"type": "item", "id": "glass_fragment", "quantity": 1},
			]
		"pyreheart_sigil":
			if PyreheartState.boss_defeated_persistent:
				return [{"type": "currency", "copper": randi_range(10, 25)}]
			return [
				{"type": "currency", "copper": randi_range(90, 140)},
				{"type": "item", "id": "sunstone_shard", "quantity": randi_range(1, 2)},
				{"type": "item", "id": "pyre_dust", "quantity": randi_range(1, 2)},
			]
		"solar_tyrant":
			if PyreheartState.boss_defeated_persistent:
				return [{"type": "currency", "copper": randi_range(10, 25)}]
			return [
				{"type": "currency", "copper": randi_range(130, 210)},
				{"type": "item", "id": "sunstone_shard", "quantity": randi_range(1, 2)},
				{"type": "item", "id": "desert_glass", "quantity": randi_range(1, 2)},
			]
		"gloom_hound":
			return [
				{"type": "currency", "copper": randi_range(10, 18)},
				{"type": "item", "id": "shadow_hide", "quantity": randi_range(1, 2)},
			]
		"nightbound_raider":
			return [
				{"type": "currency", "copper": randi_range(12, 22)},
				{"type": "item", "id": "grave_dust", "quantity": randi_range(1, 2)},
			]
		"hollow_knight":
			return [
				{"type": "currency", "copper": randi_range(18, 30)},
				{"type": "item", "id": "umbral_ore", "quantity": randi_range(1, 2)},
			]
		"eclipse_cultist":
			return [
				{"type": "currency", "copper": randi_range(14, 26)},
				{"type": "item", "id": "nightglass", "quantity": randi_range(1, 2)},
			]
		"grave_wraith":
			return [
				{"type": "currency", "copper": randi_range(14, 24)},
				{"type": "item", "id": "grave_dust", "quantity": randi_range(1, 2)},
			]
		"shadow_stalker":
			return [
				{"type": "currency", "copper": randi_range(12, 22)},
				{"type": "item", "id": "shadow_hide", "quantity": randi_range(1, 2)},
			]
		"dominion_executioner":
			return [
				{"type": "currency", "copper": randi_range(80, 120)},
				{"type": "item", "id": "umbral_ore", "quantity": randi_range(1, 2)},
				{"type": "item", "id": "moonstone", "quantity": 1},
			]
		_:
			return [{"type": "currency", "copper": randi_range(1, 5)}]


func _random_common_gem() -> String:
	return GemEffectManager.random_common_gem_id()


func _spawn_drop(drop: Dictionary, position: Vector3) -> void:
	var scene: PackedScene
	if drop.type == "currency":
		scene = CURRENCY_PICKUP_SCENE
	else:
		scene = LOOT_PICKUP_SCENE
	var pickup := scene.instantiate() as Node3D
	pickup.global_position = position
	if pickup.has_method("setup"):
		pickup.setup(drop)
	var parent := get_tree().current_scene
	if parent:
		parent.add_child(pickup)
