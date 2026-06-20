# Combat

## Overview

Auto-resolved combat triggers when **armies** move into enemy-controlled provinces ([military-armies.md](military-armies.md)); all regiments in the attacking army attack together. Battles are deterministic, with initiative-ordered multi-attacker chains resolved per province.

## Rules

**Trigger:** An **army** move ending in an enemy-owned province constitutes an attack (all regiments in that army participate). Only Great Powers initiate; Minor Nations and Tribes defend only. Province ids used in conflict detection, battle context construction, and combat resolution follow [world-model-identity.md](world-model-identity.md): all province ids are the prefixed `regionId|localId` form, not bare local ids.

**Attacker / Defender:** Attacker = faction that moved in. Defender = province owner (tie-break: lowest faction id). One defender per province; multiple attackers possible.

**Battle Mode:** Field (fort level 0, terrain modifiers) or Siege (fort level ≥ 1; walls, emplaced artillery per [siege-mechanics.md](siege-mechanics.md)).

**Initiative:** `initiative = cavalryShare × W_cav + generalMedals × W_medal`, where `cavalryShare = cavalry regiments / total regiments`. If two attackers have equal initiative, tie-break with one deterministic RNG roll for the battle context (seeded by combat seed and battle context identity), not lexical faction id.

**Multi-Attacker Chain:** Sort attackers by initiative descending, using the deterministic battle-context RNG tie-break for exact initiative ties. Resolve sequentially: defender vs highest-initiative attacker; winner (no heal) vs next attacker; repeat until no attackers remain or defender eliminated.

**Strength:** Per-regiment FPN + FPM (from [military-units.md](military-units.md)). Medals (0–4) multiply by 1.0–1.4. DEF durability = DEF / 9. Damaged units: firepower ∝ remaining / starting health. Side strength = `Σ (FPN_eff + FPM_eff) × medalMult`, adjusted by modifiers. **Current auto-resolve:** Strength aggregation uses (FPN + FPM) × medalMult only; DEF/9 and damaged-unit health scaling are deferred (no unit health field; casualty selection uses strength-weighted choice).

**Modifiers:** Terrain (province type), fort (level 0–3; damage reduction + emplaced guns per [siege-mechanics.md](siege-mechanics.md)), difficulty (scales attacker/defender; deferred in auto-resolve until difficulty is wired from game config), general (+1 deployment per medal + initiative contribution), leader (per [leader-bonuses.md](leader-bonuses.md), including fallback medal derivation when no uncommitted general is available), feeding coverage (see table below).

**Resolution:** Compare total attacker vs defender strength after modifiers. Deterministic output: winner + casualties per side.

**Outcomes:** Attacker victory (defender eliminated → province flips), defender victory (attacker eliminated, no change), stalemate (both survive, no flip), mutual annihilation (both wiped; defender recovers 20% rounded up of initial regiments if further attackers remain, otherwise ungarrisoned).

**Garrison recovery type (mutual annihilation, chain continues):** Each recovered regiment uses the **same** regiment type: the defender faction’s **most advanced infantry** for its **effective military era** `E` (Great Power `E = 4`; Minor Nation / Tribe per [factions.md](factions.md)). **Infantry-eligible** catalog entries are those that are **not** cavalry and **not** artillery ([military-units.md](military-units.md) roster / `RegimentCategory`). **Advancement** is `FPN + FPM` on the catalog row for era `E` (matches auto-resolve strength basis). **Tie-break:** among types tied on `FPN + FPM`, choose the **lexicographically smallest** regiment `id` (ASCII). **Fallback:** if no infantry-eligible row exists for `E`, use `peasant_levies`. **Implementation:** `garrisonRecoveryRegimentTypeForEra` in `combat_config.dart`; applied in `resolveBattleContext` when spawning `recover_*` units.

**Province Flip:** After **defender armies are eliminated** (no defending regiments remain in the province for the defender faction). Army casualties and army removal are applied **before** ownership flips; see [military-armies.md](military-armies.md). Flip is immediate when the defender has no regiments left, before later same-province battles in the chain. Connectivity/extraction recompute next turn.

**Unopposed capture:** When a Great Power **army** ends movement in a province owned by a faction **at war** with that GP, and the province contains **no** combat-capable units belonging to the province owner and **no** combat-capable units of any third faction, the province transfers to the capturing GP **immediately** at the start of the combat phase (before standard battle detection). If multiple eligible GPs moved armies into the same province this turn, the capturer is the **lexicographically smallest** eligible GP id. Implementation: `applyUnopposedProvinceCaptures` in `packages/colonizethis_logic`.

## Acceptance Criteria

- Given a province owned by a defending faction with fort level between 0 and 3 inclusive and at least one defending regiment (via a defending army)  
  When a Great Power moves an **attacking army** into that province and the move ends in that province  
  Then the system starts a combat resolution for that province, designates the moving faction as the attacker, designates the province owner (or, on ownership ties, the lowest faction id) as the defender, and selects `Field` battle mode when fort level = 0 or `Siege` battle mode when fort level ≥ 1.

- Given a province owned by faction O at war with Great Power GP, and the province contains no combat-capable units of O and no combat-capable units of any third faction  
  When GP’s army ends movement in that province this turn  
  Then the system transfers province ownership from O to GP at the start of the combat phase without creating a battle context for that province.

- Given one defender and two or more attacking factions each with at least one regiment in the same province  
  When the system resolves combat for that province  
  Then the system computes initiative for each attacker as `initiative = cavalryShare × W_cav + generalMedals × W_medal`, and for exact initiative ties it uses one deterministic RNG tie-break for that battle context to order tied attackers for the multi-attacker chain.

- Given a defender and an ordered list of attackers as defined above, each with at least one regiment remaining  
  When the system executes the multi-attacker chain for that province  
  Then the system first resolves a battle between the defender and the highest-initiative attacker, and for each subsequent attacker it resolves a new battle between the previous battle’s winner (without healing or regenerating regiments) and the next attacker in the ordered list until either all attackers are eliminated or the defender side is eliminated.

- Given a side in combat has no assignable general after **pre-Combat army–general binding** for that engagement  
  When the system derives `generalMedals` for initiative and combat modifiers  
  Then the system derives fallback medals from that side’s leader combat multiplier using this mapping: multiplier `>= 1.25` => 4 medals, `>= 1.20` => 3 medals, `>= 1.15` => 2 medals, `>= 1.10` => 1 medal, else 0 medals.

- Given an engagement winner is carried forward as the defender in the next step of a multi-attacker chain  
  When the system initializes the next engagement in that same BattleContext  
  Then the system reuses the carried winner’s assigned or fallback `generalMedals` as the defender medals for that next engagement.

- Given an engagement has a winning side with an assigned general record and current medals in range 0..4  
  When the system finalizes that engagement result  
  Then the system increments that winning general’s medals by exactly 1 and caps the stored value at 4, and persists the updated medals into game state for subsequent engagements and turns.

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
  Then the system records a mutual annihilation outcome for that exchange, restores a new defending garrison equal to 20% of the defender’s initial regiment count in that battle rounded up (minimum 1 regiment, at most that initial count), sets **every** recovered regiment’s type to the most advanced infantry type for the defending faction’s effective military era `E` per § Garrison recovery type, and continues the multi-attacker chain using this restored defending garrison against the next attacker faction.

- Given mutual annihilation with remaining attackers and a defending faction whose effective military era is `E`, and the active ruleset’s regiment catalog contains at least one infantry-eligible row for era `E`  
  When the system applies garrison recovery  
  Then every recovered regiment’s type equals the catalog infantry-eligible row for era `E` with maximum `FPN + FPM`, using the lexicographically smallest `id` among rows tied on that sum.

- Given mutual annihilation with remaining attackers and a defending faction whose effective military era is `E`, and the catalog has **no** infantry-eligible row for era `E`  
  When the system applies garrison recovery  
  Then every recovered regiment’s type is exactly `peasant_levies`.

- Given a combat where both the attacker side and the defender side lose all regiments in the final exchange and there are no further attackers remaining in the multi-attacker chain  
  When the system completes combat resolution for that province  
  Then the system records a mutual annihilation outcome for the province, keeps the original defending faction as the province owner, and leaves the province ungarrisoned with zero defending regiments.

- Given a combat where both the attacker side and the defender side have at least one regiment remaining after applying casualties for the final exchange  
  When the system completes combat resolution for that province  
  Then the system records a stalemate outcome for the province, preserves the existing province owner, and leaves all surviving attacker and defender regiments in place without flipping province ownership.

- Given two combat resolutions for the same province in the same game state with identical unit compositions, stats, modifiers, and move orders  
  When the system executes combat resolution for that province both times  
  Then the system produces the same ordered sequence of battle pairings, the same winner for the overall province combat, the same casualty counts per faction and side, the same province ownership outcome in both executions, and the same regiment types for any mutual-annihilation recovered garrison regiments.

## Configurable Values

| Parameter | Default | Notes |
|---|---|---|
| W_cav | 50.0 | Initiative cavalry weight; tuned to make high-cavalry forces reliably win initiative. Matches `initiativeCavalryShareWeight` in `combat_config.dart`. |
| W_medal | 10.0 | Initiative medal weight; tuned so each general medal gives a noticeable but smaller boost than full cavalry share. Matches `initiativeGeneralMedalWeight` in `combat_config.dart`. |
| Medal multipliers | 1.0 / 1.1 / 1.2 / 1.3 / 1.4 | Per medal level 0–4 |
| DEF divisor | 9 | Durability scaling |
| Recovery % | 20% (ceil) | Mutual-annihilation garrison count (min 1, max initial defender count in that exchange) |
| Garrison recovery type | Most-advanced infantry at era `E` | Per § Garrison recovery type; `garrisonRecoveryRegimentTypeForEra` in `combat_config.dart` |
| Feeding modifiers | 1.0 / 0.75 / 0.5 | Coverage ≥ 1.0 / 0.5–1.0 / < 0.5; implemented via morale multiplier and **adopted as the intended rule** (no open question). |
| Terrain modifiers | Per terrain type | In ruleset config |
| Fort modifiers | Per fort level 0–3 | In ruleset config |
| Difficulty modifiers | Per difficulty level | In ruleset config |

### Auto-resolve ratio bands and loss fractions

Auto-resolve currently uses deterministic ratio bands and loss fractions to select a winner and assign casualties when resolving engagements by strength ratio:

| Ratio band (attacker strength ÷ defender strength after modifiers) | Attacker morale relative to defender | Attacker loss fraction | Defender loss fraction | Outcome when both sides lose all regiments |
|---|---|---|---|---|
| `ratio >= 1.5` and `< 4.0` | Attacker has **lower** morale | 0.6 | 0.4 | Attacker victory is **blunted**: if all defending regiments are eliminated, result is a stalemate rather than attacker victory. |
| `ratio >= 1.5` | Any (including higher/equal morale) | 0.15 | 1.0 | Attacker victory (defender eliminated) if both sides lose all regiments. |
| `ratio <= 0.67` | Any | 1.0 | 0.15 | Defender victory if both sides lose all regiments. |
| `1.0 <= ratio < 1.5` | Any | 0.3 | 0.6 | Attacker victory if both sides lose all regiments. |
| `0.67 < ratio < 1.0` | Any | 0.5 | 0.4 | Stalemate if both sides lose all regiments. |

Casualty counts are derived by applying these loss fractions to the number of deployed regiments on each side (with ceilings and clamping), and casualties are selected from the deployed regiment lists in deterministic order.

## Interactions

- Unit stats: [military-units.md](military-units.md)
- Siege rules: [siege-mechanics.md](siege-mechanics.md)
- Factions / minor parity: [factions.md](factions.md)
- Ruleset config: [ruleset-config.md](ruleset-config.md)
- Province identity and lookup: [world-model-identity.md](world-model-identity.md) — defines the `regionId|localId` prefixed province id format used by conflict detection, BattleContext, and combat resolution.
- Resolution pipeline: [../program/combat-resolution.md](../program/combat-resolution.md)

## Open Questions

1. FPN + FPM blending — **Owner decision:** For the current auto-resolve implementation we use simple `FPN + FPM` aggregation per regiment (with medal multiplier and global modifiers) as described above. If we later introduce explicit ranged/melee phases, this blending rule MAY be revisited and moved into the ruleset as a configurable weighting between phases.
2. Auto-resolve formula future evolution — **Owner decision:** The ratio bands and loss fractions documented above are the single source of truth for the current implementation. Future changes (for example, modelling DEF/9 durability and damaged-unit health scaling explicitly) MUST update this section and corresponding tests but do not block the current implementation.
