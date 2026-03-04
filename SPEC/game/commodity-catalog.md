# Commodity Catalog

**SPEC/game** — Commodity ids, categories, and storage. Derived from GDD 04, TDD 04. Production: [production-recipes.md](production-recipes.md). Stockpiles: [stockpiles-and-production.md](stockpiles-and-production.md).

---

## Categories

Commodities are grouped by **category**: food, rawMaterial, manufactured, luxury, riches, advanced. Categories drive transport priority, UI grouping, and (later) trade. Per GDD 04.

For the **MVP ruleset**, all trained-worker luxury consumption is modelled via **manufactured** commodities (refinedSugar, cigars, furHats) rather than a separate `luxury` category. The `luxury` category is reserved as a future extension hook: no commodity currently uses `luxury` as its primary category, and any code that needs to reason about worker luxuries MUST do so via the manufactured entries and [workers-and-population.md](workers-and-population.md) rather than by checking for a `luxury` category.

---

## Commodity List

| Category | Commodities |
|----------|-------------|
| **Food** | grain, meat |
| **Raw materials** | timber, iron, wool, cotton, coal, copper, tin, sugarCane, tobacco, furs, horses |
| **Manufactured** | lumber, castIron, fabric, refinedSugar, cigars, furHats, steel, paper, bronze |
| **Luxury** | _None in MVP (reserved tag); luxuries are represented by manufactured refinedSugar, cigars, furHats consumed per [workers-and-population.md](workers-and-population.md)._ |
| **Riches** | gold, silver, gems, diamonds |
| **Advanced** | spices |

Ids are stable strings or enum values (e.g. `grain`, `castIron`). Implementation uses a single canonical list so logic and UI share the same set.

---

## Riches and treasury

Riches (gold, silver, gems, diamonds, spices) convert to treasury each turn in a dedicated phase after extraction. Per-unit base price: spices fixed at 50 (Imperialism II); other riches have base price inversely related to scarcity (spawn weight). Spawn weights and base prices are defined in ruleset config; riches-to-treasury phase applies them.

---

## Where Stored

The **commodity catalog** (id list, category per commodity, default price for spawn-weight and market) is defined in ruleset config (program-level constants; no JSON rulesets).

---

## Overflow and Capacity

For the **MVP ruleset**, capacity for all commodities is effectively infinite: there is no per-commodity or total stockpile cap, and the System does **not** apply any overflow behavior such as discarding excess or auto-selling to market. Any future per-era capacity limits or overflow rules are **deferred**; if and when they are introduced, their authoritative behavior and acceptance criteria will be defined in [stockpiles-and-production.md](stockpiles-and-production.md), and this section will cross-reference that definition.

---

## Acceptance Criteria

- Given the active ruleset config defines a commodity list where each commodity id is a non-empty string and unique within that list  
  When the system loads the ruleset at game start or when starting a new scenario  
  Then the system builds an in-memory commodity catalog that contains exactly the same set of commodity ids, with each id mapped to exactly one category from the set `food`, `rawMaterial`, `manufactured`, `luxury`, `riches`, `advanced`, and rejects any ruleset that defines duplicate ids with error code `duplicate_commodity_id`

- Given the in-memory commodity catalog has been successfully loaded from the ruleset config  
  When the system queries the category for a known commodity id such as `grain`, `timber`, `castIron`, or `gold`  
  Then the system returns the category defined in the table under "Commodity List" for that id and returns an error with code `unknown_commodity_id` when the id is not present in the catalog

- Given a player owns a province that has a non-negative integer quantity of riches commodities (for example `gold` and `silver`) stored in its stockpile, and the active ruleset defines a non-negative base price in treasury units for each of those riches  
  When the system runs the riches-to-treasury phase for turn \(N\)  
  Then the system decreases the stored quantity of each riches commodity in that province to 0, increases the player treasury by the sum over all riches of `quantity * basePrice`, and records a turn log entry tagged `riches_to_treasury` that lists, for each riches commodity, its id, quantity consumed, base price, and treasury gained

- Given the active ruleset uses the standard economy profile for ColonizeThis  
  When the system runs the riches-to-treasury phase for any turn and converts stored `spices` from any province into treasury  
  Then the system uses a fixed base price of exactly 50 treasury units per unit of `spices` regardless of any other price modifiers, and includes this price in the `riches_to_treasury` turn log entry for that turn

- Given a game is running with a ruleset era that has not defined per-commodity or total stockpile capacity limits  
  When any game logic (such as production, trade, or riches conversion) increases a province’s stockpile for any commodity to a non-negative integer amount  
  Then the system does not discard or sell any overflow for that commodity in that era, and tests that attempt to store arbitrarily large quantities (within engine integer limits) complete without triggering overflow-related discard or market-sale behavior
