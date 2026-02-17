# Naming and Historical Flavor

**SPEC/game** — Historically inspired names for factions, provinces, and capitals. Technical config: [ruleset-config.md](../program/ruleset-config.md). World model: [world-model.md](world-model.md).

---

## Goals and Source of Truth

- Provide a **default, historically inspired ruleset** so that Great Powers, their capitals, and key provinces use recognisable real-world names.
- Align Great Power identities with the **leader definitions in the GDD**; the GDD determines **which Great Powers** appear in the default ruleset and their leader/country pairing.

---

## Naming Model

Per active ruleset, naming config defines:

- **Great Powers (GP):**
  - `id` (e.g. `gp1`) mapped to:
    - `countryName` (e.g. `Spain`), `adjective` (e.g. `Spanish`).
    - `leaderKey` referencing the GDD leader entry.
    - `capitalCityName` (e.g. `Madrid`).
    - `provinceNamePool`: ordered list of historical **homeland region names** (e.g. `Castile`, `Andalusia`, `Catalonia`, ...).
- **Minor Nations:** list of `displayName` entries (e.g. `Portugal`, `Savoy`, `Bavaria`, ...) and optional province name pools.
- **Tribes:** list of `displayName` entries for New World peoples/civilisations, optionally grouped by sub-region.

All names are **ruleset-driven**; game logic only consumes resolved naming data.

---

## Application During Game Setup

After **province assignment** and **capital auto-choice**:

- For each **Great Power**:
  - Determine its **primary landmass** from the capital province.
  - For provinces owned by that GP on the primary landmass, assign `Province.displayName` deterministically from the GP’s `provinceNamePool` (stable order: sorted province ids, wrap when the pool is shorter than the province count).
  - Set the capital province’s display name from the same pool (or a dedicated homeland name) and treat `capitalCityName` as the city shown for the capital tile in UI.
- For **Minor Nations** and **Tribes**:
  - Use the naming config’s `displayName` for the faction label.
  - When province pools are present, assign province display names deterministically in the same way as GPs.

Determinism:

- Naming decisions must be **deterministic** for a given ruleset and `GameSetupConfig.seed` (no per-run randomness leaking into names).
- When rulesets change (e.g. different scenario), only the new naming config alters the resulting names; the assignment algorithm remains the same.

