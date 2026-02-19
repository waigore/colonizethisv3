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

- `naming.greatPowers`: registry keyed by semantic id, aligned with GDD 09. Each entry contains:
  - `id`: semantic id (e.g. `england`, `france`, `spain`, `portugal`, `netherlands`, `prussia`, `sweden`).
  - `countryName`: display name (e.g. `England`).
  - `adjective`: e.g. `English`.
  - `capitalCityName`: primary capital city name (e.g. `London`).
  - `leaderVariants`: array of `{ id, name, leaderKey, provinceNamePool? }`. Default variant is first. When a GP has multiple variants, setup config specifies which is chosen; province pool comes from the chosen variant (or GP default).
- `naming.minorNations`: array of `{ id, displayName, provinceNamePool? }`. The **default** ruleset provides **6** entries (`minor1`–`minor6`) with display names and province name pools from **GDD 09b (Minor Nations)**: Italy, Germany, Austria, Poland, Denmark, Scotland. Each pool has 5 province names (GDD "Starting Provinces" table). The **capital province** receives the first name in the pool.
- `naming.tribes`: array of `{ id, displayName, provinceNamePool? }`. The **default** ruleset provides **10** entries (`tribe1`–`tribe10`) with display names and province name pools from **GDD 09c (New World Tribes)**: Aztec, Maya, Inca, Muisca, Taíno, Powhatan, Iroquois, Cherokee, Sioux, Mapuche. Each pool has 5 province names. The **capital province** receives the first name in the pool; other provinces are named from the pool in randomized order (seed-based). If a faction has no entry or an empty pool/capital name, province naming falls back to a deterministic procedural name (see [naming.md](../game/naming.md)#fallback-when-naming-is-missing-or-empty).

Resolver output exposes this as a `ResolvedNamingConfig` (or equivalent) that colonizethis_logic uses during game setup to assign:

- `Province.displayName` (for Great Powers, Minor Nations, Tribes) and
- capital city display names per faction (from `capitalCityName`).

Setup names **all** provinces owned by each faction at setup (GPs and minors: all Old World provinces; tribes: all New World provinces); there is no landmass restriction. Provinces acquired during play retain their existing display name.

The **default ruleset** is historically inspired and aligned with the GDD’s Great Power & leader definitions (GDD 09) and with **GDD 09b (Minor Nations)** and **GDD 09c (New World Tribes)** for minor and tribe naming; alternative scenarios may override naming while keeping the same structure.
