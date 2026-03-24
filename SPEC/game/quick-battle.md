# Quick Battle (one-province tactical combat)

## Purpose and current phase scope

Quick Battle is a one-province attacker-vs-defender tactical resolver used by combat mode `quickBattle`. It must stay deterministic for a fixed seed and feed the same casualty/ownership pipeline as auto-resolve.

Current implementation scope (owner-confirmed decisions):

- One attacking side vs one defending side per battle context.
- Maximum 3 rounds.
- 2-3 Command Points (CP) per side each round.
- Initiative ordering uses the combat initiative formula.
- Terrain is OPEN-only for this phase.
- Effective strength is intentionally count-based for this phase.
- Multi-lane tactical deployment and full collapse model are deferred.

## Battlefield layout

Quick Battle data model supports lanes/lines, but current deployment is intentionally simplified:

- Attacker groups: `CENTER + FRONT` only.
- Defender groups: `CENTER + FRONT` only.
- Initial cohesion: 3 for both sides.

Future expansion may enable `LEFT/RIGHT/RESERVE` and richer line management.

## Terrain

Current phase uses OPEN-only lane terrain (`QuickBattleLaneTerrain.open`) for both sides.

- Province terrain still exists in battle context and may influence shared province-level combat modifiers.
- Province-to-lane terrain mapping (HILL/WOODS/TOWN/SWAMP) is deferred.

## Emplaced fort artillery (virtual units)

When the battle is a **siege** (`fortLevel ≥ 1` per [siege-mechanics.md](siege-mechanics.md)), the System **injects virtual emplaced gun entities** for the **defender** only. They are **not** stored as `Unit` records on the province map; they are created when Quick Battle input is built and discarded after the battle.

- **Count:** Matches fort level (1 / 2 / 3 guns). **Stats:** Each has **HP** and **attack** and **defense** strength derived from ruleset tables and the defender’s emplaced-quality tech (Royal → Heavy → Siege) per [tech-tree-military.md](tech-tree-military.md); **+1 RNG** vs same-era heavy artillery baseline applies when resolving their fire. **Assignment:** The System auto-places them **behind the fort** in a single deterministic slot (e.g. defender `CENTER` + `SUPPORT`, or a documented “battery” attachment to that lane — exact placement is fixed in SPEC/program so seeds replay identically).
- **Targeting:** Quick Battle actions that deal damage to defender combatants **may** allocate damage to these virtual guns per the technical spec (which actions hit the battery first vs front-line regiments is defined in [quick-battle-resolution.md](../program/quick-battle-resolution.md)).
- **Field artillery:** Attacker and defender **regiment** artillery remain normal units in battalion groups. Virtual emplaced guns **do not** duplicate them.

**Integration:** When Quick Battle ends, if **every** virtual emplaced gun was destroyed, the combat pipeline **must** decrement province `fortLevel` by 1 (floor at 0) when applying results, regardless of whether the province flips. The Quick Battle resolver **must not** add a parallel lump-sum emplaced strength term for those same guns (no double-counting).

## Cohesion and effective strength

Each group has cohesion on a 0-3 integer scale. Current implementation uses cohesion as a multiplier.

Current phase formula:

- Group effective strength = `unitCount * (cohesion / 3) * laneModifier`.
- Lane modifier is OPEN baseline for current phase behavior.
- Side effective strength = sum of group effective strengths, then action modifiers and province-level combat modifiers are applied.

This count-based formula is intentional for now. Tactical-stat-based QB (`FPN/FPM` aggregation) is deferred.


## Turn structure and actions

Quick Battle proceeds in at most 3 rounds. In each round:

1. Determine first-acting side using combat initiative score:
   `initiative = cavalryShare * W_cav + generalMedals * W_medal`.
   Tie-break is deterministic by `factionId` lexical order.
2. First side receives 2-3 CP and spends actions.
3. Second side receives 2-3 CP and spends actions.
4. Resolve combat effects in initiative order, then update casualties and cohesion.

Core actions (exact numeric modifiers in technical spec):

- **Volley Fire (1 CP):** Front-line units (and eligible artillery/support) in a chosen lane fire at the opposing front-line group. Terrain and cohesion adjust hit chances and losses.
- **Defend / Entrench (1 CP):** Set a lane to a defensive stance for the round, improving defense (especially in `HILL`, `WOODS`, `TOWN`) at the cost of maneuverability.
- **Maneuver (1 CP):** Rotate `FRONT`/`SUPPORT` within a lane, or move a group between `RESERVE` and a lane. Maneuvering through bad terrain or while under heavy pressure can cost cohesion.
- **Fall Back / Refuse Flank (2 CP):** Pull a front-line group back to `RESERVE` (and optionally replace it) to avoid destruction, or deliberately weaken a flank to reinforce `CENTER` or the opposite flank. This trades space and cohesion for preservation of forces.
- **Assault / Charge (2 CP):** Launch a high-risk, high-reward attack in one lane, especially suited for cavalry or high-MVR infantry. Very strong against disrupted or badly positioned enemies; much weaker into `WOODS`, `TOWN`, or uphill `HILL`.

Players use CP to choose when to defend, when to trade space, when to concentrate fire, and when to attempt decisive assaults. Skilled use of terrain and timing allows weaker forces to inflict favorable losses or occasionally win against stronger opponents.

## Outcome and integration

Current phase outcome does not use full lane-collapse rules. After up to 3 rounds:

- If defender has no surviving units, winner is attacker and `provinceFlips = true`.
- If attacker has no surviving units, winner is defender and `provinceFlips = false`.
- Otherwise final strength ratio decides attacker/defender hold or mutual exhaustion.

Quick Battle does **not** change the underlying combat formula for **map regiments**; it supplies structured inputs (lane-level strengths, modifiers, cohesion effects) into the resolution pipeline and receives standard outputs. **Siege Quick Battle** additionally runs the **virtual emplaced gun** model above, which replaces the aggregate emplaced defender bonus for that path only:

- Casualty lists for both sides.
- Whether the province flips to the attacker or remains with the defender (consistent with combat and siege rules).

The game then applies casualties and province ownership changes using the same world-state update logic as auto-resolve.

---

## Acceptance Criteria

- Given one Quick Battle battle context with one attacker side and one defender side  
  When the System builds Quick Battle input  
  Then the System places all attacker units in `CENTER/FRONT`, all defender units in `CENTER/FRONT`, and sets each created group cohesion to integer `3`.

- Given Quick Battle input built by the current phase input builder  
  When the System sets lane terrain for attacker and defender deployments  
  Then the System sets `center_front` to enum `open` for both sides and does not assign `hill`, `woods`, `town`, or `swamp`.

- Given a Quick Battle round with attacker cavalry share `A`, defender cavalry share `D`, attacker general medals `GA`, defender general medals `GD`, and config weights `W_cav`, `W_medal`  
  When the System determines acting order  
  Then the System computes `attackerInitiative = A * W_cav + GA * W_medal` and `defenderInitiative = D * W_cav + GD * W_medal`, and the side with the higher score acts first; if scores are equal, the lower lexical `factionId` acts first.

- Given a Quick Battle group with `unitCount > 0` and cohesion integer range `0..3`  
  When the System computes group effective strength in the current phase  
  Then the System uses `unitCount * (cohesion / 3)` as the base group strength and applies action/province modifiers without requiring regiment tactical stats (`FPN`/`FPM`).

- Given two Quick Battle runs with the same Quick Battle seed and identical battle context, lane composition, and initial cohesion  
  When the System runs the Quick Battle resolver for both  
  Then the System produces the same battle result (ATTACKER, DEFENDER, or MUTUAL_EXHAUSTION), the same per-side casualty counts, and the same provinceFlips value in both runs.

- Given a Quick Battle has completed with a decisive attacker win and the resolver returns provinceFlips true  
  When the combat pipeline applies the Quick Battle result to the game state  
  Then the System flips province ownership to the attacker and applies casualties using the same world-state update logic as auto-resolve; given a defender hold or mutual exhaustion result, the System does not flip province ownership.

- Given a siege Quick Battle (`fortLevel` 1, 2, or 3) is initialized for a province  
  When the System builds Quick Battle input  
  Then the System includes the correct count of virtual emplaced gun entities with per-gun HP and attack/defense per [siege-mechanics.md](siege-mechanics.md), places them behind the fort in the documented lane/line slot, and does not add duplicate virtual guns for defender field artillery regiments already on the map.

- Given a siege Quick Battle is in progress and at least one virtual emplaced gun has remaining HP  
  When a Quick Battle action that can deal damage to the defender resolves  
  Then the System may reduce emplaced gun HP (or destroy guns) according to [quick-battle-resolution.md](../program/quick-battle-resolution.md); destroyed guns do not contribute further offense or defense for that battle.

- Given a siege Quick Battle completes and every virtual emplaced gun was destroyed during the battle  
  When the combat pipeline applies the Quick Battle result to world state  
  Then the System sets the province `fortLevel` to `max(0, previousFortLevel - 1)` regardless of `provinceFlips` or mutual exhaustion, and applies regiment casualties and ownership per existing rules.

