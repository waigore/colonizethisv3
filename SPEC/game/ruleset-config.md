# Ruleset & Config (Game)

**SPEC/game** — Implementation scope for data-driven game parameters. **Source of truth:** GDD 19. Ruleset & Config (Obsidian). See SPEC/project for Obsidian/spec sync.

---

## Categories

Parameters are grouped into: **units** (movement, strength, caps, costs), **map** (terrain costs, adjacency, starting provinces), **economy** (price modifiers, capacity, credit limits, turn timers), **combat** (tactical stats per regiment: FPN, FPM, RNG, DEF, MVR; terrain modifiers; fort level modifiers; difficulty multipliers; initiative weights; medal multipliers), **victory** (thresholds, score weights, custom win conditions), **AI** (difficulty resource modifiers, personality weights), **scenario** (starting units, treasury, relations, powers enabled), **game/setup** (Great Power count, continent count, Minor Nation count, Tribe count).

**Map:** **Adjacency** is defined by the topology graph ([world-model.md](world-model.md), [map-topology.md](map-topology.md)). **Terrain**, **resources**, and **improvements** may come from the tile map or config overlays.

**Game/setup:** **Great Power count** (default 7), **continent count** (e.g. 3–4), **Minor Nation count** (e.g. 6), **Tribe count** (e.g. 10). Defined in base or scenario. See [game-setup.md](game-setup.md).

---

## Layers

- **Base:** Default balance; single source for all parameters.
- **Difficulty:** Introductory | Normal | Hard | Impossible. Overrides AI resource modifiers, combat difficulty bonuses, advisor/tutorial toggles.
- **Scenario:** Optional (e.g. `tutorial`, `search_for_el_dorado`). Overrides starting setup, victory condition, map/objectives, unit caps, scenario-specific modifiers.

**Order:** Base → Difficulty → Scenario. Later layers override earlier for specified keys only.

---

## Overridable Parameter Contract

GDD 19 defines the exact keys (or key paths) each layer may override, per category. Design meaning of each lever lives in GDD 04, 05, 06, 09, 10, 16; this spec and GDD 19 form the **contract** so implementation stays aligned. Do not add overridable keys without updating GDD 19.

---

## Immutability

Ruleset is fixed at game creation and cannot be changed during play except via a debug facility (see TDD 19 / SPEC/program).
