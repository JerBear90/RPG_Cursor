# Exiled Survivors Vertical Slice Playtest Guide

Manual playtest guide for the current vertical-slice demo. This build runs from the Godot project (not a packaged export).

---

## Build / Run

From the project root:

```powershell
.\start game.ps1
```

**Expected result:**

- Godot 4.6 launches the main menu (`res://scenes/main_menu/main_menu.tscn`).
- No script errors in the Godot output console.
- The launch script exits with code **0** after starting the game (it does not wait for you to close Godot).

**Requirements:**

- Godot 4.3+ (project targets 4.6). The script searches common install paths or accepts `-GodotPath`.
- First launch may import assets; allow a few minutes if prompted.

**Optional flags:**

```powershell
.\start game.ps1 -Editor    # open Godot editor instead of playing
.\start game.ps1 -Test      # run automated script tests first, then launch
```

---

## Recommended Demo Path (Solo)

1. Start **Solo New Game** (defaults to save slot 1 / index 0).
2. Spawn at **Darkpine** outpost.
3. Read intro and tutorial prompts (they should appear once, staggered).
4. Defeat or bypass the **Raider Trainee** (early teaching encounter).
5. Follow the objective to **Hearthhold Camp**.
6. Speak with **Old Blacksmith**.
7. Accept **Rebuild the Forge**.
8. Gather **Metal Scraps** and **Fire Resin** (inventory or base storage both count for turn-in).
9. Return to **Old Blacksmith** and complete the turn-in dialogue.
10. Use **Workbench** / **Forge** at Hearthhold (craft or repair as needed).
11. Speak with **Waystone Keeper**.
12. Accept **Wake the Stone**.
13. Gather **Crystal Shards** along the Darkpine Waystone route (placed near the demo path for reachability).
14. Activate the **Waystone**.
15. Speak with **Wounded Scout**.
16. Accept **Clear the Bandit Path**.
17. Defeat bandits and the **Bandit Captain** (far end of Darkpine).
18. Confirm the **demo completion** toast appears once.
19. **Save / Continue** and verify progress restores (see Save / Reset below).

---

## Co-op Path (Local)

1. Start **Local Co-op** from the main menu.
2. Confirm **P1** and **P2** spawn safely in Darkpine.
3. Confirm the **shared camera** frames both players (zoom adjusts; boss midpoint bug was fixed this pass).
4. Confirm **P2 HUD** (compact vitals row) is visible.
5. Have P1 and P2 gather different resources (shared inventory).
6. Down one player and **revive** them.
7. Use **Waystone** travel together (both players should travel).
8. Confirm **Save / Continue** restores both players and shared state.

---

## What to Watch For

- Spawn placement and safe co-op offsets
- Objective routing and distance hints on the HUD
- Quest completion and mission turn-ins (especially forge materials from base storage)
- Resource availability (scrap, fire resin, crystal shards)
- Bandit difficulty (Trainee vs Captain)
- Save / Continue reliability (solo and co-op)
- Controller navigation in menus
- UI readability at 1280×800
- Co-op camera behavior during combat and travel
- P2 prompts and HUD clarity
- Tutorial / progress toasts not spamming

---

## Controls Reference

Bindings below match `project.godot` and `InputDefaults` as of this demo pass. Saved overrides live in `user://controls.cfg`.

### Keyboard (Player 1)

| Action | Binding |
|--------|---------|
| Move | **W A S D** |
| Camera | **Mouse** |
| Interact | **E** |
| Light Attack | **Mouse 1** or **J** |
| Heavy Attack | **Mouse 2** or **K** |
| Dodge | **Ctrl** or **Alt** |
| Jump | **Space** |
| Block | **F** |
| Sprint | **Shift** |
| Spell Cast | **Q** or **3** |
| Lock On | **Mouse 3** or **R** |
| Inventory | **I** |
| Map | **M** |
| Pause | **Esc** |
| Skill Tree | *No default key bound* (action exists; keyboard-only reserved) |
| Quest Tracker (full panel) | *No default key bound* (HUD tracker always visible; use **D-pad Left/Right** on gamepad to cycle tracked quest) |
| Menu Confirm | **E**, **Enter**, or **Space** |
| Menu Cancel | **Esc** |

### Gamepad (Player 1 — Xbox-style labels)

| Action | Binding |
|--------|---------|
| Move | **Left Stick** |
| Camera | **Right Stick** |
| Interact | **X** (not A — A is menu confirm) |
| Light Attack | **RT** (right trigger) |
| Heavy Attack | **RB** |
| Dodge | **B** |
| Jump | **A** |
| Block | **LB** |
| Sprint | **L3** (click left stick) |
| Spell Cast | **LT** (left trigger) |
| Lock On | **R3** (click right stick) |
| Inventory | **View / Back** |
| Map | **D-pad Up** |
| Pause | **Start / Menu** |
| Pet Command Wheel | **D-pad Down** (hold) |
| Cycle tracked quest / quick slot | **D-pad Left** / **D-pad Right** |
| Quick consumable | **Y** (when assigned) |

### Local Co-op

- **P1** uses the default controls above (keyboard + first gamepad, device index 0).
- **P2** uses runtime `p2_*` input actions cloned from P1.
- **P2 keyboard fallback:** Arrow keys move, **U** light attack, **O** heavy attack, **P** dodge, **Enter** interact, **Shift** sprint, **8** spell, **9** quick item, **0** quick heal, **Backspace** pause.
- **P2 gamepad:** second connected controller (**device index 1**).
- **Shared:** inventory, currency, quests, waystones, one party pet.
- **Per-player:** HP, stamina, focus, skills, stats, equipment, position.
- **Menus:** the player who opens a menu owns it until closed (`GameManager.menu_owner_index`).

---

## Known Limitations

- **Placeholder visuals** and primitive resource harvest nodes.
- **Placeholder pet mesh** (Ash Hound only is fully implemented).
- **Map** uses functional placeholder art.
- **Only Ash Hound** pet is implemented for the demo.
- **Only +1 weapon/armor upgrade** is currently wired end-to-end.
- Some **gem effects** are display-only until later systems land.
- **Pet gear UI** is placeholder-only.
- **No online multiplayer.**
- **No split-screen** — local shared-screen co-op only.
- **Milestone autosave** writes **slot 0** (slot 1 in UI) without an overwrite prompt.
- **No automated playtest harness** — use this checklist manually.
- **Crystal shards** are intentionally placed near the Darkpine Waystone path for demo reachability.
- **Bandit Captain** remains at the far end of Darkpine (late-demo challenge).
- **Skill tree** and **full quest tracker panel** have no default keyboard/gamepad hotkeys (HUD tracker still shows the active objective).
- **No export presets** in the repository — playtest via `start game.ps1`, not a standalone `.exe`.
- Some content exists for future phases but is **not final** for this demo.

---

## Saving

| Method | Details |
|--------|---------|
| **Milestone autosave** | Automatic at key beats (Hearthhold arrival, mission accept, quest complete, waystone unlock). Debounced 3s; skipped during combat, boss fights, spawn placement, and region transitions. Writes **slot 0** when no manual slot is active. |
| **Pause menu** | **Esc** → **Save Game** → writes slot 0. |
| **Memory Altar** | Interact at Hearthhold **Memory Altar** → saves slot 0 with confirmation dialogue. |
| **Continue / Load Game** | Main menu loads the most recent save or pick a slot (3 slots: `slot_0.json` … `slot_2.json`). |

**Continue should restore:** tracked mission, inventory, waystones, pet, tutorials seen, vertical-slice flags, equipment/gems, and co-op player state (v3 save).

---

## Resetting Demo Saves

Save files live under Godot’s user data folder:

| Platform | Path |
|----------|------|
| **Windows** | `%APPDATA%\Godot\app_userdata\Exiled Survivors\saves\` |
| **Linux / Steam Deck (Proton)** | `~/.local/share/godot/app_userdata/Exiled Survivors/saves/` |
| **macOS** | `~/Library/Application Support/Godot/app_userdata/Exiled Survivors/saves/` |

Files: `slot_0.json`, `slot_1.json`, `slot_2.json`.

**To reset:**

1. Close the game.
2. Delete one or all `slot_*.json` files in the folder above, **or**
3. Start **New Game** on an empty slot from the main menu load list (overwrites that slot when you save).

Optional: delete `settings.cfg` and `controls.cfg` in the same `Exiled Survivors` folder to reset video/audio/control preferences.

---

## Steam Deck Notes

- Default viewport is **1280×800** (16:10) with `canvas_items` stretch — matches Steam Deck native resolution.
- In-game **Settings → Steam Deck Preset** applies: 40 FPS cap, UI scale 1.15, slightly lower camera sensitivity.
- Default **VSync on**, **60 FPS cap** (adjustable in Settings).
- Window mode in project is **maximized** on desktop; Deck fullscreen behavior depends on Proton/desktop mode.
- **Recommended:** connect or use built-in controls; P1 gamepad mappings above apply. Map on **D-pad Up**; interact on **X**.
- **No Linux export preset** is checked in yet — Deck playtest today is via Steam’s “Add Non-Steam Game” pointing at Godot + project, or a future exported Linux build.
- Verify HUD text readability after applying the Deck preset; report cramped panels in the RC checklist.

---

## Asset Pass Notes

Kenney Nature Kit assets are integrated for placeholder replacement (CC0 — see `THIRD_PARTY_ASSETS.md`).

- Wrapper scenes and docs: `res://assets/third_party/kenney/`
- Raw Nature Kit meshes: `res://art/kenney/nature_kit/` (OBJ runtime load)
- Runtime gather nodes (scrap, crystal shards, fire resin, etc.) now use Kenney meshes where available; primitives remain as fallback.
- Hearthhold camp stations (workbench, forge, water collector, garden) use updated Kenney props.
- Ash Hound pet mesh unchanged (Quaternius); map art still placeholder.
- Visuals are improved but **not final proprietary art** — expect a future custom pass.

When playtesting, watch for: gather node readability, camp station silhouettes, and any missing mesh fallbacks (primitive shapes).

---

## Related Reports

| Report | Purpose |
|--------|---------|
| `tests/production_demo_release_candidate_report.txt` | 38-item RC checklist and recommendation |
| `tests/production_export_settings_report.txt` | Export preset and project settings review |
| `tests/production_vertical_slice_playtest_report.txt` | QA/balance pass summary |
| `tests/production_vertical_slice_flow_report.txt` | Tutorial and flow pass |
| `tests/production_kenney_asset_integration_report.txt` | Kenney asset / placeholder replacement pass |

---

## Quick Smoke Test (5 minutes)

1. `.\start game.ps1` → exit 0, main menu loads.
2. Solo New Game → intro toast, bandages in quick slot, sword/cloak equipped.
3. HUD shows **Reach Hearthhold Camp**.
4. Pause → Settings opens; Esc closes.
5. Quit to menu → no script errors in Godot console.

For the full demo, follow the **Recommended Demo Path** above and check items in the release candidate report.
