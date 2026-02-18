# Tech Tree — New World Resources

**SPEC/game** — Discovery and improvement techs for New World resources. Reference: Imperialism II 08-technology (New World Resources). Overview: [tech-tree.md](tech-tree.md), [tech-tree-catalog.md](tech-tree-catalog.md). Discovery often requires Explorer finding the resource first (event/province); catalog lists tech prerequisites only.

---

## Sugar, Tobacco, Cotton, Furs, Spices, Precious Metals/Gems

| id | name | era | prerequisites | effects |
|----|------|-----|---------------|--------|
| discovery_of_sugar | Discovery of Sugar | 1 | (Explorer finds sugar) | Sugar plantations; sugar refining |
| sugar_planting | Sugar Planting | 1 | discovery_of_sugar | Sugar 2 |
| sugar_refining | Sugar Refining | 1 | discovery_of_sugar | Refined sugar (apprentice luxury) |
| large_sugar_plantations | Large Sugar Plantations | 2 | sugar_planting | Sugar 3 |
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

## Notes

- Discovery techs may be gated by game events (Explorer finds resource in a province); implementation may treat them as no-prereq until discovery condition is met.
- Labour techs (Trained Journeymen, Master Artisans) depend on cigar_production and hat_production from this category.
