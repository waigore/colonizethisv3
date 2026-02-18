# Tech Tree — Naval (Merchant and Warships)

**SPEC/game** — Ship type unlocks. Reference: Imperialism II 08-technology (Naval). Overview: [tech-tree.md](tech-tree.md), [tech-tree-catalog.md](tech-tree-catalog.md). Navy (ships, naval movement, ship reveal) in Phase 5 per [ships-and-naval.md](ships-and-naval.md); full naval combat may be minimal stub.

---

## Merchant Ships

| id | name | era | prerequisites | effects |
|----|------|-----|---------------|--------|
| superior_hull_design | Superior Hull Design | 1 | — | Construct Fluytes |
| improved_sail_design | Improved Sail Design | 2 | wind_saw_mill, superior_hull_design | Construct Trader |
| convoying | Convoying | 2 | merchant_companies | Construct Galleons |
| navigation | Navigation | 1 | superior_hull_design | Construct Sloops |
| large_hulls | Large Hulls | 2 | wind_saw_mill, navigation, convoying | Construct Indiaman |
| clipper_ships | Clipper Ships | 4 | circular_saw, advanced_hull_design | Construct Clipper |
| paddlewheels | Paddlewheels | 3 | advanced_hull_design, early_steam_engine | Construct Raider |
| merchant_steamships | Merchant Steamships | 4 | paddlewheels, riverboats | Construct Merchant Steamship |

---

## Warships

| id | name | era | prerequisites | effects |
|----|------|-----|---------------|--------|
| advanced_hull_design | Advanced Hull Design | 3 | university, improved_sail_design, privateering_companies | Construct Frigates (high intercept rating, moderate flee rating) |
| ship_of_the_line | Ship of the Line | 3 | large_hulls, large_copper_and_tin_mines | Construct Ships-of-the-Line |
| privateering_companies | Privateering Companies | 2 | navigation, diplomatic_expertise | Improves naval interception (Patrol/Blockade) and trade-raid chance; unlocks privateering doctrines required for advanced warships |
| advanced_iron_working | Advanced Iron Working | 4 | ship_of_the_line, industrial_funding_of_research, paddlewheels | Construct Ironclads |

---

## Notes

- Large Copper and Tin Mines (gathering) is also required for Ships-of-the-Line; same tech id in catalog.
- Naval unit types and ship build enter scope in Phase 5; full naval combat, interception, and trade-raid formulas are shared between tech tree and program specs and may be tuned via ruleset config.
- Ship categories:
  - **Fast interceptors:** Sloops, Frigates, Raiders — higher base intercept and flee ratings; best on Patrol/Blockade.
  - **Battle ships:** Galleons, Ships-of-the-Line, Ironclads — high FRP/ARM/HULL; stronger in decisive fleet battles but weaker at chasing fast raiders.
