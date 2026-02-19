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
    - **Default map colour id:** semantic id is also the **colour identity** for that Great Power. GDD 09 defines a default RGB ownership colour per semantic id (e.g. `england` = red, `france` = dark blue). Tools such as ctdev present colour choices in terms of semantic ids; the runtime `Game` model and map view builders may re-key these colours to per-game `Player.id` values (e.g. `gp1`, `gp2`) during setup, but the source of truth for which colour “belongs” to which country remains the semantic id.
- **Minor Nations:** `displayName` (e.g. Italy, Germany) and **province name pool** (default: **5** names per minor). The default ruleset has **6** entries per **GDD 09b (Minor Nations)**.
- **Tribes:** `displayName` for New World peoples and **province name pool** (default: **5** names per tribe; historically inspired **Amerindian / indigenous** place or region names). The default ruleset has **10** entries per **GDD 09c (New World Tribes)**.

All names are **ruleset-driven**; game logic only consumes resolved naming data.

The **default** minor nation and tribe identities and province name pools are defined in **GDD 09b (Minor Nations)** and **GDD 09c (New World Tribes)**. The default ruleset exposes 6 minors (ids `minor1`–`minor6`) and 10 tribes (ids `tribe1`–`tribe10`) in GDD order.

---

## Application During Game Setup

**Province naming is mandatory** for all factions (Great Powers, Minor Nations, Tribes). Every province receives a non-null `Province.displayName`.

Order: **after** province assignment and **after** capital auto-choice, assign province names and faction display names.

- **Capital province:** Gets the faction’s capital name (`capitalCityName` for GPs; for minors and tribes, the capital province **always** receives the first entry of the province name pool).
- **Other provinces:** Names are chosen **randomly** from the faction’s `provinceNamePool` using a RNG seeded from the game setup seed so that:
  - Same seed ⇒ same names (deterministic, reproducible).
  - Different seed ⇒ different names across games.
- **Faction display names:** Great Powers get `countryName` (e.g. England, France); Minor Nations and Tribes get `displayName` from the naming config. These are applied to the game’s players, minorNations, and tribes so UI can show human-readable faction names.

Pool sizes: default ruleset uses **10** names per Great Power and **5** per Minor Nation and Tribe. Tribes use historically inspired **Amerindian / indigenous** place or region names.

### Scope of naming

- **Great Powers and Minor Nations** start only in the Old World; province assignment assigns OW provinces only. **All** provinces owned by each GP or minor at setup are considered home and **must** be named (capital gets capital name, others from pool/fallback in deterministic order). No landmass or continent filter.
- **Tribes** start only in the New World; all provinces owned by each tribe at setup are considered home and must be named the same way.

### Provinces acquired during play

When a faction acquires a province during the game (e.g. conquest), that province already has a `displayName` from its previous owner or from setup. Naming is **not** re-run—the existing name is retained. Overseas/colony provinces are therefore not a separate naming case.

### Fallback when naming is missing or empty

When a faction has no matching entry in the naming config (e.g. tribe count > 10), or when the resolved capital name or pool is empty, game setup **must** assign a non-empty name via a **deterministic procedural fallback**. The fallback satisfies the requirement that every province receives a non-null `Province.displayName` when the ruleset does not supply one.

- **Fallback algorithm:** Combine a **word stub** (e.g. Tan, Ver, Ash) with a **place suffix** (e.g. ton, ville, ford) using a RNG seeded from the naming seed and faction/province context so the same setup yields the same names.
- **Uniqueness:** During naming, all **generated** names are added to an in-memory set; when generating a new name, the implementation must ensure the name is not already in that set (re-roll or append ordinal until unique). Names from the ruleset (pool/capital) may repeat across factions; only procedural names are guaranteed unique.
