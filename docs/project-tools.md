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
- `--tile-map-image[=path]` — export tile map as PNG. If path given, write there; otherwise temp file. Tries to open in default viewer.
- `--tile-size N` — pixels per cell in PNG (default: 24).
- `--topology-graph[=path]` — export topology as DOT (and PNG when Graphviz installed). Path derived from tile-map-image path when omitted.
- `--seed <n>` — seed for map generation (default: random)
- `--world-state <path>` — load world state JSON for owner in province detail (path must exist)
- `--join-continents` — enable join step (Pass 10); default off
- `--seed-before-assignment` — use legacy land assignment; default off
- `--skip-fill-lakes` — skip Pass 4 (fill lakes); default off
- `--continent-buffer N` — minimum sea tiles between continents (default: 2)
- `--write-tile-map-json <path>` — write `TileMapResult` JSON (`width`, `height`, `grid`; optional `terrainGrid` / `resourceGrid` when present) for tooling (e.g. Wang tile preview packer)

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

---

## sim_economy

Standalone Phase 2 economy simulation (extraction, riches, production, consumption) over N turns. No map, movement, combat, or trade. Spec: [SPEC/program/sim-economy.md](../SPEC/program/sim-economy.md).

**Invocation**

```bash
melos run sim_economy -- [--script <path>] [--turns <N>] [--seed <int>] [--output <path>] [--json-output <path>]
```

**Options**

- `--script <path>` — JSON script with initial state and per-turn instructions (optional)
- `--turns <N>` — Turns to simulate (when no script)
- `--seed <int>` — RNG seed for reproducibility (optional)
- `--output <path>` — Markdown report path (default: sim_economy.md in cwd)
- `--json-output <path>` — Per-turn JSON log path (optional)

**Examples**

```bash
melos run sim_economy -- --turns 10 --seed 42
melos run sim_economy -- --script tmp/economy_script.json --output report.md
```

---

## sim_combat

Probabilistic combat simulation on scripted scenarios. Up to 5 rounds per engagement, clamped hit odds, strength-weighted casualties. Outputs detailed per-round formula and probability stats. Spec: [SPEC/program/sim-combat.md](../SPEC/program/sim-combat.md).

**Invocation**

```bash
melos run sim_combat -- --script <path> [--output <path>] [--json-output <path>] [--seed <int>]
```

**Options**

- `--script <path>` — JSON battle script (required)
- `--output <path>` — Markdown report (default: sim_combat.md)
- `--json-output <path>` — JSON log (optional)
- `--seed <int>` — RNG seed for reproducibility (optional)

**Examples**

```bash
melos run sim_combat -- --script tmp/my_test_battle.json --output report.md --seed 42
```

---

## sim_combat_montecarlo

Monte Carlo combat simulation. Runs many trials per battle, aggregates win rates and mean casualties. Spec: [SPEC/program/sim-combat-montecarlo.md](../SPEC/program/sim-combat-montecarlo.md).

**Invocation**

```bash
melos run sim_combat_montecarlo -- --script <path> [--trials N] [--seed <int>] [--output <path>] [--json-output <path>]
```

**Options**

- `--script <path>` — JSON battle script (required, same format as sim_combat)
- `--trials <N>` — number of trials per battle (default: 1000)
- `--seed <int>` — base RNG seed (optional)
- `--output <path>` — Markdown report (default: sim_combat_montecarlo.md)
- `--json-output <path>` — JSON log (optional)

**Examples**

```bash
melos run sim_combat_montecarlo -- --script tmp/my_test_battle.json --trials 500 --seed 123
```

---

## show_tech

Technology tree diagram and query. Outputs the full tech tree as markdown or runs interactive/query mode for a single tech (description, dependencies, effects). No game state required; reads from colonizethis_data tech catalog. Spec: [SPEC/program/show-tech-tool.md](../SPEC/program/show-tech-tool.md).

**Invocation**

```bash
melos run show_tech -- [options]
```

**Options**

- `--output <path>` — Write the markdown diagram to this path instead of stdout (default: diagram to stdout).
- `--interactive` — REPL: prompt for tech id, print description/dependencies/effects, repeat until exit.
- `--query <techId>` — Single-query mode: print info for the given tech id and exit. Unknown tech id prints an error and exits non-zero.

If neither `--interactive` nor `--query` is set, the full diagram is emitted to stdout (or to `--output` if provided).

**Examples**

```bash
melos run show_tech --
melos run show_tech -- --output=./tech_tree.md
melos run show_tech -- --query organised_regiments
melos run show_tech -- --interactive
```

---

## check_gdd_coverage

Reports which GDD specs (SPEC/game) are covered by sim_scenarios. Reads the coverage mapping at SPEC/project/gdd-scenario-coverage.json and lists covered vs uncovered specs. Used by the agentic workflow to add scenario coverage one spec at a time. Spec: [SPEC/project/gdd-scenario-coverage.md](../SPEC/project/gdd-scenario-coverage.md).

**Invocation**

```bash
melos run check_gdd_coverage
```

**Behaviour**

- Discovers all SPEC/game/*.md files.
- A spec is **covered** if it has at least one scenario listed in the mapping; otherwise **uncovered**.
- Prints total, covered, and uncovered counts and lists uncovered spec paths.
- Warns if a scenario file listed in the mapping is missing from tool/sim_scenarios/scenarios/.
- Exit 0 if all specs covered; exit 1 if any uncovered (for CI).
- If the mapping uses the extended format with `verifierIssues` for a covered spec, the tool prints those issues so the **coder** can rectify them (see [agentic-gdd-verifier.md](../SPEC/project/agentic-gdd-verifier.md) and [agentic-gdd-scenario-coverage.md](../SPEC/project/agentic-gdd-scenario-coverage.md)).

---

## test_app (Melos)

Runs Flutter widget tests for the **app** package (`app/test/` only). Use this (or `cd app && flutter test test/`) when running app widget tests; Linux desktop e2e (`integration_test/`, CI: xvfb) is documented in `SPEC/program/e2e-integration-tests.md`. Do **not** run app tests with `dart test app/test/...` from the repo root — that uses the Dart test runner and fails with Flutter binding errors (Size/Rect/invalid-type). See .cursor/rules/colonizethis-testing.mdc.

**Invocation**

```bash
melos run test_app
```

Optional: run a single test file: `cd app && flutter test test/diplomacy_panel_test.dart`

---

## Python: wang_incremental_64.py (incremental Wang tiles)

**64×64** plains↔sea corner-Wang generator: **192×192** cross **inpaint-v3** (optional **`init_guide`** merged into **`inpainting_image`**; **`--no-init-image`** sends bare composite); arms and **center fill bands** use **`incremental_state.json`** generated set + **edge-signature** rules (**opposite** edge for arms, **same** edge for center bands; **no** `contracts_128/`). Missing **`tile_00`** / **`tile_15`** **auto-seeded**; **`--init`** writes initial state. **Second pass:** **`--refine-center-island II`** re-inpaints only the inner **32×32** of an existing **`tile_II.png`** on a **64×64** canvas (outer **16px** ring kept); default prompt treats that ring as **ground truth** for thematic continuity inward (override with **`--description`**). Run **`python3`** from repo root. Spec: [SPEC/ui/pytool-image-tools.md](../SPEC/ui/pytool-image-tools.md) § **wang_incremental_64.py**.

**Example**

```bash
export PIXELLAB_API_KEY=…
python3 pytool/wang_incremental_64.py --init --max-tiles 1
python3 pytool/wang_incremental_64.py --refine-center-island 6 -v
```

Default **`--run-dir`** is **`app/assets/images/terrain/base_64/wang_incremental`** (override with **`--run-dir`** when needed).

---

## Python: wang_reference_legal_layout_64.py (legal reference grid)

**4×4** **`wang_index`** permutation for **`reference_layout.json`** so **internal** sheet edges match **corner Wang** shared vertices (unlike row-major atlas order). Optional **`--update-reference`** rebuilds **`reference.png`** from **`tiles/`**. Stdlib solver; Pillow only for PNG rebuild. Spec: [SPEC/ui/tileset/wang-reference-legal-layout-64.md](../SPEC/ui/tileset/wang-reference-legal-layout-64.md), [SPEC/ui/pytool-image-tools.md](../SPEC/ui/pytool-image-tools.md) § **wang_reference_legal_layout_64.py**.

**Example**

```bash
python3 pytool/wang_reference_legal_layout_64.py --run-dir app/assets/images/terrain/base_64/wang_incremental --seed 0 --update-reference
```

---

## run_e2e_timing.sh (E2E wall-clock, #2336)

Runs the three Linux desktop `integration_test` scenarios from [SPEC/program/e2e-integration-tests.md](../SPEC/program/e2e-integration-tests.md) with `--dart-define=CT_E2E=true`, **N times each** (default 3), and writes per-run logs plus a markdown summary (min/median/max per test and sum of medians for AC8). CI does not run these tests; use on a maintainer machine with a working Flutter Linux desktop toolchain, a display or `xvfb-run`, and (for snap Flutter) `ld.lld` available to the bundled LLVM path. Set `FLUTTER_BIN` to override the Flutter executable (default search: `~/development/flutter/bin/flutter`, then `PATH`).

**Invocation**

```bash
tool/run_e2e_timing.sh          # 3 runs per test
tool/run_e2e_timing.sh 5        # 5 runs per test
E2E_TIMING_OUT=./my_timing tool/run_e2e_timing.sh 3
```

Output defaults to `.cursor/e2e-timing/` (gitignored). Paste the summary medians into the PR baseline/after table (Refs GitHub #2336 AC8–AC9).

---

## run_quality_gate_tests.sh (CI verification)

Runs the same test and coverage steps as the GitHub Quality workflow (`.github/workflows/quality.yml`): **Wang incremental assets** (`python3 pytool/test_wang_incremental_assets_and_preview.py`; CI installs **`python3-pil`** via apt; locally install Pillow e.g. `python3 -m pip install pillow` or use your `pytool` venv), packages (Dart), app (Flutter) with **app widget coverage gate ≥ 80%** (applies to `lib/widgets/` only; see SPEC/program/test-logging.md), ctdev (Flutter), tool packages (Dart), coverage gate (logic/map/ai ≥ 90%), and sim_scenarios. Use this to verify the quality gate locally before pushing. Spec: [SPEC/program/test-logging.md](../SPEC/program/test-logging.md).

**Invocation**

```bash
tool/run_quality_gate_tests.sh
```

Requires `dart`, `flutter`, and `lcov` (e.g. `sudo apt-get install lcov`).

---

## scripts/nightly_dev_to_android_pr.sh (nightly APK PR)

Creates a PR from `dev` → `build/app/android` for nightly APK builds. Merging that PR triggers the app Android build. The PR **source** is always `dev` (per GitHub workflow rules).

**Invocation**

```bash
export REPO_DIR=/path/to/colonizethisv3
./scripts/nightly_dev_to_android_pr.sh
```

**Environment**

- **REPO_DIR** (required) — path to the repo root.
- **BASE_BRANCH** (optional) — PR base/target branch (default: `build/app/android`).
- **HEAD_BRANCH** (optional) — PR head/source branch (default: `dev`).
- **REMOTE_NAME** (optional) — git remote (default: `origin`).

**Behaviour**

- Fetches and updates local `dev` and `build/app/android`. If there are no commits to merge, exits without creating a PR. If an open PR from `dev` to `build/app/android` already exists, skips creating a duplicate. Otherwise runs `gh pr create` with `--head dev --base build/app/android`. Requires `gh` CLI to be installed and authenticated (e.g. `gh auth login`).

**Cron (e.g. 02:00 daily)**

```cron
0 2 * * * REPO_DIR=/home/clawd/colonizethisv3 /home/clawd/colonizethisv3/scripts/nightly_dev_to_android_pr.sh >> /home/clawd/nightly_dev_to_android.log 2>&1
```
