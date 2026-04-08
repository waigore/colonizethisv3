# Tech Tree — Diplomacy and Civilian

**SPEC/game** — Diplomatic options and civilian unit unlocks. Reference: Imperialism II 08-technology (Diplomacy and Civilian). Overview: [tech-tree.md](tech-tree.md). Diplomacy: [diplomacy.md](diplomacy.md). Civilian units: [civilian-units.md](civilian-units.md). Province identity (e.g. provincial towns, purchase land): [world-model-identity.md](world-model-identity.md).

---

## Catalog and implementation

The **diplomacy and civilian tech table in this doc is the GDD source of truth** for tech id, name, era, prerequisites, and effects (embassy, civilian units, upgrade town, deployment limit, etc.). **Implementation:** The program-level tech catalog lives in code (e.g. `colonizethis_data`). Research order validation and completion use the catalog per [research-resolution.md](../program/research-resolution.md); build and work order validation use it per [orders.md](../program/orders.md). Builder **upgrade_town** (National Bureaucracy) and other civilian work targets are resolved in [development-resolution.md](../program/development-resolution.md).

---

## Tech Table

| id | name | era | prerequisites | effects |
|----|------|-----|---------------|--------|
| diplomatic_expertise | Diplomatic Expertise | 1 | — | Enables: embassy overture to Minor Nations and civilian work access in embassy-linked Minor Nations (Merchants, Engineers, Builders). Unlocks: prerequisite for `national_bureaucracy`. |
| merchant_companies | Merchant Companies | 1 | — | Enables: Merchant civilian unit construction and `purchase_land` work orders in Minor Nations/Tribes when an embassy exists and the parties are not at war. Unlocks: prerequisite for `trade_fairs`. |
| national_bureaucracy | National Bureaucracy | 2 | printing_press, money_lending, diplomatic_expertise | Enables: Builder `upgrade_town` work order for provincial towns. Improves: general cap floor to at least **3** per [military-generals.md](military-generals.md). Unlocks: prerequisite for `propaganda`. |
| propaganda | Propaganda | 3 | national_bureaucracy, university | Improves: third-party diplomatic protest penalty against a war aggressor from **-10** to **-5** relation score when the aggressor has `propaganda` (per diplomacy lookup constants). Unlocks: prerequisite for `nationalism`. |
| nationalism | Nationalism | 3 | propaganda, master_artisans, modern_forts | **Improves:** battle **deployment base limit** to **12** regiments (vs **10**; general medals still **+1** regiment each per [military-generals.md](military-generals.md)). **Improves:** **general cap** floor to at least **4**. **Unlocks:** prerequisite for `empire_building`. |
| empire_building | Empire Building | 4 | nationalism, banking | **Enables:** **Join Empire** diplomatic overture toward a **nearly defeated** Great Power (≤**3** provinces owned, **original capital not owned by target**) per [diplomacy.md](diplomacy.md). |

---

## Tech costs and prerequisites (MVP)

Tech costs and prerequisite ids for diplomacy/civilian techs are defined by the **tech table in this doc** (source of truth). **Implementation:** The program-level tech catalog (e.g. `colonizethis_data`) uses the same structure as other techs: fixed `cost` and `prerequisiteIds` per this table. When diplomacy/civilian techs are added to the catalog, prerequisite ids such as `printing_press` and `money_lending` are defined there (or in a shared catalog that includes labour/civilian techs). **Ruleset override** for tech costs and prereqs is deferred; when added, document in [ruleset-config.md](ruleset-config.md) and in the program ruleset-config.

## Propaganda effect

When a Great Power that **declared war** (the aggressor in an intervention context) has **`propaganda`** unlocked, **third-party** relation penalties that use the standard war-delta (e.g. **Intervention → Diplomatic Protest** against that aggressor) apply a **reduced** score drop (**5** instead of **10**). Constants: `relationScoreWarDelta` / `relationScoreWarDeltaReducedPropaganda` in program diplomacy lookup. See [diplomacy-resolution.md](../program/diplomacy-resolution.md).

---

## Effect Semantics

- **Diplomatic Expertise:** Unlocks embassy overture and allows civilian units to work in Minor Nations with embassy.
- **Merchant Companies:** Unlocks building Merchant civilian unit. **Purchasing land** (Merchant `purchase_land` work order) in a Minor Nation or Tribe requires Merchant Companies **and** an **embassy** with that Minor/Tribe (see [diplomacy.md](diplomacy.md), [civilian-units.md](civilian-units.md)).
- **Nationalism:** Raises battle **deployment base limit** to **12** regiments (vs **10**) and **general cap** floor to at least **4** per [military-generals.md](military-generals.md); prerequisite for `empire_building`.
- **Empire Building:** Enables **Join Empire** overture (GP can ask another GP to join when that target is **nearly defeated** as defined in [diplomacy.md](diplomacy.md) — three or fewer provinces remaining and original capital lost). See [diplomacy.md](diplomacy.md).

---

## Rules

### Province and tile identity

Effects that reference provinces (e.g. Builder upgrade town, Merchant purchase land) use **prefixed province ids** and **region-scoped lookup**; see [world-model-identity.md](world-model-identity.md).

---

## Acceptance criteria

- **Merchant build:** Merchant unit is buildable iff `merchant_companies` is in the player's `techUnlocked` set (catalog per [research-resolution.md](../program/research-resolution.md); build validation per [orders.md](../program/orders.md)).
- **Purchase land:** Merchant `purchase_land` work in a Minor Nation or Tribe requires Merchant Companies **and** an embassy with that Minor/Tribe **and** not at war; see [civilian-units.md](civilian-units.md), [diplomacy.md](diplomacy.md).
- **Deployment limit (Nationalism):** When `nationalism` is unlocked, deployment limit in battle is 12 regiments (vs 10 base); general may add more per [military-generals.md](military-generals.md). Resolution: [combat-resolution.md](../program/combat-resolution.md).
- **Builder upgrade_town:** Builder **upgrade_town** work requires `national_bureaucracy` in the player’s `techUnlocked` at order validation ([orders.md](../program/orders.md), `WorkOrderValidator`).
- **Join Empire:** Join Empire (GP ask) is gated by `empire_building`; see [diplomacy.md](diplomacy.md).
- **Diplomatic Expertise:** Unlocks embassy overture to Minor Nations and allows civilian units (Merchants, Engineers, Builders) to work in Minor Nations with embassy; see [diplomacy.md](diplomacy.md), [civilian-units.md](civilian-units.md).
- **Table as source of truth:** The tech table in this doc is the source of truth for tech id, name, era, prerequisites, and effects; program catalog (e.g. colonizethis_data) aligns with it per Catalog and implementation above.
