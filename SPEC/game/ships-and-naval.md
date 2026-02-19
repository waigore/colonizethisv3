# Ships and Naval

**SPEC/game** — Fleets, sea zones, and ship reveal. Reference: Imperialism II 04-units-naval, 03-units-civilian (ships reveal coast). Technical resolution: [naval-movement-resolution.md](../program/naval-movement-resolution.md). Map topology: [map-topology.md](map-topology.md).

---

## Fleets and Sea Zones

Fleets are collections of ships; located in a **sea zone** (or port as sea zone). Movement: P<->S (port), S<->S (sea). Topology provides S<->S edges for naval movement between sea zones. See [map-topology.md](map-topology.md).

---

## Missions and Movement

Each fleet can either **move** or perform **one mission** per turn, never both:

- **Move:** P<->S or S<->S along topology edges; resolves in the Movement phase.
- **Patrol:** Fleet remains in its current sea zone and attempts to **intercept hostile fleets** moving through that sea zone (including enemy patrols/blockaders).
- **Blockade:** Fleet targets a specific enemy port in its sea zone and attempts to **intercept hostile fleets entering or leaving that port**; higher interception chance than Patrol, but no reach to other ports or zones.
- **Beachhead:** Fleet establishes a landing site on a hostile coastal province, enabling overseas invasion on the following turn; the fleet is exposed to interception while on beachhead duty.
- **Defend (no mission):** Fleet stays in place and avoids actively seeking combat; it can still be attacked or drawn into combat if enemy fleets patrol/blockade the same zone.

Mission choice is per fleet and stored with the fleet state; details of interception and retreat are specified below and in [naval-movement-resolution.md](../program/naval-movement-resolution.md).

---

## Ship Types

**Merchant:** Carrack, Fluyte, Trader, Galleon, Indiaman, Clipper, Merchant Steamship.

**Warship:** Sloop, Frigate, Ship-of-the-Line, Raider, Ironclad.

Tech unlocks per [tech-tree-naval.md](tech-tree-naval.md). Cargo holds determine transport/trade capacity (home fleet); firepower (FRP), range (RNG), armour (ARM), hull (HULL), and movement (MV) determine naval combat and interception effectiveness.

---

## Ship Reveal Mechanic

When a fleet **enters** a sea zone (move order), all **coastal land tiles** of provinces adjacent to that sea zone are set to **revealed** for that player. This enables Explorer deployment to New World (at least one coastal tile must be revealed first). Reference: I2 03-units-civilian — "first terrain tile is uncovered when a ship enters a sea zone adjacent to the New World."

---

## Home Fleet

Ships built appear in home fleet (capital port). Only home fleet used for transport and trade.

---

## Naval Combat

Naval battles are **strategic resolutions** between opposing fleets in the same sea zone:

- Inputs: fleets (owner, ships with stats and medals, mission, aggression), sea zone id, tech state.
- Outcomes per engagement: attacker victory, defender victory, stalemate (both retain ships), or mutual destruction.
- Per Imp2: "superior range is usually the most important statistic" — RNG should be weighted highest in strength aggregation.

Retreat is allowed only if there is at least one **adjacent friendly or neutral sea zone**. Success depends on relative fleet speed/composition and aggression level. Failed retreat causes additional losses.

Interception and battle contexts are created when:

- A patrolling or blockading fleet successfully intercepts a hostile fleet moving through its zone or entering/leaving a blockaded port.
- Enemy fleets end Movement in the same sea zone (including at a beachhead or port).

> **REQUIRES CLARIFICATION:** (a) Naval strength aggregation formula: how FRP, RNG, ARM, HULL, MV combine into side strength/durability. (b) Retreat probability formula. (c) Naval interception probability: baseline for patrol vs blockade, how escort strength reduces losses. Imp2 confirms factors (range most important, escorts help, blockade > patrol) but provides no numeric formulas.

---

## Trade and Transport Interception

Only **home fleet** ships (in the capital port sea zone) carry a faction's transport and trade cargo. During Extraction/Trade, hostile naval forces can **raid** overseas deliveries:

- Interception of trade/transport only occurs when the intercepting faction is **at war** with the owner of the home fleet.
- Patrolling or blockading fleets in relevant sea zones can intercept **cargo** (reducing delivered quantities) and **civilian ships** (higher vulnerability than warships).
- Escorts: warships accompanying the home fleet reduce both cargo and ship loss probabilities.

> **REQUIRES CLARIFICATION:** Exact interception probability formulas for trade/transport raids. Imp2 confirms escort and patrol/blockade factors but gives no numbers.
