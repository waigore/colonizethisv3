# Tech and Extraction Cap

**SPEC/game** — Per-player tech and its effect on extraction. Derived from GDD 04b. Reference: Imperialism II 02-economy (production level 0–4; technology caps). Tech tree: [tech-tree.md](tech-tree.md). Gathering and related caps (GDD): [tech-tree-gathering.md](tech-tree-gathering.md). New World resource chains: [tech-tree-new-world.md](tech-tree-new-world.md). Extraction: [extraction-and-improvements.md](extraction-and-improvements.md).

---

## Per-Player Tech

Each player has a **tech table**: a map from tech id to unlocked (e.g. `Map<String, bool>` or equivalent). The same **static list** of tech ids is defined for all players in program-level config (no JSON rulesets).

---

## Extraction Cap

The **max effective extraction level** (1–4) per resource or improvement type is **derived from the tech tree catalog**: which techs grant which max improvement level for each resource (grain, timber, iron, coal, etc.). Effective extraction per tile = min(improvement level, **owner’s tech cap** for that resource). The improvement level on the tile is unchanged; only the amount that counts for extraction is capped.

The System resolves caps with a **resource-specific** mapping in `packages/colonizethis_data/lib/src/tech_extraction_caps.dart` (`_extractionCapByResourceByTechId`, consumed by `extractionCapForResourceForUnlocked`; re-exported from `tech_extraction.dart`). For a given resource, the cap is the highest level granted by unlocked techs for that resource. If no cap-raising tech is unlocked for that resource, the cap is **1**.

Some resources may be intentionally capped below 4 by design. These exceptions must be declared in `extractionCapDesignExceptions` in `tech_extraction_caps.dart` and mirrored in this SPEC:
- `horses`: cap 1 (no extraction upgrade chain in current design)
- `wool`: cap 3 (current design chain ends at `scientific_sheep_breeding`)

Static catalog validation must enforce extraction cap coverage:
- Every upgradeable extraction resource must have a progression reaching cap 4, **unless** that resource is explicitly declared in the design exception map above.
- Exception caps must be within 1–4 and require explicit rationale in SPEC.

---

## Acceptance Criteria

- Given a player has no grain-cap tech unlocked and a grain tile at improvement level 1  
  When the player submits `build_improvement` on that tile  
  Then the System rejects the order with a reason that includes `grain`, insufficient tech for the next level, and extraction cap **1**.

- Given a player has unlocked `land_enclosure` and has a grain tile at improvement level 1  
  When the player submits `build_improvement` on that tile  
  Then the System accepts the order because the grain cap is 2 and level 2 is allowed.

- Given an extraction resource that is not listed in `extractionCapDesignExceptions`  
  When static extraction-cap catalog validation runs  
  Then the System verifies that the resource has a valid cap progression up to level 4 in `_extractionCapByResourceByTechId`.

- Given an extraction resource listed in `extractionCapDesignExceptions`  
  When static extraction-cap catalog validation runs  
  Then the System accepts that resource only when the declared exception cap is an integer in 1–4 and the same resource/cap is documented in this SPEC.
