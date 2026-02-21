# Diplomacy

## Overview

Full diplomacy system: war/peace, alliances, overture chain for Minors/Tribes, relations, Join Empire/Colony, intervention, and foreign aid. Derived from GDD 07 and Imperialism II.

---

## Rules

### Relation Model

Per faction-pair: **relation state** (AT_PEACE | AT_WAR), **relation score** (0–100), **relation level** (Hostile 0–25, Neutral 26–50, Friendly 51–75, Allied 76–100), **sinceTurn**, **lastInteractionTurn**. Initial: all GP–GP at peace, score 50. Updated by grants, trade, war, broken treaties.

### Tribe vs Minor War Rule

- **Minor Nations (Old World):** Declaration of war required before attacking provinces or units.
- **Tribes (New World):** No declaration required unless another GP has any diplomatic relation (Consulate, Embassy, Non-Aggression Pact, or trade) with the Tribe in that province; then war must be declared on that GP.

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
