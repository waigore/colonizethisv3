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

Every fort includes **emplaced artillery**; there is no separate build queue for these pieces. Fort level determines **how many guns** are present and their baseline quality:

- Level 1 (Wood): **1** emplaced gun.
- Level 2 (Stone): **2** emplaced guns.
- Level 3 (Modern): **3** emplaced guns.

Gun **quality** upgrades automatically with technology (Royal → Heavy → Siege) per ruleset config. Emplaced guns cannot move and gain **+1 RNG** compared with heavy artillery of the same era (elevation and prepared fields of fire). If all emplaced guns are destroyed in battle, the fort is reduced by one level even if attackers lose. Emplaced guns do **not** count against the deployment limit.

---

## Battle Type and Forts

Combat mode is chosen in [combat.md](combat.md):

- Provinces with `fortLevel == 0` use **field battle** rules only.
- Provinces with `fortLevel ≥ 1` use **siege** rules from this spec (walls, wall HP, emplaced artillery, gates and sorties).

There is no separate “unfortified siege” mode: the presence or absence of a fort is the only switch between field and siege behaviour.

---

## Gates and Sortie

Forts have three gates. Friendly units can sortie or retreat through gates. Enemy units cannot use gates; walls must be breached to enter.

**Quick Battle (lane-based) interpretation:** In the current lane-based Quick Battle resolver, all defender units are treated as benefiting from wall damage reduction and emplaced artillery. Explicit "units on the wall" vs "units behind the wall" targeting (artillery-only damage to behind-wall) and gate/sortie actions are deferred to a future tactical expansion when lane/position model supports it.

---

## Acceptance Criteria

- Given a province has a fort level of 0, 1, 2, or 3 stored in the world model and the combat resolver creates a BattleContext for a battle in that province  
  When the System chooses the battle mode per [combat.md](combat.md)  
  Then the System selects field battle rules when `fortLevel == 0` and siege rules from this document (including wall damage reduction and emplaced artillery) when `fortLevel ≥ 1`.

- Given defenders are in a province with a fort level of 1, 2, or 3 and an incoming attack triggers siege combat  
  When the System computes damage to defenders that are on or behind the wall  
  Then the System reduces incoming damage by the percentage in the Wall Protection table for the current fort level and only allows non-artillery units with RNG 1 to inflict damage if defenders have sortie’d out of the fort according to the tactical rules.

- Given a fort with level 1, 2, or 3 is present in a province and a siege battle is resolved there  
  When the System initializes the battle  
  Then the System creates 1, 2, or 3 emplaced artillery guns respectively, applies a +1 RNG bonus to those guns relative to comparable heavy artillery of the same era, excludes emplaced guns from the deployment limit, and automatically downgrades the fort by one level if all emplaced guns are destroyed during the battle even if the attackers lose.
