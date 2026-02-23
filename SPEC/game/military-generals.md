# Military Generals, Armies, and Regiment Economy

**SPEC/game** — Generals, medals, army definition, movement, and regiment costs. Part of land military design. See [military-units.md](military-units.md). Combat: [combat.md](combat.md). Province identity: [world-model-identity.md](world-model-identity.md).

---

## Generals

Generals are the **heads of armies**. An army is a group of regiments led by exactly one general; armies that participate in combat always have a general attached (**no general = no army** for field forces). Generals are limited by era-based caps (see GDD 05), and determine how many armies a faction can field.

Each general has **medals** (0–4), earned through successful battles (see [combat.md](combat.md)). General medals represent experience and rank. Effects:

- **Deployment:** +1 regiment per general medal to the battle deployment limit (base 10; Nationalism tech → 12).
- **Morale aura:** Regiments in the general's army receive a morale/strength bonus that scales with general medals (configurable percent per medal).
- **Initiative:** Army initiative rating increases with general medals and cavalry share; higher-medal generals tend to act earlier in multi-attacker chains.

---

## Regiment Economy (Training & Upkeep)

Each regiment type has **training cost** and **food upkeep** defined in ruleset config:

- **Training cost:** Cash + material inputs (fabric, cast iron, lumber, steel, bronze) + **one worker** consumed from the player's WorkerPool at construction time. Cavalry and artillery cost more than line infantry; late-era elites are most expensive.
- **Upkeep (food):** Per-turn food demand per regiment, consumed during the Consumption phase. Light infantry and early-era units have lower upkeep; cavalry, artillery, and late-era elites have higher upkeep.

Per-regiment values follow the same era/category progression as the tactical stats table in [military-units.md](military-units.md).

---

## Armies and Movement

- **Army definition:** An army is a set of regiments in a province led by exactly one general. Units are always part of armies; armies are always headed by a general. Armies are inferred by grouping units in a province by owner and matching to the general in that province.
- **Location invariant:** Armies are always located in a province. A player's armies must always be located within provinces they own. When at peace, a player's units remain in their owned provinces.
- **Movement into non-owned province:** Moving an army into a province the player does not own is an act of war. War declaration is triggered during turn resolution (Diplomacy phase) before Movement; the combat and province-flip logic then applies when units enter enemy-held territory. See [combat.md](combat.md) and [movement.md](../program/movement.md).

Province ids used for army/unit location and province ownership use the prefixed form and lookup rules in [world-model-identity.md](world-model-identity.md).

---

## Acceptance criteria

1. **Deployment limit:** Participating regiments per side in each engagement are capped to base (10, or 12 with Nationalism tech) + general medals; excess units do not participate in that engagement.
2. **Initiative:** Ordering uses general medals and cavalry share per [combat.md](combat.md) when general/medal state is populated.
3. **General morale aura:** Applies when general/medal state exists (deferred until modelled).
4. **Army / no general:** Army = units in province under one general; no general = no army for field forces (enforcement deferred).
5. **GDD 05 (era-based general caps):** External; general count/cap is out of scope until modelled.
