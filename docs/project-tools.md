# Project tools

CLI tools under `tool/` are run from the **project root** via Melos. All file paths in arguments are **relative to the repo root**. One-time setup: run `melos bootstrap` (or `dart run melos bootstrap`) from the project root.

The list below is the single place for **what tools exist** and **how to invoke each**. When a new Melos script is added to the root `pubspec.yaml`, add a corresponding section here.

---

## init_game

Game creation: generate Old World and New World maps, assign provinces and capitals to Great Powers, Minor Nations, and Tribes, build initial world state. Outputs combined map PNG (with ownership and capitals) and faction setup markdown. Does not advance turns. Spec: [SPEC/program/init-game-tool.md](../SPEC/program/init-game-tool.md).

**Invocation**

```bash
melos run init_game -- [options]
```

**Options**

- `--config <path>` — JSON config (optional)
- `--output-map <path>` — write map PNG
- `--output-markdown <path>` — write faction setup markdown
- `--output-game <path>` — save game to Hive directory (use with `--no-save` to skip)
- `--no-save` — do not save game
- `--seed <n>` — RNG seed
- `--great-power-count N`, `--minor-nation-count N`, `--tribe-count N` — override config
- `--num-provinces-old-world N`, `--num-provinces-new-world N` — override config

**Output**

- Map PNG: combined OW+NW with ownership colors and capital markers.
- Markdown: Faction Setup table (Faction, Type, Capital Province, Provinces Owned) and Faction Starting State table (Stockpile, Workers, Treasury, Units).

**Examples**

```bash
melos run init_game -- --output-map=./game_map.png --output-markdown=./setup.md --no-save
melos run init_game -- --minor-nation-count 0 --tribe-count 3 --output-map=./map.png
```

---

## generate_map

End-to-end map generation: generate tile map from province and continent count, infer topology from the grid, output graph description, map summary, tile map PNG, and topology graph (DOT + PNG when Graphviz installed). Spec: [SPEC/program/map-data.md](../SPEC/program/map-data.md).

**Mode**

- Map-first only: input N provinces, C continents via `--provinces` and `--continents`. Generate map, infer topology, output both.

**Invocation**

```bash
melos run generate_map -- [options]
```

**Options**

- `--provinces N` (default: 60)
- `--continents M` (default: 3; must be 2–4)
- `--region oldWorld|newWorld` (default: oldWorld)
- `--tiles-per-province N` (default: 35)
- `--sea-fraction F` (default: 0.6; sea fraction 0–1)
- `--interactive` — prompt for province id and show detail; type `q` to quit
- `--tile-map` — generate tile map and print map summary
- `--tile-map-image[=path]` — export tile map as PNG. If path given, write there; otherwise temp file. Tries to open in default viewer.
- `--seed <n>` — seed for map generation (default: random)
- `--world-state <path>` — load world state JSON for owner in province detail (path relative to repo root)
- `--join-continents` — enable join step (Pass 10); default off
- `--seed-before-assignment` — use legacy land assignment; default off
- `--skip-fill-lakes` — skip Pass 4 (fill lakes); default off
- `--continent-buffer N` — minimum sea tiles between continents (default: 2)

**Output**

- Graph description: nodes (P = province, S = sea zone) with id and region; edges.
- Tile count per province/sea zone.
- Tile map PNG path (when `--tile-map-image`).
- Topology graph: DOT file; PNG via neato (map-aligned) when Graphviz installed (otherwise warning).
- With `--interactive`: province list, then prompt; for each entered province id, formatted detail.

**Examples**

```bash
melos run generate_map --
melos run generate_map -- --provinces 40 --continents 2 --region newWorld
melos run generate_map -- --tile-map-image=./map.png
melos run generate_map -- --interactive
```
