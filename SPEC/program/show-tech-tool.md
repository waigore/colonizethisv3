# show_tech — Technology Tree and Query Tool

**SPEC/program** — CLI tool to view the full tech tree as a markdown diagram and to query individual techs (description, dependencies, effects). Reference: [tech-tree.md](../game/tech-tree.md) and category sub-docs.

---

## Purpose and Scope

- **Purpose:** Give developers a quick way to inspect the entire technology tree and to look up any tech by id (description, prerequisites, effects). No game state or save required; read-only.
- **Data source:** Same tech catalog as the game (colonizethis_data). The tool is a thin facade over colonizethis_data and a small diagram/query module.
- **Owner:** Program layer (Dart CLI under `tool/show_tech`). Invocation via melos (e.g. `melos run show_tech`) from repo root.

---

## Output Modes

### Default: Markdown diagram

- **Behaviour:** Emit the entire tech tree as a **markdown diagram** (e.g. DAG of techs with edges for prerequisites), grouped by era and/or category. Diagram can be written to stdout or to a file via an option.
- **Content:** All tech ids from the catalog, with directed edges from prerequisite → tech. Grouping (by era, then category) improves readability. No game-specific state (e.g. which techs a player has) is required.

### Interactive / query mode

- **Behaviour:** Accept a tech id and output for that tech: **description** (short text from catalog), **dependencies** (prerequisite ids and display names), **effects** (unlocks: regiments, civilian units, extraction/transport/diplomatic/labour effects as applicable).
- **Invocation:** Either `--interactive` (REPL: prompt for tech id, print result, repeat until exit) or a single-query form such as `show_tech query <techId>` (or `--query <techId>`). Invalid or unknown tech id returns a clear error and non-zero exit code.

---

## CLI Interface

- **Command:** `melos run show_tech -- [options]` or equivalent (e.g. `dart run tool/show_tech` with appropriate package wiring).
- **Options (examples):**
  - `--output <path>` (optional): Write the markdown diagram to this path instead of stdout.
  - `--interactive`: Run in interactive mode (prompt for tech id, print description/dependencies/effects).
  - `--query <techId>` (or subcommand `query <techId>`): Single-query mode; print info for the given tech id and exit.
- If neither interactive nor query is set, default is to emit the full diagram to stdout (or to `--output` if provided).

---

## Implementation Notes

- No dependency on colonizethis_models or colonizethis_logic beyond any shared types for tech ids; no Game or WorldState. Read-only access to colonizethis_data tech catalog.
- Diagram format: markdown (e.g. headings by era/category, lists or tables of techs with prerequisite arrows, or Mermaid-style block if desired). Exact format is implementation-defined as long as it is human-readable and reflects the full tree.
