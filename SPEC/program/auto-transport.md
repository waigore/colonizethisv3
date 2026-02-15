# Auto-Transport

**SPEC/program** — Transport algorithm for extracted goods to stockpile. Reference: [economy-models.md](economy-models.md), [SPEC/game/stockpiles-and-production.md](../game/stockpiles-and-production.md).

---

## Owner

**colonizethis_logic** owns the transport algorithm. No game logic in app or other packages.

---

## Land Transport

**Land transport is automatic and unlimited.** No allocation step. Extraction resolution adds province tile yields directly to the owning player's stockpile (same turn). No per-province commodity storage; all flows to central stockpile.

---

## Sea Transport

**Sea transport** (goods from overseas provinces) is **stubbed** in current scope: all extracted goods are treated as reaching the player's stockpile. No cargo holds, no priority allocation. Later: allocate cargo by priority (food, raw materials, riches, trade goods) and capacity; algorithm in colonizethis_logic.

---

## Input and Output

- **Input:** Per-province (or per-region) extracted quantities by commodity; player's current stockpile; optionally transport priorities from orders.
- **Output:** Player stockpile updated with transported quantities. Land: extraction phase already adds to stockpile. Sea stub: same (all to stockpile).

Validation: do not exceed stockpile capacity if limits apply (per [commodity-catalog](../game/commodity-catalog.md)).
