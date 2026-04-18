# Siege Mechanics

**SPEC/game** — Fort structure and siege combat. Reference: Imperialism II 06-combat. Combat: [combat.md](combat.md). Military units: [military-units.md](military-units.md).

---

## Fort Levels

| Level | Name | Guns | Wall Strength | Cost |
|-------|------|------|---------------|------|
| 1 | Wood | 1 emplaced | Light | 3 Lumber, 3 Bronze |
| 2 | Stone | 2 emplaced | Medium | 4 Lumber, 4 Bronze (+ Mine Engineering) |
| 3 | Modern | 3 emplaced | Heavy | 5 Steel, 5 Lumber (+ Modern Forts) |

Engineers build forts on the town tile using `WorkOrder` target `build_fort`. Each completed fort build or upgrade is a **multi-turn project** resolved during the Build/Work phase; higher fort levels require more turns and stricter tech prerequisites (Mine Engineering, Modern Forts) and consume the materials shown above. Fort level is stored in the world model and read by the combat system; see [development-resolution.md](../program/development-resolution.md) and [world-model.md](world-model.md). **Province identity:** when logic looks up or updates a province (e.g. conflict detection, build_fort completion, fort downgrade), use full province id or region-scoped lookup per [world-model-identity.md](world-model-identity.md).

---

## Wall Protection

All damage to defenders on or behind the wall is reduced by a percentage based on fort level.

### Auto-resolve HP Soak

In **auto-resolved combat**, the wall absorbs a fixed amount of damage (HP soak) before the remaining attacker strength affects the defender casualty ratio:

| Fort Level | Wall HP | Description |
|-----------|----------|-------------|
| 1 (Wood) | 10 | Light wall absorbs 10 damage |
| 2 (Stone) | 20 | Medium wall absorbs 20 damage |
| 3 (Modern) | 30 | Heavy wall absorbs 30 damage |

**Mechanism:** Attacker strength is first reduced by the wall HP value. Damage exceeding the wall HP is applied to the defender casualty ratio. Exact values are configurable in the ruleset (SPEC/program/combat-resolution.md, `combat_config.dart`).

### Damage Reduction (Tactical Combat)

In tactical/quick battle, damage to defenders on or behind the wall is reduced by percentage:

| Fort Level  | Damage Reduction | Rationale             |
| ----------- | ---------------- | --------------------- |
| 0 (no fort) | 0%               | Baseline              |
| 1 (Wood)    | 25%              | Modest protection     |
| 2 (Stone)   | 45%              | Significant advantage |
| 3 (Modern)  | 60%              | Very hard to crack    |


- **Units on the wall** (adjacent to wall hex): Can be hit by firearms and artillery (at reduced damage per table above).
- **Units behind the wall** (not manning): Cannot be damaged except by enemy artillery; only artillery can return fire.
- **Melee-only units** (RNG 1): Cannot attack walls or any units in a fort. Must sortie to engage.

---

## Emplaced Artillery

Every fort includes **emplaced artillery**; there is no separate build queue for these pieces. Fort level determines **how many** emplaced pieces exist:

- Level 1 (Wood): **1** emplaced gun.
- Level 2 (Stone): **2** emplaced guns.
- Level 3 (Modern): **3** emplaced guns.

**Field artillery** (light/heavy/horse artillery regiments, etc.) are normal **military units** on the province map; they are **not** emplaced fort pieces. Only the fort’s fixed battery uses the rules below.

**Quick Battle (tactical path):** Before Quick Battle resolution, the System **auto-spawns virtual emplaced gun entities** for the defender when `fortLevel ≥ 1`. These are **not** `Unit` rows in `WorldState`; they exist only inside the Quick Battle input for that fight. Each virtual gun has its own **HP** and **attack/defense strength** (numeric combat stats — exact formulas and caps live in ruleset / `combat_config` and MUST follow the defender’s unlocked emplaced-quality tech line per [tech-tree-military.md](tech-tree-military.md) (Royal → Heavy → Siege) and fort level). The System **assigns** them to a defended position **behind the fort** per [quick-battle.md](quick-battle.md) (placement is deterministic and documented in SPEC/program). They can be **targeted** by Quick Battle actions like other combatants on the field; when HP reaches zero, that gun is **destroyed** for the rest of that battle. Emplaced virtual guns do **not** count against the deployment limit. They gain **+1 RNG** compared with heavy artillery of the same era (elevation and prepared fields of fire), applied when their stats are derived for Quick Battle.

**Fort downgrade:** If **all** emplaced virtual guns for that province battle are destroyed before Quick Battle ends, the fort is **reduced by one level** (`fortLevel := max(0, fortLevel - 1)`) when applying the Quick Battle result to world state, **even if the attackers lose** (defender holds or mutual exhaustion). This is the authoritative interpretation of “all emplaced guns destroyed” for the Quick Battle path.

**Auto-resolve path:** Until emplaced pieces are modeled there too, auto-resolve may continue to use the **aggregate** emplaced bonus (`fortGunCount` × strength) and **does not** apply the virtual-gun fort downgrade rule. A future spec change may define an aggregate proxy for downgrade or align auto-resolve with the same entity model.

---

## Battle Type and Forts

Combat mode is chosen in [combat.md](combat.md):

- Provinces with `fortLevel == 0` use **field battle** rules only.
- Provinces with `fortLevel ≥ 1` use **siege** rules from this spec (walls, wall HP, emplaced artillery, gates and sorties).

There is no separate “unfortified siege” mode: the presence or absence of a fort is the only switch between field and siege behaviour.

---

## Gates and Sortie

Forts have three gates. Friendly units can sortie or retreat through gates. Enemy units cannot use gates; walls must be breached to enter.

**Quick Battle (lane-based) interpretation:** Defender **map regiments** still use the simplified lane model (wall damage reduction, etc.). **Emplaced** pieces are the **virtual gun entities** above, not duplicate field-artillery regiments. Explicit “units on the wall” vs “behind the wall” for **map** units, artillery-only fire to behind-wall, and gate/sortie actions remain deferred until the lane/position model supports them; virtual emplaced guns are exempt from that deferral because they are first-class Quick Battle targets.

---

## Acceptance Criteria

- Given a province has a fort level of 0, 1, 2, or 3 stored in the world model and the combat resolver creates a BattleContext for a battle in that province  
  When the System chooses the battle mode per [combat.md](combat.md)  
  Then the System selects field battle rules when `fortLevel == 0` and siege rules from this document (including wall damage reduction and emplaced artillery treatment per resolution path) when `fortLevel ≥ 1`.

- Given defenders are in a province with a fort level of 1, 2, or 3 and incoming attack triggers **auto-resolved** siege combat  
  When the System computes effective strengths  
  Then the System applies wall HP soak and damage reduction per the Wall Protection / auto-resolve tables in this document. The System does **not** yet apply the “all emplaced guns destroyed → fort downgrade” rule on the auto-resolve path unless a later spec defines an aggregate proxy.

- Given a fort with level 1, 2, or 3 is present and the player (or pipeline) resolves combat via **Quick Battle**  
  When the System builds Quick Battle input for that siege  
  Then the System spawns exactly 1, 2, or 3 **virtual** emplaced gun entities respectively, assigns per-gun HP and attack/defense from ruleset and defender tech per this document, applies +1 RNG vs comparable heavy artillery of the same era, places them behind the fort per [quick-battle.md](quick-battle.md), excludes them from the deployment limit, allows Quick Battle actions to damage and destroy them, and when applying the Quick Battle result, sets `fortLevel` to `max(0, fortLevel - 1)` if every emplaced virtual gun was destroyed during that battle, even if the battle outcome is defender hold or mutual exhaustion.

- Given a siege Quick Battle includes defender field artillery regiments (normal military units) and virtual emplaced guns  
  When any Quick Battle action resolves fire or assault  
  Then the System treats field artillery as regiments in battalion groups and emplaced pieces only as virtual gun entities; the System does not spawn virtual emplaced units that duplicate existing field artillery regiments.
