# Combat

## Overview

Auto-resolved combat triggers when units move into enemy-controlled provinces. Battles are deterministic, with initiative-ordered multi-attacker chains resolved per province.

## Rules

**Trigger:** A unit's move ending in an enemy-owned province constitutes an attack. Only Great Powers initiate; Minor Nations and Tribes defend only.

**Attacker / Defender:** Attacker = faction that moved in. Defender = province owner (tie-break: lowest faction id). One defender per province; multiple attackers possible.

**Battle Mode:** Field (fort level 0, terrain modifiers) or Siege (fort level ≥ 1; walls, emplaced artillery per [siege-mechanics.md](siege-mechanics.md)).

**Initiative:** `initiative = cavalryShare × W_cav + generalMedals × W_medal`, where `cavalryShare = cavalry regiments / total regiments`.

**Multi-Attacker Chain:** Sort attackers by initiative descending (tie-break: faction id). Resolve sequentially: defender vs highest-initiative attacker; winner (no heal) vs next attacker; repeat until no attackers remain or defender eliminated.

**Strength:** Per-regiment FPN + FPM (from [military-units.md](military-units.md)). Medals (0–4) multiply by 1.0–1.4. DEF durability = DEF / 9. Damaged units: firepower ∝ remaining / starting health. Side strength = `Σ (FPN_eff + FPM_eff) × medalMult`, adjusted by modifiers.

**Modifiers:** Terrain (province type), fort (level 0–3; damage reduction + emplaced guns per [siege-mechanics.md](siege-mechanics.md)), difficulty (scales attacker/defender), general (+1 deployment per medal + initiative contribution), feeding coverage (see table below).

**Resolution:** Compare total attacker vs defender strength after modifiers. Deterministic output: winner + casualties per side.

**Outcomes:** Attacker victory (defender eliminated → province flips), defender victory (attacker eliminated, no change), stalemate (both survive, no flip), mutual annihilation (both wiped; defender recovers 20% rounded up of initial regiments if further attackers remain, otherwise ungarrisoned).

**Province Flip:** Immediate on defender elimination, before later same-province battles. Connectivity/extraction recompute next turn.

## Configurable Values

| Parameter | Default | Notes |
|---|---|---|
| W_cav | TBD | Initiative cavalry weight |
| W_medal | TBD | Initiative medal weight |
| Medal multipliers | 1.0 / 1.1 / 1.2 / 1.3 / 1.4 | Per medal level 0–4 |
| DEF divisor | 9 | Durability scaling |
| Recovery % | 20% (ceil) | Mutual-annihilation garrison |
| Feeding modifiers | 1.0 / 0.75 / 0.5 | Coverage ≥ 1.0 / 0.5–1.0 / < 0.5 |
| Terrain modifiers | Per terrain type | In ruleset config |
| Fort modifiers | Per fort level 0–3 | In ruleset config |
| Difficulty modifiers | Per difficulty level | In ruleset config |

## Interactions

- Unit stats: [military-units.md](military-units.md)
- Siege rules: [siege-mechanics.md](siege-mechanics.md)
- Factions / minor parity: [factions.md](factions.md)
- Ruleset config: [ruleset-config.md](ruleset-config.md)
- Resolution pipeline: [../program/combat-resolution.md](../program/combat-resolution.md)

## Open Questions

1. W_cav / W_medal values — Imp2 confirms factors, no numeric weights.
2. FPN + FPM blending — simple sum or range/melee phase weighting.
3. Auto-resolve formula details: (a) strength ratio → winner, (b) casualties from differential + DEF/9, (c) unit-by-unit vs proportional casualties.
4. Feeding modifier — provisional; Imp2 has no unfed penalty. Confirm mechanic and thresholds.
