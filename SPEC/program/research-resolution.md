# Research Resolution

## Responsibility
Execute the research phase of turn resolution: validate orders, deduct spending, accumulate progress, complete techs. Game rules: [tech-tree.md](../game/tech-tree.md).

## Data Model

### Inputs
- Current game state: per-player treasury, `techUnlocked` set, research progress per slot.
- Per-player research orders: slot index → tech id (or empty), funding level per slot. Only Great Powers submit research orders.
- AI research orders from active AI backend (Phase 4 minimal or Phase 6 full).

### Research Orders Structure
Per player, per turn: slot assignments (slot index → tech id) and funding level per slot (per [tech-tree.md](../game/tech-tree.md) presets). Merged with other order types per [order-engine.md](order-engine.md). **One order per slot:** if the merged list contains more than one order for the same slot index, the resolver applies exactly one per slot (last in list wins); no double spend or dual progress for that slot.

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

## Acceptance criteria

- **Phase order:** Research phase runs after Production and Consumption per [turn-resolution-phases.md](turn-resolution-phases.md); resolver reads merged orders from [order-engine.md](order-engine.md).
- **One order per slot:** At most one research order per slot index per player; if multiple exist, last in merged list wins; no double spend or dual progress for that slot.
- **Validation:** Prerequisites, slot limits, treasury, and catalog membership are checked; invalid slots are rejected or reduced before spending.
- **Spend and progress:** Research spending is deducted from treasury; funding level maps to research points per GDD presets; progress is added to the slot's tech.
- **Completion:** When progress ≥ tech cost, tech is marked unlocked, slot progress cleared, and derived state (extraction cap, military level) updated.
- **Persistence:** Updated `techUnlocked`, research progress, and treasury are persisted; clearing a slot loses all progress for that tech (no partial save).
