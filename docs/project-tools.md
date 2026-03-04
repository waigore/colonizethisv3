# Project tools

CLI tools under `tool/` are run from the **project root** via Melos. All file paths in arguments are **relative to the repo root**. One-time setup: run `melos bootstrap` (or `dart run melos bootstrap`) from the project root.

The list below is the single place for **what tools exist** and **how to invoke each**. When a new Melos script is added to the root `pubspec.yaml`, add a corresponding section here.

---

## ctterm

Terminal UI for the full single-player ColonizeThis experience. Pure Dart (Nocterm); no Flutter. Spec: [SPEC/tui/ctterm.md](../SPEC/tui/ctterm.md).

**Invocation**

```bash
dart run ctterm
```

Or from project root with Melos:

```bash
melos run ctterm
```

**Options**

- `--data-dir <path>` — Override the default Hive data directory (default: `$HOME/.colonizethis_ctterm`, or `$XDG_DATA_HOME/colonizethis_ctterm` on Linux when set).

**Behaviour**

- Shows Main Menu first (New Game, Load Game, Settings, Quit). Load Game is enabled only when at least one save exists in the ctterm data directory. Saves are separate from app/ctdev.
- Logs to **ctterm.log** in the ctterm data directory (same as `--data-dir` when set). All logger output (tui:*, logic:*, etc.) is appended to this file.

**TUI automation (agent-tui)**

- Automated TUI tests use [agent-tui](https://github.com/pproenca/agent-tui) per SPEC/tui/ctterm.md §5.2. From repo root, run:
  - `./ctterm/scripts/agent_tui_new_game_default.sh [data_dir]` — starts ctterm (if needed), creates a new game via Main Menu → Game Setup, auto-assigns nations/leaders, and waits until the in-game shell (screen `100006`) is visible. When `data_dir` is omitted, a temporary ctterm data directory is created for the session.
  - `./ctterm/scripts/agent_tui_assign_all_civilians_improvement.sh` — scenario script that assumes the in-game shell (screen `100006`) is visible, opens the Development screen (`100009` via `D`), and attempts to assign a basic `build_improvement` work order to each civilian unit row by selecting the unit, pressing `i`, and accepting the default province and tile before moving to the next row.
  - `./ctterm/scripts/agent_tui_quit_to_main_menu.sh` — from an in-game shell session, opens Pause/Options and quits back to the Main Menu (screen `100001`) via the exit confirmation dialog.
  - `./ctterm/scripts/agent_tui_screenshot.sh [output_path]` — captures the current ctterm screen via `agent-tui screenshot --strip-ansi`. When `output_path` is provided, writes the text snapshot there; otherwise prints to stdout.
  - `./ctterm/scripts/agent_tui_save_game.sh` — placeholder for an explicit in-game save flow. As of the current ctterm TUI spec/implementation there is no dedicated "Save Game" hotkey or menu item; this script fails fast and documents that limitation so tests do not assume a manual save is available yet.

  Example chained usage from repo root:

  ```bash
  # Start a fresh game into in-game shell (temp data dir)
  ./ctterm/scripts/agent_tui_new_game_default.sh

  # Open Development and attempt to assign work to all civilians
  ./ctterm/scripts/agent_tui_assign_all_civilians_improvement.sh

  # Capture a screenshot of the initial in-game shell
  ./ctterm/scripts/agent_tui_screenshot.sh tmp/in_game_shell_start.txt

  # (When a TUI save flow exists, this will attempt to save)
  ./ctterm/scripts/agent_tui_save_game.sh || echo "Save not available yet"

  # Quit back to Main Menu via Pause/Options
  ./ctterm/scripts/agent_tui_quit_to_main_menu.sh
  ```

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

## run_quality_gate_tests.sh (CI verification)

Runs the same test and coverage steps as the GitHub Quality workflow (`.github/workflows/quality.yml`): packages (Dart), app (Flutter), ctdev (Flutter), tool packages (Dart), coverage gate (logic/map/ai ≥ 90%), and sim_scenarios. Use this to verify the quality gate locally before pushing. Spec: [SPEC/program/test-logging.md](../SPEC/program/test-logging.md).

**Invocation**

```bash
tool/run_quality_gate_tests.sh
```

Requires `dart`, `flutter`, and `lcov` (e.g. `sudo apt-get install lcov`).
