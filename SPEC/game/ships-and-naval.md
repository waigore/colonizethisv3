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
- Outcomes per engagement: attacker victory, defender victory, stalemate (both retain ships), or mutual destruction. Surviving fleets may remain, retreat, or be forced to withdraw per aggression/retreat rules.
- Ship stats (FRP, RNG, ARM, HULL, MV) are aggregated into naval strength and durability; later-era ships and techs provide higher values.

Retreat is allowed only if there is at least one **adjacent friendly or neutral sea zone**. A fleet’s commander may attempt retreat when outmatched; success probability depends on relative fleet speed/composition and aggression level (cautious fleets favour retreat, aggressive fleets favour fighting on). Failed retreat causes additional losses (e.g. extra damage or sinking of a vulnerable ship).

Interception and battle contexts are created when:

- A patrolling or blockading fleet successfully intercepts a hostile fleet moving through its zone or entering/leaving a blockaded port.
- Enemy fleets end Movement in the same sea zone (including at a beachhead or port).
See [naval-combat-resolution.md](../program/naval-combat-resolution.md) for the technical model and formulas.

---

## Trade and Transport Interception

Only **home fleet** ships (in the capital port sea zone) carry a faction’s transport and trade cargo. During Extraction/Trade, hostile naval forces can **raid** overseas deliveries:

- Interception of trade/transport only occurs when the intercepting faction is **at war** with the owner of the home fleet.
- Patrolling or blockading fleets in relevant sea zones can intercept:
  - **Cargo** (reducing delivered quantities to stockpile/treasury).
  - **Civilian ships** (Carrack, Fluyte, etc.), with higher vulnerability than escorted warships.
- Escorts: warships accompanying the home fleet reduce both cargo and ship loss probabilities.

Mechanically, trade/transport interception uses the same relative-naval-strength and mission factors as fleet-vs-fleet interception, with **higher baseline probabilities vs civilian targets**. Exact formulas and config live in [naval-movement-resolution.md](../program/naval-movement-resolution.md) and [auto-transport.md](../program/auto-transport.md).
