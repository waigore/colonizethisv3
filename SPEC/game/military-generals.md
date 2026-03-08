# Military Generals, Armies, and Regiment Economy

**SPEC/game** — Generals, general cap, assignment, medals, and regiment costs. Part of land military design. See [military-units.md](military-units.md). Combat: [combat.md](combat.md). Province identity: [world-model-identity.md](world-model-identity.md).

---

## Generals

Generals are **purely abstract entities**. They have no province, no map location, and are not tied to any stack or tile. They exist only as a per-faction pool of commanders used at combat time.

### Count and tech-gated cap

Each Great Power has a **general cap**: the maximum (and minimum) number of generals that faction may have. The faction **always has exactly that many generals**—no more, no less. Generals are never removed from the game.

- **Initial cap:** 1. At game start, the faction has one general.
- **Growth (tech-gated):** The cap increases when the faction researches specific techs. Let `capBase = 1`. Then:
  - If `organised_regiments` is in `techUnlocked`, set `capBase = max(capBase, 2)`.
  - If `national_bureaucracy` **or** `improved_infantry_tactics` is in `techUnlocked`, set `capBase = max(capBase, 3)`.
  - If `nationalism` is in `techUnlocked`, set `capBase = max(capBase, 4)`.
  The faction’s **general cap** is `capBase`. When the cap increases (e.g. from 1 to 2), the system immediately creates additional generals so that total general count equals the new cap; new generals start at 0 medals. **Stacking:** `national_bureaucracy` and `improved_infantry_tactics` do not stack—only one of them is required for cap 3; researching both does not increase the cap further.
- **Scope:** The cap is per faction (global), not per region.

### Assignment

Generals are **not** assigned to provinces or stacks by default. Assignment is **required and automated at combat time**:

- **When attacking:** A faction that orders an attack (move into an enemy province) must commit one general to that attack. The system chooses **one general at random** from that faction’s generals who are not already committed to another battle this turn. That general is “assigned” to that attacking force for the **duration of that battle only**. This **caps the number of attacks** a faction can make in one turn: at most one attack per general (so at most general cap attacks per turn).
- **When defending:** When a province owned by the faction is attacked, the system automatically assigns **one general at random** from that faction’s generals who are not already committed to another battle this turn. If the faction has **no uncommitted general**, the province **may still be defended**, but **without a general** (defender general medals = 0 for that battle).

**Defender general modeling:** Currently, defender generals are **not modeled** in combat resolution—defender general medals are treated as 0. This means the defender side does not receive +1 per defender general medal to the deployment limit, and no defender morale aura or initiative bonus is applied. When defender general state is added in a future phase, the defender side should symmetrically receive +1 per defender general medal to the deployment limit (matching attacker behavior).

**Commitment lifetime:** A general is committed only for the duration of one battle. When that battle’s resolution completes, the generals assigned to that battle (attacker and defender) are **freed**. If there is a subsequent battle in the same turn (e.g. another province), the assignment process runs again and any general may be assigned, including one who was just in a previous battle.

Assignment is only for applying general bonuses in combat (deployment limit, initiative, morale aura). It does not imply any map location.

### Medals

Each general has **medals** 0–4.

- **Gain:** Each time a general **wins** a battle (they commanded the winning side), they gain one medal, up to a maximum of 4.
- **Loss:** Medals never decrease. Generals are never removed.

Medal effects in combat (see [combat.md](combat.md) and [combat-resolution.md](../program/combat-resolution.md)):

- **Deployment:** +1 regiment per general medal to the per-side deployment limit (base 10; Nationalism tech → 12).
- **Morale aura:** Regiments on that side receive a strength bonus of **5% per general medal**, up to a maximum of **20%** (at 4 medals). These values are program-level constants; ruleset-configurable morale aura is deferred to a future phase.
- **Initiative:** Army initiative uses `cavalryShare × W_cav + generalMedals × W_medal` for ordering multi-attacker chains.

Defender without a general uses 0 general medals for deployment, morale, and initiative.

**Quick Battle:** General medals (deployment limit, initiative, morale aura) apply the same way in Quick Battle as in auto-resolve; see [quick-battle.md](quick-battle.md).

---

## Regiment Economy (Training & Upkeep)

Each regiment type has **training cost** and **food upkeep** defined in **program-level config**:

- **Training cost:** Cash + material inputs (fabric, cast iron, lumber, steel, bronze) + **one worker** consumed from the player's WorkerPool at construction time. Cavalry and artillery cost more than line infantry; late-era elites are most expensive.
- **Upkeep (food):** Per-turn food demand per regiment, consumed during the Consumption phase. Light infantry and early-era units have lower upkeep; cavalry, artillery, and late-era elites have higher upkeep.

Per-regiment values follow the same era/category progression as the tactical stats table in [military-units.md](military-units.md).

**Config source:** Regiment economy values (training cost, food upkeep) live in program-level config (`colonizethis_data/lib/src/regiment_economy.dart`) per [ruleset-config.md](../program/ruleset-config.md). Ruleset-configurable regiment economy is deferred to a future phase when the ruleset loader supports JSON merge.

**Implementation:** Training cost (cash, materials, worker) is applied at build time when BuildUnitOrder (military) is resolved per [orders.md](../program/orders.md). Food upkeep is consumed during the Consumption phase per [turn-resolution-phase-details.md](../program/turn-resolution-phase-details.md) § Consumption and [economy-models.md](../program/economy-models.md).

---

## Armies and Movement

- **Army (for combat):** In a given battle, an “army” is the set of regiments on one side (attacker or defender) plus, if available, the one general assigned to that side for that battle. Generals are assigned at combat resolution time as above; they are not pre-assigned to provinces or stacks on the map.
- **Location:** Regiments are always located in a province. A player's regiments must be in provinces they own when at peace. Movement into a non-owned province is an attack and requires committing a general for that attack (subject to the attack cap).
- **Movement into non-owned province:** Moving regiments into a province the player does not own is an act of war. War declaration is triggered during turn resolution (Diplomacy phase) before Movement; combat and province-flip logic apply when units enter enemy-held territory. See [combat.md](combat.md) and [movement.md](../program/movement.md).

Province ids use the prefixed form and lookup rules in [world-model-identity.md](world-model-identity.md).

---

## Acceptance criteria

- Given a Great Power at game start  
  When the system initializes that faction’s generals  
  Then the system creates exactly one general for that faction (general cap 1) and sets that general’s medals to 0.

- Given a Great Power with general cap C and current general count equal to C  
  When the system applies a tech that increases that faction’s general cap according to the rules above  
  Then the system increases the cap to the new value C' and adds new generals so that the faction has exactly C' generals, each with medals in 0–4; every newly created general has 0 medals.

- Given a Great Power that does not have `organised_regiments` in `techUnlocked`  
  When the system initializes that faction’s generals  
  Then the general cap is 1 and the faction has exactly one general.

- Given a Great Power that researches `organised_regiments` and previously had general cap 1  
  When the system updates general cap from tech state  
  Then the general cap becomes 2 and the faction has exactly two generals, with the newly created general starting at 0 medals.

- Given a Great Power that has general cap 2 from `organised_regiments` and then researches either `national_bureaucracy` or `improved_infantry_tactics`  
  When the system updates general cap from tech state  
  Then the general cap becomes 3 and the faction has exactly three generals, with each newly created general starting at 0 medals.

- Given a Great Power that has general cap 3 and then researches `nationalism`  
  When the system updates general cap from tech state  
  Then the general cap becomes 4 and the faction has exactly four generals, with each newly created general starting at 0 medals.

- Given a Great Power that has general cap 3 from `national_bureaucracy` and then researches `improved_infantry_tactics` (or vice versa)  
  When the system updates general cap from tech state  
  Then the general cap remains 3; researching both techs does not increase the cap further.

- Given a Great Power with G generals and no attacks or defenses yet committed this turn  
  When the player orders an attack (move into an enemy province)  
  Then the system selects one general at random from that faction’s G generals, commits that general to that attack for this turn, and allows the attack to proceed; the number of attacks that faction may order this turn is at most G.

- Given a Great Power that has already committed all G of its generals to attacks or defenses this turn  
  When an enemy attack targets another province owned by that faction  
  Then the system allows the province to be defended with defender general medals equal to 0 (no general assigned to that defense).

- Given a province owned by a faction with at least one uncommitted general and under attack  
  When the system resolves the defender side for that battle  
  Then the system selects one uncommitted general at random, commits that general to this defense for this turn, and uses that general’s medals for deployment limit, initiative, and morale aura for the defender.

- Given a general who commanded the winning side of a battle and has current medals M less than 4  
  When the system records the battle outcome  
  Then the system increases that general’s medals by 1 (to M+1).

- Given a general who commanded the winning side of a battle and has current medals 4  
  When the system records the battle outcome  
  Then the system leaves that general’s medals at 4.

- Given a general who commanded the losing side (or a stalemate / mutual annihilation where that side did not win)  
  When the system records the battle outcome  
  Then the system does not change that general’s medals.

- Given combat resolution for one engagement  
  When the system applies deployment limit and modifier rules  
  Then the system caps participating regiments per side to base (10, or 12 with Nationalism tech) + that side’s assigned general medals (or 0 if no general), and applies initiative and morale aura per [combat.md](combat.md) and [combat-resolution.md](../program/combat-resolution.md).

---

## AC–scenario mapping

Each acceptance criterion above has a matching scenario file under `tool/sim_scenarios/scenarios/` for integration testing. When general state is implemented in game setup and turn resolution, scenarios may add `generalCount` (and related) assertions.

| AC summary | Scenario file |
|------------|----------------|
| Game start: one general per GP, cap 1, medals 0 | military_generals_initial_one.json |
| No organised_regiments: cap 1, exactly one general | military_generals_initial_one.json |
| Cap increase from tech: new generals created with 0 medals | military_generals_cap_increase_tech.json |
| organised_regiments → cap 2, two generals | military_generals_cap_two_organised_regiments.json |
| national_bureaucracy or improved_infantry_tactics → cap 3 | military_generals_cap_three.json |
| nationalism → cap 4 | military_generals_cap_four_nationalism.json |
| national_bureaucracy + improved_infantry_tactics: cap stays 3 (no stack) | military_generals_cap_three_no_stack.json |
| At most G attacks per turn (one general per attack) | military_generals_attack_cap.json |
| Defend with 0 general medals when no uncommitted general | military_generals_defend_without_general.json |
| Defender gets uncommitted general at random | military_generals_defender_assigned.json |
| Winning general gains +1 medal (max 4) | military_generals_medal_gain_win.json |
| Winning general at 4 medals stays at 4 | military_generals_medal_cap_four.json |
| Losing / stalemate: general medals unchanged | military_generals_medal_no_gain_loss.json |
| Combat: deployment limit and modifiers per side | military_generals_deployment_limit.json |
