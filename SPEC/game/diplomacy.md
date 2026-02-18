# Diplomacy (Phase 4 full)

**SPEC/game** — Full diplomacy: war/peace, alliances, overture chain, relations, Join Empire/Colony, intervention, aid. Derived from GDD 07 and Imperialism II. Technical resolution: [diplomacy-resolution.md](../program/diplomacy-resolution.md). Turn sequence: [turn-resolution-phases.md](../program/turn-resolution-phases.md).

---

## Relation model (game)

Per faction-pair the game maintains: **relation state** `AT_PEACE` | `AT_WAR`; **relation score** 0–100; **relation level** (Hostile 0–25, Neutral 26–50, Friendly 51–75, Allied 76–100); **sinceTurn**; **lastInteractionTurn**. Initial state at game start: all GP–GP at peace, score 50 (or configurable). Relations are updated by grants, trade, war, broken treaties, etc. (see diplomacy-resolution for modifiers).

---

## Tribe vs Minor war rule

- **Minor Nations (Old World):** A Great Power must be **AT_WAR** with a Minor before attacking its provinces or units. Declaration of war is required.
- **Tribes (New World):** A Great Power may invade a Tribe **without** a declaration of war, **unless** another Great Power has invested in the target province (e.g. Merchant land purchase); then the attacker must declare war on that GP. Combat and movement validation enforce this.

---

## GP–GP rules

**Declare War:** Precondition: `AT_PEACE`. Effect: `AT_WAR`, sinceTurn and lastInteractionTurn set. Takes effect before Movement in the same turn (Diplomacy phase runs first).

**Peace (white peace):** Both sides must agree. Effect: `AT_PEACE`; no border or ownership changes (territory from combat only).

**Alliances:** Offer/accept between GPs. Mutual defence: when an ally is attacked, the other receives a demand to join the war; refusal **breaks the alliance** and applies relation penalties. Joining an ally's **offensive** war is optional; no penalty for refusing.

**Join Empire:** A GP may request another GP to join its empire only when the target is nearly defeated (e.g. hopeless position); **tech-gated by Empire Building** (see [tech-tree-diplomacy-civilian.md](tech-tree-diplomacy-civilian.md), [tech-tree-catalog.md](tech-tree-catalog.md)). Acceptance removes the target from the game and transfers provinces to the requester.

---

## GP–Minor rules

**War required:** Declaration of war is required before attacking a Minor. Same relation and combat constraints as above.

**Overture chain:** Trade Consulate (cost) → Embassy (cost) → Non-Aggression Pact (free) → **Join Empire** (free; relation check). Each step unlocks the next. **Embassies** and the ability for Merchants/Engineers/Builders to work in Minor Nations are **tech-gated by Diplomatic Expertise**. Minors never refuse Consulate or Embassy; Join Empire is accepted only if relation score is high enough (e.g. Friendly/Allied). See [tech-tree-diplomacy-civilian.md](tech-tree-diplomacy-civilian.md).

**Foreign aid:** Preset grant amounts; deduct from treasury; improve relation score per diplomacy-resolution.

**Intervention:** When a Minor **with which the human player has an Embassy** is attacked by another GP, the human gets a one-time choice: **Intervene** (Minor joins player, player declares war on attacker), **Do Nothing** (Minor may fall; relations reset), or **Diplomatic Protest** (relation penalty with attacker). Effects on relations per resolution spec.

**Peace:** Minors never refuse peace offers.

---

## GP–Tribe rules

**No war required:** Invasion of a Tribe does not require declaration of war unless another GP has invested in the province (see Tribe vs Minor war rule).

**Overture chain:** Same progression (Trade Consulate → Embassy → NAP → **Join Empire / Colony**). Tribes become **colonies**: provinces do not count toward victory; profit share and colonial government per GDD. Tribes react to nearby conquest (relation/trade effects).

---

## Turn sequence placement

Diplomacy phase runs **before** Movement (see turn-resolution-phases.md). Declarations and peace take effect for the same turn's movement and combat. All diplomatic rules must be traceable to this spec and diplomacy-resolution; no behaviour without authorizing spec.
