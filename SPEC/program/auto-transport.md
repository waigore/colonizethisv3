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

**Cargo-hold limit (per Imp2):** Each cargo hold carries **1 unit of any commodity per turn**. Total cargo holds = sum over the player's ships. Phase 2: **stub** = fixed number per player (e.g. 24). Allocate overseas extraction to stockpile by **priority** (food, raw materials, riches, trade goods) until cargo full; rest is left behind (not delivered this turn). Validation: do not exceed stockpile capacity (per [commodity-catalog](../game/commodity-catalog.md)).

**Priority ordering within categories in case of limited cargo capacity**

| Priority | Commodity Category | Examples           | Rationale               |
| -------- | ------------------ | ------------------ | ----------------------- |
| 1        | Critical Food      | Grain, Meat        | Prevent starvation      |
| 2        | Raw Materials      | Iron, Coal, Lumber | Keep production running |
| 3        | Food Variety       | Fish, Dairy        | Morale/health bonuses   |
| 4        | Riches             | Gold, Silver, Gems | Trade income            |
| 5        | Trade Goods        | Textiles, Spices   | Discretionary income    |
| 6        | Luxury             | Wine, Tobacco      | Nice to have            |

**MVP:** Implementation uses `CommodityCategory` order (food, rawMaterial, riches, manufactured, luxury, advanced). Grain and meat are the only food commodities in the catalog; Critical Food vs Food Variety sub-ordering applies when fish/dairy are added. Cargo-hold limit uses a fixed stub per player; sum-of-ships can be wired when fleet cargo capacity is available.

---

## Output

Player stockpile updated with land totals (all) and overseas totals (up to cargo cap by priority).
