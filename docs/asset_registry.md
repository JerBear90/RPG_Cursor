# Asset Registry — Phase 1

Records free assets used for Hearthhold and Rotfen Marsh content.

## Kenney Nature Kit

| Field | Value |
|-------|-------|
| Asset name | Kenney Nature Kit (GLTF) |
| Creator | Kenney |
| Source | https://kenney.nl/assets/nature-kit |
| License | CC0 1.0 |
| Project path | `res://art/kenney/nature_kit/` |
| Modifications | Material tinting via `kenney_material_tint.gd`; scaled props in town layouts |
| Usage | Hearthhold walls, paths, tents, campfires, Rotfen boardwalks, ruins, landmarks |

## Quaternius Character Kit

| Field | Value |
|-------|-------|
| Asset name | Quaternius Low Poly Character / Zombie Kit |
| Creator | Quaternius |
| Source | https://quaternius.com (bundled in project) |
| License | CC0 (Quaternius standard) |
| Project path | `res://art/characters/_quaternius_zombie_kit/` |
| Modifications | GLTF import; character animation binding |
| Usage | Hearthhold NPCs, Rotfen enemies (Bog Stalker, Mire Hound, Drowned Husk, Cultist, Spore Brute) |

## Quaternius / Existing Player Art

| Field | Value |
|-------|-------|
| Asset name | Exiled Survivor character mesh |
| Creator | Project / Quaternius base |
| Source | `res://art/characters/player1/` |
| License | Project asset |
| Project path | `res://art/characters/player1/exiled_survivor_matt.gltf` |
| Modifications | Rigged for player |
| Usage | Player character (unchanged Phase 0) |

## Procedural / Engine Assets

| Field | Value |
|-------|-------|
| Asset name | ProceduralSkyMaterial, StandardMaterial3D ground fill |
| Creator | Godot Engine |
| Source | Engine built-in |
| License | MIT |
| Project path | Level scene sub-resources |
| Modifications | Custom colors for Hearthhold warm sky and Rotfen fog sky |
| Usage | Region atmospheres |

## Notes

- No commercial ripped assets were imported.
- KayKit and Poly Haven textures were not required for this pass; existing Kenney + Quaternius cover Phase 1 placeholders.
- Sunken Reliquary interior art is deferred to a future phase.

## Phase 3 — Ashfall Highlands & Blackvein Foundry

### Quaternius German Shepherd (Cinder Wolf)

| Field | Value |
|-------|-------|
| Asset name | Characters_GermanShepherd.gltf |
| Creator | Quaternius |
| Source | Quaternius character kit (project bundle) |
| License | CC0 |
| Project path | `res://art/characters/_quaternius_zombie_kit/Characters/glTF/Characters_GermanShepherd.gltf` |
| Modifications | Tinted via enemy scene; used as Cinder Wolf silhouette |
| Usage | Cinder Wolf dedicated enemy |

### Kenney Nature Kit (Ashfall environment pass)

| Field | Value |
|-------|-------|
| Asset name | Kenney Nature Kit props (expanded Ashfall layout) |
| Creator | Kenney |
| Source | https://kenney.nl/assets/nature-kit |
| License | CC0 1.0 |
| Project path | `res://art/kenney/nature_kit/` |
| Modifications | Scaled cliffs, paths, fences, stumps, stone/quarry markers in `town_layouts.gd` |
| Usage | Stonewatch walls, Cinder Road, rail collapse, quarry, Foundry approach, Frostgrave pass road |

### Procedural hazard visuals

| Field | Value |
|-------|-------|
| Asset name | StandardMaterial3D lava/heat/rockfall |
| Creator | Godot Engine |
| Source | Engine built-in |
| License | MIT |
| Project path | `scripts/environment/lava_hazard.gd`, `heat_zone.gd`, `falling_rock_hazard.gd` |
| Modifications | Emissive lava mesh, particle telegraphs |
| Usage | Ashfall and Foundry environmental hazards |

### Audio (Phase 3 hooks)

| Field | Value |
|-------|-------|
| Asset name | Existing AudioManager ambience keys |
| Creator | Project / prior packs |
| Source | `scripts/autoload/audio_manager.gd` |
| License | Per prior project entries |
| Project path | Reused wind/camp/combat SFX |
| Modifications | Ash storm and Foundry zones use existing ambience routing |
| Usage | Ashfall wind/storm shelter; Foundry industrial ambience via level lighting + future SFX pass |

## Phase 4 — Hollow King Boss Visual

| Field | Value |
|-------|-------|
| Asset name | Quaternius Characters Matt (Single Weapon) |
| Creator | Quaternius |
| Source | `res://art/characters/_quaternius_zombie_kit/Characters/glTF/Characters_Matt_SingleWeapon.gltf` |
| License | CC0 (Quaternius standard) |
| Project path | `scenes/enemies/bosses/hollow_king.tscn` |
| Modifications | Scale 1.85×, pale OmniLight3D core, frost tint via scene lighting |
| Usage | The Hollow King boss — distinct from Iron Crucible zombie mesh |

## Phase 4 — Procedural Audio Hooks

| Field | Value |
|-------|-------|
| Asset name | Procedural tone SFX (AudioManager) |
| Creator | Project |
| Source | `scripts/autoload/audio_manager.gd` |
| License | MIT (engine-generated WAV) |
| Project path | `_tones` dictionary |
| Modifications | Added blizzard_wind, ice_crack, frostwatch_ambience, crypt_ambience, seal_activate, boss_intro, boss_phase, boss_swing, boss_death, frost_wave, paleheart_burst, teleport, summon |
| Usage | Frostgrave blizzards, Paleheart crypt/seals, Hollow King encounter until licensed packs replace placeholders |

## Phase 5 — Tidebound Sovereign Boss

| Field | Value |
|-------|-------|
| Asset name | Quaternius Single Weapon Character (boss mesh) |
| Creator | Quaternius |
| Source | `res://art/characters/_quaternius_zombie_kit/Characters/glTF/Characters_Matt_SingleWeapon.gltf` |
| License | CC0 (Quaternius standard) |
| Project path | `scenes/enemies/bosses/tidebound_sovereign.tscn` |
| Modifications | Scale 1.9×, storm-core and crown OmniLight3D, dedicated TideboundSovereign script |
| Usage | The Tidebound Sovereign — Drowned Citadel boss (distinct from Hollow King / Iron Crucible) |

## Phase 5 — Procedural Coastal / Citadel Audio

| Field | Value |
|-------|-------|
| Asset name | Procedural tone SFX (AudioManager) |
| Creator | Project |
| Source | `scripts/autoload/audio_manager.gd` |
| License | MIT (engine-generated WAV) |
| Project path | `_tones` dictionary |
| Modifications | coastal_storm_ambience, coastal_rain, coastal_wind, thunder_roll, lightning_warn/strike, wave_crash, citadel_ambience, conduit_hum, sovereign_swing, throne_ambience |
| Usage | Shattered Coast weather, Drowned Citadel puzzle/boss until licensed maritime packs replace placeholders |

## Phase 6 — Blightheart Boss Visual

| Field | Value |
|-------|-------|
| Asset name | Quaternius Character Kit (Matt SingleWeapon) + procedural lights |
| Creator | Quaternius / project assembly |
| Source | `res://art/characters/_quaternius_zombie_kit/Characters/glTF/Characters_Matt_SingleWeapon.gltf` |
| License | CC0 (Quaternius standard) |
| Project path | `scenes/enemies/bosses/heart_of_blight.tscn` |
| Modifications | Scale 2.1×, BlightCore and RootCrown OmniLight3D (green-violet), HeartOfBlight script |
| Usage | The Blightheart — Blightspire Cathedral Heart Chamber boss |

## Phase 6 — Procedural Cathedral Audio

| Field | Value |
|-------|-------|
| Asset name | Procedural tone SFX (AudioManager) |
| Creator | Project |
| Source | `scripts/autoload/audio_manager.gd` |
| License | MIT (engine-generated WAV) |
| Project path | `_tones` dictionary |
| Modifications | cathedral_ambience, corrupted_bell, root_movement, spore_vent, purification_ignite/wave, stained_glass_break, blighted_cleric_cast, heart_chamber_pulse |
| Usage | Blightspire Cathedral ambience, puzzle, hazards, and Blightheart boss until licensed packs replace placeholders |

## Phase 7 — Solar Tyrant Boss Visual

| Field | Value |
|-------|-------|
| Asset name | Quaternius Character Kit (Matt SingleWeapon) + procedural solar lights |
| Creator | Quaternius / project assembly |
| Source | `res://art/characters/_quaternius_zombie_kit/Characters/glTF/Characters_Matt_SingleWeapon.gltf` |
| License | CC0 (Quaternius standard) |
| Project path | `scenes/enemies/bosses/solar_tyrant.tscn` |
| Modifications | Scale 2.2×, SolarCore and SolarCrown OmniLight3D (red-gold), SolarTyrant script |
| Usage | The Solar Tyrant — Pyreheart Ziggurat Solar Heart chamber boss |

## Phase 7 — Cinderhold NPC Visuals

| Field | Value |
|-------|-------|
| Asset name | Quaternius Character Kit (Lis SingleWeapon) |
| Creator | Quaternius |
| Source | `res://art/characters/_quaternius_zombie_kit/Characters/glTF/Characters_Lis_SingleWeapon.gltf` |
| License | CC0 |
| Project path | `scenes/npcs/cinderhold_npc.tscn` |
| Usage | Warden Ilyra Voss, Nima Dareth, Dagan Sunforge, Doctor Sol Marr, Scout Kera Ash at Cinderhold |

## Phase 7 — Procedural Pyreheart / Solar Tyrant Audio

| Field | Value |
|-------|-------|
| Asset name | Procedural tone SFX (AudioManager) |
| Creator | Project |
| Source | `scripts/autoload/audio_manager.gd` |
| License | MIT (engine-generated WAV) |
| Project path | `_tones` dictionary |
| Modifications | solar_heart_ambience, solar_tyrant_intro, solar_cleave, sunstrike_charge, solar_beam_charge/fire, glass_eruption_warning/impact, solar_phase_transition, crown_of_flame, sandglass_storm, solar_tyrant_death, solar_heart_exit_unlock |
| Usage | Pyreheart Ziggurat Solar Heart encounter until licensed desert/temple packs replace placeholders |

## Phase 8 — Sunless Dominion Enemy Visuals

| Field | Value |
|-------|-------|
| Asset name | Quaternius Character Kit (Matt SingleWeapon) |
| Creator | Quaternius |
| Source | `res://art/characters/_quaternius_zombie_kit/Characters/glTF/Characters_Matt_SingleWeapon.gltf` |
| License | CC0 |
| Project path | `scenes/enemies/gloom_hound.tscn`, `nightbound_raider*.tscn`, `hollow_knight.tscn`, `eclipse_cultist.tscn`, `grave_wraith.tscn`, `shadow_stalker.tscn`, `dominion_executioner.tscn` |
| Modifications | Dominion Executioner scaled 1.4× |
| Usage | Sunless Dominion overworld and Eclipse Sanctum enemies |

## Phase 8 — Dawnwatch NPC Visuals

| Field | Value |
|-------|-------|
| Asset name | Quaternius Character Kit (Lis SingleWeapon) |
| Creator | Quaternius |
| Source | `res://art/characters/_quaternius_zombie_kit/Characters/glTF/Characters_Lis_SingleWeapon.gltf` |
| License | CC0 |
| Project path | `scenes/npcs/dawnwatch_npc.tscn` |
| Usage | Commander Alaric Vane, Mira Sol, Selene Nightforge, Doctor Corvin Hale, Scout Nyra Vale at Dawnwatch |

## Phase 8 — Eclipse Sanctum Dungeon Visuals

| Field | Value |
|-------|-------|
| Asset name | Kenney Nature Kit + procedural floor tiles |
| Creator | Kenney / project assembly |
| Source | `res://art/kenney/nature_kit/Models/GLTF format/` |
| License | CC0 (Kenney standard) |
| Project path | `scenes/dungeons/eclipse_sanctum/eclipse_sanctum.tscn`, `scenes/dungeons/eclipse_sanctum_entrance.tscn` |
| Modifications | Violet umbral floor materials, shadow ward puzzle props |
| Usage | Eclipse Sanctum procedural dungeon — sealed throne chamber has no boss placeholder |

## Phase 8 — Procedural Sunless Dominion / Eclipse Sanctum Audio

| Field | Value |
|-------|-------|
| Asset name | Procedural tone SFX (AudioManager) |
| Creator | Project |
| Source | `scripts/autoload/audio_manager.gd` |
| License | MIT (engine-generated WAV) |
| Project path | `_tones` dictionary |
| Modifications | sunless_dominion_ambience, shadow_fog, dawnwatch_wards, sanctum_ambience, ward_activation, sealed_throne_heartbeat |
| Usage | Sunless Dominion region, Dawnwatch wards, and Eclipse Sanctum until licensed shadow/eclipse packs replace placeholders |
