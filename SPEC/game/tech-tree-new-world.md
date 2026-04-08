# Tech Tree — New World Resources

**SPEC/game** — Discovery and improvement techs for New World resources. Reference: Imperialism II 08-technology (New World Resources). Overview: [tech-tree.md](tech-tree.md). Discovery often requires Explorer finding the resource first (event/province); catalog lists tech prerequisites only.

---

## Sugar, Tobacco, Cotton, Furs, Spices, Precious Metals/Gems

| id | name | era | prerequisites | effects |
|----|------|-----|---------------|--------|
| discovery_of_sugar | Discovery of Sugar | 1 | (Explorer finds sugar) | Enables: researchable only when the player has revealed sugar cane per the discovery rule in this doc. Unlocks: `sugar_planting` and `sugar_refining`. |
| sugar_planting | Sugar Planting | 1 | discovery_of_sugar | Improves: sugar cane extraction cap to **2**. Unlocks: prerequisite for `large_sugar_plantations`. |
| sugar_refining | Sugar Refining | 1 | discovery_of_sugar | Enables: refined sugar luxury production consumed by Apprentice-tier workers per [workers-and-population.md](workers-and-population.md). Unlocks: prerequisite for `apprentice_workers` (with Land Enclosure) and `trade_fairs` (with Merchant Companies). |
| large_sugar_plantations | Large Sugar Plantations | 2 | sugar_planting | Improves: sugar cane extraction cap to **3**. Unlocks: prerequisite for `sugar_industry`. |
| sugar_industry | Sugar Industry | 3 | large_sugar_plantations | Sugar 4 |
| discovery_of_tobacco | Discovery of Tobacco | 1 | (Explorer finds tobacco) | Tobacco plantations |
| tobacco_planting | Tobacco Planting | 1 | discovery_of_tobacco | Tobacco 2 |
| cigar_production | Cigar Production | 1 | discovery_of_tobacco | Cigars (journeyman luxury) |
| large_tobacco_plantations | Large Tobacco Plantations | 2 | tobacco_planting, seed_drill | Tobacco 3 |
| tobacco_industry | Tobacco Industry | 3 | early_steam_engine, large_tobacco_plantations | Tobacco 4 |
| discovery_of_cotton | Discovery of Cotton | 1 | (Explorer finds cotton) | Cotton plantations |
| cotton_planting | Cotton Planting | 1 | discovery_of_cotton | Cotton 2 |
| cotton_weaving | Cotton Weaving | 1 | discovery_of_cotton | Fabric from cotton |
| large_cotton_plantations | Large Cotton Plantations | 2 | cotton_planting | Cotton 3 |
| cotton_gin | Cotton Gin | 3 | large_cotton_plantations, trained_journeymen | Cotton 4 |
| discovery_of_furs | Discovery of Furs | 1 | (Explorer finds furs) | Fur trapping |
| improved_trapping_techniques | Improved Trapping Techniques | 1 | discovery_of_furs | Furs 2 |
| hat_production | Hat Production | 1 | discovery_of_furs | Fur hats (master artisan luxury) |
| riverboats | Riverboats | 3 | improved_trapping_techniques, early_steam_engine | Furs 3 (trapper camps) |
| excessive_fur_harvesting | Excessive Fur Harvesting | 4 | later_steam_engine, riverboats | Furs 4 |
| discovery_of_spices | Discovery of Spices | 1 | (Explorer finds spices) | Spice orchards |
| improved_sea_routes | Improved Sea Routes | 1 | discovery_of_spices | Spices from upgraded farms |
| large_spice_plantations | Large Spice Plantations | 2 | seed_drill, improved_sea_routes | Spices 3 |
| improved_food_preservation | Improved Food Preservation | 3 | large_spice_plantations | Spices 4 |
| discovery_of_gold_or_silver | Discovery of Gold or Silver | 1 | (Explorer finds gold/silver) | Precious metal mines |
| precious_metals_mining | Precious Metals Mining | 1 | discovery_of_gold_or_silver, mine_engineering | Gold/silver 2 |
| discovery_of_gems_or_diamonds | Discovery of Gems or Diamonds | 1 | (Explorer finds gems/diamonds) | Precious stone mines |
| precious_stone_mining | Precious Stone Mining | 1 | discovery_of_gems_or_diamonds | Gems/diamonds 2 |

---

## Discovery prerequisite (Explorer finds X)

A tech whose prerequisite is "(Explorer finds X)" is researchable **only if** the player has **revealed at least one tile that contains resource X**. "Revealed" means the tile is visible to that player (visibility fully visible or fogged) so the tile's resource is known; for **prospect-required** resources (gold, silver, gems, diamonds per [fog-and-exploration.md](fog-and-exploration.md)), the tile must also have been **prospected** by that player. Resource ids match [resource-terrain-region-rules.md](resource-terrain-region-rules.md). The catalog must set `discoveryResourceIds` for each discovery tech as follows: `discovery_of_sugar` → `['sugarCane']`; `discovery_of_tobacco` → `['tobacco']`; `discovery_of_cotton` → `['cotton']`; `discovery_of_furs` → `['furs']`; `discovery_of_spices` → `['spices']`; `discovery_of_gold_or_silver` → `['gold', 'silver']`; `discovery_of_gems_or_diamonds` → `['gems', 'diamonds']`. The tech is researchable when the player has revealed (and if prospect-required, prospected) at least one tile containing **at least one** of the listed resource ids.

## Notes

- Labour techs (Trained Journeymen, Master Artisans) depend on cigar_production and hat_production from this category.

---

## Acceptance Criteria

- Given the New World tech table in this doc and a global tech catalog that includes all categories  
  When the System validates the catalog at startup  
  Then the System ensures that each New World tech id is unique, that its prerequisites (including discovery techs and cross-category techs such as `seed_drill`, `trained_journeymen`, and `early_steam_engine`) are present in the catalog, and that the effects in this table (resource levels, luxury unlocks) are consistent with [resource-terrain-region-rules.md](resource-terrain-region-rules.md) and [workers-and-population.md](workers-and-population.md).

- Given a discovery tech with prerequisite "(Explorer finds X)" as listed in this table  
  When the System computes researchable techs for a player  
  Then the System includes that tech only if the player has at least one tile that (a) has visibility fully visible or fogged for that player, (b) contains a resource that satisfies X (per the discoveryResourceIds mapping above), and (c) if that resource is prospect-required, the tile has been prospected by that player.

- Given a player has unlocked a New World extraction tech such as `sugar_planting`, `large_tobacco_plantations`, `cotton_gin`, `riverboats`, or `excessive_fur_harvesting`  
  When the System computes extraction caps and effective yields for the corresponding resources in New World provinces per [tech-and-extraction-cap.md](tech-and-extraction-cap.md) and [extraction-and-improvements.md](extraction-and-improvements.md)  
  Then the System increases the maximum effective improvement level for those resources in line with the numeric effects described in this table (for example, `Sugar 3` for `large_sugar_plantations`) and applies those caps only after the required discovery tech and extraction tech are both unlocked.

- Given a player has unlocked `sugar_refining`, `cigar_production`, or `hat_production` as listed in this table  
  When the System computes which luxuries can be consumed by Apprentices, Journeymen, and Masters during the Consumption phase per [workers-and-population.md](workers-and-population.md)  
  Then the System allows the corresponding luxury commodities (refined sugar, cigars, fur hats) to be produced via recipes and consumed by the appropriate worker tiers, and does not allow those luxuries to be consumed before the relevant tech has been unlocked.

- Given the `discovery_of_sugar`, `sugar_planting`, `sugar_refining`, and `large_sugar_plantations` rows in this tech table  
  When the System or UI layer renders their design descriptions from SPEC-authorized wording  
  Then each row includes at least one fixed-field phrase (`Unlocks:`, `Improves:`, `Enables:`, or `Prerequisite-only:`), names concrete mechanics (extraction caps, discovery gating, luxury consumption, or explicit unlock targets), and does not use generic fallback wording.
