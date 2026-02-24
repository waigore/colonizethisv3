# Tech and Extraction Cap

**SPEC/game** — Per-player tech and its effect on extraction. Derived from GDD 04b. Reference: Imperialism II 02-economy (production level 0–4; technology caps). Tech tree: [tech-tree.md](tech-tree.md). Extraction: [extraction-and-improvements.md](extraction-and-improvements.md).

---

## Per-Player Tech

Each player has a **tech table**: a map from tech id to unlocked (e.g. `Map<String, bool>` or equivalent). The same **static list** of tech ids is defined for all players in program-level config (no JSON rulesets).

---

## Extraction Cap

The **max effective extraction level** (1–4) per resource or improvement type is **derived from the tech tree catalog**: which techs grant which max improvement level for each resource (grain, timber, iron, coal, etc.). Effective extraction per tile = min(improvement level, **owner’s tech cap** for that resource). The improvement level on the tile is unchanged; only the amount that counts for extraction is capped.

**MVP:** The implementation uses a **single scalar** cap per player (one value for all resources) as a temporary simplification; the catalog is program-level (e.g. gathering_1/2/3). The full model will use **per-resource** caps from the category sub-docs (e.g. [tech-tree-gathering.md](tech-tree-gathering.md)).

**Fallback:** When the full tech model is not yet loaded or a resource has no tech-gated cap, use a **constant cap** (e.g. 4) per player from config so extraction resolution can run. Full model derives cap from [tech-tree.md](tech-tree.md) and category sub-docs. Ruleset: MVP program-level constants; future ruleset per [ruleset-config.md](../program/ruleset-config.md).

---

## Acceptance Criteria

- Given a player has a tech table where each tech id is either unlocked or locked and a program-level catalog that maps tech ids to extraction caps per resource  
  When the System computes the player’s current extraction caps from the tech table  
  Then the System derives, for each relevant resource, a non-negative integer cap between 1 and 4 inclusive based only on the unlocked techs and the catalog, and does not assign any cap that contradicts the catalog.

- Given the implementation is running in the MVP mode where a single scalar extraction cap is used per player for all resources  
  When the System evaluates extraction for any tile owned by that player as described in [extraction-and-improvements.md](extraction-and-improvements.md)  
  Then the System sets the production for that tile to the minimum of the tile’s improvement level and that player’s scalar cap and applies this same cap regardless of which resource is present on the tile.

- Given the full tech model is not yet loaded or a resource does not have any associated tech-gated cap in the catalog  
  When the System computes extraction caps for that resource for any player  
  Then the System uses the configured constant fallback cap (for example 4) so that extraction resolution can run, and applies this fallback in the same way as a tech-derived cap when computing per-tile production.
