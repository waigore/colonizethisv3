# Diplomacy

## Overview

Full diplomacy system: war/peace, alliances, overture chain for Minors/Tribes, relations, Join Empire/Colony, intervention, and foreign aid. Derived from GDD 07 and Imperialism II. Province identity (e.g. order targets, overture/province context, “in that province”): [world-model-identity.md](world-model-identity.md).

---

## Rules

### Relation Model

Per faction-pair: **relation state** (AT_PEACE | AT_WAR), **relation score** (0–100), **relation level** (Hostile 0–25, Neutral 26–50, Friendly 51–75, Allied 76–100), **sinceTurn**, **lastInteractionTurn**. Initial: all GP–GP at peace, score 50. Updated by grants, trade, war, broken treaties.

### Tribe vs Minor War Rule

- **Minor Nations (Old World):** Declaration of war required before attacking provinces or units.
- **Tribes (New World):** No declaration required unless another GP has any diplomatic relation (Consulate, Embassy, Non-Aggression Pact, or trade) with the Tribe in that province; then war must be declared on that GP. Any province id used in diplomacy state or in orders (e.g. “in that province”, purchase_land target) must be in prefixed form and resolved per [world-model-identity.md](world-model-identity.md).

### GP–GP Rules

- **Declare War:** Requires AT_PEACE. Sets AT_WAR; takes effect before Movement in same turn.
- **Peace (white peace):** Both sides must agree. Sets AT_PEACE; no border or ownership changes.
- **Alliances:** Offer/accept between GPs. Mutual defence: when ally is attacked, the other receives a demand to join; refusal breaks the alliance with relation penalties. Joining an ally's offensive war is optional; no penalty for refusing.
- **Join Empire:** Requires target nearly defeated; tech-gated by Empire Building (see [tech-tree-diplomacy-civilian.md](tech-tree-diplomacy-civilian.md)). Acceptance removes target GP and transfers provinces.

### GP–Minor Rules

- **Overture chain:** Trade Consulate (cost) → Embassy (cost) → Non-Aggression Pact (free) → Join Empire (free, relation check). Each step unlocks the next. Embassies and foreign civilian work are tech-gated by Diplomatic Expertise. Minors never refuse Consulate/Embassy; Join Empire requires Friendly/Allied relation.
- **Purchase land (Merchant):** The Merchant work order `purchase_land` (tile in Minor/Tribe province with resource) requires the player to have an **embassy** with that Minor/Tribe and to **not be at war** with them. See [civilian-units.md](civilian-units.md).
- **Foreign aid:** Preset grant amounts; deducts treasury; improves relation score.
- **Intervention:** When a Minor with the player's Embassy is attacked by another GP: **Intervene** (Minor joins player, war on attacker), **Do Nothing** (Minor may fall, relations reset), or **Diplomatic Protest** (relation penalty with attacker).
- **Peace:** Minors never refuse peace offers.

### GP–Tribe Rules

- No war required for invasion (see Tribe vs Minor war rule).
- **Overture chain:** Same as Minor but Join Empire creates a **colony** (provinces don't count toward victory; profit share and colonial government).
- **Purchase land (Merchant):** Same as GP–Minor: requires **embassy** with that Tribe and **not at war**.
- Tribes react to nearby conquest (relation/trade effects).

### Diplomatic Order Types

- **Declare War** — target faction; valid if AT_PEACE.
- **Offer Peace** — target faction; valid if AT_WAR.
- **Alliance** — target GP; propose, accept, or refuse.
- **Establish Overture** — target Minor/Tribe, overture type; valid if previous step achieved and costs met.
- **Grant Aid** — target faction, amount; valid if Embassy exists; deducts treasury.
- **Set Subsidy** — target, amount/percentage; valid if consulate/embassy exists.

### Turn Sequence

Diplomacy phase runs before Movement. Declarations and peace take effect for the same turn's movement and combat.

---

## Acceptance Criteria

The following Given–When–Then criteria are testable conditions for diplomacy behaviour. Implementation: [diplomacy-resolution.md](../program/diplomacy-resolution.md); phase ordering: [turn-resolution-phases.md](../program/turn-resolution-phases.md).

- Given a new game has started with at least two Great Powers  
  When the system initializes diplomatic relations at turn index 0  
  Then the system sets each unordered Great Power pair to relation state `AT_PEACE`, relation score `50`, relation level `Neutral`, and records `sinceTurn = 0` and `lastInteractionTurn = 0`.

- Given the Player is a Great Power at relation state `AT_PEACE` with a target Great Power and the current turn index is an integer `t ≥ 0`  
  When the Player issues a `Declare War` diplomatic order targeting that Great Power in the Diplomacy phase of turn `t` and the order is valid  
  Then the system changes the relation state between the two Great Powers to `AT_WAR` with `sinceTurn = t`, updates `lastInteractionTurn = t`, and uses this `AT_WAR` state for all Movement and Combat validation during turn `t`.

- Given the Player is a Great Power at relation state `AT_WAR` with a target Great Power and the current turn index is `t`  
  When both sides have accepted a peace offer between those two Great Powers in the Diplomacy phase of turn `t`  
  Then the system changes the relation state between the two Great Powers to `AT_PEACE` with `sinceTurn = t`, updates `lastInteractionTurn = t`, leaves all province ownership unchanged, and uses `AT_PEACE` for Movement and Combat validation during turn `t`.

- Given the Player controls a Great Power with a valid treasury balance in pounds as a non-negative integer and has no existing consulate or embassy with a target Minor Nation  
  When the Player issues an `Establish Overture` order for a `Consulate` with that Minor and the treasury is greater than or equal to `Consulate cost` for the active ruleset  
  Then the system deducts exactly the `Consulate cost` from the Player treasury, records a Consulate overture between the Great Power and that Minor, and unlocks the ability for the Player to offer an Embassy to that same Minor in later turns.

- Given the Player controls a Great Power that already has an Embassy with a target Minor Nation or Tribe, is not at relation state `AT_WAR` with that faction, and has a Merchant unit assigned a `purchase_land` work order targeting a tile in that Minor or Tribe province  
  When the system validates the `purchase_land` work order during turn resolution  
  Then the system accepts the work order for execution and does not reject it for missing diplomatic prerequisites.

- Given the Player controls a Great Power with an Embassy in a Minor Nation that is currently being attacked by a different Great Power in turn `t`  
  When the system presents the Player with an Intervention choice and the Player selects **Intervene**  
  Then the system changes the relation state between the Player’s Great Power and the attacking Great Power to `AT_WAR` with `sinceTurn = t`, adds the Minor’s provinces and units to the Player’s side in that war, and uses this war state for all Movement and Combat validation during turn `t`.

- Given the Player controls a Great Power with an Embassy in a Minor Nation that is currently being attacked by a different Great Power in turn `t`  
  When the system presents the Player with an Intervention choice and the Player selects **Do Nothing**  
  Then the system does not change the relation state between the Player’s Great Power and the attacking Great Power in turn `t`, allows combat between the attacker and the Minor to proceed, and, if the Minor is eliminated, clears all diplomatic relations between the Player and that Minor from the game state.

- **Relation thresholds and config:** Relation level (Hostile, Neutral, Friendly, Allied) is derived from relation score using the thresholds in Configurable Values; the table in this document is the source of truth for default values; ruleset overrides apply when specified.
- **Implementation:** Order validation and resolution flow: [diplomacy-resolution.md](../program/diplomacy-resolution.md). Phase order: [turn-resolution-phases.md](../program/turn-resolution-phases.md).

## Configurable Values

| Parameter | Default | Notes |
|---|---|---|
| Initial GP–GP relation score | 50 | |
| Hostile threshold | 0–25 | |
| Neutral threshold | 26–50 | |
| Friendly threshold | 51–75 | |
| Allied threshold | 76–100 | |
| Consulate cost | £500 | |
| Embassy cost | £1000 | |

---

## Interactions

- Tech gates: [tech-tree-diplomacy-civilian.md](tech-tree-diplomacy-civilian.md), [tech-tree.md](tech-tree.md)
- Turn sequence: see program/turn-resolution-phases.md
- Combat validation: [combat.md](combat.md)
- Province identity (prefixed ids, region-scoped lookup in state and orders): [world-model-identity.md](world-model-identity.md)
