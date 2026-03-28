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
- **Tribes (New World):** No declaration required to attack unless another GP has any diplomatic relation (Consulate, Embassy, Non-Aggression Pact, or trade) with the Tribe. If such relations exist, war must be declared on that GP before attacking the Tribe. Diplomatic relations with Tribes are per-nation (not per-province); an Embassy with a Tribe applies to all its provinces. The phrase "in that province" refers to the attack location, not relation scope. Any province id used in diplomacy state or in orders (e.g. "in that province", purchase_land target) must be in prefixed form and resolved per [world-model-identity.md](world-model-identity.md).

### GP–GP Rules

- **Declare War:** Requires AT_PEACE. Sets AT_WAR; takes effect before Movement in same turn.
- **Peace (white peace):** Both sides must agree. Sets AT_PEACE; no border or ownership changes.
- **Alliances:** Offer/accept between GPs. **Mutual defence (call to arms):** When a Great Power **declares war** on another Great Power (same Diplomacy phase resolution as declare war—including any path that applies GP–GP war before Movement, e.g. naval context is still a declared GP–GP war), each other Great Power that is **allied** (`RelationLevel.allied`, `AT_PEACE`) with the **declared-upon** GP receives exactly **one** call to arms per aggressor–defender pair for that turn. **AI** allies **join** the war (enter `AT_WAR` with the aggressor) if their relation score with the defended ally is **≥ 50**; otherwise they **refuse**. **Human** allies: turn resolution **suspends** until the player chooses join or refuse (app popup / TUI screen; same blocking pattern as human overture target). **Join:** ally enters `AT_WAR` with the aggressor; subsidies between those two are cancelled like a normal war. **Refuse:** relation score between ally and defended GP drops by **20** (clamped 0–100), alliance ends (level no longer Allied; if score would remain Allied, clamp to top of Friendly); **subsidies are not** cancelled by this refusal. History records `callToArmsAccepted` / `callToArmsRefused`. Joining an ally's **offensive** war separately remains optional with no penalty; this rule is only for **defence** of an allied GP that was declared upon.
- **Join Empire:** Requires target nearly defeated; tech-gated by Empire Building (see [tech-tree-diplomacy-civilian.md](tech-tree-diplomacy-civilian.md)). Acceptance removes target GP and transfers provinces.

#### Nearly defeated (GP target)

For MVP, a Great Power is treated as **nearly defeated** when **both** of the following are true:

- The target currently owns **three or fewer provinces** in total (Old World + New World combined; count is based on current world state, not starting setup).
- The target **no longer controls its original capital province** (its `capitalProvinceId` in world state is not owned by that faction at the time the Join Empire overture is resolved).

When these conditions hold, other Great Powers that meet the tech and overture requirements may offer **Join Empire** to that target.

### GP–Minor Rules

- **Overture chain:** Trade Consulate (cost) → Embassy (cost) → Non-Aggression Pact (free) → Join Empire (cost, relation check). Each step unlocks the next. Embassies and foreign civilian work are tech-gated by Diplomatic Expertise. **Overtures are two-way:** one player offers; the **target** faction must accept or reject. When the target is a Minor or Tribe, the accept/reject decision is applied at turn resolution by rule (e.g. Minors never refuse Consulate/Embassy; Join Empire requires Friendly/Allied relation and cost). When the target is a Great Power, that GP's controller decides: if the target is **AI**, the decision is made during the Diplomacy phase; if the target is **human**, turn resolution **blocks** until the human responds (see [turn-resolution-phases.md](../program/turn-resolution-phases.md) § Blocking human input). Only when the target accepts are cost deducted and overture stage advanced. Minors never refuse Consulate/Embassy; Join Empire requires Friendly/Allied relation and a **cost in pounds** that scales with the size of the Minor/Tribe (see Configurable Values). When enacted, the Minor or Tribe is **absorbed**: all provinces, units, and fleets owned by that faction transfer to the requesting GP; the Minor/Tribe is removed from the game; overture and relation records involving that faction are removed. The GP’s treasury is reduced by the Join Empire cost.
- **Purchase land (Merchant):** The Merchant work order `purchase_land` (tile in Minor/Tribe province with resource) requires the player to have an **embassy** with that Minor/Tribe and to **not be at war** with them. See [civilian-units.md](civilian-units.md).
- **Foreign aid:** **Grant Aid** — deducts the chosen amount from the granting GP’s treasury and improves relation score. **MVP** matches the **Grant Aid** order rules under **Diplomatic Order Types** below: **positive multiple of £1000** (minimum £1000), enforced at validation and resolution; there is **no** percentage mode and **no** fixed menu of allowed amounts—only step/min rules. UI **defaults** (e.g. £1000) and AI suggestions are conveniences, not an exclusive list of legal values (see **Amount parameters (MVP)**).
- **Intervention (human and AI, at war declaration):**
  - Trigger (embassy or investment protection): When a Great Power **declares war** on a Minor that currently has **at least one GP Embassy** **or** at least one GP with **purchased land** recorded in its provinces (`purchasedTilesByTileKey` entries where the tile’s province ownerId is that Minor), each such GP evaluates or is offered a **one-time Intervention choice** against the aggressor **during the Diplomacy phase**, as part of resolving that `Declare War` order.
  - Human GP with Embassy or purchased land: For each valid GP–Minor war declaration, each human GP that:
    - is **not** the declaring GP, and
    - has an **Embassy** with the Minor **or** has **purchased land** in any province owned by that Minor  
    is presented an Intervention choice **once, at war declaration time**:
    - **Intervene (human):** The intervening GP immediately enters a war state (`AT_WAR`) with the declaring Great Power; this war state is in effect for all subsequent Movement and Combat in that turn and beyond. The Minor remains an independent faction for province ownership purposes in MVP.
    - **Do Nothing (human):** The intervening GP does not change relation score or war state with the declaring Great Power at that moment, but **loses its Embassy** with the attacked Minor (all overtures with that Minor are cleared). Any existing **purchased land** in that Minor’s provinces remains recorded until normal province conquest rules apply (see province conquest rules).
    - **Diplomatic Protest (human):** The intervening GP remains at peace but applies a relation penalty with the declaring Great Power; the Minor’s diplomatic state is unchanged. Purchased land and Embassy state remain unchanged.
  - AI GP with Embassy or purchased land: For each GP–Minor war declaration:
    - Every AI-controlled GP that has an Embassy with the attacked Minor, or has any purchased land in that Minor’s provinces, independently evaluates whether to intervene against the declaring Great Power.
    - The **probability to intervene** is a monotonic function of the GP–Minor relation score; default values for MVP are: relation score 0–25 → 0% chance, 26–50 → 25% chance, 51–75 → 50% chance, 76–100 → 80% chance.
    - On **AI Intervene**, the AI GP immediately enters a war state with the declaring Great Power; this war state is used for all Movement and Combat validation in that turn and subsequent turns. Embassy and overture state with the Minor remain unchanged.
    - On **AI Do Nothing**, the AI GP does not change relation or war state with the declaring Great Power but **loses its Embassy** with the attacked Minor (all overtures with that Minor are cleared), matching the human Do Nothing outcome. Purchased land remains recorded until province conquest rules apply.
    - MVP does not implement an AI **Protest** choice; AI either intervenes or does nothing.
  - Turn timing and scope: Intervention is evaluated **once per war declaration** during the Diplomacy phase, before Movement and Combat. There are **no additional intervention prompts tied to later battles** in that war; once the war state has been updated (or not) based on Intervention choices, subsequent combats proceed with that fixed war/peace state.
- **Peace:** Minors never refuse peace offers.
 - **War and overtures:** When a GP declares war on a Minor (relationState becomes `AT_WAR`), any existing overture state between that GP and that Minor (Trade Consulate, Embassy, NAP, or Join Empire) is **cleared to `none`**. While `AT_WAR`, the GP cannot establish any new overtures with that Minor; after peace, the overture chain must be rebuilt from `none` if the player wants renewed consulate/embassy status.

### GP–Tribe Rules

- No war required for invasion (see Tribe vs Minor war rule).
- **Overture chain:** Same as Minor but Join Empire creates a **colony** (provinces don't count toward victory; profit share and colonial government).
- **Purchase land (Merchant):** Same as GP–Minor: requires **embassy** with that Tribe and **not at war**.
- Tribes react to nearby conquest (relation/trade effects).
 - **Investment intervention:** When a Tribe that currently owns any province with **purchased land** belonging to a GP (entries in `purchasedTilesByTileKey` whose tile’s province ownerId is that Tribe) is attacked by a Great Power during combat resolution, that GP is treated as having an **investment-based intervention trigger**, analogous to an Embassy-based trigger for Minors. Human GPs with such purchased land may be offered an Intervention choice; AI GPs may evaluate intervention probabilistically using the same rules as for Minors.
 - **War and overtures:** If relationState becomes `AT_WAR` between a GP and a Tribe, any existing overture state between that GP and that Tribe is **cleared to `none`** and cannot be re-established while they remain at war. After peace, the GP must rebuild the overture chain from `none` if it wants to regain consulate/embassy/colony-level relations.

### Diplomatic Order Types

- **Declare War** — target faction; valid if AT_PEACE.
- **Offer Peace** — target faction; valid if AT_WAR.
- **Alliance** — target GP; propose, accept, or refuse.
- **Establish Overture** — target Minor/Tribe **or** Great Power, overture type; valid if previous step achieved and costs met. **At most one Establish Overture per (player, target faction) per turn.** The overture is a **two-way agreement**: at turn resolution the **target** accepts or rejects. For Minor/Tribe targets the decision is applied by rule during the Diplomacy phase. For GP targets: if the target is human-controlled, turn resolution suspends and the app must prompt the human and resume with the decision; if AI-controlled, the decision is made during the phase. Validation rejects any second Establish Overture order for the same target.
- **Grant Aid** — target faction, **amount**: a **positive integer** in pounds (£). Valid if Embassy exists, treasury ≥ amount, and other diplomacy preconditions hold. Resolves as a **one-time** transfer: treasury deduction and relation update per resolver rules.
- **Set Subsidy** — target faction, **amount**: a **positive integer** in pounds (£) **per turn** (ongoing subsidy until updated or cancelled). Valid if Consulate **or** Embassy exists and treasury meets validation (see resolver). **MVP** is **amount in £/turn only**; there is **no** percentage-based subsidy mode in orders or resolution.

**Amount parameters (MVP):** Both orders use the same **order field model**: a single integer `amount` in diplomatic orders. **Grant Aid:** `amount` must be a **positive multiple of £1000** (minimum £1000). **Set Subsidy:** `amount` must be a **positive multiple of £100** (minimum £100). Validation and diplomacy resolution enforce these steps. Defaults in UI steppers and AI suggestions use **£1000** for both unless the ruleset changes; defaults are **not** an exclusive list of legal values.

### Turn Sequence

Diplomacy phase runs before Movement. Declarations and peace take effect for the same turn's movement and combat.

---

## Acceptance Criteria

The following Given–When–Then criteria are testable conditions for diplomacy behaviour. Implementation: [diplomacy-resolution.md](../program/diplomacy-resolution.md); phase ordering: [turn-resolution-phases.md](../program/turn-resolution-phases.md).

- Given a new game has started with at least two Great Powers  
  When the system initializes diplomatic relations at turn index 0  
  Then the system sets each unordered Great Power pair to relation state `AT_PEACE`, relation score `50`, relation level `Neutral`, and records `sinceTurn = 0` and `lastInteractionTurn = 0`.

- Given a new game has started with Great Powers, Minor Nations, and Tribes  
  When the system initializes diplomatic relations at turn index 0  
  Then the system sets diplomatic relations **only between factions in the same region**:
  - Old World: all pairs among Great Powers and Minor Nations (GP↔GP, GP↔Minor, Minor↔Minor) at `AT_PEACE`, score `50`
  - New World: all pairs among Tribes (Tribe↔Tribe) at `AT_PEACE`, score `50`
  - Cross-region pairs (GP/Minor ↔ Tribe) are **not initialized** (undiscovered/unknown)

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
- Given the Player controls a Great Power A and there is a target Great Power B such that B currently owns three or fewer provinces in total, B does **not** own its original capital province (its `capitalProvinceId` in world state is owned by some other faction), and A has unlocked the `empire_building` tech and is not at war with B  
  When the Player issues a `Join Empire` diplomatic order targeting B in the Diplomacy phase and all other Join Empire preconditions are satisfied  
  Then the system treats B as **nearly defeated**, accepts the `Join Empire` order as valid, and resolves it per the Join Empire rules (absorbing B’s remaining provinces, units, and fleets into A and removing B from the game).

- Given the Player controls a Great Power and has already submitted one `Establish Overture` diplomatic order targeting a Minor Nation or Tribe in the current turn  
  When the Player submits a second `Establish Overture` order targeting the same Minor or Tribe in the same turn  
  Then the system rejects the second order at validation (e.g. reason: already have an Establish Overture order for this faction this turn) and does **not** apply it at resolution.

- Given a Great Power has submitted an `Establish Overture` order targeting a Minor Nation or Tribe and preconditions (previous stage, cost, not at war) are met at resolution  
  When the Diplomacy phase processes that overture  
  Then the system applies the target’s accept/reject decision per rules (e.g. Minor/Tribe accept Consulate/Embassy/NAP by rule); only when the decision is **accept** does the system deduct cost and advance overture stage.

- Given a Great Power has submitted an `Establish Overture` order whose **target is a human-controlled Great Power** and preconditions are met at resolution  
  When the Diplomacy phase reaches that overture  
  Then the system does **not** apply it immediately; it suspends turn resolution and returns a **pending overture decision** for that target. The app must prompt the human target to accept or reject; when the app supplies the decision and resumes resolution, the system applies the decision (deduct cost and advance stage if accept, else leave state unchanged) and continues the turn.

- **Relation thresholds and config:** Relation level (Hostile, Neutral, Friendly, Allied) is derived from relation score using the thresholds in Configurable Values; the table in this document is the source of truth for default values; ruleset overrides apply when specified.
- **Implementation:** Order validation and resolution flow: [diplomacy-resolution.md](../program/diplomacy-resolution.md). Phase order: [turn-resolution-phases.md](../program/turn-resolution-phases.md).

- Given the user views the diplomacy panel (app or TUI) for a discovered faction with a diplomatic relation  
  When the panel displays the current relation  
  Then the system shows the **one-word relation state** (Hostile, Unfriendly, Cordial, or Friendly) derived from the relation score per the Player-facing relation display table (0–29 Hostile, 30–49 Unfriendly, 50–69 Cordial, 70–100 Friendly), and does **not** display the numeric relation score.

- Given the user views the diplomacy panel and the list includes at least one other Great Power  
  When the panel displays each Great Power row  
  Then the system shows that GP’s **power score** per the Great Power power score formula (province count, regiment strength, ship count with default weights). If that GP’s score is **greater** than the human player’s power score, the value is shown in **red**; otherwise in **green**.

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
| Call to arms refusal score penalty | 20 | Subtracted from ally–defender relation score; alliance ends (no longer Allied). |
| Call to arms AI join threshold | 50 | AI ally joins the war if relation score with the defended ally is ≥ this value. |

### Player-facing relation display

The **relation score** (0–100) is a **hidden variable**: it is not shown to the player in the diplomacy UI (app or TUI). Validation and game logic continue to use the internal score and relation level (Hostile/Neutral/Friendly/Allied) per the thresholds above.

The diplomacy panel (app and ctterm) shows instead a **one-word relation state** derived from the score:

| Score range | Display label |
|-------------|---------------|
| 0–29 | Hostile |
| 30–49 | Unfriendly |
| 50–69 | Cordial |
| 70–100 | Friendly |

Same mapping for both Flutter app and TUI. Game logic (e.g. Join Empire ≥ 51, Alliance ≥ 76) uses the internal score and level; only the displayed label uses these bands.

### Great Power power score

An **absolute power score** is computed for each Great Power for display on the diplomacy panel. It reflects territorial, land, and naval strength.

- **Formula:** `powerScore = provinceCount × W_province + round(regimentStrength) × W_regiment + shipCount × W_ship`
- **Definitions:** `provinceCount` = number of provinces owned by that GP (Old + New World). `regimentStrength` = same aggregation as [military-strength](../program/military-strength.md) (FPN+FPM, era downgrade, medal multiplier). `shipCount` = total number of ships (sum of `shipTypeIds.length` over all fleets owned by that GP).
- **Default weights:** W_province = 10, W_regiment = 1, W_ship = 5. So one province = 10, one point of army strength = 1, one ship = 5.
- **Display:** The diplomacy panel shows this score for each GP. If the GP’s score is **higher** than the human player’s score, the value is shown in **red**; otherwise in **green**. Same formula and display rule for app and TUI where applicable.

### Where defined (MVP)

Default values for the parameters above are given in this table; the table is the **source of truth** for design defaults. In the current (MVP) implementation, the program does **not** read these from the ruleset. Relation thresholds (Hostile/Neutral/Friendly/Allied bands) and overture costs (Consulate, Embassy) are implemented as **code constants** in `colonizethis_logic` (see `diplomacy_resolver.dart`: `overtureConsulateCost`, `overtureEmbassyCost`, and the thresholds used in `scoreToLevel`). Ruleset-driven override for diplomacy parameters is **deferred**; when added, the key path and loader contract will be specified in this document and in [ruleset-config.md](ruleset-config.md); program loading: [ruleset-config.md](../program/ruleset-config.md).

---

## Interactions

- Tech gates: [tech-tree-diplomacy-civilian.md](tech-tree-diplomacy-civilian.md), [tech-tree.md](tech-tree.md)
- Turn sequence: see program/turn-resolution-phases.md
- Combat validation: [combat.md](combat.md)
- Province identity (prefixed ids, region-scoped lookup in state and orders): [world-model-identity.md](world-model-identity.md)

---

## Diplomatic History

The game maintains a **diplomatic history log** for each Great Power, consisting of **structured events** involving that GP and any other faction (GP, Minor, or Tribe). Events are stored in game state as data and rendered as **human-readable** entries by the UI.

- **Scope (who logs what):**
  - Only **Great Powers** initiate diplomatic actions, but the history log records all events where any Great Power is a **party**: GP–GP, GP–Minor, GP–Tribe.
  - For a given Great Power `A`, the **per-faction history view** in the diplomacy panel shows only events where `A` and the selected faction `B` are both parties.
- **Event types (what is recorded):**
  - **State changes:** Declarations of war, transitions to peace, alliances formed or broken, Join Empire/Colony resolutions (including removal of a Minor/Tribe), intervention outcomes (Intervene, Do Nothing, Protest).
  - **Overtures and treaties:** Consulate established, Embassy established, NAP signed, Join Empire/Colony overture accepted. Failed overtures (rejected by human/AI GP, or rejected for validation reasons) are recorded as **attempted but not applied** if they reach diplomacy resolution.
  - **War side-effects:** Overtures cleared due to war, subsidies cancelled due to war.
  - **Economic diplomacy:** GrantAid applications and SetSubsidy creations, updates, and cancellations that successfully apply.
  - **AI vs human symmetry:** Events are recorded for both **human** and **AI-controlled** Great Powers; the history is a world-level log, not per-controller.
- **Time and ordering:**
  - Each event stores the **turn number** when it occurred (integer, same as `worldState.turnState.turnNumber`).
  - Events are **ordered** by (turn, within-turn index) in a way that preserves resolution order; the history is effectively append-only.
  - UI displays events grouped and sorted by **newest first**, using a **year label** derived from turn via the game calendar mapping (e.g. `Year 1505 (Turn 12)`), per the program-level time mapping spec.
- **Visibility and “unknown faction”:**
  - The underlying history is a **global** world log (all Great Power events), but **PlayerView-safe** projections for a given human player **substitute undiscovered factions** with `Unknown faction`:
    - If a faction in an event is not yet discovered by the viewing player (no relation and outside visibility rules), the UI renders that party as `Unknown faction` while keeping the rest of the event text intact.
    - When the same event involves the viewing player’s GP directly, the viewing player is always allowed to see their **own** identity; only other, still-undiscovered factions are substituted.
  - All human players see the **same underlying event list**, but with party names filtered/substituted per their own discovery state.
- **Retention:**
  - Diplomatic history is **unbounded** within a campaign: there is no cap on the number of events persisted in a save.
  - Old saves created before this feature may have an empty or partial history; the game shows **whatever history exists** in the saved Game state without backfilling from current relations.
