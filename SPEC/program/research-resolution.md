# Research Resolution

## Responsibility
Execute the research phase of turn resolution: validate orders, deduct spending, accumulate progress, complete techs. Game rules: [tech-tree.md](../game/tech-tree.md).

## Data Model

### Inputs
- Current game state: per-player treasury, `techUnlocked` set, research progress per slot.
- Per-player research orders: slot index → tech id (or empty), funding level per slot. Only Great Powers submit research orders.
- AI research orders from active AI backend (Phase 4 minimal or Phase 6 full).

### Research Orders Structure
Per player, per turn: slot assignments (slot index → tech id) and funding level per slot (per [tech-tree.md](../game/tech-tree.md) presets). Merged with other order types per [order-engine.md](order-engine.md).

## Algorithm / Flow

1. **For each GP:** Read research orders (slot assignments, funding per slot).
2. **Validate:** Check prerequisites, slot limits, treasury, and catalog membership per game rules. Reject or reduce invalid slots.
3. **Deduct** research spending from treasury.
4. **Add progress:** Map funding level to research points (per GDD presets); add to slot's tech progress.
5. **Complete:** Where progress ≥ tech cost: mark tech as unlocked, clear slot progress, update derived state (extraction cap, military level).
6. **Persist** updated `techUnlocked`, research progress, and treasury.

## Integration

- **Phase:** Runs after Production and Consumption in turn resolution. See [turn-resolution-phases.md](turn-resolution-phases.md).
- **Upstream:** Research orders from human UI or AI backend; treasury from economy phases.
- **Downstream:** Updated `techUnlocked` drives extraction caps, unit availability, diplomatic options.
- **Order merge:** Human and AI research orders merged per [order-engine.md](order-engine.md) precedence.

## Constraints
- Clearing a slot loses all progress for that tech (no partial save).
- A tech cannot be started in the same turn its prerequisite completes.
- Total research commitment per turn ≤ player treasury.
