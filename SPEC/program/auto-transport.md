# Auto-Transport

**SPEC/program** — Transport algorithm for extracted goods to stockpile. Reference: [economy-models.md](economy-models.md), [SPEC/game/stockpiles-and-production.md](../game/stockpiles-and-production.md), [extraction-pipeline.md](extraction-pipeline.md).

---

## Owner

**colonizethis_logic** owns the transport algorithm. No game logic in app or other packages. Pre-aggregation: a **resource extractor** (see extraction-pipeline) computes per-player extractable amounts using a **connectivity resolver**; transport does not iterate raw tiles and does not change terrain or connectivity (it only moves already-extracted quantities).

---

## Input

**Per-player extracted quantities by commodity** — produced by the resource extractor (land = same-region totals, overseas = different-region totals). Player's current stockpile. No raw tile iteration inside transport.

---

## Caller-supplied extraction override (`extractedByPlayerId`)

When turn resolution (or economy preview) is invoked with a **non-empty** `Map<String, Map<CommodityId, int>> extractedByPlayerId`, the implementation applies those per-player commodity totals **directly** to each player’s central stockpile via `applyExtractionForPlayers` and **does not** run the normal extraction auto-transport pipeline for that turn. In particular, this path **intentionally bypasses**:

- Connectivity resolution  
- Per-tile resource extraction (`computeExtraction`)  
- Land vs overseas split  
- Cargo-hold allocation (`allocateOverseasToStockpile`)  
- Trade/transport interception (`applyTradeInterception`)

Callers using this override must therefore supply **already-final** delivered amounts (as if land and overseas processing were already complete). It is intended for tests, sim_economy, and similar controlled inputs—not for normal play when tile maps drive extraction.

---

**Sea cargo priority is not configurable:** Overseas allocation under cargo-hold limits uses a **single fixed** category order (see table below). The system does **not** read transport-priority preferences from player orders, AI, or rulesets, and implementations must **not** expose a per-player, per-faction, or per-ruleset override for this ordering. (GitHub #1290 — design decision: no order-driven priority.)

---

## Land Transport

All **same-region** extracted goods are added to the player's stockpile. Extraction phase already applied connectivity and transport level; no separate allocation step. No per-province commodity storage; all flows to central stockpile.

---

## Sea Transport (Overseas Only)

**Cargo-hold limit (per Imp2):** Each cargo hold carries **1 unit of any commodity per turn**. Total cargo holds for a turn are defined as the sum of cargo-hold values for all ships that are members of the **home fleet** (in port at the capital province; see [ships-and-naval.md](../game/ships-and-naval.md) § Home Fleet and [naval-movement-resolution.md](naval-movement-resolution.md)). For a ship type `t` with cargoHold `H(t)` and home-fleet count `count_home(t)`, total cargo holds for a player are:

\\[
\text{cargoHolds} = \sum_t H(t) \times \text{count\\_home}(t)
\\]

If a player has **no** ships in the home fleet (or cargoHold data is unavailable for all such ships), implementations MAY fall back to a fixed stub value per player (e.g. 24) for backwards compatibility, but this must be treated as a ruleset/config option.

Sea transport applies this cargo-hold limit in two steps each turn:

1. **Overseas extraction (cross-region transport, e.g. New World → Old World):**  
   Allocate overseas extraction totals to stockpile by **priority** (food, raw materials, riches, trade goods) until cargoHolds are exhausted; any remaining overseas extraction beyond cargoHolds is **not delivered** this turn (it stays in the source region and does not enter the central stockpile).
2. **Trade / exports (open market shipments):**  
   If any cargoHolds remain after step (1), allocate that remaining capacity to trade/export shipments for that player, using the **same fixed** per-category priority ordering as step (1). Once capacity is exhausted, additional trade/export orders are not shipped this turn.

**Central stockpile storage** is unbounded by design ([commodity-catalog](../game/commodity-catalog.md), [stockpiles-and-production](../game/stockpiles-and-production.md)): it abstracts a nation’s strategic pool, not warehouse capacity. Auto-transport does not clamp additions against a storage maximum. Sea transport must only add to or remove from the **central stockpile**, never from per-province commodity storage.

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

---

## Acceptance Criteria

- **Land transport:** Given per-player same-region extraction totals from the extraction pipeline and a current stockpile  
  When auto-transport runs for that player  
  Then all same-region extracted quantities are added to the player’s central stockpile, without creating any per-province commodity storage and without iterating raw tiles.

- **Sea transport and cargo cap:** Given per-player overseas extraction totals, a derived cargo-hold capacity from the player’s home fleet (in port at the capital; or a configured stub value when allowed by ruleset), and a current stockpile  
  When auto-transport runs  
  Then it allocates overseas quantities to the central stockpile by the **fixed** category priority order (food, raw materials, riches, manufactured/advanced per `CommodityCategory`), does not exceed the effective cargo-hold capacity, and leaves any undelivered overseas quantities outside the central stockpile for that turn.

- **Fixed sea priority (not configurable):** Given per-player overseas extraction totals and any player orders, AI plans, or ruleset configuration that might otherwise imply a custom shipment order  
  When auto-transport allocates overseas delivery under cargo-hold limits (and when remaining capacity is used for trade/export in the same turn)  
  Then the system uses **only** that fixed `CommodityCategory` order; the system does not apply order-driven or ruleset-driven overrides to sea cargo fill priority.

- **Unbounded central stockpile:** Given per-player land and overseas extraction totals and a current central stockpile with no storage maximum defined in game rules  
  When auto-transport applies land totals then overseas totals already limited only by cargo-hold throughput  
  Then it adds the full land extraction to the central stockpile and adds the full overseas-delivered amounts (post cargo-hold allocation and any upstream interception) with no additional clamping against a warehouse or per-commodity storage cap.

- **Trade interception:** Given overseas extraction and trade/export shipments for a player and that naval trade/transport interception has reduced delivered cargo per [naval-movement-resolution.md](naval-movement-resolution.md) § Trade/Transport Interception  
  When auto-transport applies sea transport for that turn  
  Then it uses the already-reduced delivered amounts as input and does not attempt to re-run interception; any further cargo reductions are applied upstream and only the post-interception totals are added to stockpile.

- **World-model identity:** Given extraction inputs where land and overseas totals were computed from tile keys and province ownership per [world-model-identity.md](../game/world-model-identity.md)  
  When auto-transport runs  
  Then it treats those totals as per-player aggregates and does not reinterpret or modify province or tile identity, relying on upstream systems for province lookup and identity correctness.

