extends Node
## Item metadata for use, equip, and combat bonuses.

const ITEMS: Dictionary = {
	"dried_rations": {"type": "consumable", "use": "eat", "amount": 35.0, "label": "Eat"},
	"waterskin": {"type": "consumable", "use": "drink", "amount": 30.0, "label": "Drink"},
	"purified_water": {"type": "consumable", "use": "drink", "amount": 50.0, "label": "Drink"},
	"bandage": {"type": "consumable", "use": "heal", "amount": 25.0, "label": "Use"},
	"herb_bundle": {"type": "consumable", "use": "heal", "amount": 15.0, "label": "Use"},
	"rusty_sword": {"type": "weapon", "slot": "main_weapon", "damage": 12.0, "rarity": "common", "max_sockets": 1, "max_durability": 50.0, "label": "Equip"},
	"iron_sword": {"type": "weapon", "slot": "main_weapon", "damage": 22.0, "rarity": "uncommon", "label": "Equip"},
	"epic_blade": {"type": "weapon", "slot": "main_weapon", "damage": 35.0, "rarity": "rare", "label": "Equip"},
	"traveler_cloak": {"type": "armor", "slot": "chest", "health": 10.0, "rarity": "common", "max_sockets": 1, "label": "Equip"},
	"wolf_crest": {"type": "quest", "label": "Quest item"},
	"wood": {"type": "material"},
	"stone": {"type": "material"},
	"cloth_scrap": {"type": "material"},
	"iron_scrap": {"type": "material"},
	"nails": {"type": "material"},
	"grove_heart": {"type": "material"},
	"repair_kit": {"type": "consumable", "use": "repair_kit", "amount": 35.0, "label": "Use"},
	"bogward_tonic": {"type": "consumable", "use": "antidote", "amount": 20.0, "label": "Use"},
	"torch": {"type": "consumable", "use": "heal", "amount": 5.0, "label": "Use"},
	"leather_armor": {"type": "armor", "slot": "chest", "health": 18.0, "rarity": "common", "max_sockets": 1, "label": "Equip"},
	"wooden_shield": {"type": "armor", "slot": "off_hand", "health": 8.0, "block_bonus": 0.08, "rarity": "common", "max_sockets": 1, "label": "Equip"},
	"steel_dagger": {"type": "weapon", "slot": "main_weapon", "damage": 16.0, "rarity": "common", "label": "Equip"},
	"upgrade_material": {"type": "material"},
	"bog_herb": {"type": "material"},
	"rotwood": {"type": "material"},
	"poison_gland": {"type": "material"},
	"corrupted_fiber": {"type": "material"},
	"swamp_iron": {"type": "material"},
	"mire_crystal": {"type": "material"},
	"drowned_scrap": {"type": "material"},
	"ancient_bone": {"type": "material"},
	"caravan_ledger": {"type": "quest", "label": "Quest item"},
	"reliquary_seal": {"type": "quest", "label": "Quest item"},
	"marsh_sigil": {"type": "quest", "label": "Quest item"},
	"cinder_ore": {"type": "material"},
	"ashwood": {"type": "material"},
	"blackvein_iron": {"type": "material"},
	"machine_scrap": {"type": "material"},
	"ember_crystal": {"type": "material"},
	"volcanic_glass": {"type": "material"},
	"furnace_core": {"type": "material"},
	"burned_hide": {"type": "material"},
	"blackvein_access_key": {"type": "quest", "label": "Quest item"},
	"foundry_core": {"type": "quest", "label": "Quest item"},
	"frostgrave_pass": {"type": "quest", "label": "Quest item"},
	"heat_resistance_tonic": {"type": "consumable", "use": "heat_resist", "amount": 15.0, "label": "Use"},
	"crucible_hammer": {"type": "weapon", "slot": "main_weapon", "damage": 42.0, "rarity": "epic", "label": "Equip"},
	"ash_filter_mask": {"type": "consumable", "use": "heat_resist", "amount": 10.0, "label": "Use"},
	"frostwood": {"type": "material"},
	"rime_ore": {"type": "material"},
	"black_ice": {"type": "material"},
	"glacial_crystal": {"type": "material"},
	"frozen_hide": {"type": "material"},
	"grave_dust": {"type": "material"},
	"paleheart_shard": {"type": "material"},
	"paleheart_access_key": {"type": "quest", "label": "Quest item"},
	"paleheart_relic": {"type": "quest", "label": "Quest item"},
	"shattered_coast_pass": {"type": "quest", "label": "Quest item"},
	"warming_tonic": {"type": "consumable", "use": "cold_resist", "amount": 15.0, "label": "Use"},
	"hollow_king_blade": {"type": "weapon", "slot": "main_weapon", "damage": 44.0, "rarity": "epic", "label": "Equip"},
	"gravewind_charm": {"type": "armor", "slot": "off_hand", "health": 14.0, "label": "Equip"},
	"frostguard_armor": {"type": "armor", "slot": "chest", "health": 24.0, "rarity": "rare", "label": "Equip"},
	"driftwood": {"type": "material"},
	"salt_iron": {"type": "material"},
	"stormglass": {"type": "material"},
	"abyssal_pearl": {"type": "material"},
	"kelp_fiber": {"type": "material"},
	"barnacle_plate": {"type": "material"},
	"drowned_relic": {"type": "material"},
	"leviathan_bone": {"type": "material"},
	"tidebound_crown": {"type": "quest", "label": "Quest item"},
	"storm_resistance_tonic": {"type": "consumable", "use": "storm_resist", "amount": 15.0, "label": "Use"},
	"stormwake_charm": {"type": "armor", "slot": "off_hand", "health": 14.0, "label": "Equip"},
	"sovereign_trident": {"type": "weapon", "slot": "main_weapon", "damage": 46.0, "rarity": "epic", "label": "Equip"},
	"tideguard_armor": {"type": "armor", "slot": "chest", "health": 26.0, "rarity": "rare", "label": "Equip"},
	"crown_of_the_deep": {"type": "armor", "slot": "head", "health": 12.0, "label": "Equip"},
	"blightwood": {"type": "material"},
	"sporecap": {"type": "material"},
	"purified_resin": {"type": "material"},
	"root_iron": {"type": "material"},
	"viridian_crystal": {"type": "material"},
	"fungal_gland": {"type": "material"},
	"ancient_bark": {"type": "material"},
	"blightspire_seal": {"type": "quest", "label": "Quest item"},
	"blight_resistance_tonic": {"type": "consumable", "use": "blight_resist", "amount": 15.0, "label": "Use"},
	"spore_filter": {"type": "consumable", "use": "spore_resist", "amount": 15.0, "label": "Use"},
	"cleansing_salve": {"type": "consumable", "use": "heal", "amount": 20.0, "label": "Use"},
	"spore_antidote": {"type": "consumable", "use": "heal", "amount": 18.0, "label": "Use"},
	"corruption_cleanse": {"type": "consumable", "use": "heal", "amount": 25.0, "label": "Use"},
	"regeneration_salve": {"type": "consumable", "use": "heal", "amount": 30.0, "label": "Use"},
	"ember_wastes_pass": {"type": "quest", "label": "Quest item"},
	"blightheart_core": {"type": "quest", "label": "Quest item"},
	"purifiers_thorn": {"type": "weapon", "slot": "main_hand", "damage": 22.0, "label": "Equip"},
	"scorched_sand": {"type": "material"},
	"sunstone_shard": {"type": "material"},
	"glass_fragment": {"type": "material"},
	"pyre_dust": {"type": "material"},
	"cactus_fiber": {"type": "material"},
	"ancient_obelisk_fragment": {"type": "quest", "label": "Quest item"},
	"pyreheart_sigil": {"type": "quest", "label": "Quest item"},
	"hydration_salts": {"type": "consumable", "use": "drink", "amount": 40.0, "label": "Use"},
	"cooling_salve": {"type": "consumable", "use": "heat_resist", "amount": 18.0, "label": "Use"},
	"burn_salve": {"type": "consumable", "use": "heal", "amount": 22.0, "label": "Use"},
	"sand_lung_remedy": {"type": "consumable", "use": "heal", "amount": 20.0, "label": "Use"},
	"desert_glass": {"type": "material"},
	"pyre_crystal": {"type": "material"},
	"solar_heart_core": {"type": "quest", "label": "Quest item"},
	"sunless_dominion_pass": {"type": "quest", "label": "Quest item"},
	"sunforged_halo": {"type": "armor", "slot": "head", "health": 16.0, "label": "Equip"},
	"silverwood": {"type": "material"},
	"umbral_ore": {"type": "material"},
	"moonstone": {"type": "material"},
	"nightglass": {"type": "material"},
	"eclipse_shard": {"type": "quest", "label": "Quest item"},
	"shadow_hide": {"type": "material"},
	"royal_relic": {"type": "quest", "label": "Quest item"},
	"sanctum_sigil": {"type": "quest", "label": "Quest item"},
	"dread_resistance_tonic": {"type": "consumable", "use": "dread_resist", "amount": 15.0, "label": "Use"},
	"shadow_cleanse": {"type": "consumable", "use": "shadow_cleanse", "amount": 20.0, "label": "Use"},
	"ward_candle": {"type": "material"},
	"lantern_oil": {"type": "consumable", "use": "dread_resist", "amount": 10.0, "label": "Use"},
	"fiber": {"type": "material"},
	"berries": {"type": "material"},
	"mushrooms": {"type": "material"},
	"hide": {"type": "material"},
	"bone": {"type": "material"},
	"raw_meat": {"type": "material"},
	"cooked_meat": {"type": "consumable", "use": "eat", "amount": 40.0, "label": "Eat"},
	"dirty_water": {"type": "material"},
	"wire": {"type": "material"},
	"bolts": {"type": "material"},
	"rope": {"type": "material"},
	"leather_strips": {"type": "material"},
	"broken_blade": {"type": "material"},
	"weapon_parts": {"type": "material"},
	"armor_plates": {"type": "material"},
	"oil": {"type": "material"},
	"gears": {"type": "material"},
	"crystal_shard": {"type": "material"},
	"crystal_dust": {"type": "material"},
	"fire_resin": {"type": "material"},
	"corrupted_roots": {"type": "material"},
	"charcoal": {"type": "material"},
	"firewood": {"type": "material"},
	"seeds": {"type": "material"},
	"charm_fragment": {"type": "material"},
	"silver_ore": {"type": "material"},
	"fire_coating": {"type": "consumable", "use": "heat_resist", "amount": 12.0, "label": "Use"},
	"pet_treat": {"type": "consumable", "use": "eat", "amount": 10.0, "label": "Use"},
	"ash_collar": {"type": "pet_gear", "slot": "collar", "pet_hp_bonus": 10.0},
	"bone_charm": {"type": "pet_gear", "slot": "charm", "pet_damage_bonus": 1.0},
	"small_pack": {"type": "pet_gear", "slot": "pack", "resource_discovery_bonus": 0.05},
	"weapon_upgrade_kit": {"type": "consumable", "use": "weapon_upgrade_kit", "amount": 0.0, "label": "Use"},
	"armor_reinforcement_kit": {"type": "consumable", "use": "armor_reinforcement_kit", "amount": 0.0, "label": "Use"},
	"gem_ruby": {
		"type": "gem", "gem_id": "ruby", "display_name": "Ruby", "rarity": "uncommon", "gem_color": "#cc3344",
		"sell_value": 40, "allowed_gear_types": ["weapon", "armor"], "allow_shield": true,
		"effects": {
			"weapon": {"flat_damage": 2.0, "fire_damage": 2.0, "description": "+2 Fire Damage"},
			"armor": {"armor_hp": 2.0, "fire_resist": 0.08, "description": "+8% Fire Resistance"},
			"shield": {"block_bonus": 0.03, "fire_resist": 0.06, "description": "+Fire Block Resistance"},
		},
	},
	"gem_sapphire": {
		"type": "gem", "gem_id": "sapphire", "display_name": "Sapphire", "rarity": "uncommon", "gem_color": "#3366cc",
		"sell_value": 40, "allowed_gear_types": ["weapon", "armor"], "allow_shield": true,
		"effects": {
			"weapon": {"flat_damage": 1.0, "description": "+1 Damage"},
			"armor": {"stamina_recovery": 0.05, "water_resist": 0.08, "description": "+5% Stamina Recovery"},
			"shield": {"block_stamina_efficiency": 0.1, "description": "+10% Block Stamina Efficiency"},
		},
	},
	"gem_emerald": {
		"type": "gem", "gem_id": "emerald", "display_name": "Emerald", "rarity": "uncommon", "gem_color": "#33aa55",
		"sell_value": 40, "allowed_gear_types": ["weapon", "armor"], "allow_shield": true,
		"effects": {
			"weapon": {"poison_damage": 2.0, "description": "+2 Poison Damage"},
			"armor": {"poison_resist": 0.08, "description": "+8% Poison Resistance"},
			"utility": {"resource_discovery_bonus": 0.05, "description": "+5% Resource Discovery"},
		},
	},
	"gem_onyx": {
		"type": "gem", "gem_id": "onyx", "display_name": "Onyx", "rarity": "uncommon", "gem_color": "#443355",
		"sell_value": 45, "allowed_gear_types": ["weapon", "armor"], "allow_shield": true,
		"effects": {
			"weapon": {"dark_damage": 2.0, "life_siphon": 1.0, "description": "+2 Dark Damage, +1 Life Siphon"},
			"armor": {"dark_resist": 0.08, "description": "+8% Dark Resistance"},
			"shield": {"stagger_resist": 0.06, "description": "+6% Stagger Resistance"},
		},
	},
	"gem_topaz": {
		"type": "gem", "gem_id": "topaz", "display_name": "Topaz", "rarity": "common", "gem_color": "#ccaa33",
		"sell_value": 30, "allowed_gear_types": ["weapon", "armor"], "allow_shield": true,
		"effects": {
			"weapon": {"currency_gain_bonus": 0.05, "description": "+5% Currency Drops"},
			"armor": {"item_discovery_bonus": 0.05, "description": "+5% Item Discovery"},
			"utility": {"rare_resource_chance": 0.03, "description": "+3% Rare Resource Chance"},
		},
	},
	"gem_amethyst": {
		"type": "gem", "gem_id": "amethyst", "display_name": "Amethyst", "rarity": "rare", "gem_color": "#8844cc",
		"sell_value": 55, "allowed_gear_types": ["weapon", "armor"], "allow_shield": true,
		"effects": {
			"weapon": {"spell_power": 3.0, "description": "+3 Spell Power"},
			"armor": {"focus_max": 5.0, "description": "+5 Focus Max"},
			"shield": {"focus_regen": 0.05, "description": "+5% Focus Regen"},
		},
	},
	"gem_diamond": {
		"type": "gem", "gem_id": "diamond", "display_name": "Diamond", "rarity": "rare", "gem_color": "#ddeeff",
		"sell_value": 60, "allowed_gear_types": ["weapon", "armor"], "allow_shield": true,
		"effects": {
			"weapon": {"durability_bonus": 8.0, "description": "+8 Max Durability"},
			"armor": {"armor_hp": 4.0, "defense_bonus": 0.08, "description": "+8% Defense"},
			"shield": {"block_bonus": 0.05, "durability_bonus": 8.0, "description": "+5% Block Strength"},
		},
	},
	"gem_garnet": {
		"type": "gem", "gem_id": "garnet", "display_name": "Garnet", "rarity": "uncommon", "gem_color": "#992233",
		"sell_value": 42, "allowed_gear_types": ["weapon", "armor"], "allow_shield": true,
		"effects": {
			"weapon": {"crit_chance": 0.03, "bleed_damage": 1.0, "description": "+3% Crit, +1 Bleed"},
			"armor": {"armor_hp": 3.0, "description": "+3 Armor HP"},
			"utility": {"execution_bonus": 0.05, "description": "+5% Execution Bonus"},
		},
	},
}

const DESCRIPTIONS: Dictionary = {
	"dried_rations": "Restores hunger. Field staple for long marches.",
	"waterskin": "Restores thirst. Refill at camp or streams.",
	"purified_water": "Clean water. Restores thirst efficiently.",
	"bandage": "Restores 25 health. Basic wound care.",
	"herb_bundle": "Restores 15 health. Used in quests and crafting.",
	"rusty_sword": "A worn blade. Better than bare hands.",
	"iron_sword": "Reliable steel for seasoned exiles.",
	"epic_blade": "Rare edge humming with old power.",
	"traveler_cloak": "Light armor. +10 max health.",
	"wood": "Crafting material.",
	"stone": "Crafting material.",
	"cloth_scrap": "Salvaged fabric for patches and trade.",
	"iron_scrap": "Salvaged metal for forging.",
	"repair_kit": "Restores gear durability. Targets first damaged equipped item.",
	"bogward_tonic": "Marsh antidote. Restores health and resists poison.",
	"torch": "Portable light source.",
	"leather_armor": "Light armor. +18 max health.",
	"wooden_shield": "Basic shield. +8 max health.",
	"steel_dagger": "Quick blade for close work.",
	"bog_herb": "Rotfen marsh herb used in tonics.",
	"caravan_ledger": "Quest record from the lost caravan.",
	"reliquary_seal": "Seal from a sunken shrine.",
	"wolf_crest": "Quest relic. Cannot be sold.",
	"blackvein_access_key": "Opens the Blackvein Foundry exterior gates.",
	"foundry_core": "Heart of the corrupted foundry. Unlocks the path to Frostgrave.",
	"frostgrave_pass": "Signed writ allowing travel beyond Ashfall.",
	"heat_resistance_tonic": "Ashfall tonic. Restores health and resists heat buildup.",
	"crucible_hammer": "Forged from the Iron Crucible's core. Heavy fire-touched steel.",
	"ash_filter_mask": "Filters volcanic ash during storms.",
	"frostwood": "Frozen timber from dead Frostgrave forests.",
	"rime_ore": "Ore veined with rime frost. Used in cold-forged gear.",
	"black_ice": "Corrupted ice that never melts. Handle with care.",
	"glacial_crystal": "Clear crystal from shattered glaciers.",
	"frozen_hide": "Hide stripped from frost beasts.",
	"grave_dust": "Ash from disturbed burial sites.",
	"paleheart_shard": "Fragment of pale magical ice from Paleheart.",
	"paleheart_access_key": "Ritual key that unlocks Paleheart Crypt.",
	"paleheart_relic": "Heart of the Hollow King. Opens the road to the Shattered Coast.",
	"shattered_coast_pass": "Writ of passage beyond Frostgrave.",
	"warming_tonic": "Frostgrave tonic. Restores health and resists cold buildup.",
	"hollow_king_blade": "Blade tempered in gravewind frost.",
	"gravewind_charm": "Wards against frostbite. +14 max health.",
	"frostguard_armor": "Cold-forged plate. +24 max health.",
	"driftwood": "Salt-warped timber washed ashore on the Shattered Coast.",
	"salt_iron": "Corroded iron salvaged from drowned wrecks.",
	"stormglass": "Glass fused by lightning strikes along the coast.",
	"abyssal_pearl": "Luminous pearl dredged from deep citadel waters.",
	"kelp_fiber": "Tough coastal kelp used in rope and padding.",
	"barnacle_plate": "Dense shell plate harvested from shellback brutes.",
	"drowned_relic": "Relic from mariners lost to the drowned citadel.",
	"leviathan_bone": "Bone fragment touched by leviathan cult rites.",
	"tidebound_crown": "Crown of the Tidebound Sovereign. Opens the road to Blightreach.",
	"storm_resistance_tonic": "Coastal tonic. Restores health and resists storm buildup.",
	"stormwake_charm": "Wards against coastal storms. +14 max health.",
	"sovereign_trident": "Trident of the Tidebound Sovereign. Storm-touched steel.",
	"tideguard_armor": "Salt-forged plate. +26 max health.",
	"crown_of_the_deep": "Ceremonial crown of drowned kings. +12 max health.",
	"blightwood": "Timber warped by corruption. Used in blight-resistant gear.",
	"sporecap": "Fungal cap harvested from spore zones.",
	"corrupted_fiber": "Vine fiber soaked in blight residue.",
	"purified_resin": "Resin cleansed at Lastwall braziers.",
	"root_iron": "Iron ore entangled in living roots.",
	"viridian_crystal": "Sickly green crystal from corruption basins.",
	"fungal_gland": "Gland from fungal husks. Used in antidotes.",
	"ancient_bark": "Bark from pre-blight trees near the abbey.",
	"blightspire_seal": "Seal recovered from the Fallen Abbey. Opens Blightspire Cathedral.",
	"blight_resistance_tonic": "Lastwall tonic. Restores health and resists blight buildup.",
	"spore_filter": "Filters airborne spores during blight surges.",
	"cleansing_salve": "Clears minor blight exposure and restores health.",
	"spore_antidote": "Counters spore infection effects.",
	"corruption_cleanse": "Purges corruption buildup from sustained exposure.",
	"regeneration_salve": "Accelerates recovery from blight ailments.",
	"ember_wastes_pass": "Writ granting passage toward the Ember Wastes beyond Blightreach.",
	"blightheart_core": "Living corruption core of The Blightheart. Proof the cathedral's heart is stilled.",
	"purifiers_thorn": "Thorned relic tempered in purification fire. Cuts through blight-touched flesh.",
	"scorched_sand": "Sun-baked sand from the Ember Wastes. Used in desert crafting.",
	"sunstone_shard": "Crystallized solar heat trapped in desert stone.",
	"glass_fragment": "Volcanic glass shard buried beneath the wastes.",
	"pyre_dust": "Fine ash dust from pyre cult rituals.",
	"cactus_fiber": "Dried fiber from desert succulents. Restores hydration when processed.",
	"ancient_obelisk_fragment": "Fragment from a burning obelisk. Unlocks the Pyreheart Ziggurat.",
	"pyreheart_sigil": "Sigil of the cooled solar heart. Proof the ziggurat's heart is claimed.",
	"hydration_salts": "Mineral salts that restore thirst and ease dehydration.",
	"cooling_salve": "Desert salve that eases heat buildup and restores health.",
	"burn_salve": "Soothes burning wounds from pyre cultists and glass eruptions.",
	"sand_lung_remedy": "Clears sand-lung affliction from prolonged sandstorm exposure.",
	"desert_glass": "Tempered volcanic glass from the Ember Wastes. Used in sun-forged gear.",
	"pyre_crystal": "Crystallized solar heat from Pyreheart. Used in desert armaments.",
	"solar_heart_core": "Cooled core of the Solar Heart. Proof The Solar Tyrant is defeated.",
	"sunless_dominion_pass": "Writ granting passage toward the Sunless Dominion beyond the dunes.",
	"sunforged_halo": "Halo tempered in the Solar Heart's cooling channels. +16 max health.",
	"silverwood": "Pale wood from the Sunless Dominion. Used in ward crafting.",
	"umbral_ore": "Ore steeped in perpetual twilight. Used in nightsmith gear.",
	"moonstone": "Crystallized moonlight trapped in dominion stone.",
	"nightglass": "Obsidian glass formed near the Dark Observatory.",
	"eclipse_shard": "Shard from the Dark Observatory. Unlocks Eclipse Sanctum.",
	"shadow_hide": "Tanned hide from shadow beasts. Used in dominion armor.",
	"royal_relic": "Relic from the forsaken hamlet's royal line.",
	"sanctum_sigil": "Sigil earned at the sealed eclipse throne antechamber.",
	"dread_resistance_tonic": "Dawnwatch tonic that eases dread buildup and restores health.",
	"shadow_cleanse": "Clears shadow exposure and umbral sickness.",
	"ward_candle": "Warded candle that steadies light against dominion dread.",
	"lantern_oil": "Lantern oil that briefly resists dread in open shadow.",
	"fiber": "Plant fiber for rope, padding, and garden plots.",
	"berries": "Foraged berries. Used in pet treats and rations.",
	"hide": "Salvaged hide for armor reinforcement.",
	"bone": "Bone fragments for crafting and shelter builds.",
	"raw_meat": "Uncooked meat. Cook before eating.",
	"cooked_meat": "Cooked meat. Restores hunger.",
	"dirty_water": "Unsafe water. Purify before drinking.",
	"wire": "Salvaged wire for repairs and upgrades.",
	"bolts": "Metal bolts from scrap piles.",
	"oil": "Machine oil for repair kits and coatings.",
	"weapon_parts": "Rare weapon components for upgrades.",
	"armor_plates": "Salvaged armor plates for reinforcement.",
	"crystal_shard": "Crystal shards from broken clusters.",
	"crystal_dust": "Fine crystal dust for crafting.",
	"fire_resin": "Sticky resin used in forge upgrades and coatings.",
	"corrupted_roots": "Twisted roots from corrupted growth.",
	"fire_coating": "Fire-resistant coating for gear.",
	"pet_treat": "Treat for bonded beasts.",
	"ash_collar": "Pet collar. +10 pet max HP.",
	"bone_charm": "Pet charm. +1 pet damage.",
	"small_pack": "Pet pack. +resource find (display).",
	"weapon_upgrade_kit": "Upgrade kit for weapons (+1 damage tier).",
	"armor_reinforcement_kit": "Reinforcement kit for armor (+1 defense tier).",
	"gem_ruby": "Fire gem. Attack and burn power.",
	"gem_sapphire": "Water gem. Stamina and recovery.",
	"gem_emerald": "Poison gem. Resource discovery.",
	"gem_onyx": "Dark gem. Life drain and fear ward.",
	"gem_topaz": "Loot gem. Currency and item discovery.",
	"gem_amethyst": "Focus gem. Spell power and cooldown support.",
	"gem_diamond": "Defense gem. Durability and protection.",
	"gem_garnet": "Crit gem. Bleed and execution power.",
	"silver_ore": "Silver ore for advanced forge work.",
	"seeds": "Seeds for garden plots.",
	"rope": "Rope for camp builds and collectors.",
	"charcoal": "Charcoal for purification and cooking.",
	"firewood": "Dry firewood for camp cooking.",
	"charm_fragment": "Fragment of a ward charm.",
}


static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})


static func can_use(item_id: String) -> bool:
	var data := get_item(item_id)
	return data.get("type") == "consumable" and data.has("use")


static func can_equip(item_id: String) -> bool:
	var data := get_item(item_id)
	return data.get("type") in ["weapon", "armor"]


static func get_weapon_damage(item_id: String) -> float:
	return float(get_item(item_id).get("damage", 0.0))


static func get_armor_health_bonus(item_id: String) -> float:
	return float(get_item(item_id).get("health", 0.0))


static func normalize_equipment_slot(raw_slot: String) -> String:
	match raw_slot:
		"off_hand", "offhand":
			return "offhand"
		"head", "helmet":
			return "helmet"
		"main_hand", "main_weapon":
			return "main_weapon"
		_:
			return raw_slot


static func get_max_durability(item_id: String) -> float:
	var data := get_item(item_id)
	if data.has("max_durability"):
		return float(data.max_durability)
	if data.get("type") == "weapon":
		var dmg := float(data.get("damage", 12.0))
		if dmg >= 40.0:
			return 100.0
		if dmg >= 25.0:
			return 80.0
		if dmg >= 18.0:
			return 60.0
		return 40.0
	if data.get("type") == "armor":
		var slot := normalize_equipment_slot(str(data.get("slot", "")))
		if slot == "offhand":
			return 80.0
		return 70.0
	return 0.0


static func can_have_sockets(item_id: String) -> bool:
	if is_quest_item(item_id):
		return false
	return get_item(item_id).get("type") in ["weapon", "armor"]


static func get_max_sockets(item_id: String) -> int:
	if not can_have_sockets(item_id):
		return 0
	var data := get_item(item_id)
	if data.has("max_sockets"):
		return int(data.max_sockets)
	match get_rarity(item_id):
		"common":
			return 1
		"uncommon":
			return 1
		"rare":
			return 2
		"epic", "legendary":
			return 3
		_:
			return 1


static func get_rarity(item_id: String) -> String:
	return str(get_item(item_id).get("rarity", "common"))


static func get_rarity_label(item_id: String) -> String:
	return get_rarity(item_id).capitalize()


static func is_gem(item_id: String) -> bool:
	return get_item(item_id).get("type") == "gem"


static func get_shield_block_bonus(item_id: String) -> float:
	return float(get_item(item_id).get("block_bonus", 0.0))


static func get_display_name(item_id: String) -> String:
	var data := get_item(item_id)
	if data.has("display_name"):
		return str(data.display_name)
	return item_id.replace("_", " ").replace("gem ", "").capitalize()


static func get_description(item_id: String) -> String:
	return str(DESCRIPTIONS.get(item_id, "No description available."))


static func get_item_type_label(item_id: String) -> String:
	var data := get_item(item_id)
	return str(data.get("type", "item")).capitalize()


static func is_quest_item(item_id: String) -> bool:
	return get_item(item_id).get("type") == "quest"


static func is_stackable(item_id: String) -> bool:
	return get_item(item_id).get("type") in ["consumable", "material", "gem"]
