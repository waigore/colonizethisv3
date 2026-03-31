# Ships and Naval

**SPEC/game** — Fleets, sea zones, and ship reveal. Reference: Imperialism II 04-units-naval, 03-units-civilian (ships reveal coast). Technical resolution: [naval-movement-resolution.md](../program/naval-movement-resolution.md). Map topology: [map-topology.md](map-topology.md).

---

## Fleet location: in port vs at sea

A fleet's location is either **in port** or **at sea**:

- **In port:** The fleet is **attached to a province** (docked at that province's port). The fleet is not in a sea zone; it is at the province. Only **one** location type applies: in port at province P (we do not distinguish which port/seaboard when a province has multiple).
- **At sea:** The fleet is in a **sea zone** (no province attachment). Movement between sea zones uses topology S↔S; entering or leaving port uses P↔S (dock or undock).

**Docking rule:** A fleet may only go **in port** at a province **owned by the fleet's owner**. A fleet cannot dock at an enemy or neutral province.

Topology provides P↔S (province–sea zone) and S↔S edges; see [map-topology.md](map-topology.md).

---

## Missions and Movement

Each fleet can either **move** or perform **one mission** per turn, never both:

- **Move:** For a fleet **at sea:** S↔S or move to a port (dock at an **owned** province adjacent to current sea zone). For a fleet **in port:** move to an adjacent sea zone (undock). Resolves in the Movement phase.
- **Patrol:** Fleet **at sea** remains in its current sea zone and attempts to **intercept hostile fleets** moving through that sea zone (including enemy patrols/blockaders).
- **Blockade:** Fleet **at sea** targets a specific enemy **province**; the blockading fleet must be in a **sea zone adjacent to that province's port**. It attempts to **intercept hostile fleets** that **enter that sea zone** (e.g. when they leave port into that zone). Higher interception chance than Patrol. Ships in port at the blockaded province remain in port; when they **leave port into the same sea zone** as the blockading fleet, interception is resolved like any other fleet entering that zone.
- **Beachhead:** Fleet **at sea** establishes a landing site on a hostile coastal province, enabling overseas invasion on the following turn; the fleet is exposed to interception while on beachhead duty. A beachhead is **valid for exactly one full turn after it is created**: during the next turn's Movement and Combat phases, land units of the same faction may invade that province from eligible adjacent tiles or sea zones; after the associated invasion is resolved (or if no invasion occurs that turn), the beachhead marker for that province expires.
- **Defend (no mission):** Fleet **at sea** stays in place and avoids actively seeking combat; it can still be attacked or drawn into combat if enemy fleets patrol/blockade the same zone.

Mission choice is per fleet and stored with the fleet state. **Naval combat occurs only in sea zones**; fleets in port do not participate in combat until they leave port. Details of interception and retreat are specified below and in [naval-movement-resolution.md](../program/naval-movement-resolution.md).

---

## Ship Types

**Merchant:** Carrack, Fluyte, Trader, Galleon, Indiaman, Clipper, Merchant Steamship.

**Warship:** Sloop, Frigate, Ship-of-the-Line, Raider, Ironclad.

Tech unlocks per [tech-tree-naval.md](tech-tree-naval.md). Cargo holds determine transport/trade capacity (home fleet); firepower (FRP), range (RNG), armour (ARM), hull (HULL), and movement (MV) determine naval combat and interception effectiveness.

### Ship build economy (canonical)

**Source of truth:** The tables below are the authoritative build costs for naval `BuildUnitOrder` validation and deduction. Implementation (`ShipEconomyCatalog` and related code) MUST match these values. Commodity ids use the [commodity-catalog.md](commodity-catalog.md) canonical strings (`lumber`, `fabric`, `castIron`, `coal`).

**Scaling:** Costs increase with the **unlocking tech era** (1–4) from [tech-tree-naval.md](tech-tree-naval.md). Merchants emphasize **treasury + cargo** progression; warships emphasize **hulls and combat materials**. Steam-era hulls add **cast iron** and/or **coal**.

**Treasury scale:** `build_treasury_cost` values are the prior Phase 5 baseline multiplied by **100**.

**Frozen baseline (do not change without explicit design pass):** `carrack` and `fluyte` treasury and material rows match the original Phase 5 catalog.

| ship_type_id | role | unlock era | build_treasury_cost | build_inputs |
| --- | --- | ---: | ---: | --- |
| carrack | merchant | (none — always buildable) | 8000 | `lumber`×2, `fabric`×1 |
| fluyte | merchant | 1 | 6000 | `lumber`×1, `fabric`×1 |
| sloop | warship | 1 | 5500 | `lumber`×1, `fabric`×1 |
| trader | merchant | 2 | 7500 | `lumber`×2, `fabric`×2 |
| galleon | merchant | 2 | 9500 | `lumber`×3, `fabric`×2 |
| indiaman | merchant | 2 | 11000 | `lumber`×3, `fabric`×3 |
| frigate | warship | 3 | 10500 | `lumber`×2, `fabric`×2 |
| raider | warship | 3 | 11500 | `lumber`×2, `fabric`×1, `castIron`×2 |
| ship_of_the_line | warship | 3 | 16500 | `lumber`×5, `fabric`×3 |
| clipper | merchant | 4 | 13500 | `lumber`×3, `fabric`×3 |
| merchant_steamship | merchant | 4 | 15500 | `lumber`×2, `fabric`×2, `coal`×3 |
| ironclad | warship | 4 | 21000 | `lumber`×2, `fabric`×2, `castIron`×5 |

Every `ship_type_id` that appears in any `shipUnlockIds` entry in the global tech catalog MUST have exactly one row in this table. `carrack` MUST NOT appear in `shipUnlockIds` (no unlocking tech).

### Ship food upkeep (canonical)

**Source of truth:** Per turn, each ship consumes **2 food units** (grain/meat, same stockpile abstraction as land military upkeep). Values are stored on `ShipEconomyEntry.foodUpkeep` in colonizethis_data (currently **2** for every row). Consumption phase order and invalid-id behavior: [workers-and-population.md](workers-and-population.md) § Consumption and Production.

### Ship combat and cargo stats (canonical)

**Source of truth:** The table below defines per-ship **FRP**, **RNG**, **ARM**, **HULL**, **MV**, **interceptRating**, **fleeRating**, and **cargoHold** for naval combat, interception, and home-fleet cargo (`NavalStatsCatalog` and related code MUST match). **Warships** use `cargoHold = 0` (they do not contribute merchant cargo capacity). **Merchants** use `cargoHold ≥ 1`.

**Scaling:** Stats generally increase with unlock era; fast interceptors (sloop, frigate, raider) emphasize **interceptRating**, **fleeRating**, and **MV**; line ships emphasize **FRP**, **ARM**, and **HULL**.

**Frozen baseline:** `carrack` and `fluyte` rows match the original Phase 5 catalog.

| ship_type_id | role | FRP | RNG | ARM | HULL | MV | intercept_rating | flee_rating | cargo_hold |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| carrack | merchant | 2 | 1 | 1 | 2 | 2 | 1 | 2 | 3 |
| fluyte | merchant | 1 | 1 | 1 | 1 | 2 | 1 | 3 | 4 |
| sloop | warship | 2 | 2 | 1 | 2 | 3 | 4 | 4 | 0 |
| trader | merchant | 1 | 1 | 1 | 2 | 2 | 1 | 3 | 5 |
| galleon | merchant | 2 | 1 | 2 | 4 | 2 | 1 | 2 | 6 |
| indiaman | merchant | 2 | 2 | 2 | 5 | 2 | 1 | 2 | 8 |
| frigate | warship | 4 | 3 | 2 | 4 | 3 | 5 | 4 | 0 |
| raider | warship | 3 | 2 | 2 | 3 | 4 | 6 | 5 | 0 |
| ship_of_the_line | warship | 6 | 4 | 4 | 8 | 2 | 2 | 1 | 0 |
| clipper | merchant | 1 | 2 | 1 | 3 | 4 | 2 | 4 | 7 |
| merchant_steamship | merchant | 2 | 2 | 3 | 5 | 3 | 1 | 3 | 9 |
| ironclad | warship | 5 | 3 | 8 | 6 | 3 | 2 | 2 | 0 |

---

## Ship instances (hulls)

Like military and civilian **units**, each ship **hull** in play has a **stable unique instance id** for the life of the save.

- **Fleet state:** Each fleet holds an ordered list of instances `{ id, typeId }` (catalog type, e.g. `carrack`). UI counts such as “carrack × 3” are **aggregations** of distinct hulls that share the same `typeId`.
- **Minting:** New hulls use ids `ship_<n>`; `WorldState.nextShipInstanceSeq` must stay consistent (at least the next free index; implementations may infer from existing ids on load). Legacy saves that stored only repeated `shipTypeIds` strings **must** migrate to instances without collapsing duplicate types into one hull.
- **Split / combine:** Operations move **whole instances** between fleets. The same `id` must never appear in two fleets. Combine **appends** source fleets’ instance lists onto the target fleet’s list (order preserved per source order); split **partitions** instances by id.

---

## Ship Reveal Mechanic

When a fleet **enters** a sea zone (move order), all **coastal land tiles** of provinces adjacent to that sea zone are set to **revealed** for that player, and all **water** tiles in that sea zone are set **fully visible** for that player (see [fog-and-exploration.md](fog-and-exploration.md) § Distant sea zone fog for End-of-turn re-fog when no owned adjacent coast and no fleet at sea there). This enables Explorer deployment to New World (at least one coastal tile must be revealed first). Reference: I2 03-units-civilian — "first terrain tile is uncovered when a ship enters a sea zone adjacent to the New World."

Province identity for visibility updates must use **full** province id (`regionId|localId`) and **region-scoped** lookup (only provinces in the destination sea zone's region); see [world-model-identity.md](world-model-identity.md).

---

## Home Fleet

The **home fleet** is a special fleet for each Great Power:

- It is always **in port at the player's capital province** and **cannot move**; naval move orders do not change its location.
- It contains ships that are **in port** and not assigned to any mission; these ships are not at sea.
- It is the **only** fleet whose ships can carry a faction's **transport and trade cargo** during the Extraction/Trade phase.

### Membership and state

- **Only the Home Fleet** may be **in port at the capital province**. Sea‑going fleets **never** remain docked at the capital; any naval **move** that **docks at the capital** resolves by **merging** that fleet’s ships into the Home Fleet and **removing** the sea‑going fleet (same merge semantics as combine: instance ids preserved, no duplicates).
- A ship is either **part of the home fleet** (in port at capital) or **part of a sea‑going fleet** (at sea or in port at **non‑capital** owned provinces); membership is mutually exclusive.
- Ships **enter** the home fleet when:
  - They are built as naval units via `BuildUnitOrder` (default spawn into the home fleet in port at the capital), or
  - A naval **move** order **docks** at the player’s **capital province** during turn resolution, or
  - A `join home fleet` order resolves successfully when a sea‑going fleet is **in port at the capital** (legacy or transitional saves only; under normal rules no sea‑going fleet occupies the capital port).
- Ships **leave** the home fleet when they receive a naval move or mission order that creates or updates a non‑home fleet (a fleet that can move and receive missions).

### Missions and movement

- The home fleet itself **cannot move** and cannot be assigned active missions:
  - Naval move orders targeting the home fleet do not change its location.
  - Mission orders cannot set the home fleet's mission to `patrol`, `blockade`, `beachhead`, or `defend`; its mission is effectively `none`.
- Only **sea‑going fleets** (non‑home fleets) participate in missions (`Move`, `Patrol`, `Blockade`, `Beachhead`, `Defend`); ships must leave the home fleet before they can be used for these missions.

### Cargo holds and capacity

- Each merchant ship type has a **cargoHold** value defined in the naval stats/economy catalog.
- The faction's total cargo capacity for the turn is the sum of cargoHold values for **all ships in the home fleet** (in port at the capital):

  \[
  \text{cargoHolds} = \sum_t H(t) \times \text{count\\_home}(t)
  \]

  where `H(t)` is the cargoHold for ship type `t` and `count_home(t)` is the number of **ship instances** in the home fleet whose `typeId` is `t` (aggregation over distinct hulls).

- Each cargo hold carries exactly **1 unit** of any commodity per turn.
- Cargo capacity is used **only** for:
  - (1) transport of cross‑region resources (e.g. New World → Old World), and
  - (2) trade/export shipments on the open market.

Transport and trade use this capacity in priority order (cross‑region extraction first, then trade) per [auto-transport.md](../program/auto-transport.md).

---

## Naval Combat

Naval battles are **strategic resolutions** between opposing fleets **in the same sea zone**. **Naval combat can only take place in sea zones**; fleets in port do not fight until they leave port.

- Inputs: fleets **at sea** (owner, ships with stats and medals, mission, aggression), sea zone id, tech state.
- Outcomes per engagement: attacker victory, defender victory, stalemate (both retain ships), or mutual destruction.
- Per Imp2: "superior range is usually the most important statistic" — RNG should be weighted highest in strength aggregation.

Retreat is allowed only if there is at least one **adjacent friendly or neutral sea zone**. Success depends on relative fleet speed/composition and aggression level. Failed retreat causes additional losses.

Interception and battle contexts are created when:

- A patrolling or blockading fleet **at sea** successfully intercepts a hostile fleet moving through its zone (including a fleet that **leaves port** into that zone).
- Enemy fleets **at sea** end Movement in the same sea zone (including at a beachhead).

## Naval Strength Aggregation Formula

This defines how ship stats (FRP, RNG, ARM, HULL, MV) combine into combat strength.

| Stat | Weight          | Rationale                         |
| ---- | --------------- | --------------------------------- |
| FRP  | 1.0             | Baseline firepower                |
| RNG  | 0.4 per point   | "Usually most important" per Imp2 |
| ARM  | 0.15 per point  | Damage reduction                  |
| HULL | Durability pool | Hits before sinking               |
| MV   | 0.1 per point   | Initiative/initiative             |

Durability is defined as `HULL × (1 + ARM/10)`

## Naval Retreat Formula

This defines when a fleet can retreat from naval combat. Refer to the following pseudo-code:

```
canRetreat = existsFriendlyOrNeutralAdjacentZone()
if canRetreat:
retreatSuccess = baseChance + speedAdvantage - enemyAggression
baseChance = 0.6
speedAdvantage = (ownAvgMV - enemyAvgMV) × 0.1 # +/- 0.2 typical
enemyAggression = 0.1 if enemyMission == Patrol else 0.2 # Blockade harder to escape
```

`existsFriendlyOrNeutralAdjacentZone()` means there is an adjacent sea zone with no hostile fleet present for the retreating side (hostility from diplomacy `atWar` relation).

## Naval Interception Probability

Patrol vs blockade interception chance:

```
fleetInterceptScore = Σ ship.interceptRating
targetFleeScore = Σ ship.fleeRating
ratio = fleetInterceptScore / (fleetInterceptScore + targetFleeScore)
missionFactor = 0.5 for Patrol, 0.9 for Blockade
interceptChance = clamp(missionFactor × ratio, 0.05, 0.85)
```


---

## Trade and Transport Interception

Only **home fleet** ships (in port at the capital province) carry a faction's transport and trade cargo. During Extraction/Trade, hostile naval forces **at sea** can **raid** overseas deliveries:

- Interception of trade/transport only occurs when the intercepting faction is **at war** with the owner of the home fleet.
- Patrolling or blockading fleets in relevant sea zones can intercept **cargo** (reducing delivered quantities) and **civilian ships** (higher vulnerability than warships).
- Escorts: warships accompanying the home fleet reduce both cargo and ship loss probabilities.

For trade/transport interception:

- **escortStrength** is defined as the sum of `HULL` values for all **warships** assigned as escorts to the home fleet's transport route during Extraction/Trade.
- **cargoStrength** is defined as the sum of `HULL` values for all **merchant ships** in the home fleet that are carrying overseas cargo during Extraction/Trade.

Escort protection

```
lossReduction = min(0.5, escortStrength / cargoStrength × 0.3)
# Max 50% loss reduction from strong escorts
```

Exact formulas for cargo/ship losses during overseas transport

```
interceptionChance = base × blockadeBonus × (1 - escortFactor)
cargoLost = interceptedAmount × raidEfficiency
shipLossChance = baseShipLoss × (1 - escortFactor) × civilianPenalty

civilianPenalty = 2.0 # Civilian ships twice as vulnerable
raidEfficiency = 0.3 to 0.7 depending on relative strength
```

---

## Acceptance Criteria

- Given a fleet **at sea** moves into a sea zone during the Movement phase per [map-topology.md](map-topology.md) and that sea zone is adjacent to one or more coastal provinces  
  When the System updates fog-of-war state for the moving player per [fog-and-exploration.md](fog-and-exploration.md)  
  Then the System sets all coastal tiles of provinces adjacent to that sea zone to at least `revealed` for that player, enabling Explorer deployment into those provinces.

- Given a fleet **at sea** is assigned one of the missions `Move`, `Patrol`, `Blockade`, `Beachhead`, or `Defend` for a turn and the naval movement resolver runs per [naval-movement-resolution.md](../program/naval-movement-resolution.md)  
  When the System processes that fleet’s orders  
  Then the System either moves the fleet along valid S–S edges or docks at an **owned** province (P–S) or undocks from port into an adjacent sea zone for `Move`, leaves it in place and evaluates interception chances for `Patrol` and `Blockade` using the base and modified probabilities in the interception table, or treats it as stationary and vulnerable for `Beachhead` and `Defend` while still allowing it to be attacked by enemy fleets in the same sea zone, and for `Beachhead` additionally marks the targeted hostile coastal province with a one-turn beachhead that permits associated land invasions during the next turn before expiring.

- Given a player orders a fleet to dock (move to port) at a province  
  When the System validates and applies the move  
  Then the System accepts the order only if that province is **owned by the fleet's owner**; otherwise the order is rejected.

- Given a blockading fleet is **at sea** in a sea zone adjacent to an enemy province and a hostile fleet **in port** at that province leaves port into that same sea zone  
  When the System resolves naval interception for that turn  
  Then the System evaluates interception as for any fleet entering the blockading fleet's sea zone (same interception chance and combat resolution). Ships in port at the blockaded province are not in combat until they leave port.

- Given two opposing fleets **at sea** with known ship stats (FRP, RNG, ARM, HULL, MV) and medals occupy the same sea zone and a naval battle is triggered  
  When the System computes naval combat strength and resolves the battle  
  Then the System uses the aggregation and durability formulas in this document (including RNG weighting and HULL × (1 + ARM/10)), applies tech modifiers as specified in related specs (leader bonuses do not apply to naval combat; see [leader-bonuses.md](leader-bonuses.md) § When Bonuses Apply), and produces deterministic outcomes (winner, casualties, and possible retreats) for identical inputs across multiple runs. Fleets in port do not participate in naval combat.

- Given a fleet is **in port at the player's capital province** (and is not the home fleet) and the player issues a `join_home_fleet` order for that fleet  
  When the System resolves the order during the Movement phase  
  Then the System merges that fleet's ships into the home fleet and removes the sea-going fleet. If the fleet is not in port at the capital province, the order has no effect (or is rejected).

- Given a Great Power’s home fleet (in port at the capital) carries overseas cargo during Extraction/Trade and hostile fleets **at sea** at war with that Great Power are patrolling or blockading relevant sea zones  
  When the System resolves overseas transport and trade for that turn  
  Then the System uses the interception probabilities and escort protection formulas in this document (including the definitions of `escortStrength` and `cargoStrength`) to determine whether cargo and civilian ships are lost, reduces delivered quantities and ship counts accordingly, and applies at most the documented maximum loss reduction from escorts.

- Given the global tech catalog’s `shipUnlockIds` lists and the ship build economy table in this document  
  When the System loads ship build data  
  Then the System defines a build economy entry for every `ship_type_id` in that table, `carrack` has no unlocking tech (absent from `unlockingTechByShipId`), every id referenced in any `shipUnlockIds` array appears in the table with costs exactly as listed, and implementation values match the table.

- Given the ship combat and cargo stats table in this document  
  When the System resolves naval combat, interception scoring, or home-fleet cargo capacity  
  Then the System uses the listed FRP, RNG, ARM, HULL, MV, intercept_rating, flee_rating, and cargo_hold for each `ship_type_id`, with warship `cargo_hold` equal to 0 for transport capacity sums.

- Given a player owns a capital province adjacent to a sea zone, has treasury and stockpile sufficient for a non-`carrack` ship per the build economy table, and has the unlocking tech for that ship in `techUnlocked`  
  When the player issues a valid naval `BuildUnitOrder` for that ship type during the build phase  
  Then the System accepts the order, deducts treasury and commodities per the table, and adds the ship to the home fleet (subject to topology and capital rules elsewhere in this document).

---

## Testing Approach

- **Unit tests:** Cover naval strength aggregation, retreat probability, interception probability, and the trade/transport interception formulas (including use of `escortStrength` and `cargoStrength`) with deterministic inputs and expected outputs. Cover alignment of `ShipEconomyCatalog` / `NavalStatsCatalog` with the canonical tables in this document (every tech-unlocked ship type plus `carrack`) and at least one sim scenario that builds a non-`carrack` ship when tech and resources are satisfied.
- **Integration tests:** Use sim_game or focused scenarios to verify ship reveal on movement into a sea zone, mission handling (Move/Patrol/Blockade/Beachhead/Defend), one-turn beachhead lifecycle and its interaction with land invasions, and trade/transport raids during Extraction/Trade.
- **Scenario tests:** Construct scenario data for edge cases (e.g. minimal escorts, overwhelming escorts, symmetric and asymmetric naval strength) to validate that interception and raid outcomes remain within documented clamps and respect war/peace conditions.
