# Repo Layout and Package Plan

**SPEC/program** — In-repo source of truth for repository structure and shared packages. Derived from **TDD 15 (Technical Architecture)**.

---

## Repo layout

Monorepo layout:

- **Root:** `SPEC/`, `packages/`, `app/`, **`ctterm/`**, optional `assets/`, **`tool/`** (standalone CLI tools), tooling (e.g. `analysis_options.yaml`).
- **Flutter app** lives under **`app/`** (not at root). Run and build from `app/` (e.g. `flutter run`, `flutter build macos`). Package work is done in `packages/<name>/`.
- **ctterm** lives at top-level **`ctterm/`** — standalone Dart TUI (Nocterm). Run via `dart run ctterm` or `melos run ctterm`. Uses its own Hive data directory; see [SPEC/tui/ctterm.md](../tui/ctterm.md).
- **Standalone CLI tools** (e.g. topology description, map generation) live under **`tool/`**. Run from the **project root** via **Melos**: `melos run <tool_name> -- [args]` (paths in args are relative to repo root). The repo uses a root Dart workspace and Melos for scripts; see [.cursor/rules/colonizethis-tools.mdc](../../.cursor/rules/colonizethis-tools.mdc). Tools may depend on colonizethis_data or a shared reader to load topology.
- **No `server/`** in current scope.

---

## Package list and responsibilities

Five shared Dart packages under `packages/`. TDD 15 allows merging _models and _save into _logic; we use **five separate packages**.

| Package | Contents (TDD 15) | Internal package deps |
|---------|-------------------|------------------------|
| **colonizethis_models** | Data models, schemas, serialization (Game, Player, Orders, WorldState, Province, Unit, etc.). Stockpile, WorkerPool. | None |
| **colonizethis_data** | Constants, tech tree, **static map data**: (1) **region topology** (nodes: provinces, sea zones; links P<->P, P<->S; cross-region); (2) **tile maps** (per region). Ruleset/config (e.g. `rules/` for JSON later). Topology and tile map **formats** and loaders; topology/tile-map **describe** helpers. | None |
| **colonizethis_map** | Topology and tile map **generation** (tile-based map generator), topology inference from tile map, tile map topology validation, and tile map **PNG visualization**. Implements TDD map generation algorithms; consumed by tools and loaders. | colonizethis_data |
| **colonizethis_save** | Save format, schema, migrations | colonizethis_models |
| **colonizethis_logic** | Turn resolution, combat, economy, diplomacy, victory checks, order validation (uses map topology for movement). Extraction, production, stockpile, worker models; tile map or terrain data for costs/combat. | colonizethis_models, colonizethis_data |
| **colonizethis_ai** | AI behavior, planning, personalities | colonizethis_logic |

**Config consumers:** colonizethis_logic and colonizethis_ai consume resolved config; app receives config at game load. See [ruleset-config.md](ruleset-config.md). Flutter does not perform merge or file parsing.

**Rule:** No UI in shared packages. Game logic lives only in shared packages; app is shell, routing, and integration.

**Riverpod in packages:** Canonical `Provider`s for logic/map/AI seams live in optional `di.dart` libraries; see [dependency-injection.md](dependency-injection.md).

---

## Dependency direction

```
app
 └── colonizethis_logic, colonizethis_models, colonizethis_ai, colonizethis_data, colonizethis_save

colonizethis_ai
 └── colonizethis_logic

colonizethis_logic
 └── colonizethis_models, colonizethis_data

colonizethis_save
 └── colonizethis_models

colonizethis_models  (no package deps)
colonizethis_data    (no package deps)
```

---

## Flutter app `lib/` structure (TDD 15)

Structure under `app/lib/`:

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── constants.dart
│   ├── routes.dart
│   └── themes.dart
├── core/
│   ├── models/
│   ├── services/
│   └── utils/
├── features/
│   ├── auth/
│   ├── game/
│   │   ├── flame/       # Flame components: map, battle, HUD (game canvas)
│   │   ├── map/
│   │   ├── orders/
│   │   ├── combat/
│   │   └── widgets/
│   ├── multiplayer/
│   ├── tutorial/
│   └── settings/
├── providers/
└── widgets/
```

Flame owns game canvas and in-game pixel-art UI; Flutter owns app shell, routes, and list/form screens. Communication only via state (Riverpod) and callbacks.
