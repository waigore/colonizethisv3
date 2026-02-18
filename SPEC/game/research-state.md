# Research State

**SPEC/game** — Technology research model. Full implementation in Phase 5. Sim game uses stubs. Reference: GDD 05 (Academy, tech tree), [phase-4-project-tasks.md](../project/phase-4-project-tasks.md), [phase-5-project-tasks.md](../project/phase-5-project-tasks.md) (when present).

---

## Model (Phase 5)

- **currentResearchTechId:** Tech currently being researched (null if none). Progress tracked per turn.
- **techUnlocked:** Map of tech id → true for researched techs. Exists on `Player`; already implemented.
- **researchableTechIds:** List of tech ids that can be researched next (dependencies satisfied). Phase 5.
- **Dependencies:** All technologies have dependencies per Imperialism II tech tree. A tech becomes researchable when its dependencies are in `techUnlocked`.

---

## Phase 5 stubs (sim game)

Until Phase 5:
- `currentResearchTechId` = null
- `researchableTechIds` = []
- Player tabs show `techUnlocked` only; display placeholder or empty for "currently researching" and "next paths".
