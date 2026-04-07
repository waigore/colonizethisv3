# Tech Tree — Labour and Economy

**SPEC/game** — Worker tiers, banking, trade, and University. Reference: Imperialism II 08-technology (Labour and Economy). Overview: [tech-tree.md](tech-tree.md).

---

## Tech Table

| id | name | era | prerequisites | effects |
|----|------|-----|---------------|--------|
| printing_press | Printing Press | 1 | — | Leads to Journeymen, tactics, siege engineering |
| apprentice_workers | Apprentice Workers | 2 | land_enclosure, sugar_refining | 4× labour; consume refined sugar |
| trained_journeymen | Trained Journeymen | 2 | cigar_production, printing_press | 6× labour; consume cigars |
| master_artisans | Master Artisans | 3 | apprentice_workers, university, hat_production | 8× labour; consume fur hats |
| money_lending | Money Lending | 1 | land_enclosure | Research treasury floor −500 (see below); borrowing/interest deferred |
| banking | Banking | 3 | master_artisans, trade_fairs | Prereq for other techs; extended debt/interest/military-treasury links deferred |
| trade_fairs | Trade Fairs | 2 | merchant_companies, sugar_refining | Forward-looking: more trade commodity slots vs baseline (not wired in MVP; see below) |
| university | University | 3 | money_lending, apprentice_workers, printing_press | Increases research slots from 3 to 4 (permanent per player); leads to many advances |

---

## Effect implementation status (MVP)

This section resolves ambiguity called out for **#145**: which table rows are **live rules** vs **prerequisite-only** vs **deferred**.

### money_lending

- **Implemented:** During the **Research phase** only, research funding may reduce treasury to a floor of **−500** ducats (inclusive). Without `money_lending`, the floor is **0** (research spending cannot make treasury negative). Numeric owner: `maxDebtForPlayer` in `packages/colonizethis_logic/lib/src/turn/economy_debt_rules.dart`, applied by the research resolver (`research_resolver.dart`). Program contract: [research-resolution.md](../program/research-resolution.md), [economy-models.md](../program/economy-models.md) § Research treasury debt.
- **Deferred:** General borrowing, loans, and interest rates are **not** simulated in MVP. Flavor text may mention “borrow” or “interest”; there is no separate banking UI or formula until a future economy spec.

### banking

- **Implemented in MVP:** Unlock graph only — `banking` is a **prerequisite** in the global tech catalog for other techs (e.g. `modern_military_funding`, `empire_building`, `dynamite` per their tables).
- **Deferred:** “Lower interest”, “larger negative spending” beyond Money Lending, and any treasury-linked “military funding” effect from this row are **not** implemented. **`banking` alone does not change** `maxDebtForPlayer` today; only `money_lending` does. When extended debt or interest is added, update this doc and program specs with exact formulas, phase ownership, and tests.

### trade_fairs

- **Deferred:** “Bid on 6 commodities (vs 3)” is **not** connected to diplomacy trade or any market/auction in MVP. Diplomacy uses a **stub** trade-slot helper (`tradeSlotsForGp`: 0 without embassy, 1 with embassy) that does **not** model commodity counts; see [diplomacy-resolution.md](../program/diplomacy-resolution.md).
- **Design contract when implemented:** The baseline **3** and **6 with Trade Fairs** refer to **maximum distinct commodities** (or equivalent slots) per **trade agreement** or trade UI — **not** a separate mechanic from trade agreements unless GDD explicitly splits them. Until that feature ships, treat the table line as forward-looking flavor; the authoritative behavior is the stub above.

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
