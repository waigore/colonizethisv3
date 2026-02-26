# Ruleset & Config — Implementation

## Responsibility
Load, merge, and expose ruleset configuration at game creation. Game rules: [ruleset-config.md](../game/ruleset-config.md).

## Scope (MVP)
**MVP uses program-level config only.** No JSON load or merge from `rules/` asset path in MVP. Base → Difficulty → Scenario merge is deferred until the ruleset loader is implemented. Current behaviour: config (e.g. GameSetupConfig, default naming) is supplied from code constants / colonizethis_data. See [game-setup-pipeline.md](game-setup-pipeline.md) § Data Model (GameSetupConfig), #57 (loader tracking), and #235 for current behaviour.

## Data Model

### File Format
JSON files under `rules/` asset path: `base.json`, `difficulty/{level}.json`, `scenario/{id}.json`.

### Resolved Ruleset
Single merged object containing all category parameters (units, map, economy, combat, victory, AI, scenario, game/setup) plus naming and turn-time mapping sections.

**Naming structure:**
- `greatPowers`: registry keyed by semantic id. Fields: `id`, `countryName`, `adjective`, `capitalCityName`, `leaderVariants[]` (`{ id, name, leaderKey, provinceNamePool? }`).
- `minorNations[]`: `{ id, displayName, provinceNamePool? }`.
- `tribes[]`: `{ id, displayName, provinceNamePool? }`.

**Turn-time mapping:** `{ startYear, cutoffYear, yearsPerTurnBeforeCutoff, yearsPerTurnAfterCutoff }`. See [turn-time-mapping.md](../game/turn-time-mapping.md).

## Algorithm / Flow

### Merge
1. Load `base.json`.
2. If difficulty is set, overlay `difficulty/{level}.json`.
3. If scenario is set, overlay `scenario/{id}.json`.
4. Key-level replace; nested objects merged per key.
5. Output: single resolved object, stored with the game.

### Debug Exception
Debug builds only: dev menu may inspect and change resolved parameters for the live session. Changes not persisted; not used for multiplayer authority.

## Integration

- **Phase:** Game creation only. Game settings include difficulty and scenario id.
- **Upstream:** JSON asset files in `rules/` path (package `colonizethis_data`).
- **Downstream:** `colonizethis_logic` and `colonizethis_ai` consume the resolved ruleset; no layer awareness. App receives resolved config at game load; Flutter does not perform merge or parsing.

## Constraints
- Resolved ruleset is read-only after creation.
- Consumers depend only on the merged result, not layer structure.
- Province naming at setup uses the resolved naming section; see [ruleset-config.md](../game/ruleset-config.md) for naming rules.

## Acceptance criteria
- **Read-only after creation:** Given a game has been created with a resolved ruleset, when any consumer (logic, AI, app) reads config during play, then the system exposes the same merged result and no component may mutate it.
- **Consumer contract:** Given a resolved ruleset, when colonizethis_logic or colonizethis_ai consume config, then they depend only on the merged result and do not depend on layer structure (Base/Difficulty/Scenario).
- **Merge order (when JSON merge is implemented):** Given JSON files under `rules/` (base, optional difficulty, optional scenario), when the ruleset loader runs at game creation, then merge order is: (1) load base.json, (2) overlay difficulty/{level}.json if set, (3) overlay scenario/{id}.json if set, (4) key-level replace with nested merge, (5) output stored with the game; logic and AI consume only this merged result.
- **Resolved structure:** Given the resolved ruleset, when consumers read it, then the object contains naming (greatPowers, minorNations, tribes per Data Model) and turn-time mapping; when turn-time mapping is absent, default is per [turn-time-mapping.md](../game/turn-time-mapping.md) (e.g. GDD 01).
- **Province naming at setup:** Given game setup has run with a resolved ruleset, when provinces are named, then setup uses the resolved naming section per [ruleset-config.md](../game/ruleset-config.md) and [naming.md](../game/naming.md).
