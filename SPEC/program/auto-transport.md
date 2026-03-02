# Auto-Transport

**SPEC/program** — Transport algorithm for extracted goods to stockpile. Reference: [economy-models.md](economy-models.md), [SPEC/game/stockpiles-and-production.md](../game/stockpiles-and-production.md), [extraction-pipeline.md](extraction-pipeline.md).

---

## Owner

**colonizethis_logic** owns the transport algorithm. No game logic in app or other packages. Pre-aggregation: a **resource extractor** (see extraction-pipeline) computes per-player extractable amounts using a **connectivity resolver**; transport does not iterate raw tiles and does not change terrain or connectivity (it only moves already-extracted quantities).

---

## Input

**Per-player extracted quantities by commodity** — produced by the resource extractor (land = same-region totals, overseas = different-region totals). Player's current stockpile; optionally transport priorities from orders. No raw tile iteration inside transport.

---

## Land Transport

All **same-region** extracted goods are added to the player's stockpile. Extraction phase already applied connectivity and transport level; no separate allocation step. No per-province commodity storage; all flows to central stockpile.

---

## Sea Transport (Overseas Only)

**Cargo-hold limit (per Imp2):** Each cargo hold carries **1 unit of any commodity per turn**. Total cargo holds for a turn are defined as the sum of cargo-hold values for all ships that are members of the **home fleet** at the capital port (see [ships-and-naval.md](../game/ships-and-naval.md) § Home Fleet and [naval-movement-resolution.md](naval-movement-resolution.md)). For a ship type `t` with cargoHold `H(t)` and home-fleet count `count_home(t)`, total cargo holds for a player are:

\\[
\text{cargoHolds} = \sum_t H(t) \times \text{count\\_home}(t)
\\]

If a player has **no** ships in the home fleet (or cargoHold data is unavailable for all such ships), implementations MAY fall back to a fixed stub value per player (e.g. 24) for backwards compatibility, but this must be treated as a ruleset/config option.

Sea transport applies this cargo-hold limit in two steps each turn:

1. **Overseas extraction (cross-region transport, e.g. New World → Old World):**  
   Allocate overseas extraction totals to stockpile by **priority** (food, raw materials, riches, trade goods) until cargoHolds are exhausted; any remaining overseas extraction beyond cargoHolds is **not delivered** this turn (it stays in the source region and does not enter the central stockpile).
2. **Trade / exports (open market shipments):**  
   If any cargoHolds remain after step (1), allocate that remaining capacity to trade/export shipments for that player, using the same per-category priority ordering (or an explicit trade-priority rule when defined). Once capacity is exhausted, additional trade/export orders are not shipped this turn.

Validation: do not exceed stockpile capacity (per [commodity-catalog](../game/commodity-catalog.md)); sea transport must only add to or remove from the **central stockpile**, never from per-province storage.

**Priority ordering within categories in case of limited cargo capacity**

| Priority | Commodity Category | Examples           | Rationale               |
| -------- | ------------------ | ------------------ | ----------------------- |
| 1        | Critical Food      | Grain, Meat        | Prevent starvation      |
| 2        | Raw Materials      | Iron, Coal, Lumber | Keep production running |
| 3        | Food Variety       | Fish, Dairy        | Morale/health bonuses   |
| 4        | Riches             | Gold, Silver, Gems | Trade income            |
| 5        | Trade Goods        | Textiles, Spices   | Discretionary income    |

**Note:** Implementation uses `CommodityCategory` order (food, rawMaterial, riches, manufactured, advanced). The luxury category is excluded from priority until luxury is properly defined in the commodity catalog (see [commodity-catalog](../game/commodity-catalog.md) and issue #344). Grain and meat are the only food commodities in the catalog; Critical Food vs Food Variety sub-ordering applies when fish/dairy are added. Cargo-hold limit is derived from home-fleet composition as described above; a fixed per-player stub may be used only as a temporary fallback when no valid cargoHold data is available.

---

## Output

Player stockpile updated with land totals (all) and overseas totals (up to cargo cap by priority).
