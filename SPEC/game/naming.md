# Naming and Historical Flavor

**SPEC/game** — Historically inspired names for factions, provinces, capitals, and sea zones. Technical config: [ruleset-config.md](../program/ruleset-config.md). World model: [world-model.md](world-model.md).

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
- **Sea zones:** Region-specific display-name presets for sea zones. `oldWorld` uses well-known European and nearby Atlantic/Mediterranean sea names; `newWorld` uses well-known North/South American sea names. Sea-zone names are display-only and do not alter topology semantics.

All names are **ruleset-driven**; game logic only consumes resolved naming data.

**current product source note:** Until ruleset JSON load/merge is implemented (tracked in #57), game setup resolves naming from the program-level `defaultNamingConfig` in `colonizethis_data`. This is the temporary current product source of truth for runtime naming data; see [ruleset-config.md](../program/ruleset-config.md).

The **default** minor nation and tribe identities and province name pools are defined in **GDD 09b (Minor Nations)** and **GDD 09c (New World Tribes)**. The default ruleset exposes 6 minors (ids `minor1`–`minor6`) and 10 tribes (ids `tribe1`–`tribe10`) in GDD order.

---

## Application During Game Setup

**Province naming is mandatory** for all factions (Great Powers, Minor Nations, Tribes). After the Naming phase of game setup completes, every province stored in the starting `WorldState` has a non-null, non-empty `Province.displayName`. During earlier pipeline steps or in tooling, `Province.displayName` MAY be absent or null, but game logic MUST treat a missing name at the end of setup as a bug.

Order: during game setup/map creation, after province assignment and after capital auto-choice, assign province names, faction display names, and sea-zone display names. All province ids used during naming (e.g. capital province id, owned-province lists) use the **prefixed** `regionId|localId` form per [world-model-identity.md](world-model-identity.md); naming logic must never look up provinces by bare local id.

- **Capital province:** Gets the faction’s capital name (`capitalCityName` for GPs; for minors and tribes, the capital province **always** receives the first entry of the province name pool when that string is still available; if it is already used in the same region by an earlier-assigned province, the System picks a substitute name using the same deterministic collision rules as for non-capital provinces).
- **Other provinces:** Names are chosen from the faction’s `provinceNamePool` in a **deterministic shuffle order** (same helper and seed family as today) so that:
  - Same seed ⇒ same names (deterministic, reproducible).
  - Different seed ⇒ different names across games.
  - **Without replacement across the region:** a pool string already assigned to any province in that region (including the assigning faction’s capital) is never assigned again to another province in the same region; the walk continues to the next shuffled pool candidate.
- **Faction display names:** Great Powers get `countryName` (e.g. England, France); Minor Nations and Tribes get `displayName` from the naming config. These are applied to the game’s players, minorNations, and tribes so UI can show human-readable faction names.
- **Sea-zone display names:** Every sea zone node in topology receives a non-empty display name keyed by prefixed id (`regionId|seaZoneLocalId`). **Implementation (fixed-order, no shuffle):** Sea-zone local ids are sorted, and the System walks that order while assigning names from the region preset list in declared list order (`preset[i % preset.length]`). When there are more zones than preset entries, later cycles append deterministic numeric ordinals `(2)`, `(3)`, … to preserve non-empty stable labels. Assignment does **not** use shuffle/permutation. **The same generated topology must always yield the same display string for each prefixed sea-zone id** when setup runs again. **Pairwise distinct** display names across all sea zones in a region are **not** required unless the GDD explicitly adds that requirement later.

Pool sizes: default ruleset uses **10** names per Great Power and **5** per Minor Nation and Tribe. Tribes use historically inspired **Amerindian / indigenous** place or region names.

### Scope of naming

- **Great Powers and Minor Nations** start only in the Old World; province assignment assigns OW provinces only. **All** provinces owned by each GP or minor at setup are considered home and **must** be named (capital gets capital name, others from pool/fallback in deterministic order). No landmass or continent filter.
- **Tribes** start only in the New World; all provinces owned by each tribe at setup are considered home and must be named the same way.
- **Sea zones** are named per region graph node, not by merged water bodies. Each sea-zone node gets exactly one display name.

### Sea-zone list overflow fallback

When a region has more sea zones than unique preset names in that region list, setup must continue assigning names using deterministic suffixes derived from stable sea-zone ordering (for example appending a Roman or numeric ordinal). Overflow fallback must still produce non-empty names for all sea zones.

### Provinces acquired during play

When a faction acquires a province during the game (e.g. conquest), that province already has a `displayName` from its previous owner or from setup. Naming is **not** re-run—the existing name is retained. Overseas/colony provinces are therefore not a separate naming case.

### Fallback when naming is missing or empty

When a faction has no matching entry in the naming config (e.g. tribe count > 10), or when the resolved capital name or pool is empty, game setup **must** assign a non-empty name via a **deterministic fallback** so that every province still ends setup with a non-null `Province.displayName`.

- **Configured-but-empty entries (hybrid fallback):**
  - If a Minor Nation or Tribe has a naming entry but its province name pool is empty, the **capital province** uses the faction `displayName` (e.g. `Italy`, `Aztec`) as its name.
  - In the same empty-pool case, **non-capital provinces** for that faction receive a deterministic prefix+ordinal form such as `\"Italy 1\"`, `\"Italy 2\"` or `\"Aztec Territory 1\"`, `\"Aztec Territory 2\"`, derived from a fallback prefix and deterministic ordering of owned provinces.
  - If any computed fallback string is empty, naming switches to the procedural algorithm below for that province.
- **No naming entry or unusable capital name (procedural fallback):**
  - When a faction has **no naming entry** at all (e.g. more tribes than configured ids) or when the chosen name for a province would be empty, the System uses a **procedural stub+suffix** algorithm: combine a **word stub** (e.g. Tan, Ver, Ash) with a **place suffix** (e.g. ton, ville, ford) using a RNG seeded from the naming seed and faction/province context so the same setup yields the same names.
- **Uniqueness (land provinces at end of setup):** After the Naming phase completes, **no two land provinces in the same region** (`oldWorld` or `newWorld`) may share the same `Province.displayName` string. **Within a single faction**, no two provinces owned by that faction at setup may share the same `Province.displayName` (this follows from global per-region uniqueness when combined with the fact that each province has exactly one display name). The in-memory set used for collision checks is **scoped per region** (Old World names do not block identical strings in the New World, and vice versa).
- **Procedural names:** All **procedurally generated** names (from the stub+suffix algorithm) are added to that region’s in-memory set; when generating a new procedural name, the implementation must ensure the name is not already in that set (re-roll or append ordinal until unique).
- **Ruleset strings vs procedural:** When no unused pool string remains for a province in that region, or when the capital’s configured string is already used in the region, the System assigns a non-empty name via **`generateUniqueProvinceName`** (or the hybrid prefix+ordinal path when the pool is empty), updating the same per-region set so the final name is unique in the region.

---

## Acceptance Criteria

- Given a naming config for the active ruleset that defines Great Power, Minor Nation, and Tribe entries as described in this document  
  When the System loads naming data during game setup  
  Then the System validates that each Great Power id has at least one leader variant, that province name pools and capital names (when present) are non-empty strings, and that Minor Nation and Tribe entries provide at least one province name each, rejecting the ruleset if required naming data is structurally invalid.

- Given provinces have been assigned to factions during game setup per [game-setup.md](game-setup.md) and naming data has been loaded successfully  
  When the System assigns names in the Naming phase  
  Then every province receives a non-null `Province.displayName`; capital provinces receive the configured capital city name for their faction or the first entry from the province name pool **when that string is still unused in the region**, otherwise a deterministic substitute; non-capital provinces draw from their faction’s pool in shuffled deterministic order skipping strings already used in the region; identical seeds and inputs yield identical name assignments; every sea zone in each region receives a non-empty display name stored by prefixed sea-zone id; and land province display names are pairwise distinct within each of `oldWorld` and `newWorld` as required elsewhere in this document.

- Given a faction or province lacks a matching entry or usable name pool in the naming config (for example, when there are more tribes than configured entries or when a configured pool is empty)  
  When the System assigns names for that faction’s provinces  
  Then the System applies the deterministic fallback rules described here: for configured-but-empty entries, capital provinces may use faction `displayName` and non-capital provinces may use deterministic prefix+ordinal names; for factions with no usable naming entry or when a computed name would be empty, the System invokes the procedural stub+suffix algorithm to generate unique, reproducible names per province using a naming seed and faction/province context; in all cases, the System ensures that procedurally generated names are not reused across procedural names in the same game and still guarantees that every province ends the setup process with a non-empty `Province.displayName`.

- Given a generated region has more sea-zone nodes than entries in that region’s sea-name preset list  
  When the System assigns sea-zone display names during setup  
  Then the System assigns deterministic suffixed fallback names for overflow sea zones, keeps names non-empty, and still assigns a display name to every sea-zone node.

- Given a region topology includes at least one sea-zone node  
  When the System assigns sea-zone display names during setup  
  Then the System sorts local sea-zone ids, assigns display strings by cycling the region preset in declared list order (no shuffle/permutation), and applies numeric ordinal suffixes on later cycles when zone count exceeds preset length (`colonizethis_data` `sea_zone_naming_test.dart`; `colonizethis_logic` `init_game_orchestrator_test.dart`).

- Given the Naming phase has completed for a game created from generated maps  
  When a tester collects `Province.displayName` for every **Old World** land province  
  Then the multiset of those strings has the same cardinality as the set of those strings (pairwise distinct display names across the Old World).

- Given the Naming phase has completed for a game created from generated maps  
  When a tester collects `Province.displayName` for every **New World** land province  
  Then the multiset of those strings has the same cardinality as the set of those strings (pairwise distinct display names across the New World).

- Given a single faction id `F` and a region `R` (`oldWorld` or `newWorld`)  
  When the tester lists all land provinces in `R` whose `ownerId` equals `F` after naming  
  Then the `displayName` values of those provinces are pairwise distinct.

- Given a locked full-init profile game (`GameSetupConfig` with six default Great Powers, six minor nations, ten tribes, 60 Old World provinces, 30 New World provinces, `minProvincesPerMinor` = 3) and setup `seed` = 42 produced by `runInitGame` with default map generation  
  When the tester counts Old World provinces owned by `minor4` whose `displayName` is exactly `Greater Poland`  
  Then that count is at most 1.

- Given a `GameSetupConfig` where at least one tribe owns more home provinces in the New World than there are distinct strings in that tribe’s configured `provinceNamePool`  
  When the Naming phase runs  
  Then every such province still receives a non-empty `Province.displayName`, and all New World land province display names remain pairwise distinct (procedural fallback covers the shortfall).
