# Ruleset & Config (Program)

**SPEC/program** — Implementation scope for loading and applying ruleset configuration. **Source of truth:** TDD 19. Ruleset & config — Implementation (Obsidian). See SPEC/project for Obsidian/spec sync.

---

## Where and Format

- **Package:** colonizethis_data (or dedicated colonizethis_ruleset). JSON files under `rules/` asset path.
- **Files:** `base.json`, `difficulty/introductory.json`, `difficulty/normal.json`, `difficulty/hard.json`, `difficulty/impossible.json`, `scenario/search_for_el_dorado.json` (and other scenarios).

---

## Load and Merge

- **When:** Game creation only. `GameSettings` includes `difficulty` and `scenarioId` (or null). Resolver runs once; result stored with the game.
- **Merge order:** Base → difficulty overlay → scenario overlay. Key-level replace (nested objects merged per key). Output: single **ResolvedRuleset** (or **GameConfig**) object.
- **Immutability:** No mid-game ruleset reload in production.

---

## Example Scenario

**Search for El Dorado** (`scenario/search_for_el_dorado.json`): Overrides victory (primary = exploration_el_dorado, gold_bonus 500), units (explorer prospect_speed_multiplier 2.0), economy (riches_cash_multiplier 1.5), scenario (starting_treasury_bonus 200, description_key). Base + chosen difficulty + this file → resolved config.

---

## Debug Exception

Debug builds only: a debug console (or dev menu) may allow inspecting and optionally changing resolved parameters for the live session. Changes are not persisted and not used for multiplayer authority. This is the only allowed path to change ruleset-derived parameters after game start.

---

## Turn-Time Mapping

| Key path / concept | Base | Difficulty | Scenario |
|--------------------|------|------------|----------|
| turnTimeMapping (startYear, cutoffYear, yearsPerTurnBeforeCutoff, yearsPerTurnAfterCutoff) | ✓ (GDD 01 default) | — | ✓ (post-MVP) |

Structure: `{ startYear, cutoffYear, yearsPerTurnBeforeCutoff, yearsPerTurnAfterCutoff }`. See [turn-time-mapping.md](../game/turn-time-mapping.md).

---

## Consumers

colonizethis_logic and colonizethis_ai take a single ResolvedRuleset/GameConfig; no layer awareness. App receives resolved config at game load. Flutter does not perform merge or file parsing.

---

## Naming (default ruleset)

The resolved ruleset includes a **naming** section that drives historically inspired names:

- `naming.greatPowers`: array where each entry contains:
  - `id`: internal id (e.g. `gp1`).
  - `countryName`: display name (e.g. `Spain`).
  - `adjective`: e.g. `Spanish`.
  - `leaderKey`: key into the GDD leader definition for this power.
  - `capitalCityName`: primary capital city name (e.g. `Madrid`).
  - `provinceNamePool`: ordered list of homeland province/region names.
- `naming.minorNations`: array of `{ id, displayName, provinceNamePool? }`.
- `naming.tribes`: array of `{ id, displayName }`.

Resolver output exposes this as a `ResolvedNamingConfig` (or equivalent) that colonizethis_logic uses during game setup to assign:

- `Province.displayName` (for Great Powers, Minor Nations, Tribes) and
- capital city display names per faction (from `capitalCityName`).

The **default ruleset** is historically inspired and aligned with the GDD’s Great Power & leader definitions; alternative scenarios may override naming while keeping the same structure.
