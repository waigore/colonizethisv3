# Tech Tree — Naval (Merchant and Warships)

**SPEC/game** — Ship type unlocks. Reference: Imperialism II 08-technology (Naval). Overview: [tech-tree.md](tech-tree.md). Navy (ships, naval movement, ship reveal) in Phase 5 per [ships-and-naval.md](ships-and-naval.md); full naval combat may be minimal stub.

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

---

## Acceptance Criteria

- Given the naval tech table in this doc and the global tech catalog  
  When the System validates the catalog at startup  
  Then the System ensures that each naval tech id is unique, that its prerequisites refer to techs present in the catalog, and that each ship type unlocked by these techs has a corresponding ship definition in the naval unit specs referenced by [ships-and-naval.md](ships-and-naval.md).

- Given a player has unlocked a naval tech such as `superior_hull_design`, `improved_sail_design`, `convoying`, `large_hulls`, `clipper_ships`, `paddlewheels`, `merchant_steamships`, `advanced_hull_design`, `ship_of_the_line`, `privateering_companies`, or `advanced_iron_working`  
  When the System evaluates which ship types are buildable for that player during a build phase per [ships-and-naval.md](ships-and-naval.md)  
  Then the System allows the player to build exactly the ship types listed in this table as effects of the unlocked techs (plus any baseline ships that require no tech) and forbids building ship types whose unlocking tech is not yet in the player’s `techUnlocked` set.

- Given a player has unlocked `privateering_companies`  
  When the System computes naval interception and trade-raid chances for that player’s fleets on Patrol or Blockade missions as described in the naval combat specs  
  Then the System applies the privateering bonuses defined in the naval rules only when this tech is present in the player’s `techUnlocked` set and does not apply those bonuses when the tech is locked.
