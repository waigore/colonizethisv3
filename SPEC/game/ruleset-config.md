# Ruleset & Config (Game)

**SPEC/game** — Implementation scope for data-driven game parameters. **Source of truth:** GDD 19. Ruleset & Config (Obsidian). See SPEC/project for Obsidian/spec sync.

---

## Categories

Parameters are grouped into: **units** (movement, strength, caps, costs), **map** (terrain costs, adjacency, starting provinces), **economy** (price modifiers, capacity, credit limits, turn timers), **combat** (base strength, difficulty modifiers, fort/terrain), **victory** (thresholds, score weights, custom win conditions), **AI** (difficulty resource modifiers, personality weights), **scenario** (starting units, treasury, relations, powers enabled).

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
