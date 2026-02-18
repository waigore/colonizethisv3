# Naval Movement and Resolution

**SPEC/program** — Fleet model, naval movement, and ship reveal. Game design: [ships-and-naval.md](../game/ships-and-naval.md). Visibility: [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md).

---

## Fleet Model

Fleet = owner, seaZoneId, list of ships (type, count or individual). Stored in WorldState per region; naval units in `RegionData.navalUnits` or equivalent. Ships built appear in home fleet (capital port).

---

## Naval Movement and Missions

Each fleet can either **move** or perform **one mission** per turn:

- **Move:** MoveOrder for naval with destination = seaZoneId. Valid if destination sea zone is adjacent to current zone (S<->S or P<->S). Resolution: update fleet location; trigger **ship reveal** for coastal provinces adjacent to destination.
- **Patrol:** Fleet remains in its current sea zone and registers as a **patrolling interceptor** for that zone.
- **Blockade:** Fleet targets an enemy port in its current sea zone and registers as a **blockading interceptor** for that port only.
- **Beachhead:** Fleet establishes a beachhead marker tied to a coastal enemy province; this enables overseas invasion next turn and makes the fleet eligible for interception in that zone.
- **Defend (no mission):** Fleet remains in the zone, does not actively seek combat, but may still be drawn into battle if a hostile fleet patrols/blockades the same zone.

Movement and mission state are stored on the fleet and read during Movement and Naval Interception phases. See [movement.md](movement.md) and [orders.md](orders.md) for order structures.

---

## Ship Reveal Resolution

On fleet enter sea zone S: for each province P with P<->S edge in topology, for each coastal tile of P (tiles in P adjacent to S in grid/topology), set visibility to `revealed` for fleet owner. Implement in colonizethis_logic; updates visibility state from [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md). Enables Explorer deployment to New World.

---

## Phase Ordering

Naval movement runs in the **Movement** phase alongside land movement. Ship reveal runs when the fleet arrives in its destination sea zone. After movement:

- Patrol and Blockade missions are active and used by the **Naval Interception & Naval Combat** step described in [turn-resolution-phases.md](turn-resolution-phases.md).
- Beachhead fleets may be intercepted in the same step before land invasions are resolved.

---

## Topology

S<->S edges required for sea zone connectivity. Map generation / topology must produce these. See [map-topology.md](../game/map-topology.md), [tile-map-generation.md](tile-map-generation.md). Coastal tiles: land tiles in province P with grid adjacency to sea zone S.

---

## Build Ship

BuildUnitOrder for naval unit type (e.g. carrack); spawns in home fleet (capital port). Costs from colonizethis_data ship economy catalog. Home-fleet ships provide cargo holds for transport/trade and count towards naval interception/defence ratings when used as escorts.

---

## Interception Formulas

Naval interception uses per-ship ratings from colonizethis_data:

- **interceptRating:** ability to catch and bring enemies to battle (fast interceptors have higher values).
- **fleeRating:** ability to evade interception or retreat from battle (fast or late-era ships have higher values).

For an intercepting fleet:

- `fleetInterceptScore = sum(ship.interceptRating)` over its ships.

For the target fleet:

- `targetEvasionScore = sum(ship.fleeRating)` over its ships.

Let:

- `ratio = fleetInterceptScore / (fleetInterceptScore + targetEvasionScore)` (0..1).
- `actionFactor` depend on mission type:
  - Patrol: `actionFactor_patrol = 0.5` (baseline).
  - Blockade: `actionFactor_blockade = 0.9` (stronger, but only for fleets entering/leaving the blockaded port).
- Tech/composition bonuses scale `fleetInterceptScore` (e.g. `+20%` from `privateering_companies`, additional `+10–15%` when most ships are fast interceptors).

Then:

- `base = actionFactor * ratio`.
- **Per-encounter interception probability:** `P_intercept_ship = clamp(base, 0.05, 0.85)`.

Exact numeric values live in ruleset config; this spec fixes the **shape** of the formula (mission factor × relative naval strength × tech/composition).

On a successful interception, colonizethis_logic creates a BattleContextSea and calls the naval combat resolver per [naval-combat-resolution.md](naval-combat-resolution.md).

---

## Trade and Transport Interception

During Extraction/Trade, overseas cargo is carried by home-fleet ships. Trade/transport raids reuse the same interception framework, with the following rules:

- Interception only considered when the intercepting faction is **AT_WAR** with the owner of the home fleet.
- Civilian-only targets (merchant ship types with no warships escorting) are more vulnerable:
  - Civilian ships have lower `fleeRating`.
  - A `civilianTargetBonus` (e.g. `1.25–1.5`) may be applied to `base` for cargo interception.
- Escorts (warships in the home fleet) contribute to `targetEvasionScore` and thus reduce both cargo and ship loss probabilities.

Using the `base` value from above:

- **Cargo interception probability:** `P_cargo_intercept = clamp(1.2 * base, 0.1, 0.9)`.
- **Ship loss probability:** `P_ship_sunk = clamp(0.4 * base, 0.02, 0.5)`.

Application:

- On cargo interception, reduce delivered quantities from overseas sources before they are added to stockpile/treasury (see [auto-transport.md](auto-transport.md)).
- On ship loss, remove the affected merchant ships from the home fleet; damages may be modelled as partial loss or repair mechanics in future phases.
