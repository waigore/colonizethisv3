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
| Builder | `_appendBuilderPathResult` | `build_improvement`, `upgrade_town` |
| Merchant | `_appendMerchantPathResult` | `purchase_land` |
| Rail Builder | `_appendRailBuilderPathResult` | `build_rail` |
| Engineer | `_appendEngineerPathResult` | `build_road`, `build_port`, `build_fort` |
| Spy | `_appendSpyPathResult` | `counter_spy` only (passive RP boost and scouting need no work order) |

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

## Engineer scoring model

`_appendEngineerPathResult` scores every Engineer candidate
(`build_road`, `build_port`, `build_fort`) in a **single unified pool**
(`_engineerWorkScore`) and selects the highest. This replaces the lexicographic
fallback, which always picked `build_fort` first because it sorts alphabetically
before `build_port` / `build_road` regardless of context.

Each target type has its own GA-tunable **baseline** (relative-priority weight);
contextual bonuses (all GA-tunable) then differentiate candidates of the same
target using the same cheap per-tile proxies as the Rail Builder model
(`worldState.resourceByTileKey` non-empty for resource output, tile in the
player's `capitalProvinceId`, tile in the New World region) rather than
path-finding:

```
build_road score = kEngineerBuildRoadBaseWorkScore
      + (tile carries a resource         ? kEngineerRoadResourceConnectivityBonus : 0)
      + (tile in player capital province ? kEngineerRoadCapitalLogisticsBonus     : 0)

build_port score = kEngineerBuildPortBaseWorkScore
      + (tile carries a resource         ? kEngineerPortResourceExtractionBonus   : 0)
      + (tile in New World region        ? kEngineerPortNewWorldCoastalBonus      : 0)

build_fort score = kEngineerBuildFortBaseWorkScore
      + (tile in player capital province ? kEngineerFortCapitalDefenseBonus       : 0)
      + (tile in New World region        ? kEngineerFortNewWorldBorderBonus       : 0)
```

Any non-Engineer target scores `0`; an empty Engineer pool falls back to
`_pickLexicographic`; an idle Engineer with no candidates records a single
`FullAiCivilianWorkIdle(reason: 'no_suggestions')`. Equal scores break via
`_compareEngineerCandidate` — province id, then full tile key, then target — a
stable secondary ordering where the selected candidate is driven by score, not
by the target string's alphabetical position.

## Builder scoring model

`_appendBuilderPathResult` selects via `_bestBuilderRow`, which scores every
`build_improvement` **and** `upgrade_town` candidate in a **single unified pool**
and selects the highest. This replaces the prior behaviour, where `upgrade_town`
was reachable only through the lexicographic fallback (picked only when no
`build_improvement` candidate existed, regardless of context).

`build_improvement` scoring is unchanged (normative in
[economy-planner.md](economy-planner.md) and
[growth-stage-planner.md](growth-stage-planner.md)). `upgrade_town` scoring
(`_upgradeTownWorkScore`) is a GA-tunable baseline plus context bonuses using the
same cheap per-tile proxies as the Rail Builder / Engineer scorers:

```
upgrade_town score = kUpgradeTownBaseWorkScore
      + (tile carries a resource              ? kUpgradeTownResourceValueBonus : 0)
      + (tile in New World region             ? kUpgradeTownFrontlineBonus     : 0)
      + (tile improvement level == 0          ? kUpgradeTownLowDevBonus        : 0)
```

The baseline `kUpgradeTownBaseWorkScore` (300) sits below the
`build_improvement` extractable-resource score (580) so a genuine unimproved
resource extraction still outranks a bare town upgrade, yet above the degenerate
`build_improvement` sentinel scores (`1` already improved, `2` no resource) so a
town upgrade competes when no high-value extraction exists. The unified pool
selects the highest-scoring candidate across **both** target types.

When no `upgrade_town` candidate exists, `_bestBuilderRow` returns the
`build_improvement`-only selection unchanged (no regression). An empty Builder
pool falls back to `_pickLexicographic`; an idle Builder with no candidates
records a single `FullAiCivilianWorkIdle(reason: 'no_suggestions')`. An exact
cross-type score tie breaks via `_compareBuilderCrossType` — province id, then
full tile key, then target — a stable, non-alphabetical-driven ordering.

## Spy scoring model (Refs #3834)

`_appendSpyPathResult` scores only `counter_spy` candidates (`_spyWorkScore`). **`steal_tech` removed** — passive RP boost and scouting require no work order; idle Spies in rival GP territory are positioned via movement, not work selection.

**Empire-wide counter-espionage:** One Spy on `counter_spy` anywhere is sufficient. When the player already has a Spy on `counter_spy`, additional `counter_spy` candidates receive `kSpyCounterSpyBaseWorkScore ~/ 10` so a second assignment is strongly disfavored.

The selector receives `spyDevelopPhase` from the orchestrator (`resolvePhaseEconomyDevelopActive`). In DEVELOP, `kSpyPhaseCounterSpyBonus` is added to `counter_spy` scores.

```
counter_spy score = kSpyCounterSpyBaseWorkScore
      + (foreign-owned Spy in province ? kSpyCounterSpyEnemySpyPresenceBonus : 0)
      + (province == player capital        ? kSpyCounterSpyCapitalBonus          : 0)
      + (province in New World region      ? kSpyCounterSpyBorderBonus           : 0)
      + (DEVELOP phase                     ? kSpyPhaseCounterSpyBonus            : 0)
      — (player already has counter_spy    ? score replaced with base/10         : 0)
```

Enemy-spy presence scans `worldState.allUnitsById` once per pass. Equal scores break via `_compareSpyCandidate` (province id, tile key, target). An empty Spy pool records `FullAiCivilianWorkIdle(reason: 'no_suggestions')`.

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
| `kEngineerBuildRoadBaseWorkScore` | 120 | baseline score for any valid `build_road` candidate |
| `kEngineerBuildPortBaseWorkScore` | 110 | baseline score for any valid `build_port` candidate |
| `kEngineerBuildFortBaseWorkScore` | 100 | baseline score for any valid `build_fort` candidate |
| `kEngineerRoadResourceConnectivityBonus` | 200 | `build_road` on a tile carrying a resource |
| `kEngineerRoadCapitalLogisticsBonus` | 150 | `build_road` on a tile in the player's capital province |
| `kEngineerPortResourceExtractionBonus` | 180 | `build_port` on a tile carrying a resource |
| `kEngineerPortNewWorldCoastalBonus` | 120 | `build_port` on a tile in the New World region |
| `kEngineerFortCapitalDefenseBonus` | 160 | `build_fort` on a tile in the player's capital province |
| `kEngineerFortNewWorldBorderBonus` | 100 | `build_fort` on a tile in the New World region |
| `kUpgradeTownBaseWorkScore` | 300 | baseline score for any valid `upgrade_town` candidate |
| `kUpgradeTownResourceValueBonus` | 200 | `upgrade_town` on a town tile carrying a resource |
| `kUpgradeTownFrontlineBonus` | 150 | `upgrade_town` on a town tile in the New World region |
| `kUpgradeTownLowDevBonus` | 120 | `upgrade_town` on an undeveloped town tile (improvement level 0) |
| `kSpyCounterSpyBaseWorkScore` | 200 | baseline score for any valid `counter_spy` candidate |
| `kSpyCounterSpyEnemySpyPresenceBonus` | 200 | `counter_spy` in a province occupied by a foreign-owned Spy |
| `kSpyCounterSpyCapitalBonus` | 120 | `counter_spy` in the player's capital province |
| `kSpyCounterSpyBorderBonus` | 90 | `counter_spy` in a New World region province (frontier/border proxy) |
| `kSpyPhaseCounterSpyBonus` | 2000 | added to `counter_spy` scores in the DEVELOP phase |

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

- **AC11 (Engineer unified scored selection over mixed targets):**
  Given an idle Engineer whose candidate set contains a `build_road` candidate on
  a tile carrying a resource and a `build_fort` candidate on a plain tile,
  when `selectFullAiCivilianWorkOrders` runs,
  then the system emits exactly one `WorkOrder` whose `target` is `build_road`
  (the higher-scoring candidate), not the alphabetically-first `build_fort`.

- **AC12 (Engineer per-target context bonus):**
  Given an Engineer with two `build_port` candidates that differ only in that one
  tile carries a resource and the other does not,
  when selection runs,
  then the system selects the resource-carrying `build_port` candidate.

- **AC13 (Engineer fort capital-defense bonus):**
  Given an Engineer with two `build_fort` candidates that differ only in that one
  tile lies in the player's capital province and the other does not,
  when selection runs,
  then the system selects the capital-province `build_fort` candidate.

- **AC14 (Engineer non-zero baseline):**
  Given an idle Engineer with a single `build_fort` candidate on a plain Old
  World tile outside the capital,
  when selection runs,
  then the system emits exactly one `WorkOrder` and records no
  `FullAiCivilianWorkIdle` event for that unit.

- **AC15 (Engineer idle when no candidates):**
  Given an idle Engineer with an empty candidate set,
  when selection runs,
  then the system emits no `WorkOrder` and records a single
  `FullAiCivilianWorkIdle` with `reason == 'no_suggestions'` for that unit.

- **AC16 (Engineer deterministic tie-break by province id):**
  Given two equally-scored Engineer candidates of the same target in provinces
  `p1` and `p2` of the same region presented in either input order,
  when selection runs,
  then the system emits the `p1` candidate in both orders (province-id ordering,
  independent of input order).

- **AC17 (Engineer parameters registered):**
  Given the AI parameter registry,
  when `AiParameterRegistry.byName(name)` is called for each of
  `kEngineerBuildRoadBaseWorkScore`, `kEngineerBuildPortBaseWorkScore`,
  `kEngineerBuildFortBaseWorkScore`, `kEngineerRoadResourceConnectivityBonus`,
  `kEngineerRoadCapitalLogisticsBonus`, `kEngineerPortResourceExtractionBonus`,
  `kEngineerPortNewWorldCoastalBonus`, `kEngineerFortCapitalDefenseBonus`, and
  `kEngineerFortNewWorldBorderBonus`,
  then the system returns a non-null `AiParameter` whose `category` equals
  `victory_config`.

- **AC18 (Builder unified scored selection over mixed targets):**
  Given an idle Builder whose candidate set contains an `upgrade_town` candidate
  on a tile carrying a resource and a `build_improvement` candidate on an
  already-improved tile (improvement level `>= 1`, score `1`),
  when `selectFullAiCivilianWorkOrders` runs,
  then the system emits exactly one `WorkOrder` whose `target` is `upgrade_town`
  (the higher-scoring candidate), not the alphabetically-first
  `build_improvement`.

- **AC19 (Builder build_improvement still outranks bare town upgrade):**
  Given an idle Builder with a `build_improvement` candidate on an unimproved
  resource tile (score `>= kBuildImprovementExtractableResourceScore`) and a
  plain `upgrade_town` candidate (baseline only),
  when selection runs,
  then the system emits the `build_improvement` `WorkOrder`.

- **AC20 (upgrade_town context bonus):**
  Given a Builder with two `upgrade_town` candidates that differ only in that one
  town tile carries a resource and the other does not,
  when selection runs,
  then the system selects the resource-carrying `upgrade_town` candidate.

- **AC21 (upgrade_town deterministic non-alphabetical tie-break):**
  Given two equally-scored `upgrade_town` candidates in provinces `p1` and `p2`
  of the same region presented in either input order,
  when selection runs,
  then the system emits the `p1` candidate in both orders (province-id ordering,
  independent of input order).

- **AC22 (upgrade_town parameters registered):**
  Given the AI parameter registry,
  when `AiParameterRegistry.byName(name)` is called for each of
  `kUpgradeTownBaseWorkScore`, `kUpgradeTownResourceValueBonus`,
  `kUpgradeTownFrontlineBonus`, and `kUpgradeTownLowDevBonus`,
  then the system returns a non-null `AiParameter` whose `category` equals
  `victory_config`.

- **AC23 (Spy empire-wide counter_spy — second assignment disfavored):**
  Given an idle Spy whose candidate set contains two `counter_spy` candidates and
  another Spy of the same player is already on `counter_spy`,
  when `selectFullAiCivilianWorkOrders` runs,
  then the system emits at most one `WorkOrder` (additional counter-spy sharply
  reduced).

- **AC24 (Spy phase preference — DEVELOP prefers counter_spy):**
  Given an idle Spy with one `counter_spy` candidate and `spyDevelopPhase == true`,
  when `selectFullAiCivilianWorkOrders` runs,
  then the system emits exactly one `WorkOrder` whose `target` is `counter_spy`.

- **AC25 (counter_spy enemy-spy-presence bonus):**
  Given a Spy with two `counter_spy` candidates that differ only in that one owned
  province is occupied by a foreign-owned Spy and the other is not,
  when selection runs,
  then the system selects the `counter_spy` candidate in the province occupied by
  the foreign-owned Spy.

- **AC26 (Spy non-zero baseline):**
  Given an idle Spy with a single `counter_spy` candidate on a plain Old World
  owned province (no enemy spy, not the capital),
  when selection runs,
  then the system emits exactly one `WorkOrder` and records no
  `FullAiCivilianWorkIdle` event for that unit.

- **AC27 (Spy idle when no candidates):**
  Given an idle Spy with an empty candidate set,
  when selection runs,
  then the system emits no `WorkOrder` and records a single
  `FullAiCivilianWorkIdle` with `reason == 'no_suggestions'` for that unit.

- **AC28 (Spy deterministic tie-break by province id):**
  Given two equally-scored Spy candidates of the same target in provinces `p1`
  and `p2` presented in either input order,
  when selection runs,
  then the system emits the `p1` candidate in both orders (province-id ordering,
  independent of input order and of the target string).

- **AC29 (Spy parameters registered):**
  Given the AI parameter registry,
  when `AiParameterRegistry.byName(name)` is called for each of
  `kSpyCounterSpyBaseWorkScore`, `kSpyCounterSpyEnemySpyPresenceBonus`,
  `kSpyCounterSpyCapitalBonus`, `kSpyCounterSpyBorderBonus`,
  and `kSpyPhaseCounterSpyBonus`,
  then the system returns a non-null `AiParameter` whose `category` equals
  `victory_config`.

- **AC30 (Spy phase wiring — live DEVELOP prefers counter_spy):**
  Given the economy build pass runs for an idle Spy with a `counter_spy`
  candidate and the dispatched `PhasePlanOutcome` resolves
  `resolvePhaseEconomyDevelopActive` to `true`,
  when the orchestrator calls `selectFullAiCivilianWorkOrders`,
  then the orchestrator passes `spyDevelopPhase: true` and the emitted Spy
  `WorkOrder` has `target == counter_spy`.

## Deferred (follow-up work for #3794)

All civilian unit types (Explorer, Builder, Merchant, Rail Builder, Engineer,
Spy) now have dedicated scored selection paths. No civilian-work scoring slices
of #3794 remain deferred.
