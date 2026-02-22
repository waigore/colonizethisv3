# Research State

**SPEC/game** — Technology research model. Full implementation in research resolution; sim game uses stubs. Reference: GDD 05 (Academy, tech tree).

---

## Model

- **currentResearchTechId:** Tech currently being researched (null if none). Progress tracked per turn.
- **techUnlocked:** Map of tech id → true for researched techs. Exists on `Player`; already implemented.
- **researchableTechIds:** List of tech ids that can be researched next (dependencies satisfied).
- **Dependencies:** All technologies have dependencies per Imperialism II tech tree. A tech becomes researchable when its dependencies are in `techUnlocked`.

---

## Stubs (sim game)

Currently:
- `currentResearchTechId` = null
- `researchableTechIds` = []
- Player tabs show `techUnlocked` only; display placeholder or empty for "currently researching" and "next paths".
