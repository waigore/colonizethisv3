# Research State

**SPEC/game** — Technology research model. Full implementation in research resolution; sim game uses stubs. Reference: GDD 05 (Academy, tech tree). Cross-reference: [tech-tree.md](tech-tree.md), [research-resolution.md](../program/research-resolution.md).

---

## Model (Multi-Slot)

The research system uses a **multi-slot model** where multiple technologies can be researched in parallel (one per slot):

- **researchSlots:** Number of available research slots (default 3; 4 with University tech). Each slot can hold at most one active tech.
- **researchProgressByTechId:** Map of tech id → progress (RP accumulated). Non-empty keys represent techs currently being researched across all slots. There is no single "currentResearchTechId"; instead, "currently researching" is derived from the keys of this map. Every in-progress tech is expected to occupy a slot in `researchSlotAssignments` (see below).
- **researchSlotAssignments:** Persisted map of slot index (`0..researchSlots-1`) → `{techId, funding}`. This is the durable record of which tech occupies each slot and at which `ResearchFundingLevel`, surviving turn resolution and save/load. It is **distinct** from the per-turn `Orders.researchOrdersByPlayerId` (the transient UI mutation surface): after each turn resolution the surviving slot assignments are persisted back to `Player.researchSlotAssignments`. Null/absent on legacy saves → treated as empty (no slot assignments).
- **techUnlocked:** Map of tech id → true for researched/unlocked techs. Exists on `Player`; already implemented.
- **researchableTechIds:** **Derived** list of tech ids that can be researched next (dependencies satisfied). Computed from `techUnlocked` + tech catalog prerequisites; not stored on Player.
- **Dependencies:** All technologies have dependencies per Imperialism II tech tree. A tech becomes researchable when all its dependencies are in `techUnlocked`.

## Research Slots

Per [tech-tree.md](tech-tree.md):
- Default: 3 slots
- With University tech: 4 slots
- Each slot holds at most one active tech (or is empty)
- Funding presets apply per slot (None/Low/Medium/High/Maximum)

## Slot Occupancy Persistence

An in-progress tech keeps occupying the slot it was assigned to until that tech is unlocked or the player cancels it. Slot occupancy is persisted as `Player` game state via `researchSlotAssignments` and survives turn resolution and save/load.

- **Model layer (`Player`):** `researchSlotAssignments` serializes as a JSON object keyed by the slot index (string form) → `{techId, funding}` entry, where `funding` is a `ResearchFundingLevel` name. Self-contained deserialization drops structurally invalid entries: a negative slot index, or an empty/missing `techId`. The `funding` of any entry that omits or carries an unknown level defaults to `none`.
- **Orphaned progress discard (load):** On deserialization, any `researchProgressByTechId` entry whose tech id is **not** bound to a surviving `researchSlotAssignments` entry is **discarded** (the progress is forfeited). This guarantees every retained in-progress tech occupies a slot. Legacy saves predating `researchSlotAssignments` therefore load with **no** in-progress research (all prior progress forfeited). Entries whose tech is bound to a slot are preserved verbatim. No save migration is performed.
- **Load/resolver layer (catalog-aware):** Entries whose `techId` is absent from the tech catalog, or whose slot index is `>= researchSlots`, are dropped during catalog-aware load/resolution reconciliation (defined in [research-resolution.md](../program/research-resolution.md)); the model layer does not depend on the catalog.
- **Progress pruning:** `researchProgressByTechId` entries are retained while the tech occupies a persisted slot; they are pruned only on tech completion (progress ≥ cost → unlock) or slot cancellation. Detailed resolution and pruning rules are in [research-resolution.md](../program/research-resolution.md).

## Stubs (sim game)

Currently:
- `researchProgressByTechId` = empty map (no active research)
- `researchSlots` = 3 (default)
- Player tabs show `techUnlocked` only; display placeholder or empty for "currently researching" and "next paths".

## Acceptance Criteria

- **State on Player:** `techUnlocked` (map tech id → true) and `researchProgressByTechId` (map tech id → progress RP) exist; `researchSlots` (int, default 3) is defined.
- **Multi-slot model:** Multiple techs can be researched in parallel (one per slot). "Currently researching" is derived from non-empty keys in `researchProgressByTechId`, not a single `currentResearchTechId`.
- **Dependencies:** A tech is researchable when all its dependencies are in `techUnlocked`; dependencies follow Imperialism II–style tech tree per [tech-tree.md](tech-tree.md).
- **researchableTechIds:** Explicitly **derived** (computed from `techUnlocked` + catalog prerequisites), not stored on Player.
- **Progress:** Research progress is tracked per tech in `researchProgressByTechId`; completion and slot clearing are defined in [research-resolution.md](../program/research-resolution.md).
- **Sim game stubs:** When stubs are used, `researchProgressByTechId` is empty, `researchSlots` is 3, and UI may show placeholders for "currently researching" and "next paths".

### Slot occupancy persistence (model layer)

- **Given** a `Player` with `researchSlotAssignments = {0: {techId: T, funding: medium}}`, **when** the player is serialized to JSON and deserialized back, **then** the resulting `researchSlotAssignments[0]` equals `{techId: T, funding: medium}`.
- **Given** a legacy save whose `Player` JSON has no `researchSlotAssignments` key, **when** the player is deserialized, **then** `researchSlotAssignments` is empty (no slot assignments).
- **Given** a `Player` JSON whose `researchSlotAssignments` contains an entry with a negative slot index or an empty `techId`, **when** the player is deserialized, **then** that entry is dropped and the remaining valid entries are retained.
- **Given** a `Player` JSON whose `researchSlotAssignments` entry omits `funding`, **when** the player is deserialized, **then** that entry's `funding` defaults to `none`.
- **Given** a legacy `Player` JSON with a non-empty `researchProgressByTechId` and no `researchSlotAssignments` key, **when** the player is deserialized, **then** `researchProgressByTechId` is empty (all orphaned progress discarded) and `researchSlotAssignments` is empty.
- **Given** a `Player` JSON whose `researchProgressByTechId` contains tech `T` (progress > 0) and whose `researchSlotAssignments` binds tech `T` to some slot, **when** the player is deserialized, **then** `researchProgressByTechId[T]` is retained with its serialized value.
- **Given** a `Player` JSON whose `researchProgressByTechId` contains both a tech `T` bound to a slot in `researchSlotAssignments` and a tech `U` bound to no slot, **when** the player is deserialized, **then** `researchProgressByTechId` retains `T` and drops `U`.
