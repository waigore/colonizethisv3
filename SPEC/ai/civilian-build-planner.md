# Civilian Build Planner

**SPEC/ai** — Derives from [civilian-units.md](../game/civilian-units.md) (types, costs, tech gates), [economy-planner.md](economy-planner.md) (recruitment/build emit order), and [order-suggestions.md](../program/order-suggestions.md) (candidate enumeration). Defines how the Full AI builds, replaces, and prioritizes civilian units (Explorer, Builder, Engineer, Spy, Merchant, Rail Builder).

---

## Problem

The AI deploys its starting civilians (2 Explorer, 2 Builder, 1 Engineer) but never issues a civilian `BuildUnitOrder`: lost civilians are never replaced and the workforce never expands.

## Goal

A deterministic, GA-tunable model that builds, replaces, and uses each civilian type, competing in the same weighted build pool as regiments/ships, gated by phase, per-type caps, tech, and a shared paper budget.

---

## Candidate enumeration (suggestion layer)

`suggestBuildOrders` ([order-suggestions.md](../program/order-suggestions.md) § Build orders) exposes civilian build candidates through an opt-in `includeCivilianBuilds` flag (default `false`). When enabled, it emits one `BuildUnitOrder` per `CivilianEconomyCatalog` type (`isMilitary: false`, `spawnProvinceId = capital`) that the order engine accepts, alongside regiment and ship candidates. The shared incremental candidate validator enforces **affordability** (treasury covers `buildTreasuryCost`, stockpile covers `buildInputs` paper, incl. pending riches), the **tech gate** (`unlockingTechByCivilianId`: Merchant ⇐ `merchant_companies`, Rail Builder ⇐ `early_steam_engine`; ungated types always buildable), and a **civilian capital spawn tile**. Ordering is deterministic (ascending `unitType`); when `false` the list is byte-identical to the military+naval-only list. The live economy path (`domain_planner_orchestrator_economy.dart`, `recruitment_planner.dart`) keeps the default `false` until the live-wiring slice lands, so AI build behaviour is unchanged by enumeration and scoring alone.

## Scoring model (build pool)

Civilian candidates compete in the same `pickBuildOrder` weighted pool as regiments/ships. The civilian branch is **additive**: military/naval scores are unchanged for identical inputs. A civilian candidate score is:

```
base × phaseMultiplier[type] × minCapBoost × replacementUrgency × demandBoost
```

`pickBuildOrder` accepts an optional `CivilianBuildScoringInput` (owned count per type). When absent the civilian branch is inert (civilians keep the neutral `base` score; military/naval scoring is byte-identical to the pre-scoring path). When present:

- **Min cap (hard floor):** when `currentCount[type] < minCount[type]`, multiply by `kCivilianBuildMinCapScoreBoost` (a large elevation that dominates the military/naval bonus envelope).
- **Replacement urgency (soft pull):** while `minCount ≤ currentCount < targetCount`, multiply by `1 + replacementUrgencyFactor × (targetCount − currentCount)`; `1.0` when `currentCount ≥ targetCount`.
- **Max cap (ceiling):** a candidate at or above `maxCount[type]` is excluded from the pool before scoring (prevents over-building starving military/naval).
- **Phase multiplier:** `phaseMultiplier[type]` is read from `kCivilianBuildPhaseMultiplierByPhaseType` keyed by the active phase (`ObserverGoalPhase.name`, passed via `CivilianBuildScoringInput.phaseName`). EXPAND (and COLONIAL-lite) favor Builder; COLONIAL favors Explorer + Merchant; DEVELOP favors Engineer + Rail Builder (favored = `kCivilianBuildPhaseMultiplierFavored = 2.0`; all other type/phase pairs = base `1.0`). When `phaseName` is `null` every multiplier is the base, so the branch is phase-agnostic. Multipliers are **discrete per-phase** values; smooth `[0,1]` ramping (hysteresis via `phase_priority_weights.dart`) is deferred.
- **Spy (phase-flat + demand):** Spy uses `kCivilianBuildSpyPhaseFlatMultiplier` (identical across every phase — Spy never follows the economic phase model), plus `kCivilianBuildSpyDemandBoost` when `CivilianBuildScoringInput.spyDemand` is `true` (GP at war or pursuing a tech-steal posture). The Spy min floor is `kCivilianBuildMinSpies` (= `minCount[Spy]`, default `0`).

The scoring math lives in `ai_victory_config.dart` (`civilianBuildCandidateScore`, `civilianBuildPhaseMultiplier`, `isCivilianBuildAtOrAboveMaxCount`). `ObserverGoalPhase.name` ↔ `kCivilianBuildPhase*` key equality is locked by an `colonizethis_ai` contract test (`colonizethis_data` cannot import `colonizethis_ai`).

## Tech prioritization & paper budget (deferred)

The research planner boosts civilian-gating techs (`merchant_companies`, `early_steam_engine`), bounded by `researchPaperReserveShare`. Paper is shared across research, worker training, and civilian builds: reserve research paper up to `researchPaperReserveShare`, then allocate the remainder via the recruitment-planner phase emit order against a running ledger, dropping candidates that would push remaining paper below `0`.

## GA-tunable parameters

Declared in `ai_victory_config.dart` (no planner magic numbers): per-type `minCount`/`maxCount`/`targetCount` maps, `kCivilianBuildBaseScore`, `kCivilianBuildMinCapScoreBoost`, `kCivilianBuildReplacementUrgencyFactor`, the per-phase multiplier map `kCivilianBuildPhaseMultiplierByPhaseType` (with `kCivilianBuildPhaseMultiplierBase` / `kCivilianBuildPhaseMultiplierFavored`), `kCivilianBuildSpyPhaseFlatMultiplier`, `kCivilianBuildSpyDemandBoost`, `kCivilianBuildMinSpies`, plus the deferred pool weight and `researchPaperReserveShare`. Defaults: `minCount` Builder 2 / Explorer 1 / Engineer 1 / others 0; `targetCount` Explorer 2 / Builder 2 / Engineer 1 / others = `minCount`; `maxCount` Builder 6 / Explorer 4 / Engineer 4 / Spy 3 / Merchant 4 / Rail Builder 4; phase favored multiplier 2.0 / base 1.0; Spy phase-flat 1.0; Spy demand boost 2.0.

---

## Implemented vs deferred

- **Slice 1 (enumeration):** `includeCivilianBuilds` on `suggestBuildOrders`; AC1, AC1b, AC5, AC9, AC12.
- **Slice 2 (scoring caps):** additive civilian scoring branch in `pickBuildOrder` (min-cap floor, replacement urgency, max-cap exclusion) via optional `CivilianBuildScoringInput` + GA caps/constants; AC2, AC3, AC10, AC13, ACMax, AC8.
- **Slice 3 (phase multiplier + Spy demand — this slice):** discrete per-phase, per-type multipliers and the Spy phase-flat baseline + demand boost folded into `civilianBuildCandidateScore`, plumbed via `CivilianBuildScoringInput.phaseName` / `.spyDemand`; GA params added; `ObserverGoalPhase.name` key contract test; AC4, AC4b.
- **Deferred:** smooth `[0,1]` phase ramping (hysteresis), paper ledger (AC7), research bias (AC6), live economy wiring (count/phase/demand plumbing + flag flip).

---

## Acceptance criteria

- **AC1 (enumeration):** Given a Great Power with treasury ≥ 1000 and paper ≥ 2, when `suggestBuildOrders` runs with `includeCivilianBuilds: true`, then the returned list includes affordable, tech-unlocked civilian `BuildUnitOrder` candidates (Builder, Engineer, Explorer) alongside military/naval candidates, ordered deterministically by `unitType`.
- **AC1b (opt-out default):** Given the same player, when `suggestBuildOrders` runs with `includeCivilianBuilds` omitted (default `false`), then the returned list contains no civilian-type `BuildUnitOrder` and equals the military+naval-only list.
- **AC5 (tech gate):** Given a Great Power that has not unlocked `merchant_companies`, when `suggestBuildOrders` runs with `includeCivilianBuilds: true`, then the list contains no Merchant candidate; given `merchant_companies` unlocked and affordable, then the list contains a Merchant candidate.
- **AC9 (determinism):** Given identical `(Game, MapTopology, PlayerView, Orders)` and `includeCivilianBuilds: true`, when `suggestBuildOrders` runs twice, then both returned lists are identical in content and order.
- **AC12 (affordability floor):** Given a Great Power with treasury `0` or paper `< 2`, when `suggestBuildOrders` runs with `includeCivilianBuilds: true`, then the list contains no civilian `BuildUnitOrder`.
- **AC2 (scored, selectable):** Given a `Builder` civilian candidate and a regiment candidate with a `CivilianBuildScoringInput` whose `Builder` count equals `targetCount` (2), when `pickBuildOrder` runs, then `Builder` scores the neutral base `1.0` and is in the weighted pool (selectable, not guaranteed).
- **AC3 (min-cap hard floor):** Given a `Builder` count of `0` (below `minBuilders = 2`), when scored, then `civilianBuildCandidateScore('Builder', 0)` equals `kCivilianBuildBaseScore × kCivilianBuildMinCapScoreBoost` (50.0) — far above any military/naval score — and `pickBuildOrder` selects `Builder` over a regiment candidate.
- **AC13 (replacement urgency, distinct from min cap):** Given `minCount = 0`, `targetCount = 2`, when `civilianBuildCandidateScore` is evaluated at count `1`, then the result is `1 + kCivilianBuildReplacementUrgencyFactor × 1 = 1.5`; at count `≥ targetCount` the result is `1.0`.
- **ACMax (max-cap exclusion):** Given a `Builder` count at `maxCount` (6) and a candidate list of that `Builder` plus one regiment, when `pickBuildOrder` runs, then `Builder` is excluded and the regiment is selected.
- **AC10 (no regression — military/naval):** Given a military+naval-only candidate list, when `pickBuildOrder` runs with `CivilianBuildScoringInput` supplied versus omitted, then the selected order is identical.
- **AC8 (GA tunability):** When civilians are scored, the caps and scoring constants (including phase multipliers and the Spy demand boost) are read from `ai_victory_config.dart` (no civilian magic numbers in `build_planner.dart`).
- **AC4 (phase-dependent priority):** Given a non-Spy civilian type and `currentCount = targetCount` (replacement urgency neutral), when `civilianBuildCandidateScore` is evaluated with `phaseName`, then the score equals `kCivilianBuildBaseScore × phaseMultiplier`: in `expand` Builder = `2.0` while Explorer/Engineer/Rail Builder = `1.0`; in `colonial` Explorer = Merchant = `2.0` while Builder/Engineer = `1.0`; in `develop` Engineer = Rail Builder = `2.0` while Builder/Explorer = `1.0`. With `phaseName = null` every non-Spy type scores `1.0`.
- **AC4b (Spy phase-flat + demand):** Given a Spy with `currentCount ≥ targetCount` and `spyDemand = false`, when `civilianBuildCandidateScore` is evaluated for `phaseName` ∈ {`expand`, `colonial`, `develop`}, then the score is identical across all three phases (phase-flat, `kCivilianBuildSpyPhaseFlatMultiplier`). Given `spyDemand = true`, then the Spy score is multiplied by `kCivilianBuildSpyDemandBoost` on top of that phase-flat baseline, and this boost applies to no non-Spy type.
