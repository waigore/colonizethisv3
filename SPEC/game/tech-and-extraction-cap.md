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
