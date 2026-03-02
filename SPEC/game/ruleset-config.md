# Ruleset & Config

## Overview
Data-driven game parameters organized in categories and layers, fixed at game creation.

## Rules

### Categories
Parameters are grouped into: **units** (movement, strength, caps, costs), **map** (terrain costs, adjacency, starting provinces), **economy** (price modifiers, capacity, credit limits, turn timers), **combat** (FPN, FPM, RNG, DEF, MVR; terrain/fort/difficulty modifiers; initiative weights; medal multipliers; leader bonus table — MVP: not in ruleset, see [leader-bonuses.md](leader-bonuses.md) § Where defined (MVP)), **victory** (thresholds, score weights, custom win conditions), **AI** (difficulty resource modifiers, personality weights), **scenario** (starting units, treasury, relations, powers enabled), **game/setup** (Great Power count, continent count, Minor Nation count, Tribe count, minimum provinces per Minor Nation, Old World/New World province counts).

**Map:** Adjacency from topology graph ([world-model.md](world-model.md), [map-topology.md](map-topology.md)). Terrain, resources, and improvements may come from tile map or config overlays.

### Layers
- **Base:** Default balance; single source for all parameters.
- **Difficulty:** Introductory | Normal | Hard | Impossible. Overrides AI resource modifiers, combat difficulty bonuses, advisor/tutorial toggles.
- **Scenario:** Optional (e.g. tutorial, Search for El Dorado). Overrides starting setup, victory condition, map/objectives, unit caps, scenario-specific modifiers.

**Order:** Base → Difficulty → Scenario. Later layers override earlier for specified keys only.

### Overridable Parameter Contract
This spec defines the exact keys each layer may override, per category. Do not add overridable keys without updating this contract.

### Immutability
Ruleset is fixed at game creation and cannot be changed during play except via a debug facility (see [ruleset-config.md](../program/ruleset-config.md)).

### Naming
The ruleset includes a **naming** section for historically inspired names:

- **Great Powers:** Keyed by semantic id (e.g. england, france, spain). Each entry: id, country name, adjective, capital city name, leader variants (id, name, leader key, optional province name pool). Default variant is first; setup config chooses which variant.
- **Minor Nations:** Default 6 entries with display names and province name pools (5 names each). Capital province receives first name in pool.
- **Tribes:** Default 10 entries with display names and province name pools (5 names each). Capital receives first name; others randomized (seed-based).
- **Fallback:** Empty pool or missing entry → deterministic procedural name (see [naming.md](naming.md)).

Setup names all provinces owned by each faction at creation. Provinces acquired during play retain existing display name. Scenarios may override naming while keeping the same structure.

### Turn-time mapping

The resolved ruleset includes a **turn-time mapping** section that defines how turn numbers map to calendar years for narrative and UI; see [turn-time-mapping.md](turn-time-mapping.md) for structure and defaults (`startYear`, `cutoffYear`, `yearsPerTurnBeforeCutoff`, `yearsPerTurnAfterCutoff`).

- **MVP default:** When the resolved ruleset does not supply turn-time mapping, game setup uses the default GDD 01 mapping (`TurnTimeMapping.gdd01`) when initializing `Game.turnTimeMapping`. See [turn-time-mapping.md](turn-time-mapping.md) and [game-setup-pipeline.md](../program/game-setup-pipeline.md) step 7e.

## Configurable Values

| Parameter | Default | Layer |
|-----------|---------|-------|
| Great Power count | 6 | Base, Scenario |
| Minor Nation count | 6 | Base, Scenario |
| Tribe count | 10 | Base, Scenario |
| Min provinces per Minor | 3 | Base, Scenario |
| Old World provinces | ≈60 | Base, Scenario |
| New World provinces | ≈80 | Base, Scenario |
| Continent count | 3–4 | Base, Scenario |

Turn-time mapping parameters are part of the resolved ruleset but documented in [turn-time-mapping.md](turn-time-mapping.md). Scenarios or future ruleset layers may override the mapping as a whole; when no mapping is present in the resolved ruleset, the System uses the default described there.

## Interactions
- [world-model.md](world-model.md), [map-topology.md](map-topology.md) — adjacency, terrain
- [game-setup.md](game-setup.md) — setup counts
- [naming.md](naming.md) — fallback naming
- Program: [ruleset-config.md](../program/ruleset-config.md) — loading, merge, data model


## Acceptance Criteria

- **Immutability:** Given a resolved ruleset at game creation, when the game is in progress, then the ruleset parameters are fixed and cannot be changed except through a documented debug facility.

- **Merge order:** Given ruleset layers (Base, Difficulty, Scenario) in the resolved ruleset, when the System loads the ruleset, then later layers override only the keys they specify, following the order Base → Difficulty → Scenario.

- **Naming structure:** Given a resolved ruleset with a naming section, when the System uses names for Great Powers, Minor Nations, and Tribes, then it uses the structure defined in this GDD (id, display name, name pools) and applies the fallback per [naming.md](naming.md) when entries or pools are missing.

- **Configurable Values table:** Given the Configurable Values table in this GDD, when the System initializes game parameters, then it uses these as the default source of values; scenario or difficulty layers may override per the overridable parameter contract.

- **Province naming at setup:** Given a game in the setup phase, when the System names provinces owned by each faction, then it uses the resolved naming section from the ruleset. Provinces acquired during play retain their existing display name.
