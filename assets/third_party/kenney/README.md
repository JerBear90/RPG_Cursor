# Kenney Third-Party Assets (Project Layout)

Official source: [https://kenney.nl/](https://kenney.nl/)

This folder holds **Godot wrapper scenes**, license copies, and documentation for Kenney assets used in Exiled Survivors. Raw mesh data for the primary Nature Kit remains in the legacy import location:

- `res://art/kenney/nature_kit/` — Nature Kit 2.1 (OBJ runtime load via `MeshLoader`)
- `res://art/kenney/ui_pack/` — UI Pack (CC0)

## Structure

```text
assets/third_party/kenney/
  README.md              — this file
  licenses/              — CC0 license text copies
  scenes/
    props/               — reusable static prop wrappers
    resources/           — gather-node visual references
    environment/         — trees/rocks (reference wrappers)
    camp/                — camp dressing wrappers
    dungeon/             — reserved for future dungeon kit import
    pets/                  — reserved; Ash Hound uses Quaternius mesh
```

## Usage

- Prefer **wrapper `.tscn`** scenes here for new placements.
- Existing gameplay scenes may still reference `GltfVisual` + `art/kenney/...` paths directly (unchanged behavior).
- Runtime resource nodes use `KenneyPropCatalog` + `ResourceNodeVisualFactory` (Kenney mesh first, primitive fallback).

## Import rules

1. GLB/glTF preferred when adding new packs under `raw/[pack_name]/`.
2. Do not scatter Kenney files outside `art/kenney/` or `assets/third_party/kenney/`.
3. Preserve each pack's original `License.txt` under `licenses/`.

See also: `THIRD_PARTY_ASSETS.md` (repo root).
