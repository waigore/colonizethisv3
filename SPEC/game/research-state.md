# Research State

**SPEC/game** — Technology research model. Full implementation in research resolution; sim game uses stubs. Reference: GDD 05 (Academy, tech tree). Cross-reference: [tech-tree.md](tech-tree.md), [research-resolution.md](../program/research-resolution.md).

---

## Model (Multi-Slot)

The research system uses a **multi-slot model** where multiple technologies can be researched in parallel (one per slot):

- **researchSlots:** Number of available research slots (default 3; 4 with University tech). Each slot can hold at most one active tech.
- **researchProgressByTechId:** Map of tech id → progress (RP accumulated). Non-empty keys represent techs currently being researched across all slots. There is no single "currentResearchTechId"; instead, "currently researching" is derived from the keys of this map.
- **techUnlocked:** Map of tech id → true for researched/unlocked techs. Exists on `Player`; already implemented.
- **researchableTechIds:** **Derived** list of tech ids that can be researched next (dependencies satisfied). Computed from `techUnlocked` + tech catalog prerequisites; not stored on Player.
- **Dependencies:** All technologies have dependencies per Imperialism II tech tree. A tech becomes researchable when all its dependencies are in `techUnlocked`.

## Research Slots

Per [tech-tree.md](tech-tree.md):
- Default: 3 slots
- With University tech: 4 slots
- Each slot holds at most one active tech (or is empty)
- Funding presets apply per slot (None/Low/Medium/High/Maximum)

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
