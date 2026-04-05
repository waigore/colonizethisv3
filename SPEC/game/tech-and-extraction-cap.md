# Tech and Extraction Cap

**SPEC/game** — Per-player tech and its effect on extraction. Derived from GDD 04b. Reference: Imperialism II 02-economy (production level 0–4; technology caps). Tech tree: [tech-tree.md](tech-tree.md). Gathering and related caps (GDD): [tech-tree-gathering.md](tech-tree-gathering.md). New World resource chains: [tech-tree-new-world.md](tech-tree-new-world.md). Extraction: [extraction-and-improvements.md](extraction-and-improvements.md).

---

## Per-Player Tech

Each player has a **tech table**: a map from tech id to unlocked (e.g. `Map<String, bool>` or equivalent). The same **static list** of tech ids is defined for all players in program-level config (no JSON rulesets).

---

## Extraction Cap

The **max effective extraction level** (1–4) per resource or improvement type is **derived from the tech tree catalog**: which techs grant which max improvement level for each resource (grain, timber, iron, coal, etc.). Effective extraction per tile = min(improvement level, **owner’s tech cap** for that resource). The improvement level on the tile is unchanged; only the amount that counts for extraction is capped.

**MVP:** The implementation uses a **single scalar** cap per player (one integer 1–4 applied to every resource on every owned tile) as a temporary simplification. The full model will use **per-resource** caps from the category sub-docs (e.g. [tech-tree-gathering.md](tech-tree-gathering.md)).

**MVP scalar mapping (program):** The System maintains a **program-level map** from tech id → max effective extraction level (1–4) for techs that raise the cap. That map includes techs aligned with the **gathering / industry** tree and with **New World** plantation, fur, spice, and precious-metal/stone chains (see [tech-tree-gathering.md](tech-tree-gathering.md), [tech-tree-new-world.md](tech-tree-new-world.md)). For a player, the scalar cap is the **maximum** level among all map entries whose tech id is unlocked; if none apply, the System uses the fallback below. **Authoritative list:** `packages/colonizethis_data/lib/src/tech_extraction.dart` (`_extractionCapByTechId`, consumed by `extractionCapForUnlocked`). Do not duplicate the full id list in this doc; update the Dart map when adding or changing cap-granting techs.

**Fallback:** When the tech table is missing or empty, or when no tech in the program map is unlocked for that player, the System uses a **constant fallback cap of 4** per player so extraction resolution can run. The full per-resource model derives caps from [tech-tree.md](tech-tree.md) and category sub-docs. Ruleset: MVP program-level constants (including the fallback cap); future ruleset per [ruleset-config.md](../program/ruleset-config.md).

---

## Acceptance Criteria

- Given a player has a tech table where each tech id is either unlocked or locked and a program-level map from tech id to extraction cap level (1–4) as defined in `tech_extraction.dart`  
  When the System computes the player’s MVP scalar extraction cap from the tech table  
  Then the System sets that scalar to the maximum cap level among unlocked techs present in that map, or to the configured fallback (4) when no mapped tech is unlocked, and does not use a level that contradicts the map.

- Given the implementation is running in the MVP mode where a single scalar extraction cap is used per player for all resources  
  When the System evaluates extraction for any tile owned by that player as described in [extraction-and-improvements.md](extraction-and-improvements.md)  
  Then the System sets the production for that tile to the minimum of the tile’s improvement level and that player’s scalar cap and applies this same cap regardless of which resource is present on the tile.

- Given the full tech model is not yet loaded or a resource does not have any associated tech-gated cap in the catalog  
  When the System computes extraction caps for that resource for any player  
  Then the System uses the configured constant fallback cap (for example 4) so that extraction resolution can run, and applies this fallback in the same way as a tech-derived cap when computing per-tile production.
