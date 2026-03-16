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
| money_lending | Money Lending | 1 | land_enclosure | Borrow more; lower interest; allows research spending to drive treasury down to −500 (vs 0) |
| banking | Banking | 3 | master_artisans, trade_fairs | Lower interest; larger negative spending; military funding |
| trade_fairs | Trade Fairs | 2 | merchant_companies, sugar_refining | Bid on 6 commodities (vs 3) |
| university | University | 3 | money_lending, apprentice_workers, printing_press | Fourth research slot; leads to many advances |

---

## Notes

- Cigar Production and Hat Production are listed under New World (discovery/luxury); Trained Journeymen and Master Artisans depend on them.
- Labour effects drive production/consumption and worker pool tiers; see economy specs.

---

## Acceptance Criteria

- Given the Labour and Economy tech table in this doc and the global tech catalog built from all tech-tree docs  
  When the System validates the catalog at startup  
  Then the System ensures that each id in this table is unique, that its prerequisites refer to techs present in the global catalog, and that the effects (worker tiers, trade slots, research slots, banking) are consistent with the economy specs that consume them.

- Given a player has `apprentice_workers`, `trained_journeymen`, or `master_artisans` in `techUnlocked` as defined in this table  
  When the System computes available labour for Production and food and luxury consumption for the Consumption phase per [workers-and-population.md](workers-and-population.md)  
  Then the System uses the labour-per-turn and consumption patterns in the worker tiers table and allows the presence of these techs to unlock the corresponding worker tiers and luxury dependencies.

- Given a player has unlocked `university` via this table  
  When the System sets up or updates the player’s research model per [tech-tree.md](tech-tree.md) and [research-state.md](research-state.md)  
  Then the System increases the player’s number of active research slots from three to four and allows that extra slot to hold a separate tech with its own funding preset and progress.
