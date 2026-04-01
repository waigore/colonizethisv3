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

By **permanent game design**, each player’s **central stockpile** is **unbounded**: there is no per-commodity maximum, no total stockpile maximum, and no ruleset-defined storage ceiling. The System does **not** discard goods, auto-sell to market, or apply any other **storage** overflow behavior because storage cannot be exceeded. The stockpile represents a **national strategic resource pool**, not simulated warehouse logistics ([stockpiles-and-production.md](stockpiles-and-production.md) § Strategic abstraction). Per-turn **cargo holds** still limit how much **overseas** extraction reaches the stockpile; that is transport throughput, not warehouse capacity — see [auto-transport.md](../program/auto-transport.md).

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

- Given the game rules define no maximum quantity for any commodity in the player’s **central** stockpile (unbounded storage by design)  
  When any game logic (such as extraction delivery, production, trade, consumption, or riches-to-treasury) changes that player’s central stockpile quantities during a turn  
  Then the System does not apply any storage cap, discard excess for storage reasons, or auto-sell to market due to a full warehouse, and all quantities remain non-negative integers within the engine’s integer range
