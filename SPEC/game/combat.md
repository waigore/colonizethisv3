# Combat

## Overview

Auto-resolved combat triggers when units move into enemy-controlled provinces. Battles are deterministic, with initiative-ordered multi-attacker chains resolved per province.

## Rules

**Trigger:** A unit's move ending in an enemy-owned province constitutes an attack. Only Great Powers initiate; Minor Nations and Tribes defend only.

**Attacker / Defender:** Attacker = faction that moved in. Defender = province owner (tie-break: lowest faction id). One defender per province; multiple attackers possible.

**Battle Mode:** Field (fort level 0, terrain modifiers) or Siege (fort level ≥ 1; walls, emplaced artillery per [siege-mechanics.md](siege-mechanics.md)).

**Initiative:** `initiative = cavalryShare × W_cav + generalMedals × W_medal`, where `cavalryShare = cavalry regiments / total regiments`.

**Multi-Attacker Chain:** Sort attackers by initiative descending (tie-break: faction id). Resolve sequentially: defender vs highest-initiative attacker; winner (no heal) vs next attacker; repeat until no attackers remain or defender eliminated.

**Strength:** Per-regiment FPN + FPM (from [military-units.md](military-units.md)). Medals (0–4) multiply by 1.0–1.4. DEF durability = DEF / 9. Damaged units: firepower ∝ remaining / starting health. Side strength = `Σ (FPN_eff + FPM_eff) × medalMult`, adjusted by modifiers. **Current auto-resolve:** Strength aggregation uses (FPN + FPM) × medalMult only; DEF/9 and damaged-unit health scaling are deferred (no unit health field; casualty selection uses strength-weighted choice).

**Modifiers:** Terrain (province type), fort (level 0–3; damage reduction + emplaced guns per [siege-mechanics.md](siege-mechanics.md)), difficulty (scales attacker/defender; deferred in auto-resolve until difficulty is wired from game config), general (+1 deployment per medal + initiative contribution), leader (per [leader-bonuses.md](leader-bonuses.md)), feeding coverage (see table below).

**Resolution:** Compare total attacker vs defender strength after modifiers. Deterministic output: winner + casualties per side.

**Outcomes:** Attacker victory (defender eliminated → province flips), defender victory (attacker eliminated, no change), stalemate (both survive, no flip), mutual annihilation (both wiped; defender recovers 20% rounded up of initial regiments if further attackers remain, otherwise ungarrisoned).

**Province Flip:** Immediate on defender elimination, before later same-province battles. Connectivity/extraction recompute next turn.

## Acceptance Criteria

- Given a province owned by a defending faction with fort level between 0 and 3 inclusive and at least one defending regiment  
  When a Great Power moves at least one attacking regiment into that province and the move ends in that province  
  Then the system starts a combat resolution for that province, designates the moving faction as the attacker, designates the province owner (or, on ownership ties, the lowest faction id) as the defender, and selects `Field` battle mode when fort level = 0 or `Siege` battle mode when fort level ≥ 1.

- Given one defender and two or more attacking factions each with at least one regiment in the same province  
  When the system resolves combat for that province  
  Then the system computes initiative for each attacker as `initiative = cavalryShare × W_cav + generalMedals × W_medal`, breaks ties by ascending faction id, and orders the attackers from highest to lowest initiative for the multi-attacker chain.

- Given a defender and an ordered list of attackers as defined above, each with at least one regiment remaining  
  When the system executes the multi-attacker chain for that province  
  Then the system first resolves a battle between the defender and the highest-initiative attacker, and for each subsequent attacker it resolves a new battle between the previous battle’s winner (without healing or regenerating regiments) and the next attacker in the ordered list until either all attackers are eliminated or the defender side is eliminated.

- Given a defender and one or more attackers with regiment-level stats (FPN, FPM, medals, DEF) and combat modifiers (terrain, fort, difficulty, leaders, feeding coverage) defined in the active ruleset  
  When the system computes side strength for auto-resolve combat in that province  
  Then the system aggregates each side’s strength as the sum over that side’s regiments of `(FPN + FPM) × medalMultiplier`, applies the configured combat modifiers to the aggregated totals, and uses these modified totals as the only inputs to decide the winner and casualty distribution for the current auto-resolve implementation (deferring DEF/9 and damaged-unit health scaling until unit health is introduced into the model).

- Given a combat where the aggregated attacker strength after modifiers is strictly greater than the aggregated defender strength  
  When the system completes combat resolution for that province  
  Then the system declares an attacker victory, eliminates all defending regiments, flips province ownership to the attacker faction that was last in the chain, and marks the province as owned by that attacker for subsequent turns while leaving connectivity and extraction recomputation to the next turn-processing step.

- Given a combat where the aggregated defender strength after modifiers is greater than or equal to the aggregated attacker strength and the defender still has at least one regiment remaining at the end of resolution  
  When the system completes combat resolution for that province  
  Then the system declares a defender victory, eliminates all attacking regiments in that province, keeps province ownership with the defending faction, and does not trigger a province flip.

- Given a combat where both the attacker side and the defender side lose all regiments in the final exchange, and there is at least one additional attacker faction remaining in the multi-attacker chain for that province  
  When the system completes the current attacker–defender exchange  
  Then the system records a mutual annihilation outcome for that exchange, restores a new defending garrison equal to 20% of the defender’s initial regiment count in that battle rounded up, and continues the multi-attacker chain using this restored defending garrison against the next attacker faction.

- Given a combat where both the attacker side and the defender side lose all regiments in the final exchange and there are no further attackers remaining in the multi-attacker chain  
  When the system completes combat resolution for that province  
  Then the system records a mutual annihilation outcome for the province, keeps the original defending faction as the province owner, and leaves the province ungarrisoned with zero defending regiments.

- Given a combat where both the attacker side and the defender side have at least one regiment remaining after applying casualties for the final exchange  
  When the system completes combat resolution for that province  
  Then the system records a stalemate outcome for the province, preserves the existing province owner, and leaves all surviving attacker and defender regiments in place without flipping province ownership.

- Given two combat resolutions for the same province in the same game state with identical unit compositions, stats, modifiers, and move orders  
  When the system executes combat resolution for that province both times  
  Then the system produces the same ordered sequence of battle pairings, the same winner for the overall province combat, the same casualty counts per faction and side, and the same province ownership outcome in both executions.

## Configurable Values

| Parameter | Default | Notes |
|---|---|---|
| W_cav | 1.0 | Initiative cavalry weight — **CLARIFICATION NEEDED:** verify against Imperialism II |
| W_medal | 0.5 | Initiative medal weight — **CLARIFICATION NEEDED:** verify against Imperialism II |
| Medal multipliers | 1.0 / 1.1 / 1.2 / 1.3 / 1.4 | Per medal level 0–4 |
| DEF divisor | 9 | Durability scaling |
| Recovery % | 20% (ceil) | Mutual-annihilation garrison |
| Feeding modifiers | 1.0 / 0.75 / 0.5 | Coverage ≥ 1.0 / 0.5–1.0 / < 0.5 |
| Terrain modifiers | Per terrain type | In ruleset config |
| Fort modifiers | Per fort level 0–3 | In ruleset config |
| Difficulty modifiers | Per difficulty level | In ruleset config |

## Interactions

- Unit stats: [military-units.md](military-units.md)
- Siege rules: [siege-mechanics.md](siege-mechanics.md)
- Factions / minor parity: [factions.md](factions.md)
- Ruleset config: [ruleset-config.md](ruleset-config.md)
- Resolution pipeline: [../program/combat-resolution.md](../program/combat-resolution.md)

## Open Questions

1. W_cav / W_medal values — Imp2 confirms factors, no numeric weights.
2. FPN + FPM blending — simple sum or range/melee phase weighting.
3. Auto-resolve formula details: (a) strength ratio → winner, (b) casualties from differential + DEF/9, (c) unit-by-unit vs proportional casualties.
4. Feeding modifier — provisional; Imp2 has no unfed penalty. Confirm mechanic and thresholds.
