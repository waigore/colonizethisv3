# Project tools

CLI tools under `tool/` are run from the **project root** via Melos. All file paths in arguments are **relative to the repo root**. One-time setup: run `melos bootstrap` (or `dart run melos bootstrap`) from the project root.

The list below is the single place for **what tools exist** and **how to invoke each**. When a new Melos script is added to the root `pubspec.yaml`, add a corresponding section here.

---

## describe_topology

Load a region topology and describe the entire map (graph, optional tile map summary, optional interactive province detail). Used for inspection and debugging. Spec: [SPEC/program/map-data.md](../SPEC/program/map-data.md).

**Invocation**

```bash
melos run describe_topology -- <path_to_topology.json> [options]
```

**Options**

- **Required:** `<path_to_topology.json>` — path to topology JSON (relative to repo root).
- `--interactive` — prompt for province id and show detail; type `q` to quit.
- `--tile-map` — generate tile map and print map summary (tile counts per province/sea zone).
- `--tile-map-image[=path]` — export tile map as PNG with legend (each color = region; P = province, S = sea zone). If path is given, write there; otherwise write to a temp file. Tries to open in the default image viewer; if that fails, prints "Saved to: &lt;path&gt;". Always prints the path.
- `--world-state <path>` — load world state JSON so province detail shows owner (path relative to repo root).

**Output**

- Graph description: nodes (P = province, S = sea zone) with id and region; edges.
- With `--tile-map`: tile count per province/sea zone.
- With `--tile-map-image`: path to PNG; viewer opened if possible.
- With `--interactive`: province list, then prompt; for each entered province id, formatted detail (region, owner or "no owner", tiles, improvements).

**Examples**

```bash
melos run describe_topology -- tool/describe_topology/example_topology.json
melos run describe_topology -- tool/describe_topology/example_topology.json --tile-map
melos run describe_topology -- tool/describe_topology/example_topology.json --tile-map-image
melos run describe_topology -- tool/describe_topology/example_topology.json --tile-map-image=./map.png
melos run describe_topology -- tool/describe_topology/example_topology.json --interactive
```
