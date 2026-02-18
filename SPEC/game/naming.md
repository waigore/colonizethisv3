# Naming and Historical Flavor

**SPEC/game** — Historically inspired names for factions, provinces, and capitals. Technical config: [ruleset-config.md](../program/ruleset-config.md). World model: [world-model.md](world-model.md).

---

## Goals and Source of Truth

- Provide a **default, historically inspired ruleset** so that Great Powers, their capitals, and key provinces use recognisable real-world names.
- Align Great Power identities with the **leader definitions in the GDD**; the GDD determines **which Great Powers** appear in the default ruleset and their leader/country pairing.

---

## Naming Model

Per active ruleset, naming config defines:

- **Great Powers (GP):** Registry keyed by semantic id (e.g. `england`, `france`, `spain`). Game setup uses `selectedGreatPowerIds` to determine which powers appear; players (ordinal gp1, gp2…) are mapped to selected powers for naming. Each GP may have multiple **leader variants**; when multiple exist, setup config must specify which is chosen (`leaderVariantByGpId`). Province naming and leader display use the selected variant. Each entry has:
  - `id`: semantic id (e.g. `england`) mapped to:
    - `countryName` (e.g. `England`), `adjective` (e.g. `English`).
    - `capitalCityName` (e.g. `London`).
    - `leaderVariants`: list of `{ id, name, leaderKey, provinceNamePool? }`; first is default. Province pool comes from the chosen variant (or GP default when variant has none).
- **Minor Nations:** `displayName` (e.g. `Portugal`, `Savoy`) and **province name pool** (default: **5** names per minor).
- **Tribes:** `displayName` for New World peoples and **province name pool** (default: **5** names per tribe; historically inspired **Amerindian / indigenous** place or region names).

All names are **ruleset-driven**; game logic only consumes resolved naming data.

---

## Application During Game Setup

**Province naming is mandatory** for all factions (Great Powers, Minor Nations, Tribes). Every province receives a non-null `Province.displayName`.

Order: **after** province assignment and **after** capital auto-choice, assign province names and faction display names.

- **Capital province:** Gets the faction’s capital name (`capitalCityName` for GPs; for minors/tribes, the first entry of the province name pool or a dedicated capital name when present).
- **Other provinces:** Names are chosen **randomly** from the faction’s `provinceNamePool` using a RNG seeded from the game setup seed so that:
  - Same seed ⇒ same names (deterministic, reproducible).
  - Different seed ⇒ different names across games.
- **Faction display names:** Great Powers get `countryName` (e.g. England, France); Minor Nations and Tribes get `displayName` from the naming config. These are applied to the game’s players, minorNations, and tribes so UI can show human-readable faction names.

Pool sizes: default ruleset uses **10** names per Great Power and **5** per Minor Nation and Tribe. Tribes use historically inspired **Amerindian / indigenous** place or region names.
