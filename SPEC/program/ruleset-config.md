# Ruleset & Config — Implementation

## Responsibility
Load, merge, and expose ruleset configuration at game creation. Game rules: [ruleset-config.md](../game/ruleset-config.md).

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
