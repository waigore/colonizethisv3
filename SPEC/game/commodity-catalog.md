# Commodity Catalog

**SPEC/game** — Commodity ids, categories, and storage. Derived from GDD 04, TDD 04. Production: [production-recipes.md](production-recipes.md). Stockpiles: [stockpiles-and-production.md](stockpiles-and-production.md).

---

## Categories

Commodities are grouped by **category**: food, rawMaterial, manufactured, luxury, riches, advanced. Categories determine which priority **bucket** each commodity belongs to for overseas sea transport (fill order is **fixed** in [auto-transport.md](../program/auto-transport.md); not player-, AI-, or ruleset-configurable). Categories also drive UI grouping and (later) trade. Per GDD 04.

For the **current product ruleset**, all trained-worker luxury consumption is modelled via **manufactured** commodities (refinedSugar, cigars, furHats) rather than a separate `luxury` category. The `luxury` category is reserved as a future extension hook: no commodity currently uses `luxury` as its primary category, and any code that needs to reason about worker luxuries MUST do so via the manufactured entries and [workers-and-population.md](workers-and-population.md) rather than by checking for a `luxury` category.

---

## Commodity List

| Category | Commodities |
|----------|-------------|
| **Food** | grain, meat |
| **Raw materials** | timber, iron, wool, cotton, coal, copper, tin, sugarCane, tobacco, furs, horses |
| **Manufactured** | lumber, castIron, fabric, refinedSugar, cigars, furHats, steel, paper, bronze |
| **Luxury** | _None in current product (reserved tag); luxuries are represented by manufactured refinedSugar, cigars, furHats consumed per [workers-and-population.md](workers-and-population.md)._ |
| **Riches** | gold, silver, gems, diamonds |
| **Advanced** | spices |

Ids are stable strings or enum values (e.g. `grain`, `castIron`). Implementation uses a single canonical list so logic and UI share the same set.

---

## Riches and treasury

Riches (gold, silver, gems, diamonds, spices) convert to treasury each turn in a dedicated phase after extraction. Per-unit base price: spices fixed at 50 (Imperialism II); other riches have base price inversely related to scarcity (spawn weight). Spawn weights and base prices are defined in ruleset config; riches-to-treasury phase applies them.

---

## Manufactured base prices

Each manufactured commodity has a **catalog-published base market price** in integer treasury units, derived from the **sum of input prices** of its primary canonical recipe in [production-recipes.md](production-recipes.md). The base price equals exactly that input-cost subtotal — no markup is added at the catalog level — so it represents the **break-even** treasury cost of producing one output unit from raw inputs at their default market prices.

When a recipe accepts an interchangeable raw input (the two `fabric` recipes accept either `wool` or `cotton`), the manufactured base price uses the **cheaper** of the two input prices so the catalog floor matches the most efficient legitimate production path.

| Manufactured commodity | Canonical recipe (per [production-recipes.md](production-recipes.md)) | Input-cost subtotal | Base price |
|---|---|---|---|
| `lumber` | `timber × 2` (`30 × 2 = 60`) | `60` | `60` |
| `fabric` | `wool × 2` (`40 × 2 = 80`; cotton variant is `90`, cheaper input is used) | `80` | `80` |
| `castIron` | `timber × 2 + iron × 2` (`60 + 160`) | `220` | `220` |
| `refinedSugar` | `sugarCane × 2` (`35 × 2 = 70`) | `70` | `70` |
| `cigars` | `tobacco × 3` (`40 × 3 = 120`) | `120` | `120` |
| `furHats` | `furs × 2` (`55 × 2 = 110`) | `110` | `110` |
| `steel` | `castIron × 2 + coal × 1` (`220 × 2 + 90`) | `530` | `530` |
| `paper` | `timber × 3` (`30 × 3 = 90`) | `90` | `90` |
| `bronze` | `copper × 1 + tin × 1` (`70 + 75`) | `145` | `145` |

These prices are consumed via `ResourceRules.defaultMarketPriceForCommodityId(commodityId)` so the Trade UI, `effectiveMarketPriceForCommodityId`, the bid-validator, and the AI treasury planner all read a non-null fallback for every manufactured commodity before in-game price discovery first runs. World-market price-discovery floors continue to anchor at the **raw-resource** `defaultMarketPrice` map only — manufactured prices act as the initial market reading and are not used to recompute the per-commodity price floor.

The chain of derivations is `raw-resource defaultMarketPrice` (per-Resource catalog in code) → `manufactured base price` (this table) → live `WorldMarketState.prices[c]` (in-game price discovery). Each step is integer-only and defers to the published catalog value when the live state lacks an entry.

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

- Given the active ruleset uses the standard economy profile and `ResourceRules.defaultRules` is loaded  
  When the System queries `defaultMarketPriceForCommodityId(commodityId)` for any manufactured commodity id in `{ 'lumber', 'fabric', 'castIron', 'refinedSugar', 'cigars', 'furHats', 'steel', 'paper', 'bronze' }`  
  Then the System returns the matching integer base price from the table under § Manufactured base prices (`lumber=60`, `fabric=80`, `castIron=220`, `refinedSugar=70`, `cigars=120`, `furHats=110`, `steel=530`, `paper=90`, `bronze=145`), and these prices remain constant between turns until in-game price discovery first updates them on `WorldMarketState.prices`

- Given the same ruleset and the System queries `defaultMarketPriceForCommodityId(commodityId)` for any id that is neither a raw-resource id (i.e. an entry on the `Resource` enum) nor a manufactured-commodity id enumerated under § Manufactured base prices (for example `'gold'`, `'spices'`, or `'not_a_commodity'`)  
  When the call evaluates the catalog  
  Then the System returns `null` (no catalog-published default price) and does not raise — riches and `spices` are intentionally excluded from the trade-side catalog default because they convert to treasury in a dedicated phase rather than clearing on the world market
