# Tech and Extraction Cap

**SPEC/game** — Per-player tech and its effect on extraction. Derived from GDD 04b. Reference: Imperialism II 02-economy (production level 0–4; technology caps). Extraction: [extraction-and-improvements.md](extraction-and-improvements.md).

---

## Per-Player Tech

Each player has a **tech table**: a map from tech id to unlocked (e.g. `Map<String, bool>` or equivalent). The same **static list** of tech ids is defined for all players and lives in **colonizethis_data** (no JSON rulesets in MVP).

---

## Extraction Cap

One tech (or a small set) defines the **max effective extraction level** (e.g. 1–4). Effective extraction per tile = min(improvement level, **owner’s tech cap**). The improvement level on the tile is unchanged; only the amount that counts for extraction is capped.

**Phase 2 default:** If the full tech model is not yet implemented, use a **constant cap** (e.g. 4) per player from config so extraction resolution can run without a tech table.

---

## Implementation

- **colonizethis_data:** Static list of tech ids; optional constant for default extraction cap.
- **colonizethis_models:** Player (or separate structure) holds tech table; serialization for save/load.
- **colonizethis_logic:** Extraction resolution reads owner’s tech cap (from tech table or constant) when computing effective yield per tile.
