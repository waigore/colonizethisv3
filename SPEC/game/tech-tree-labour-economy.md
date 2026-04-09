# Tech Tree — Labour and Economy

**SPEC/game** — Worker tiers, banking, trade, and University. Reference: Imperialism II 08-technology (Labour and Economy). Overview: [tech-tree.md](tech-tree.md).

---

## Tech Table

| id | name | era | prerequisites | effects |
|----|------|-----|---------------|--------|
| printing_press | Printing Press | 1 | — | Unlocks: prerequisite for `trained_journeymen`, `university`, `improved_infantry_tactics`, `siege_engineering`, and `national_bureaucracy`. Prerequisite-only: no direct production or treasury modifier in current product. |
| apprentice_workers | Apprentice Workers | 2 | land_enclosure, sugar_refining | Enables: Apprentice worker tier with **4x labour output** and refined sugar luxury consumption per [workers-and-population.md](workers-and-population.md). Unlocks: prerequisite for `master_artisans` and `university`. |
| trained_journeymen | Trained Journeymen | 2 | cigar_production, printing_press | Enables: Journeyman worker tier with **6x labour output** and cigar luxury consumption per [workers-and-population.md](workers-and-population.md). Unlocks: prerequisite for `cotton_gin` and `steppe_horsemen` recruitment path. |
| master_artisans | Master Artisans | 3 | apprentice_workers, university, hat_production | Enables: Master worker tier with **8x labour output** and fur hat luxury consumption per [workers-and-population.md](workers-and-population.md). Unlocks: prerequisite for `banking`, `nationalism`, and `scientific_cattle_breeding`. |
| money_lending | Money Lending | 1 | land_enclosure | Research treasury floor **−500** (see below); general borrowing/interest remains deferred |
| banking | Banking | 3 | master_artisans, trade_fairs | Extends research treasury floor to **−1000** when combined with `money_lending` (see below). Unlocks: prerequisite for `dynamite`, `empire_building`, and `modern_military_funding`. |
| trade_fairs | Trade Fairs | 2 | merchant_companies, sugar_refining | Diplomacy trade agreements use **6** commodity slots (vs baseline **3**) when the GP has embassy access; see [diplomacy-resolution.md](../program/diplomacy-resolution.md). Unlocks: prerequisite for `banking`. |
| university | University | 3 | money_lending, apprentice_workers, printing_press | Increases research slots from 3 to 4 (permanent per player); leads to many advances |

---

## Effect implementation status (current product)

This section resolves ambiguity called out for **#145**: which table rows are **live rules** vs **prerequisite-only** vs **deferred**.

### money_lending

- **Implemented:** During the **Research phase** only, research funding may reduce treasury to a floor of **−500** ducats (inclusive) when `money_lending` is unlocked and `banking` is not. Without `money_lending`, the floor is **0**. Owner: `maxDebtForPlayer` in `economy_debt_rules.dart`. [research-resolution.md](../program/research-resolution.md).
- **Deferred:** General borrowing, loans, and interest rates outside the research-phase debt floor.

### banking

- **Implemented:** With **`money_lending` + `banking`**, the research treasury floor extends to **−1000** ducats. `banking` without `money_lending` does not change the floor. Unlock graph: prerequisite for `modern_military_funding`, `empire_building`, `dynamite`, etc.

### trade_fairs

- **Implemented:** `tradeSlotsForGp` returns **0** without embassy toward the target, **3** with embassy (baseline commodity capacity), **6** with embassy when `trade_fairs` is unlocked on the ordering GP. See [diplomacy-resolution.md](../program/diplomacy-resolution.md).

### “Leads to” wording (e.g. Printing Press, University)

- **Semantics:** Phrases such as “Leads to Journeymen…” or “leads to many advances” are **narrative hints** for the tech tree. **Authoritative unlock relationships** are **`prerequisiteIds`** in the global catalog (and prerequisite columns in tech-tree docs). There is **no** separate runtime “leads to” flag beyond prerequisites and discovery rules.

---

## Notes

- Cigar Production and Hat Production are listed under New World (discovery/luxury); Trained Journeymen and Master Artisans depend on them.
- Labour effects drive production/consumption and worker pool tiers; see economy specs.

---

## Acceptance Criteria

- Given the Labour and Economy tech table in this doc and the global tech catalog built from all tech-tree docs  
  When the System validates the catalog at startup  
  Then the System ensures that each id in this table is unique, that its prerequisites refer to techs present in the global catalog, and that **implemented** effects (worker tiers, research slots, Money Lending research debt floor) match [economy-models.md](../program/economy-models.md) and [research-resolution.md](../program/research-resolution.md). **Deferred** rows (`banking` economy effects, `trade_fairs` commodity counts) must remain explicitly marked as deferred in this doc until wired.

- Given a player does **not** have `money_lending` in `techUnlocked`  
  When the Research phase applies research funding that would spend treasury  
  Then the System does not reduce treasury below **0**.

- Given a player has `money_lending` in `techUnlocked`  
  When the Research phase applies research funding  
  Then the System does not reduce treasury below **−500** inclusive for that phase’s research spending.

- Given a player has `banking` in `techUnlocked` but **not** `money_lending`  
  When the System computes the research treasury floor for the Research phase  
  Then the System uses a floor of **0** (Banking does not extend research debt until specified in a future spec change).

- Given the global tech catalog  
  When a designer reads a “Leads to …” cell in this doc’s table  
  Then the only gameplay unlock graph required to match implementation is **prerequisite ids** (and discovery rules where applicable); “Leads to” text has no separate runtime effect.

- Given a player has `apprentice_workers`, `trained_journeymen`, or `master_artisans` in `techUnlocked` as defined in this table  
  When the System computes available labour for Production and food and luxury consumption for the Consumption phase per [workers-and-population.md](workers-and-population.md)  
  Then the System uses the labour-per-turn and consumption patterns in the worker tiers table and allows the presence of these techs to unlock the corresponding worker tiers and luxury dependencies.

- Given a player has unlocked `university` via this table  
  When the System sets up or updates the player’s research model per [tech-tree.md](tech-tree.md) and [research-state.md](research-state.md)  
  Then the System increases the player’s number of active research slots from three to four and allows that extra slot to hold a separate tech with its own funding preset and progress.
