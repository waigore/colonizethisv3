# Military Generals, Armies, and Regiment Economy

**SPEC/game** — Generals, general cap, **pre-combat assignment to armies**, medals, and regiment costs. Part of land military design. **Armies (containers, movement, split/combine):** [military-armies.md](military-armies.md). Regiments: [military-units.md](military-units.md). Combat: [combat.md](combat.md). Province identity: [world-model-identity.md](world-model-identity.md).

---

## Generals

Generals are **purely abstract entities**. They have no province, no map location, and are not tied to a tile. They exist as a per-faction pool of commanders. **Binding to forces** happens only through **pre-combat assignment to armies** ([military-armies.md](military-armies.md)), not through permanent map stacks.

### Count and tech-gated cap

Each Great Power has a **general cap**: the maximum (and minimum) number of generals that faction may have. The faction **always has exactly that many generals**—no more, no less. Generals are never removed from the game.

- **Initial cap:** 1. At game start, the faction has one general.
- **Growth (tech-gated):** The cap increases when the faction researches specific techs. Let `capBase = 1`. Then:
  - If `organised_regiments` is in `techUnlocked`, set `capBase = max(capBase, 2)`.
  - If `national_bureaucracy` **or** `improved_infantry_tactics` is in `techUnlocked`, set `capBase = max(capBase, 3)`.
  - If `nationalism` is in `techUnlocked`, set `capBase = max(capBase, 4)`.
  The faction’s **general cap** is `capBase`. When the cap increases (e.g. from 1 to 2), the system immediately creates additional generals so that total general count equals the new cap; new generals start at 0 medals. **Stacking:** `national_bureaucracy` and `improved_infantry_tactics` do not stack—only one of them is required for cap 3; researching both does not increase the cap further.
- **Scope:** The cap is per faction (global), not per region. The cap applies to **Great Powers only**; Minor Nations and Tribes have no general cap and no generals.

### Persistence and load reconciliation (spawn-only)

The System **persists** each Great Power's effective general cap (`Player.generalCap`) in the save file. On **load** the System reconciles each GP's `generals` roster to its effective cap:

- The effective cap is the persisted `Player.generalCap`. When a loaded save has **no** persisted cap (legacy migration), the System derives it from `techUnlocked` via the cap-stacking rules above (minimum 1).
- Reconciliation is **spawn-only**: when the roster has fewer generals than the cap, the System spawns missing generals with 0 medals until the roster size equals the cap. The System **never deletes** generals; a roster that already **exceeds** the cap is retained (above-cap rosters are tolerated, not trimmed). Cap growth is therefore monotonic.

### Assignment (pre-Combat phase)

Generals are **not** permanently assigned to provinces. **Immediately before the Combat phase begins** — after Movement and Minor Regiment Upgrade, before any land battle is resolved — the system runs **general–army binding** for every faction that will participate in land combat this phase:

- **Attacking armies:** Each **army** that moved into a hostile/neutral province (or otherwise triggers an attack engagement this turn per combat rules) must receive **one** general from that faction’s pool, chosen **at random** from generals **not already bound** to another **attacking** army this phase. Binding lasts for the **Combat phase** (all that army’s engagements in that phase). This preserves the **attack cap:** at most **one distinct attacking army** per general per Combat phase for offensive binding (equivalently: at most `general cap` simultaneous offensive army commitments when generals are available).
- **Defending armies:** For each **defending army** present in a province where a land battle will occur, the system assigns **one** general at random from generals not already bound to another **defending** army this phase **when** a general is required for that army’s side. If **no** general is available for a defending side, that side uses fallback `generalMedals` from leader combat multiplier: `>=1.25 => 4`, `>=1.20 => 3`, `>=1.15 => 2`, `>=1.10 => 1`, else `0`.

**Defender general in province:** When multiple defending armies of the same faction share a province, combat uses **one** defender medal value for the merged defender side: the **primary defending army**’s bound general (see [military-armies.md](military-armies.md)); if that army has no binding, use fallback for the side.

**Medal effects** (deployment limit, morale aura, initiative) use the **army-bound** general for each attacking army; ledger and Quick Battle rules in [combat-resolution.md](../program/combat-resolution.md) refer to **army** and `generalId` on each attacking side, not ad-hoc per-battle random picks after the pre-Combat binding step.

**Commitment lifetime:** Bindings for the Combat phase are **released** when the Combat phase ends. A general may be rebound in a later turn.

Assignment applies only combat modifiers; it does not place generals on the map.

### Medals

Each general has **medals** 0–4.

- **Gain:** Each time a general **wins** a battle (they commanded the winning side), they gain one medal, up to a maximum of 4.
- **Loss:** Medals never decrease. Generals are never removed.

Medal effects in combat (see [combat.md](combat.md) and [combat-resolution.md](../program/combat-resolution.md)):

- **Deployment:** +1 regiment per general medal to the per-side deployment limit (base 10; Nationalism tech → 12).
- **Morale aura:** Regiments on that side receive a strength bonus of **5% per general medal**, up to a maximum of **20%** (at 4 medals). These values are program-level constants; ruleset-configurable morale aura is deferred to a future phase.
- **Initiative:** Army initiative uses `cavalryShare × W_cav + generalMedals × W_medal` for ordering multi-attacker chains.

Defender without an uncommitted general uses fallback medals derived from leader combat multiplier for deployment, morale, and initiative.

**Quick Battle:** General medals (deployment limit, initiative, morale aura) apply the same way in Quick Battle as in auto-resolve; see [quick-battle.md](quick-battle.md).

---

## Regiment Economy (Training & Upkeep)

Each regiment type has **training cost** and **food upkeep** defined in **program-level config**:

- **Training cost:** Cash + material inputs (fabric, cast iron, lumber, steel, bronze) + **one worker** consumed from the player's WorkerPool at construction time. Cavalry and artillery cost more than line infantry; late-era elites are most expensive.
- **Upkeep (food):** Per-turn food demand per regiment, consumed during the Consumption phase. Light infantry and early-era units have lower upkeep; cavalry, artillery, and late-era elites have higher upkeep.

Per-regiment values follow the same era/category progression as the tactical stats table in [military-units.md](military-units.md).

### Regiment treasury cost scale (canonical)

`buildTreasuryCost` for every regiment is defined as the Phase 5 baseline value multiplied by **100**. This scale is the source of truth for military `BuildUnitOrder` treasury validation and deduction.

| regiment_id | build_treasury_cost |
| --- | ---: |
| peasant_levies | 2000 |
| pikemen | 4000 |
| arquebusiers | 5000 |
| bowmen | 3000 |
| squires | 6000 |
| knights | 8000 |
| culverin | 8000 |
| calivermen | 7000 |
| halberdiers | 7000 |
| musketeers | 8000 |
| cossacks | 9000 |
| lancers | 10000 |
| harquebusiers | 11000 |
| horse_artillery | 11000 |
| royal_artillery | 12000 |
| skirmishers | 9000 |
| regulars | 11000 |
| grenadiers | 13000 |
| hussars | 13000 |
| cuirassiers | 15000 |
| light_artillery | 14000 |
| heavy_artillery | 16000 |
| sharpshooters | 12000 |
| rifle_infantry | 14000 |
| guards | 18000 |
| scouts | 15000 |
| carbine_cavalry | 18000 |
| field_artillery | 18000 |
| siege_guns | 22000 |

**Config source:** Regiment economy values (training cost, food upkeep) live in program-level config (`colonizethis_data/lib/src/regiment_economy.dart`) per [ruleset-config.md](../program/ruleset-config.md). Ruleset-configurable regiment economy is deferred to a future phase when the ruleset loader supports JSON merge.

**Implementation:** Training cost (cash, materials, worker) is applied at build time when BuildUnitOrder (military) is resolved per [orders.md](../program/orders.md). Food upkeep is consumed during the Consumption phase per [turn-resolution-phase-details.md](../program/turn-resolution-phase-details.md) § Consumption and [economy-models.md](../program/economy-models.md).

---

## Armies and movement (summary)

Persistent **armies** (containers of regiment ids, one province per army) are defined in [military-armies.md](military-armies.md). **Combat-side** “army” in battle is built from those regiments plus the **pre-bound** general for each **attacking army** and the **primary defending army**’s general for the defender side.

- **Location:** Regiments are always in a province via their army’s station. Movement orders are **per army**; all regiments in the army move together.
- **Movement into non-owned province:** Still an act of war; war declaration runs in Diplomacy before Movement. **General** commitment is expressed through pre-Combat binding to **attacking armies** (subject to cap). See [combat.md](combat.md) and [movement.md](../program/movement.md).

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

- Given a Great Power with G generals at the start of the Combat phase and K distinct **attacking armies** of that faction that will enter land combat this phase, when the system runs **pre-Combat general–army binding**, then the system assigns a distinct general to each of up to min(K, G) of those armies chosen at random from the pool, and any further attacking army beyond that receives **fallback** attacker medals (leader mapping) with no `generalId` for the ledger.

- Given a defending faction whose generals are all already bound to other **defending** armies this Combat phase and leader combat multiplier `L`, when a land battle still requires defender medals for that side, then the system uses fallback defender general medals derived from `L` using this mapping: `>=1.25 => 4`, `>=1.20 => 3`, `>=1.15 => 2`, `>=1.10 => 1`, else `0`.

- Given a defending army in a province under land attack and at least one general still eligible for **defender** binding this Combat phase, when the system runs pre-Combat binding for that army, then the system assigns one such general at random to that army and uses that general’s medals (via the primary-army rule in [military-armies.md](military-armies.md) when merged) for deployment limit, initiative, and morale aura for the defender side.

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

- Given a faction id that owns one or more `General` records in game state (any such faction, not only a Great Power), when the Combat phase runs multiple land battles and that faction fields multiple **attacking armies**, then the system applies the phase ledger in [combat-resolution.md](../program/combat-resolution.md) §3 so a general already bound to an attacking army this phase is not bound to another attacking army in the same phase; if no general remains for another attacking army, that army’s attacking side uses fallback medals only.

- Given Quick Battle is selected for a land battle, when the system builds Quick Battle input from the same `BattleContext`, pre-Combat bindings, and phase ledger as auto-resolve would use, then attacker and defender general medal inputs match the pre-Combat binding + fallback rules in [combat-resolution.md](../program/combat-resolution.md) §3, with the primary attacker defined as the first `BattleContext.attackers` entry.

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
| At most G attacking armies bound to distinct generals per Combat phase | military_generals_attack_cap.json (update for armies) |
| Defend with fallback when no defender general available | military_generals_defend_without_general.json |
| Defender army gets bound general when pool allows | military_generals_defender_assigned.json |
| Winning general gains +1 medal (max 4) | military_generals_medal_gain_win.json |
| Winning general at 4 medals stays at 4 | military_generals_medal_cap_four.json |
| Losing / stalemate: general medals unchanged | military_generals_medal_no_gain_loss.json |
| Combat: deployment limit and modifiers per side | military_generals_deployment_limit.json |
