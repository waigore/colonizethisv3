# Commodity Catalog

**SPEC/game** — Commodity ids, categories, and storage. Derived from GDD 04, TDD 04. Production: [production-recipes.md](production-recipes.md). Stockpiles: [stockpiles-and-production.md](stockpiles-and-production.md).

---

## Categories

Commodities are grouped by **category**: food, rawMaterial, manufactured, luxury, riches, advanced. Categories drive transport priority, UI grouping, and (later) trade. Per GDD 04.

---

## Commodity List

| Category | Commodities |
|----------|-------------|
| **Food** | grain, meat |
| **Raw materials** | timber, iron, wool, cotton, coal, copper, tin, sugarCane, tobacco, furs, horses |
| **Manufactured** | lumber, castIron, fabric, refinedSugar, cigars, furHats, steel, paper, bronze |
| **Luxury** | (consumed by trained workers; e.g. refinedSugar, cigars, furHats) |
| **Riches** | gold, silver, gems, diamonds |
| **Advanced** | spices |

Ids are stable strings or enum values (e.g. `grain`, `castIron`). Implementation uses a single canonical list so logic and UI share the same set.

---

## Riches and treasury

Riches (gold, silver, gems, diamonds, spices) convert to treasury each turn in a dedicated phase after extraction. Per-unit base price: spices fixed at 50 (Imperialism II); other riches have base price inversely related to scarcity (spawn weight). Implementation: colonizethis_data defines spawn weights and base prices; colonizethis_logic applies them in the riches-to-treasury phase.

---

## Where Stored

The **commodity catalog** (id list, category per commodity, default price for spawn-weight and market) lives in **colonizethis_data** as program-level constants. No JSON rulesets in MVP; single source. colonizethis_logic and colonizethis_ai consume this via resolved config at game load.

---

## Overflow and Capacity

Capacity limits may apply per commodity or to total stockpile; configurable per era. **Overflow rules:** excess sold at market or discarded, per design. Details in [stockpiles-and-production.md](stockpiles-and-production.md). Implementation may stub capacity (e.g. unlimited) until design is fixed.
