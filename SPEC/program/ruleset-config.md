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

## Consumers

colonizethis_logic and colonizethis_ai take a single ResolvedRuleset/GameConfig; no layer awareness. App receives resolved config at game load. Flutter does not perform merge or file parsing.
