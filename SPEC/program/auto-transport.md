# Auto-Transport

**SPEC/program** — Transport algorithm for extracted goods to stockpile. Reference: [economy-models.md](economy-models.md), [SPEC/game/stockpiles-and-production.md](../game/stockpiles-and-production.md), [extraction-pipeline.md](extraction-pipeline.md).

---

## Owner

**colonizethis_logic** owns the transport algorithm. No game logic in app or other packages. Pre-aggregation: a **resource extractor** (see extraction-pipeline) computes per-player extractable amounts using a **connectivity resolver**; transport does not iterate raw tiles.

---

## Input

**Per-player extracted quantities by commodity** — produced by the resource extractor (land = same-region totals, overseas = different-region totals). Player's current stockpile; optionally transport priorities from orders. No raw tile iteration inside transport.

---

## Land Transport

All **same-region** extracted goods are added to the player's stockpile. Extraction phase already applied connectivity and transport level; no separate allocation step. No per-province commodity storage; all flows to central stockpile.

---

## Sea Transport (Overseas Only)

**Cargo-hold limit:** Total cargo holds = sum over the player's ships. Phase 2: **stub** = fixed number per player (e.g. 24). Allocate overseas extraction to stockpile by **priority** (food, raw materials, riches, trade goods) until cargo full; rest is left behind (not delivered this turn). Validation: do not exceed stockpile capacity (per [commodity-catalog](../game/commodity-catalog.md)).

---

## Output

Player stockpile updated with land totals (all) and overseas totals (up to cargo cap by priority).
