# Quick Battle (one-province tactical combat)

## Purpose and scope

Quick Battle is a **one-province attacker vs defender** tactical mini-game that replaces pure auto-resolve when players choose the Quick Battle mode. It offers a short, command-point-based, turn-by-turn system that preserves tactical combat stats and formulas while giving players meaningful tactical choices (terrain, maneuvers, focus fire, timing of assaults). Output is compatible with the existing combat casualty/flip pipeline.

Constraints:

- One attacking stack vs one defending stack in a single province.
- At most **3 battle rounds**.
- Each round, each side has **2–3 Command Points (CP)** to spend on actions.
- System must be simple to operate but allow skilled players to trade better and occasionally win uphill fights.

## Battlefield layout and terrain

Each side arrays units on a simplified battlefield inspired by early modern deployments:

- **Lanes per side:** `LEFT`, `CENTER`, `RIGHT`, and `RESERVE`.
- **Lines per non-reserve lane:** `FRONT` and `SUPPORT`.
- Each `(lane, line)` holds 0–N regiments; these are treated as a **battalion group** for Quick Battle.

Province terrain provides a base context; each lane is tagged with a single terrain type (shared by both sides in that lane):

- `OPEN` — baseline.
- `HILL` — better defense and ranged fire; harder to charge uphill.
- `WOODS` — better cover; worse ranged visibility; harder to maneuver.
- `TOWN` — very strong defense; modest penalties to movement and some artillery fire.
- `SWAMP` — very poor footing; bad for both attack and defense; hard to maneuver.

Lane terrain is used as a modifier on top of existing tactical stats (FPN, FPM, RNG, DEF, MVR).

## Emplaced fort artillery (virtual units)

When the battle is a **siege** (`fortLevel ≥ 1` per [siege-mechanics.md](siege-mechanics.md)), the System **injects virtual emplaced gun entities** for the **defender** only. They are **not** stored as `Unit` records on the province map; they are created when Quick Battle input is built and discarded after the battle.

- **Count:** Matches fort level (1 / 2 / 3 guns). **Stats:** Each has **HP** and **attack** and **defense** strength derived from ruleset tables and the defender’s emplaced-quality tech (Royal → Heavy → Siege) per [tech-tree-military.md](tech-tree-military.md); **+1 RNG** vs same-era heavy artillery baseline applies when resolving their fire. **Assignment:** The System auto-places them **behind the fort** in a single deterministic slot (e.g. defender `CENTER` + `SUPPORT`, or a documented “battery” attachment to that lane — exact placement is fixed in SPEC/program so seeds replay identically).
- **Targeting:** Quick Battle actions that deal damage to defender combatants **may** allocate damage to these virtual guns per the technical spec (which actions hit the battery first vs front-line regiments is defined in [quick-battle-resolution.md](../program/quick-battle-resolution.md)).
- **Field artillery:** Attacker and defender **regiment** artillery remain normal units in battalion groups. Virtual emplaced guns **do not** duplicate them.

**Integration:** When Quick Battle ends, if **every** virtual emplaced gun was destroyed, the combat pipeline **must** decrement province `fortLevel` by 1 (floor at 0) when applying results, regardless of whether the province flips. The Quick Battle resolver **must not** add a parallel lump-sum emplaced strength term for those same guns (no double-counting).

## Cohesion (morale) model

Each battalion group (lane + line) has a **cohesion** value on a 0–3 integer scale:

| Cohesion | State | Effect |
|---|---|---|
| 3 | Fresh | Full combat power |
| 2 | Engaged | 75% combat power |
| 1 | Shaken | 50% combat power |
| 0 | Broken | No offensive strength; routed to RESERVE |

- Starts at 3 for all groups.
- Cohesion declines when the group suffers significant casualties, maneuvers through bad ground under pressure, or a neighboring lane collapses.
- At **0 cohesion** (per Imp2: "green bar empty"), the group is **broken**: it surrenders if surrounded, otherwise flees.

**Battle morale index:** Sum of group cohesion across all lanes. Used to distinguish decisive wins from mutual exhaustion.

**Effective combat power per group:** `basePower * (cohesion / 3)`, where `basePower = Σ (FPN_eff + FPM_eff) * medalMult` for regiments in that group, adjusted by terrain modifier for the lane.

**Percentage adjustments to combat power**

| Terrain | Attacker | Defender | Rationale                                     |
| ------- | -------- | -------- | --------------------------------------------- |
| OPEN    | 100%     | 100%     | Baseline                                      |
| HILL    | 75%      | 120%     | Hard to attack uphill                         |
| WOODS   | 80%      | 110%     | Cover benefits defense, impedes movement      |
| TOWN    | 60%      | 130%     | Strong defensive positions                    |
| SWAMP   | 70%      | 90%      | Bad for everyone, slightly worse for attacker |


## Turn structure and actions

Quick Battle proceeds in at most **3 rounds**. In each round:

1. Determine which side acts first (initiative, consistent with combat rules; ties may alternate).
2. Side A receives **2–3 CP** and spends them on actions.
3. Side B receives **2–3 CP** and spends them on actions.
4. Resolve all fire, charges, maneuver consequences, casualties, cohesion changes, and possible lane collapses.

Core actions (examples; exact numbers live in technical spec):

- **Volley Fire (1 CP):** Front-line units (and eligible artillery/support) in a chosen lane fire at the opposing front-line group. Terrain and cohesion adjust hit chances and losses.
- **Defend / Entrench (1 CP):** Set a lane to a defensive stance for the round, improving defense (especially in `HILL`, `WOODS`, `TOWN`) at the cost of maneuverability.
- **Maneuver (1 CP):** Rotate `FRONT`/`SUPPORT` within a lane, or move a group between `RESERVE` and a lane. Maneuvering through bad terrain or while under heavy pressure can cost cohesion.
- **Fall Back / Refuse Flank (2 CP):** Pull a front-line group back to `RESERVE` (and optionally replace it) to avoid destruction, or deliberately weaken a flank to reinforce `CENTER` or the opposite flank. This trades space and cohesion for preservation of forces.
- **Assault / Charge (2 CP):** Launch a high-risk, high-reward attack in one lane, especially suited for cavalry or high-MVR infantry. Very strong against disrupted or badly positioned enemies; much weaker into `WOODS`, `TOWN`, or uphill `HILL`.

Players use CP to choose when to defend, when to trade space, when to concentrate fire, and when to attempt decisive assaults. Skilled use of terrain and timing allows weaker forces to inflict favorable losses or occasionally win against stronger opponents.

## Outcome and integration

**Collapse conditions** (battle ends early):

- **Attacker collapse:** CENTER broken AND at least one flank broken, OR total battle morale index ≤ 2.
- **Defender collapse:** CENTER broken AND at least one flank broken, OR total battle morale index ≤ 2.
- **Mutual exhaustion:** Both sides' battle morale index ≤ 4 at end of a round.

After up to 3 rounds (or earlier if one side collapses), the Quick Battle produces:

- Casualties per side (by unit type or equivalent granularity).
- Updated status of key lanes and side morale (e.g. broken center vs intact battle line).
- A single **battle result**: decisive attacker win, decisive defender hold, or mutual exhaustion.

Quick Battle does **not** change the underlying combat formula for **map regiments**; it supplies structured inputs (lane-level strengths, modifiers, cohesion effects) into the resolution pipeline and receives standard outputs. **Siege Quick Battle** additionally runs the **virtual emplaced gun** model above, which replaces the aggregate emplaced defender bonus for that path only:

- Casualty lists for both sides.
- Whether the province flips to the attacker or remains with the defender (consistent with combat and siege rules).

The game then applies casualties and province ownership changes using the same world-state update logic as auto-resolve.

---

## Acceptance Criteria

- Given a Quick Battle is initiated for a province with one attacking stack and one defending stack and the combat context includes terrain and lane assignments as described in this spec  
  When the System sets up the Quick Battle battlefield  
  Then the System assigns each side’s regiments to lanes and lines (`LEFT`, `CENTER`, `RIGHT`, `RESERVE` × `FRONT`/`SUPPORT`), tags each lane with a single terrain type from the allowed set (`OPEN`, `HILL`, `WOODS`, `TOWN`, `SWAMP`), and initializes each battalion group’s cohesion to 3 (Fresh).

- Given a Quick Battle round begins and both sides have defined tech, regiment stats, medal levels, and lane terrain  
  When the System computes effective combat power for each battalion group and side for that round  
  Then the System uses `basePower = Σ(FPN_eff + FPM_eff) × medalMult` for the regiments in each group, multiplies by the terrain and cohesion multipliers from the tables in this spec, and uses these adjusted values to resolve fire, charges, casualties, and cohesion changes for that round.

- Given a Quick Battle proceeds for up to 3 rounds or until a collapse condition is met  
  When the System checks outcome conditions at the end of each round  
  Then the System ends the battle immediately when the attacker collapse, defender collapse, or mutual exhaustion conditions from this spec are satisfied, computes casualties per side and a final battle result (decisive attacker win, decisive defender hold, or mutual exhaustion), and passes these results into the same province-flip and casualty application pipeline used by auto-resolve.

- Given two Quick Battle runs with the same Quick Battle seed and identical battle context, lane composition, and initial cohesion  
  When the System runs the Quick Battle resolver for both  
  Then the System produces the same battle result (ATTACKER, DEFENDER, or MUTUAL_EXHAUSTION), the same per-side casualty counts, and the same provinceFlips value in both runs.

- Given a Quick Battle has completed with a decisive attacker win and the resolver returns provinceFlips true  
  When the combat pipeline applies the Quick Battle result to the game state  
  Then the System flips province ownership to the attacker and applies casualties using the same world-state update logic as auto-resolve; given a defender hold or mutual exhaustion result, the System does not flip province ownership.

- Given the System computes lane-level effective combat power for a Quick Battle round  
  When the System applies terrain modifiers for each lane  
  Then the System uses the attacker and defender percentage adjustments from the Percentage adjustments to combat power table in this spec (OPEN 100% / 100%, HILL 75% / 120%, WOODS 80% / 110%, TOWN 60% / 130%, SWAMP 70% / 90%).

- Given a Quick Battle round is about to begin and both sides have regiments and optional general medals  
  When the System determines which side acts first in that round  
  Then the System computes initiative consistent with [combat.md](combat.md) § Rules (Initiative) (cavalryShare × W_cav + generalMedals × W_medal) and uses that ordering (or tie-break by faction id) to decide first-acting side. General medals (deployment limit, initiative, morale aura) apply the same way as in auto-resolve per [military-generals.md](military-generals.md).

- Given a siege Quick Battle (`fortLevel` 1, 2, or 3) is initialized for a province  
  When the System builds Quick Battle input  
  Then the System includes the correct count of virtual emplaced gun entities with per-gun HP and attack/defense per [siege-mechanics.md](siege-mechanics.md), places them behind the fort in the documented lane/line slot, and does not add duplicate virtual guns for defender field artillery regiments already on the map.

- Given a siege Quick Battle is in progress and at least one virtual emplaced gun has remaining HP  
  When a Quick Battle action that can deal damage to the defender resolves  
  Then the System may reduce emplaced gun HP (or destroy guns) according to [quick-battle-resolution.md](../program/quick-battle-resolution.md); destroyed guns do not contribute further offense or defense for that battle.

- Given a siege Quick Battle completes and every virtual emplaced gun was destroyed during the battle  
  When the combat pipeline applies the Quick Battle result to world state  
  Then the System sets the province `fortLevel` to `max(0, previousFortLevel - 1)` regardless of `provinceFlips` or mutual exhaustion, and applies regiment casualties and ownership per existing rules.

