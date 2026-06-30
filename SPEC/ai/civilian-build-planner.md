# Civilian Build Planner

**SPEC/ai** — Derives from [civilian-units.md](../game/civilian-units.md) (types, costs, tech gates), [economy-planner.md](economy-planner.md) (recruitment/build emit order), and [order-suggestions.md](../program/order-suggestions.md) (candidate enumeration). Defines how the Full AI builds, replaces, and prioritizes civilian units (Explorer, Builder, Engineer, Spy, Merchant, Rail Builder).

---

## Problem

The AI deploys its starting civilians (2 Explorer, 2 Builder, 1 Engineer) but never issues a civilian `BuildUnitOrder`: lost civilians are never replaced and the workforce never expands. `BuildUnitCategory.civilian` is classified but unused by AI decisions.

## Goal

Give the AI a deterministic, GA-tunable model that builds, replaces, and uses each civilian type, competing civilian builds in the same weighted-selection build pool as regiments/ships, gated by phase, per-type caps, tech, and a shared paper budget.

---

## Candidate enumeration (suggestion layer)

`suggestBuildOrders` ([order-suggestions.md](../program/order-suggestions.md) § Build orders) exposes civilian build candidates through an opt-in `includeCivilianBuilds` flag (default `false`). When enabled, it emits one `BuildUnitOrder` per `CivilianEconomyCatalog` type (`isMilitary: false`, `spawnProvinceId = capital`) that the order engine accepts, alongside military (regiment) and naval (ship) candidates. Each civilian candidate is validated by the same incremental candidate validator as other build families, which enforces:

- **Affordability** — treasury covers `buildTreasuryCost` and the stockpile covers `buildInputs` (paper), including pending-riches treasury (per § Build orders).
- **Tech gate** — `unlockingTechByCivilianId` (Merchant ⇐ `merchant_companies`, Rail Builder ⇐ `early_steam_engine`); ungated types are always buildable.
- **Spawn tile** — a civilian capital spawn tile exists.

Ordering remains deterministic (ascending `unitType`). When the flag is `false`, the returned list is byte-identical to the military+naval-only list (no civilian candidates).

The live Full-AI economy path (`domain_planner_orchestrator_economy.dart`, `recruitment_planner.dart`) keeps the default `false` until the scoring/cap layer below lands, so AI build behavior is unchanged by enumeration alone.

## Scoring model (build pool)

Civilian candidates compete in the same `pickBuildOrder` weighted pool as regiments/ships. The civilian branch is **additive**: military/naval scores are unchanged for identical inputs. A civilian candidate score is:

```
base × phaseMultiplier[type] × minCapBoost × replacementUrgency × demandBoost
```

- **Min cap (hard floor):** when `currentCount[type] < minCount[type]`, apply a large score elevation.
- **Replacement urgency (soft pull):** while `minCount ≤ currentCount < targetCount`, multiply by `1 + replacementUrgencyFactor × (targetCount − currentCount)`; `1.0` when `currentCount ≥ targetCount`.
- **Max cap (ceiling):** a candidate at or above `maxCount[type]` is excluded from the pool (prevents over-building starving military/naval).
- **Phase multiplier (smooth):** per-phase multipliers transition continuously across phase boundaries using the `[0,1]` ramp in `phase_priority_weights.dart`. EXPAND → Builder; COLONIAL → Explorer + Merchant; DEVELOP → Engineer + Rail Builder.
- **Spy (phase-flat + demand):** identical multiplier across EXPAND/COLONIAL/DEVELOP, plus a `spyDemandBoost` when the GP is at war or pursuing a tech-steal posture, gated by `minSpies` (default `0`).

## Tech prioritization

The research planner boosts civilian-gating techs (`merchant_companies`, `early_steam_engine`) so the AI unlocks Merchant/Rail Builder, bounded by `researchPaperReserveShare` so it cannot starve builds.

## Paper budget (shared, deterministic)

Paper is shared across research, worker training, and civilian builds. The AI (a) reserves research paper up to `researchPaperReserveShare` of current paper, then (b) allocates the remainder via the existing recruitment-planner phase emit order (DEVELOP: recruit/train before builds; EXPAND/COLONIAL: builds first), checking each candidate against a running paper ledger and dropping any that would push remaining paper below `0`.

## GA-tunable parameters

Declared in `ai_victory_config.dart` / personality thresholds (no planner magic numbers): per-type `minCount`/`maxCount`/`targetCount`, per-type per-phase multiplier, `spyDemandBoost`, `minSpies`, civilian-build pool weight, `replacementUrgencyFactor`, `researchPaperReserveShare`. Defaults: starting types seed `targetCount` (Explorer 2, Builder 2, Engineer 1); other types `targetCount = minCount`.

---

## Implemented vs deferred

- **This slice (enumeration):** `includeCivilianBuilds` flag on `suggestBuildOrders`; AC1, AC5, AC9, AC12.
- **Deferred (follow-up on #3793):** scoring branch, min/max/target caps, phase dispatch + Spy demand, paper ledger, research bias, GA params, and flipping the AI flag on; AC2, AC3, AC4, AC4b, AC6, AC7, AC8, AC10, AC13.

---

## Acceptance criteria

- **AC1 (enumeration):** Given a Great Power with treasury ≥ 1000 and paper ≥ 2, when `suggestBuildOrders` runs with `includeCivilianBuilds: true`, then the returned list includes affordable, tech-unlocked civilian `BuildUnitOrder` candidates (Builder, Engineer, Explorer) alongside military/naval candidates, ordered deterministically by `unitType`.
- **AC1b (opt-out default):** Given the same player, when `suggestBuildOrders` runs with `includeCivilianBuilds` omitted (default `false`), then the returned list contains no civilian-type `BuildUnitOrder` and equals the military+naval-only list.
- **AC5 (tech gate):** Given a Great Power that has not unlocked `merchant_companies`, when `suggestBuildOrders` runs with `includeCivilianBuilds: true`, then the list contains no Merchant candidate; given `merchant_companies` unlocked and affordable, then the list contains a Merchant candidate.
- **AC9 (determinism):** Given identical `(Game, MapTopology, PlayerView, Orders)` and `includeCivilianBuilds: true`, when `suggestBuildOrders` runs twice, then both returned lists are identical in content and order.
- **AC12 (affordability floor):** Given a Great Power with treasury `0` or paper `< 2`, when `suggestBuildOrders` runs with `includeCivilianBuilds: true`, then the list contains no civilian `BuildUnitOrder`.
