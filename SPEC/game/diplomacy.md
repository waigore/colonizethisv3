# Diplomacy

## Overview

Full diplomacy system: war/peace, alliances, overture chain for Minors/Tribes, relations, Join Empire/Colony, intervention, and foreign aid. Derived from GDD 07 and Imperialism II. Province identity (e.g. order targets, overture/province context, “in that province”): [world-model-identity.md](world-model-identity.md).

---

## Rules

### Relation Model

Per faction-pair: **relation state** (AT_PEACE | AT_WAR), **relation score** (0–100), **relation level** (Hostile 0–25, Neutral 26–50, Friendly 51–75, Allied 76–100), **sinceTurn**, **lastInteractionTurn**. Initial: all GP–GP at peace, score 50. Updated by grants, trade, war, broken treaties.

While relationState is `AT_WAR` between a Great Power and any other faction, **no new overtures may be established** between that pair. Any existing overtures between that pair are **terminated when war begins** and are **not restored automatically** by later peace; the GP must rebuild the overture chain from `none` after peace.

### Tribe vs Minor War Rule

- **Minor Nations (Old World):** Declaration of war required before attacking provinces or units.
- **Tribes (New World):** No declaration required unless another GP has any diplomatic relation (Consulate, Embassy, Non-Aggression Pact, or trade) with the Tribe in that province; then war must be declared on that GP. Any province id used in diplomacy state or in orders (e.g. “in that province”, purchase_land target) must be in prefixed form and resolved per [world-model-identity.md](world-model-identity.md).

### GP–GP Rules

- **Declare War:** Requires AT_PEACE. Sets AT_WAR; takes effect before Movement in same turn.
- **Peace (white peace):** Both sides must agree. Sets AT_PEACE; no border or ownership changes.
- **Alliances:** Offer/accept between GPs. Mutual defence: when ally is attacked, the other receives a demand to join; refusal breaks the alliance with relation penalties. Joining an ally's offensive war is optional; no penalty for refusing.
- **Join Empire:** Requires target nearly defeated; tech-gated by Empire Building (see [tech-tree-diplomacy-civilian.md](tech-tree-diplomacy-civilian.md)). Acceptance removes target GP and transfers provinces.

### GP–Minor Rules

- **Overture chain:** Trade Consulate (cost) → Embassy (cost) → Non-Aggression Pact (free) → Join Empire (cost, relation check). Each step unlocks the next. Embassies and foreign civilian work are tech-gated by Diplomatic Expertise. Minors never refuse Consulate/Embassy; Join Empire requires Friendly/Allied relation and a **cost in pounds** that scales with the size of the Minor/Tribe (see Configurable Values). When enacted, the Minor or Tribe is **absorbed**: all provinces, units, and fleets owned by that faction transfer to the requesting GP; the Minor/Tribe is removed from the game; overture and relation records involving that faction are removed. The GP’s treasury is reduced by the Join Empire cost.
- **Purchase land (Merchant):** The Merchant work order `purchase_land` (tile in Minor/Tribe province with resource) requires the player to have an **embassy** with that Minor/Tribe and to **not be at war** with them. See [civilian-units.md](civilian-units.md).
- **Foreign aid:** Preset grant amounts; deducts treasury; improves relation score.
- **Intervention (human and AI):**
  - Trigger: When a Minor with at least one GP Embassy is attacked by a Great Power during combat resolution, each GP with an Embassy may be offered or may internally evaluate an **Intervention** choice.
  - Human GP with Embassy: The player chooses **Intervene**, **Do Nothing**, or **Diplomatic Protest**.
    - **Intervene (human):** The intervening GP immediately enters a war state with each attacking Great Power; the battle proceeds with this new war state in effect. The Minor remains an independent faction for province ownership purposes in MVP.
    - **Do Nothing (human):** The intervening GP does not change relation score or war state with any attacker in that battle, but **loses its Embassy** with the attacked Minor (all overtures with that Minor are cleared).
    - **Diplomatic Protest (human):** The intervening GP remains at peace but applies a relation penalty with each attacking Great Power; the Minor’s diplomatic state is unchanged.
  - AI GP with Embassy: Before combat resolution, each AI-controlled GP that has an Embassy with the attacked Minor independently evaluates whether to intervene on the Minor’s side:
    - The **probability to intervene** is a monotonic function of the GP–Minor relation score; default values for MVP are: relation score 0–25 → 0% chance, 26–50 → 25% chance, 51–75 → 50% chance, 76–100 → 80% chance.
    - On **AI Intervene**, the AI GP immediately enters a war state with each attacking Great Power, and the battle resolves with that GP treated as a belligerent against the attackers.
    - On **AI Do Nothing**, the AI GP does not change relation or war state with the attackers but **also loses its Embassy** with the attacked Minor (all overtures with that Minor are cleared), matching the human Do Nothing outcome.
    - MVP does not implement an AI **Protest** choice; AI either intervenes or does nothing.
  - Turn timing: Because interventions are evaluated during combat resolution, a GP (including the human player) may have war declared on them **after** the Diplomacy phase has completed, but **before** movement/combat for that battle is finalized.
- **Peace:** Minors never refuse peace offers.
 - **War and overtures:** When a GP declares war on a Minor (relationState becomes `AT_WAR`), any existing overture state between that GP and that Minor (Trade Consulate, Embassy, NAP, or Join Empire) is **cleared to `none`**. While `AT_WAR`, the GP cannot establish any new overtures with that Minor; after peace, the overture chain must be rebuilt from `none` if the player wants renewed consulate/embassy status.

### GP–Tribe Rules

- No war required for invasion (see Tribe vs Minor war rule).
- **Overture chain:** Same as Minor but Join Empire creates a **colony** (provinces don't count toward victory; profit share and colonial government).
- **Purchase land (Merchant):** Same as GP–Minor: requires **embassy** with that Tribe and **not at war**.
- Tribes react to nearby conquest (relation/trade effects).
 - **War and overtures:** If relationState becomes `AT_WAR` between a GP and a Tribe, any existing overture state between that GP and that Tribe is **cleared to `none`** and cannot be re-established while they remain at war. After peace, the GP must rebuild the overture chain from `none` if it wants to regain consulate/embassy/colony-level relations.

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

- Given the Player controls a Great Power with an Embassy in a Minor Nation that is currently being attacked by a different Great Power in turn index `t` and the battle has not yet been resolved  
  When the system presents the Player with an Intervention choice and the Player selects **Intervene**  
  Then the system changes the relation state between the Player’s Great Power and each attacking Great Power to `AT_WAR` with `sinceTurn = t`, updates `lastInteractionTurn = t` for each such relation, and uses this `AT_WAR` state for all Movement and Combat validation for that battle during turn `t`.

- Given the Player controls a Great Power with an Embassy in a Minor Nation that is currently being attacked by a different Great Power in turn index `t` and the battle has not yet been resolved  
  When the system presents the Player with an Intervention choice and the Player selects **Do Nothing**  
  Then the system does not change the relation state or relation score between the Player’s Great Power and any attacking Great Power in turn `t`, allows combat between the attacker and the Minor to proceed unchanged, and clears all overture state (Consulate, Embassy, NAP, Join Empire) between the Player’s Great Power and that Minor from the game state.

- Given the Player controls a Great Power with an Embassy in a Minor Nation that is currently being attacked by a different Great Power in turn index `t` and the battle has not yet been resolved  
  When the system presents the Player with an Intervention choice and the Player selects **Diplomatic Protest**  
  Then the system leaves the relation state between the Player’s Great Power and each attacking Great Power as `AT_PEACE` during turn `t`, decreases the relation score with each attacking Great Power by a fixed penalty of 10 points (clamped between 0 and 100 inclusive), updates `lastInteractionTurn = t` for each such relation, and does not change any overture or Embassy state with the attacked Minor.

- Given the system controls an AI Great Power that has an Embassy with a Minor Nation, that Minor Nation is currently being attacked by a different Great Power in turn index `t`, and the battle has not yet been resolved  
  When the system evaluates whether that AI Great Power will intervene on the Minor’s side  
  Then the system computes a probability to intervene based solely on the current relation score between the AI Great Power and that Minor, using the default mapping 0–25 → 0%, 26–50 → 25%, 51–75 → 50%, 76–100 → 80% unless overridden by a ruleset, and samples a single Bernoulli trial with that probability to decide whether to intervene.

- Given the system controls an AI Great Power that has an Embassy with a Minor Nation, that Minor Nation is currently being attacked by a different Great Power in turn index `t`, and the battle has not yet been resolved  
  When the system decides that the AI Great Power **will intervene** based on the relation-score-driven probability  
  Then the system changes the relation state between that AI Great Power and each attacking Great Power to `AT_WAR` with `sinceTurn = t`, updates `lastInteractionTurn = t` for each such relation, uses this `AT_WAR` state for all Movement and Combat validation for that battle during turn `t`, and leaves the Embassy and overture state between the AI Great Power and the Minor unchanged.

- Given the system controls an AI Great Power that has an Embassy with a Minor Nation, that Minor Nation is currently being attacked by a different Great Power in turn index `t`, and the battle has not yet been resolved  
  When the system decides that the AI Great Power **will not intervene** based on the relation-score-driven probability  
  Then the system does not change the relation state or relation score between that AI Great Power and any attacking Great Power in turn `t`, allows combat between the attacker and the Minor to proceed unchanged, and clears all overture state (Consulate, Embassy, NAP, Join Empire) between that AI Great Power and that Minor from the game state.

- Given the Player controls a Great Power with a Non-Aggression Pact overture with a target Minor Nation or Tribe, relation score between that GP and that faction is at least 51 (Friendly or Allied), the target owns at least one province, and the Player’s treasury is at least the Join Empire cost (base cost + per-province cost × number of provinces owned by the target)  
  When the Player issues an `Establish Overture` order with overture stage `Join Empire` targeting that Minor or Tribe in the Diplomacy phase and the order is valid  
  Then the system deducts exactly that Join Empire cost from the Player’s treasury, transfers ownership of all provinces owned by the target to the Player’s Great Power, transfers all units and fleets owned by the target to the Player’s Great Power, removes the target Minor Nation or Tribe from the game, removes all overture state and diplomacy relations involving that target, and logs the outcome with the `logic:` prefix.

- Given the Player controls a Great Power that currently has a Consulate or Embassy overture stage recorded with a target Minor Nation or Tribe and the current relation state between those two factions changes from `AT_PEACE` to `AT_WAR` in turn `t`  
  When the Diplomacy phase for turn `t` completes  
  Then the system removes any overture state between that Great Power and that Minor or Tribe so that subsequent state inspection reports `overtureStage = none` for that pair, and later peace between them does **not** restore the previous overture stage.

- Given the Player controls a Great Power at relation state `AT_WAR` with a target Minor Nation or Tribe in turn `t` and the Player has at least the Consulate or Embassy cost in treasury  
  When the Player issues an `Establish Overture` diplomatic order targeting that Minor or Tribe in the Diplomacy phase of turn `t`  
  Then the system treats that order as **invalid** for the current turn, does **not** create or advance any overture state between those factions, and does **not** deduct any overture cost from the Player’s treasury for that order.

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
| Join Empire base cost | £5000 | One-time cost when enacting Join Empire. |
| Join Empire per-province cost | £2000 | Added for each province owned by the target Minor/Tribe. Total cost = base + (province count × per-province). |

### Where defined (MVP)

Default values for the parameters above are given in this table; the table is the **source of truth** for design defaults. In the current (MVP) implementation, the program does **not** read these from the ruleset. Relation thresholds (Hostile/Neutral/Friendly/Allied bands) and overture costs (Consulate, Embassy) are implemented as **code constants** in `colonizethis_logic` (see `diplomacy_resolver.dart`: `overtureConsulateCost`, `overtureEmbassyCost`, and the thresholds used in `scoreToLevel`). Ruleset-driven override for diplomacy parameters is **deferred**; when added, the key path and loader contract will be specified in this document and in [ruleset-config.md](ruleset-config.md); program loading: [ruleset-config.md](../program/ruleset-config.md).

---

## Interactions

- Tech gates: [tech-tree-diplomacy-civilian.md](tech-tree-diplomacy-civilian.md), [tech-tree.md](tech-tree.md)
- Turn sequence: see program/turn-resolution-phases.md
- Combat validation: [combat.md](combat.md)
- Province identity (prefixed ids, region-scoped lookup in state and orders): [world-model-identity.md](world-model-identity.md)
