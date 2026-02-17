# Combat

**SPEC/game** — Auto-resolve combat. Derived from GDD 06. Units: [unit-types.md](unit-types.md), [military-units.md](military-units.md). Siege: [siege-mechanics.md](siege-mechanics.md). Factions: [factions.md](factions.md). Technical flow: [combat-resolution.md](../program/combat-resolution.md). Phase sequence: [turn-resolution-phases.md](../program/turn-resolution-phases.md).

---

## When Combat Triggers

Combat triggers when a unit's **move ends in a province owned by another faction** (or containing enemy units). Moving into such a province is an **attack**. Only **Great Powers** initiate attacks; **Minor Nations** and **Tribes** defend when their provinces are attacked. No separate declaration of war in Phase 3; the move order is the attack.

---

## Attacker vs Defender

**Attacker:** The faction whose unit(s) moved into the province this turn (the one executing the move order into that province).

**Defender:** The faction that owns the province (or whose units are present in it). Each province has at most one defending faction: the current province owner. Contested provinces with no owner use the faction that **did not** move in this turn as defender; if both moved in, break ties by consistent rule (e.g. lowest faction id).

Each province produces at most **one defender** per turn, but may see multiple **attacking armies** from different Great Powers. These are resolved in sequence (see *Multi‑Attacker Resolution*).

---

## Battle Modes

Battle mode is determined purely by the **fort level** of the province:

- **Field battle:** `fortLevel == 0`. No walls or emplaced artillery; both sides fight in the open. Terrain modifiers apply.
- **Siege battle:** `fortLevel ≥ 1`. Use fort walls, wall HP, emplaced artillery, and siege rules from [siege-mechanics.md](siege-mechanics.md). Fort level determines wall strength and number/quality of emplaced guns.

All forts automatically include emplaced artillery; there is no separate unit build for these pieces.

---

## Initiative

When multiple attacking armies target the same province in a single turn, resolution order depends on **army initiative rating**. Per Imperialism II: initiative = army composition (e.g. more cavalry → higher) + general medals. Higher initiative fights first. Implementation: configurable weights for cavalry share and general medals per [ruleset-config.md](ruleset-config.md).

---

## Multi-Attacker Resolution

When two or more **Great Power armies** invade the same province in one turn:

1. Identify the single **defender** (province owner) and all attacking armies that moved into the province.
2. For each attacking army, compute an **army initiative score** (composition + general medals).
3. Sort attackers by initiative (descending); use faction id as a deterministic tie‑breaker.
4. Resolve a chain of battles:
   - Battle 1: Defender vs highest‑initiative attacker.
   - If both sides survive (see *Battle Outcomes*), defender and attacker remain; no province flip.
   - If **only one side** has units left, that side immediately fights the next attacker in the ordered list, with its **remaining** units (no free heal).
   - Repeat until there are no attackers left or the defender is eliminated.

This chain uses the same combat formula for each battle. Other provinces’ battles are independent and may be ordered by a separate rule (e.g. province id).

---

## Strength

**Source of strength:** Per regiment type, tactical stats (FPN, FPM, RNG, DEF, MVR) from [military-units.md](military-units.md) and program-level config. Combined strength aggregates FPN and FPM (with blend for ranged vs melee) per side. **Medals** (0–4): multiply FPN and FPM by 1.0, 1.1, 1.2, 1.3, 1.4. Civilian units have zero strength.

---

## Modifiers

Modifiers adjust effective strength (or outcome) and come from:

- **Terrain:** Province or tile terrain type (plains, mountain, forest, etc.); modifier from config.
- **Fort:** Fort level (0–3) from [siege-mechanics.md](siege-mechanics.md). Defender receives damage reduction and emplaced artillery contribution per siege spec.
- **Difficulty:** Optional difficulty (Introductory, Normal, Hard, Impossible) scales defender or attacker per config.
- **General bonuses:** General present adds deployment limit (+1 per medal) and contributes to initiative.

All modifier values live in colonizethis_data (ruleset contract per [ruleset-config.md](ruleset-config.md) combat group).

---

## Resolution

A single **auto-resolve formula** determines the outcome: combined attacker strength vs combined defender strength, after modifiers. Strength is derived from tactical stats (FPN, FPM) and medals; siege mechanics apply when a fort is present (wall protection, emplaced artillery). The formula produces a **winner** (attacker or defender) and **casualties** (how many units, or which units, are removed on each side). Resolution is deterministic (no dice in spec; implementation may use fixed or seeded RNG if needed). Quick Battle (Phase 4) uses the same tactical stats and formula.

---

## Casualties

Casualties are **units removed** from the game. The formula specifies how many units (or which) are lost per side. Typically the loser suffers more; the winner may also take losses. Deterministic: same inputs produce same casualties.

---

## Battle Outcomes

Per battle (one attacker vs one defender in a given province and mode), outcomes are:

- **Attacker victory (defender eliminated):** Defender has no surviving units; see *Province Flip*.
- **Defender victory (attacker eliminated):** Attacker has no surviving units; province owner unchanged; surviving defenders remain in the province.
- **Stalemate (both sides survive):** Both attacker and defender retain units in the province; no province flip. Follow‑up battles in the multi‑attacker chain use these surviving units as their starting state.
- **Mutual annihilation (both wiped out):** Both attacker and defender lose all units in this battle; province owner unchanged and temporarily ungarrisoned. If another attacker remains in the chain this turn, that army fights a **small recovering garrison**: the defender regains **20%** (rounded up) of its initial regiment count for this battle as fresh units, representing rapid local reconstitution. If no further attackers remain, the province simply has no defending units at end of turn.

---

## Province Flip

When the **defender is eliminated** (no defender units remain after the battle) and the province **had the defender as owner**, the province **flips** to the attacker: set `province.ownerId` to the attacker's faction id. If the defender still has units in the province, no flip. Capital and connectivity are recomputed next turn; a conquered province may become the new owner's territory for extraction in the following turn.

---

## Relations

Technical pipeline (conflict detection, resolver, application to world state): [combat-resolution.md](../program/combat-resolution.md).
