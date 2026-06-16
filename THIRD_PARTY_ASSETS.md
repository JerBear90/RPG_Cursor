# Third-Party Assets

## Kenney Assets

Source:
https://kenney.nl/

Usage:
Kenney game assets are commonly provided for free use, often under CC0/public-domain style terms depending on the pack. Confirm each downloaded pack's included license/readme file and preserve it in the project.

Imported packs:

- **Nature Kit 2.1** — `res://art/kenney/nature_kit/` (primary 3D props, terrain, camp, statues)
- **UI Pack** — `res://art/kenney/ui_pack/` (HUD/input prompt art)

Wrapper scenes and license copies:

- `res://assets/third_party/kenney/` — organized Godot wrapper scenes + `licenses/`

Recommended for future import (not yet in repo):

- Graveyard Kit — https://kenney.nl/assets/graveyard-kit
- Modular Dungeon Kit / Mini Dungeon — dungeon dressing
- Survival Kit — additional camp props

Notes:

- Attribution is not required for many Kenney CC0 assets, but attribution is appreciated (Kenney / www.kenney.nl).
- Original gameplay code, systems, and project-specific scenes remain part of this project.
- Runtime meshes load as OBJ via `MeshLoader` from Nature Kit (`GLTF format/*.glb` paths normalize to OBJ).
- Ash Hound pet uses Quaternius (see `art/CREDITS.md`), not Kenney Cube Pets.

License file copies:

- `assets/third_party/kenney/licenses/nature_kit_license.txt`
- `assets/third_party/kenney/licenses/ui_pack_license.txt`
