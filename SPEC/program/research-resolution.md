# Research Resolution

## Responsibility
Execute the research phase of turn resolution: validate orders, deduct spending, accumulate progress, complete techs. Game rules: [tech-tree.md](../game/tech-tree.md). **Discovery (New World) techs** — ids, resources, and “Explorer finds X” semantics: [tech-tree-new-world.md](../game/tech-tree-new-world.md); revealed vs prospected tiles: [tech-tree.md](../game/tech-tree.md), [fog-and-exploration.md](../game/fog-and-exploration.md).

## Data Model

### Inputs
- Current game state: per-player treasury, `techUnlocked` set, research progress per slot.
- Per-player research orders: slot index → tech id (or empty), funding level per slot. Only Great Powers submit research orders.
- AI research orders from active AI backend (Phase 4 minimal or Phase 6 full).

### Research Orders Structure
Per player, per turn: slot assignments (slot index → tech id) and funding level per slot (per [tech-tree.md](../game/tech-tree.md) presets). Merged with other order types per [order-engine.md](order-engine.md). **One order per slot:** if the merged list contains more than one order for the same slot index, the resolver applies exactly one per slot (last in list wins); no double spend or dual progress for that slot.

### Discovery techs
Techs that require the player to have found a resource on the map carry **discovery resource ids** in the program catalog (`discoveryResourceIds` on the tech definition; see [tech-tree-new-world.md](../game/tech-tree-new-world.md)). For those techs, research is allowed only when the player has **revealed** at least one tile containing the required resource, and for **prospect-required** resources (per [tech-tree.md](../game/tech-tree.md)) when that tile has also been **prospected** by the player.

## Algorithm / Flow

1. **For each GP:** Read research orders (slot assignments, funding per slot).
2. **Validate:** Check prerequisites, slot limits, treasury, and catalog membership per game rules; for techs with non-empty `discoveryResourceIds`, check the discovery gate (revealed / prospected per GDD). Reject or reduce invalid slots.
3. **Deduct** research spending from treasury.
4. **Add progress:** Map funding level to research points (per GDD presets); add to slot's tech progress.
5. **Complete:** Where progress ≥ tech cost: mark tech as unlocked, clear slot progress, update derived state (extraction cap, military level).
6. **Persist** updated `techUnlocked`, research progress, and treasury.

## Integration

- **Phase:** Runs after Production and Consumption in turn resolution. See [turn-resolution-phases.md](turn-resolution-phases.md).
- **Upstream:** Research orders from human UI or AI backend; treasury from economy phases.
- **Downstream:** Updated `techUnlocked` drives extraction caps, unit availability, diplomatic options.
- **Order merge:** Human and AI research orders merged per [order-engine.md](order-engine.md) precedence.
- **Discovery enforcement:** The Research phase resolver (`packages/colonizethis_logic`, e.g. `research_resolver.dart`) applies the discovery gate when validating slot assignments. **Research eligibility** for UI, AI order suggestions, and similar callers uses `researchableTechIds` in `packages/colonizethis_data` with a `hasDiscoveredResource` callback backed by game visibility/prospection (e.g. `hasRevealedResourceForPlayer` in `packages/colonizethis_logic`).

## Slot occupancy persistence

Slot→tech occupancy is persisted as `Player.researchSlotAssignments` (slot index → `{techId, funding}`; see [research-state.md](../game/research-state.md) § Slot Occupancy Persistence). The per-turn `Orders.researchOrdersByPlayerId` remains the UI mutation surface; the resolver reconciles persisted occupancy with the turn's orders and persists the surviving occupancy back.

- **Effective occupancy:** For each player the resolver builds the effective per-slot occupancy from the persisted `researchSlotAssignments` (each entry validated: slot index in `0..researchSlots-1` and `techId` present in the catalog; invalid entries dropped) and then applies the turn's orders as overrides — a non-empty order assigns/updates the slot's tech and funding; an **empty-`techId`** order **cancels** (frees) the slot.
- **Process condition:** A player is processed when they have research orders this turn **or** have non-empty persisted `researchSlotAssignments`; a player with neither is passed through unchanged. The phase short-circuits (returns the game unchanged) only when there are no research orders **and** no player has persisted assignments.
- **Progress pruning:** `researchProgressByTechId` entries are retained while their tech still occupies a slot in the effective occupancy. Progress is pruned only on **completion** (progress ≥ cost → unlock) or when the tech **no longer occupies any slot** (slot cancelled or reassigned to a different tech).
- **Completion frees the slot:** When a tech completes, its slot assignment is removed and is not persisted.
- **Persistence:** After allocation/completion the surviving effective occupancy is written back to `Player.researchSlotAssignments` (empty map when no slot is occupied).

## Constraints
- Clearing a slot loses all progress for that tech (no partial save).
- A tech cannot be started in the same turn its prerequisite completes.
- **Treasury floor for research spending:** After each research spend, treasury must remain ≥ **−maxDebt** where `maxDebt` comes from labour techs (`maxDebtForPlayer` in `economy_debt_rules.dart`). **current product debt floors:** no qualifying tech → max debt **0** (treasury cannot go negative for research); `money_lending` unlocked (without `banking`) → max debt **500**; `banking` unlocked (with its prerequisite chain) → max debt **1000**. Treasury may go to the floor value inclusive during research spending only. Game rules: [tech-tree-labour-economy.md](../game/tech-tree-labour-economy.md) § Effect implementation status; program detail: [economy-models.md](economy-models.md) § Research treasury debt.

## Acceptance criteria

- **Phase order:** Research phase runs after Production and Consumption per [turn-resolution-phases.md](turn-resolution-phases.md); resolver reads merged orders from [order-engine.md](order-engine.md).
- **One order per slot:** At most one research order per slot index per player; if multiple exist, last in merged list wins; no double spend or dual progress for that slot.
- **Validation:** Prerequisites, slot limits, treasury **including the research debt floor** (−`maxDebt` .. +∞), and catalog membership are checked; invalid slots are rejected or skipped before spending.
- **Discovery techs:** Given a tech has non-empty `discoveryResourceIds` per [tech-tree-new-world.md](../game/tech-tree-new-world.md), when the System validates research for that tech in the Research phase, then the System applies progress only if the player meets the revealed (and if required, prospected) tile rules per [tech-tree.md](../game/tech-tree.md). Given such a tech, when the UI or suggestion layer lists researchable techs for a player, then the System includes that tech only under the same discovery conditions (via `researchableTechIds` and player visibility/prospection state).
- **Spend and progress:** Research spending is deducted from treasury; funding level maps to research points per GDD presets; progress is added to the slot's tech.
- **Completion:** When progress ≥ tech cost, tech is marked unlocked, slot progress cleared, and derived state (extraction cap, military level) updated.
- **Persistence:** Updated `techUnlocked`, research progress, and treasury are persisted; clearing a slot loses all progress for that tech (no partial save).

### Slot occupancy persistence

- **Given** a player assigns tech `T` to slot `i` at funding `F` (order: `slotIndex=i, techId=T, funding=F`) and the tech does not complete this turn, **when** the Research phase resolves, **then** `Player.researchSlotAssignments[i]` equals `{techId: T, funding: F}` and `Player.researchProgressByTechId[T]` is retained (> 0).
- **Given** a player has tech `T` occupying slot `i` with `0 < researchProgressByTechId[T] < T.cost`, **when** the Research phase resolves with no cancellation order for slot `i` (no order, or an order that re-asserts `T`), **then** `Player.researchProgressByTechId[T]` is **not** removed.
- **Given** a player has tech `T` occupying slot `i` and accrued progress reaches or exceeds `T.cost` during resolution, **when** the Research phase resolves, **then** `T` is unlocked (`techUnlocked[T] == true`), `Player.researchSlotAssignments[i]` is cleared, and `Player.researchProgressByTechId[T]` is removed.
- **Given** a player has tech `T` occupying slot `i` with accrued progress, **when** the Research phase resolves with an empty-`techId` order for slot `i` (cancellation), **then** `Player.researchSlotAssignments[i]` is cleared and `Player.researchProgressByTechId[T]` is removed (forfeited).
- **Given** a player has non-empty persisted `researchSlotAssignments` but submits no research order for a still-occupied slot this turn, **when** the Research phase resolves, **then** the slot remains occupied (assignment retained) and continues to accrue progress at its persisted funding.
