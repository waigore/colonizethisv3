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
| Spy | `_appendSpyPathResult` | `steal_tech`, `counter_spy` |

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

## Spy scoring model

`_appendSpyPathResult` scores every Spy candidate (`steal_tech` and
`counter_spy`) in a **single unified pool** (`_spyWorkScore`) and selects the
highest. This replaces the lexicographic fallback, which always picked
`counter_spy` first because it sorts alphabetically before `steal_tech`
regardless of context or phase.

Spy selection is **phase-dependent** (Refs #3794 design decision #8): the
selector receives a single `spyDevelopPhase` flag from the orchestrator
(`domain_planner_orchestrator_economy.dart`, derived from the dispatched phase
plan via `resolvePhaseEconomyDevelopActive`). In the DEVELOP phase `counter_spy`
is preferred; in every other phase (EXPAND / COLONIAL / COLONIAL-lite)
`steal_tech` is preferred. The preference is expressed as a GA-tunable phase
bonus added to the preferred target type, sized to dominate the contextual
bonuses of the other target type so the phase choice is decisive while context
still differentiates candidates of the same target.

`steal_tech` targets a rival Great Power capital province (the suggestion yields
one candidate per rival GP capital). `counter_spy` targets one of the player's
own provinces. Both use cheap, deterministic proxies (no per-tile path-finding),
consistent with the budget rule:

```
steal_tech score = kSpyStealTechBaseWorkScore
      + min(techDeficit, 60) * kSpyStealTechTechDeficitWeight
      + (relations hostile: at war OR relation score <= 25 ? kSpyStealTechHostileRelationsBonus : 0)
      + (rival capital region == spy region              ? kSpyStealTechProximityBonus        : 0)
      + (NOT DEVELOP phase                               ? kSpyPhaseStealTechBonus            : 0)

counter_spy score = kSpyCounterSpyBaseWorkScore
      + (a foreign-owned Spy occupies the province ? kSpyCounterSpyEnemySpyPresenceBonus : 0)
      + (province == player capital province       ? kSpyCounterSpyCapitalBonus          : 0)
      + (province in New World region              ? kSpyCounterSpyBorderBonus           : 0)
      + (DEVELOP phase                             ? kSpyPhaseCounterSpyBonus            : 0)
```

`techDeficit` is the count of tech ids the rival GP has unlocked
(`Player.techUnlocked[id] == true`) that the player has not, capped at `60` for
determinism/budget. The cap and `kSpyStealTechTechDeficitWeight` keep the
non-phase `steal_tech` ceiling below `kSpyPhaseStealTechBonus`. Era weighting of
missing techs is intentionally **not** modelled (cheap-proxy decision; the
deficit count stands in for tech value). Hostile relations use the read-only
`getRelation` / `factionsAtWar` world lookups (expando-cached per `Game`); a
rival counts as hostile when at war or when the decimal relation score is in the
0-25 Hostile band (scores are `[0, 100]` with 50 neutral, so a lower score means
worse relations).
Enemy-spy presence is a ground-truth scan of `worldState.allUnitsById` for a
foreign-owned `Spy` whose `locationProvinceId` equals the candidate province,
precomputed once per selection pass (consistent with the observer AI reading
ground-truth `worldState` like the Rail Builder / Engineer scorers).

Any non-Spy target scores `0`; an empty Spy pool falls back to
`_pickLexicographic`; an idle Spy with no candidates records a single
`FullAiCivilianWorkIdle(reason: 'no_suggestions')`. Equal scores break via
`_compareSpyCandidate` — province id, then full tile key, then target — a stable
secondary ordering where the selected candidate is driven by score, not by the
target string's alphabetical position.

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
| `kSpyStealTechBaseWorkScore` | 200 | baseline score for any valid `steal_tech` candidate |
| `kSpyStealTechTechDeficitWeight` | 10 | per-tech bonus for each tech the rival has unlocked that the player lacks (deficit capped at 60) |
| `kSpyStealTechHostileRelationsBonus` | 150 | `steal_tech` toward a rival the player is at war with or whose relation score is in the 0-25 Hostile band |
| `kSpyStealTechProximityBonus` | 90 | `steal_tech` whose rival capital is in the same region as the Spy |
| `kSpyCounterSpyBaseWorkScore` | 200 | baseline score for any valid `counter_spy` candidate |
| `kSpyCounterSpyEnemySpyPresenceBonus` | 200 | `counter_spy` in a province occupied by a foreign-owned Spy |
| `kSpyCounterSpyCapitalBonus` | 120 | `counter_spy` in the player's capital province |
| `kSpyCounterSpyBorderBonus` | 90 | `counter_spy` in a New World region province (frontier/border proxy) |
| `kSpyPhaseStealTechBonus` | 2000 | added to `steal_tech` scores outside the DEVELOP phase (decisive phase preference) |
| `kSpyPhaseCounterSpyBonus` | 2000 | added to `counter_spy` scores in the DEVELOP phase (decisive phase preference) |

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

- **AC23 (Spy phase preference — non-DEVELOP prefers steal_tech):**
  Given an idle Spy whose candidate set contains one `steal_tech` candidate (in a
  rival GP capital) and one `counter_spy` candidate (in the player's own
  province), and `spyDevelopPhase == false`,
  when `selectFullAiCivilianWorkOrders` runs,
  then the system emits exactly one `WorkOrder` whose `target` is `steal_tech`.

- **AC24 (Spy phase preference — DEVELOP prefers counter_spy):**
  Given the same idle Spy candidate set as AC23 but `spyDevelopPhase == true`,
  when `selectFullAiCivilianWorkOrders` runs,
  then the system emits exactly one `WorkOrder` whose `target` is `counter_spy`,
  not the alphabetically-later `steal_tech`.

- **AC25 (steal_tech tech-deficit scoring):**
  Given (outside DEVELOP) a Spy with two `steal_tech` candidates targeting two
  rival GP capitals identical except that rival A has unlocked more techs the
  player lacks than rival B,
  when selection runs,
  then the system selects the `steal_tech` candidate targeting rival A's capital.

- **AC26 (steal_tech hostile-relations bonus):**
  Given (outside DEVELOP) a Spy with two `steal_tech` candidates that differ only
  in that the player is at war with one rival and at peace with the other,
  when selection runs,
  then the system selects the `steal_tech` candidate targeting the at-war rival.

- **AC27 (counter_spy enemy-spy-presence bonus):**
  Given (in DEVELOP) a Spy with two `counter_spy` candidates that differ only in
  that one owned province is occupied by a foreign-owned Spy and the other is not,
  when selection runs,
  then the system selects the `counter_spy` candidate in the province occupied by
  the foreign-owned Spy.

- **AC28 (Spy non-zero baseline):**
  Given an idle Spy with a single `counter_spy` candidate on a plain Old World
  owned province (no enemy spy, not the capital),
  when selection runs,
  then the system emits exactly one `WorkOrder` and records no
  `FullAiCivilianWorkIdle` event for that unit.

- **AC29 (Spy idle when no candidates):**
  Given an idle Spy with an empty candidate set,
  when selection runs,
  then the system emits no `WorkOrder` and records a single
  `FullAiCivilianWorkIdle` with `reason == 'no_suggestions'` for that unit.

- **AC30 (Spy deterministic tie-break by province id):**
  Given two equally-scored Spy candidates of the same target in provinces `p1`
  and `p2` presented in either input order,
  when selection runs,
  then the system emits the `p1` candidate in both orders (province-id ordering,
  independent of input order and of the target string).

- **AC31 (Spy parameters registered):**
  Given the AI parameter registry,
  when `AiParameterRegistry.byName(name)` is called for each of
  `kSpyStealTechBaseWorkScore`, `kSpyStealTechTechDeficitWeight`,
  `kSpyStealTechHostileRelationsBonus`, `kSpyStealTechProximityBonus`,
  `kSpyCounterSpyBaseWorkScore`, `kSpyCounterSpyEnemySpyPresenceBonus`,
  `kSpyCounterSpyCapitalBonus`, `kSpyCounterSpyBorderBonus`,
  `kSpyPhaseStealTechBonus`, and `kSpyPhaseCounterSpyBonus`,
  then the system returns a non-null `AiParameter` whose `category` equals
  `victory_config`.

- **AC32 (Spy phase wiring — live DEVELOP prefers counter_spy):**
  Given the economy build pass (`domain_planner_orchestrator_economy.dart`)
  runs for an idle Spy whose suggested candidate set contains one `steal_tech`
  candidate (in a rival GP capital) and one `counter_spy` candidate (in the
  player's own province), and the dispatched `PhasePlanOutcome` resolves
  `resolvePhaseEconomyDevelopActive` to `true`,
  when the orchestrator calls `selectFullAiCivilianWorkOrders`,
  then the orchestrator passes `spyDevelopPhase: true` and the emitted Spy
  `WorkOrder` has `target == counter_spy`.

- **AC33 (Spy phase wiring — live non-DEVELOP prefers steal_tech):**
  Given the same orchestrator pass and Spy candidate set as AC32 but the
  dispatched `PhasePlanOutcome` resolves `resolvePhaseEconomyDevelopActive` to
  `false` (e.g. EXPAND),
  when the orchestrator calls `selectFullAiCivilianWorkOrders`,
  then the orchestrator passes `spyDevelopPhase: false` and the emitted Spy
  `WorkOrder` has `target == steal_tech`.

## Deferred (follow-up work for #3794)

All civilian unit types (Explorer, Builder, Merchant, Rail Builder, Engineer,
Spy) now have dedicated scored selection paths. No civilian-work scoring slices
of #3794 remain deferred.
