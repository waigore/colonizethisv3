# Civilian work planner

Refs #3794. Authoritative SPEC for Full-AI **civilian work selection** — how a
deterministic AI picks which `WorkOrder` each idle civilian (Builder, Explorer,
Merchant, Engineer, Rail Builder, Spy) acts on from the candidate set produced by
`suggestWorkOrders`.

## Purpose

`selectFullAiCivilianWorkOrders`
(`packages/colonizethis_ai_contracts/lib/src/ai/full_ai_civilian_work_selection.dart`)
re-ranks already-suggested work candidates per unit and emits at most one
`WorkOrder` per idle civilian. It never invents candidates and never bypasses
suggestion, validation, or affordability gates; it only **orders** existing
candidates and selects the highest-scoring one, with a deterministic
lexicographic tie-break by `(target, targetTileKey)`.

Candidate enumeration is normative in
[../program/order-suggestions.md](../program/order-suggestions.md); this document
governs **selection scoring** only.

## Per-unit selection paths

| Unit type | Scored path | Targets scored |
|-----------|-------------|----------------|
| Explorer | `_appendExplorerPathResult` | `explore`, `prospect` |
| Builder | `_appendBuilderPathResult` | `build_improvement` |
| Merchant | `_appendMerchantPathResult` | `purchase_land` |
| Rail Builder | `_appendRailBuilderPathResult` | `build_rail` |
| Engineer / Spy | lexicographic fallback | none (see Deferred) |

A unit type with no dedicated scorer falls through to a deterministic
lexicographic fallback (`_pickLexicographic`), and an unrecognized unit type uses
the same fallback without raising an exception.

## Rail Builder scoring model

`_appendRailBuilderPathResult` scores every `build_rail` candidate in a single
pool (`_buildRailWorkScore`) and selects the highest. A candidate score is the
sum of a baseline plus context bonuses (all GA-tunable):

```
score = kBuildRailBaseWorkScore
      + (tile carries a resource         ? kBuildRailResourceOutputBonus   : 0)
      + (tile in player capital province ? kBuildRailCapitalConnectorBonus : 0)
      + (tile in New World region        ? kBuildRailNewWorldBonus         : 0)
```

Resource output uses the cheap per-tile proxy `worldState.resourceByTileKey`
(non-empty) rather than path-finding; capital-connector uses the proxy "tile in
the player's `capitalProvinceId`". Non-`build_rail` orders score `0`; an empty
pool falls back to `_pickLexicographic`; an idle Rail Builder with no candidates
records a single `FullAiCivilianWorkIdle(reason: 'no_suggestions')`.

Equal scores break via `_compareRailCandidate` — province id first, then full
tile key — a stable, **non-alphabetical** secondary ordering.

## GA-tunable scoring parameters

All civilian-work score boosts are **GA-tunable** constants declared in
`packages/colonizethis_data/lib/src/ai_victory_config.dart` and registered in
`ai_parameter_registry.dart` (category `victory_config`). Each preserves the
value previously hard-coded as a planner-internal constant, so behaviour is
unchanged at default values.

| Parameter | Default | Applies to |
|-----------|---------|------------|
| `kRegimentBuildInputFeedstockExtractionScoreBoost` | 600 | `build_improvement` on an unimproved feedstock tile under the feedstock-extraction gate |
| `kGrowthStageFabricFeedstockScoreBoost` | 700 | `build_improvement` on an unimproved fabric feedstock tile (growth-stage) |
| `kGrowthStageInfraFeedstockScoreBoost` | 520 | `build_improvement` on an unimproved infrastructure feedstock tile (growth-stage) |
| `kFeedstockMineralProspectScoreBoost` | 600 | `prospect` on an unprospected mineral feedstock tile under the feedstock-extraction gate |
| `kBuildRailBaseWorkScore` | 100 | baseline score for any valid `build_rail` candidate |
| `kBuildRailResourceOutputBonus` | 200 | `build_rail` on a road tile carrying a resource |
| `kBuildRailCapitalConnectorBonus` | 150 | `build_rail` on a road tile in the player's capital province |
| `kBuildRailNewWorldBonus` | 80 | `build_rail` on a road tile in the New World region |

The feedstock-extraction and growth-stage gates that decide when each boost
applies are unchanged; they remain self-clearing pure functions of
`(game, playerId)` and the static catalogs. Detailed gate behaviour is normative
in [economy-planner.md](economy-planner.md) (seller / supplier feedstock
extraction) and [growth-stage-planner.md](growth-stage-planner.md) (fabric /
infrastructure feedstock routing).

## Acceptance criteria

- **AC1 (parameters registered):**
  Given the AI parameter registry,
  when `AiParameterRegistry.byName(name)` is called for each of
  `kRegimentBuildInputFeedstockExtractionScoreBoost`,
  `kGrowthStageFabricFeedstockScoreBoost`,
  `kGrowthStageInfraFeedstockScoreBoost`, and
  `kFeedstockMineralProspectScoreBoost`,
  then the system returns a non-null `AiParameter` whose `category` equals
  `victory_config` and whose `isInteger` is `true`.

- **AC2 (defaults preserved):**
  Given the AI victory config,
  when the four feedstock-boost constants are read,
  then their values equal `600`, `700`, `520`, and `600` respectively, and
  `AiParameterRegistry.defaults[name]` equals each constant.

- **AC3 (registry bounds rule):**
  Given each of the four registered feedstock-boost parameters,
  when its bounds are inspected,
  then `minValue == 0` and `maxValue == max(2000, 4 × defaultValue)`.

- **AC4 (behaviour preserved):**
  Given identical game state, player id, and feedstock gate inputs,
  when `selectFullAiCivilianWorkOrders` runs,
  then the emitted `WorkOrder`s are identical to the pre-migration selection
  (the existing feedstock-extraction, mineral-prospect, and growth-stage
  selection tests pass unchanged).

- **AC5 (Rail Builder unified scored selection):**
  Given a Rail Builder with two `build_rail` candidates where one road tile
  carries a resource and the other does not,
  when `selectFullAiCivilianWorkOrders` runs,
  then the system emits exactly one `build_rail` `WorkOrder` whose
  `targetTileKey` is the resource-carrying tile.

- **AC6 (Rail Builder context bonuses):**
  Given two equally-baselined `build_rail` candidates that differ only by a
  single context factor (capital province, or New World region),
  when selection runs,
  then the system selects the candidate that satisfies that factor
  (capital-province tile, or New World tile, respectively).

- **AC7 (Rail Builder non-zero baseline):**
  Given an idle Rail Builder with a single `build_rail` candidate that carries
  no resource, is not in the capital, and is in the Old World,
  when selection runs,
  then the system emits exactly one `WorkOrder` and records no
  `FullAiCivilianWorkIdle` event for that unit.

- **AC8 (Rail Builder deterministic non-alphabetical tie-break):**
  Given two equally-scored `build_rail` candidates in provinces `p1` and `p2`
  of the same region presented in either input order,
  when selection runs,
  then the system emits the `p1` candidate in both orders (province-id
  ordering, independent of the target string).

- **AC9 (Rail Builder idle when no candidates):**
  Given an idle Rail Builder with an empty candidate set,
  when selection runs,
  then the system emits no `WorkOrder` and records a single
  `FullAiCivilianWorkIdle` with `reason == 'no_suggestions'` for that unit.

- **AC10 (Rail Builder parameters registered):**
  Given the AI parameter registry,
  when `AiParameterRegistry.byName(name)` is called for each of
  `kBuildRailBaseWorkScore`, `kBuildRailResourceOutputBonus`,
  `kBuildRailCapitalConnectorBonus`, and `kBuildRailNewWorldBonus`,
  then the system returns a non-null `AiParameter` whose `category` equals
  `victory_config`.

## Deferred (follow-up work for #3794)

The following remain on the lexicographic fallback and are **not** yet scored;
they are tracked by #3794 and will be specified here when implemented:

- Builder `upgrade_town` unified scoring.
- Engineer `build_road` / `build_port` / `build_fort` unified scoring.
- Spy `steal_tech` / `counter_spy` phase-dependent scoring.

When those scorers land, their weights are added to `ai_victory_config.dart` /
`ai_parameter_registry.dart` following the GA-tunable pattern above.
