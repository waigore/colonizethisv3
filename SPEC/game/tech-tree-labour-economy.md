# Tech Tree — Labour and Economy

**SPEC/game** — Worker tiers, banking, trade, and University. Reference: Imperialism II 08-technology (Labour and Economy). Overview: [tech-tree.md](tech-tree.md), [tech-tree-catalog.md](tech-tree-catalog.md).

---

## Tech Table

| id | name | era | prerequisites | effects |
|----|------|-----|---------------|--------|
| printing_press | Printing Press | 1 | — | Leads to Journeymen, tactics, siege engineering |
| apprentice_workers | Apprentice Workers | 2 | land_enclosure, sugar_refining | 4× labour; consume refined sugar |
| trained_journeymen | Trained Journeymen | 2 | cigar_production, printing_press | 6× labour; consume cigars |
| master_artisans | Master Artisans | 3 | apprentice_workers, university, hat_production | 8× labour; consume fur hats |
| money_lending | Money Lending | 1 | land_enclosure | Borrow more; lower interest; leads to bureaucracy |
| banking | Banking | 3 | master_artisans, trade_fairs | Lower interest; larger negative spending; military funding |
| trade_fairs | Trade Fairs | 2 | merchant_companies, sugar_refining | Bid on 6 commodities (vs 3) |
| university | University | 3 | money_lending, apprentice_workers, printing_press | Fourth research slot; leads to many advances |

---

## Notes

- Cigar Production and Hat Production are listed under New World (discovery/luxury); Trained Journeymen and Master Artisans depend on them.
- Labour effects drive production/consumption and worker pool tiers; implementation in colonizethis_logic and economy specs.
