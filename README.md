# Exiled Survivors

Dark post-apocalyptic fantasy **shared-screen co-op survival Action RPG** prototype built in **Godot 4.3+**.

## Quick Start

1. Install [Godot 4.3+](https://godotengine.org/download/windows/) (Standard, not .NET).
2. Open Godot → **Import** → select `C:\Users\shawn\Projects\exiled-survivors\project.godot`.
3. Press **F5** (or click Play) to run from the main menu.

## Quick verify (after Godot install)

```powershell
cd C:\Users\shawn\Projects\exiled-survivors
.\start` game.ps1                # quickest — launches main menu (no editor)
.\start` game.ps1 -Editor        # open Godot editor instead
.\scripts\run_tests.ps1          # 18 headless checks — expect exit 0
.\scripts\run_preview.ps1        # opens game window (main menu)
.\scripts\capture_screenshot.ps1   # saves docs/screenshots/preview.png
```

Double-click **`start game.bat`** in Explorer for the same quick launch.

Godot 4.3 is expected at `%LOCALAPPDATA%\Godot\Godot_v4.3-stable_win64.exe`.

## 3D art (CC0)

Characters use the [Quaternius Zombie Apocalypse Kit](https://quaternius.com/packs/zombieapocalypsekit.html) (CC0). Full credits: `art/CREDITS.md`.

- **P1:** Matt (`art/characters/player1/exiled_survivor_matt.gltf`)
- **P2:** Sam (kit GLTF via `player_visual.gd`)
- **Enemies / NPCs / pet:** Quaternius GLTF via `gltf_visual.gd` with capsule fallback
- **Props / ground:** colored primitives until environment GLTF is imported

After pulling art changes, use **Project → Reload Current Project** in Godot.

## Controls (controller-first)

| Input | Action |
|-------|--------|
| Esc / Start | Pause menu |
| LB / Tab | Inventory |
| Select / Back | World map (fog-of-war regions) |
| RB | Skill tree |
| Hold D-pad Up | Spell wheel |
| A | Interact / confirm |
| B | Cancel / close menu |
| Y (hold) | Execute near-death enemy |

Main menu **Continue** loads save slot 0 when present.

## Preview & Testing

### Play in editor (recommended)

| Step | Action |
|------|--------|
| 1 | Open `project.godot` in Godot 4.3+ |
| 2 | Press **F5** — main menu loads |
| 3 | Choose **Solo** or **Co-op** — enters Darkpine Forest |
| 4 | Move, fight bandits, interact with NPCs and waystone |

### PowerShell scripts

```powershell
cd C:\Users\shawn\Projects\exiled-survivors

# Headless automated tests (autoloads, scenes, currency, quests)
.\scripts\run_tests.ps1

# If Godot is not on PATH:
.\scripts\run_tests.ps1 -GodotPath "C:\path\to\Godot_v4.3-stable_win64.exe"

# Open game window via Godot editor binary
.\scripts\run_preview.ps1
```

Test output is written to `tests/last_run.log`.

### Expected behavior checklist

- [ ] Main menu shows title and Solo / Co-op buttons (controller + keyboard)
- [ ] Solo spawns one player capsule at forest spawn
- [ ] Co-op spawns two players; shared camera keeps both in frame
- [ ] WASD / left stick moves; right stick rotates camera
- [ ] J / X light attack; K / Y heavy attack; Space / B dodge
- [ ] Forest Bandit, Shield Bandit, Bandit Archer aggro and attack
- [ ] E / A interacts with waystone, camp, chest, trees, NPCs
- [ ] HUD shows health, stamina, hunger, thirst, quest text, currency
- [ ] Crates break from attacks and drop loot
- [ ] Camp chest sends wood to base storage
- [ ] Headless tests report all `[PASS]` in `tests/last_run.log`

### Screenshot

After playing in the editor, capture a screenshot manually (Win+Shift+S) and save to:

`docs/screenshots/preview.png`

Automated screenshot capture requires Godot with display support; use editor **F12** or OS tools for now.

## Controls

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| Move | WASD | Left stick |
| Camera | — | Right stick |
| Light attack | J | X |
| Heavy attack | K | Y |
| Dodge | Space | B |
| Block | — | LB |
| Sprint | Shift | L3 (mapped) |
| Interact | E | A |
| Quick spell | — | RB |
| Pause | Esc | Menu |

## Vertical Slice (Darkpine Forest)

- Third-person movement + shared-screen co-op camera
- Combat: light/heavy attacks, dodge, block, lock-on, executions
- 3 enemy types + Bandit Captain mini-boss + Hollow Grove Warden boss
- Loot, currency, inventory, quests, survival meters
- Waystone, camp site, camp chest, destructible crates, resource trees
- NPCs: Silent Merchant, Wounded Scout
- Spells (Ember Bolt, Healing Mist, etc.) via RB

**Hearthhold Camp** (`scenes/levels/hearthhold_camp/`) — base with Workbench, Forge, Item Box, Memory Altar.

## Folder Structure

```
scenes/          # Player, enemies, UI, levels, interactables
scripts/         # Gameplay, autoload, combat, AI, UI
  autoload/      # 16 manager singletons
  run_tests.ps1  # Headless test launcher
  run_preview.ps1
tests/           # test_runner.gd + last_run.log
resources/       # Item/quest data (expand later)
docs/screenshots/
```

## Autoload Managers

`GameManager`, `InputManager`, `SaveManager`, `SceneTransitionManager`, `InventoryManager`, `CurrencyManager`, `QuestManager`, `MapManager`, `LootManager`, `CraftingManager`, `BaseManager`, `WaystoneManager`, `DialogueManager`, `AchievementManager`, `AudioManager`, `SettingsManager`

## Next Milestones

1. Animation trees and attack timing polish
2. Full inventory/equipment UI
3. Skill tree + spell wheel UI
4. Merchant shop UI
5. Steam Deck playtest pass
6. Steam integration (achievements, overlay)

## Steam Deck

- Resolution: 1280×800 (16:10)
- Main menu → **Steam Deck Preset** applies UI scale and 40 FPS cap
- `export_presets.cfg` includes a Steam Deck export stub

## Install Godot (if missing)

1. Download **Godot 4.3** Standard 64-bit: https://godotengine.org/download/windows/
2. Extract `Godot_v4.3-stable_win64.exe` anywhere (e.g. `%LOCALAPPDATA%\Godot\`)
3. Optional: add to PATH or pass `-GodotPath` to the scripts above
