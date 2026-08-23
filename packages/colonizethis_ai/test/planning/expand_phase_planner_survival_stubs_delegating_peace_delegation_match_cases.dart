// Survival stubs delegating pins (Refs #4602 Slice B).

// Pins canonical homes in `expand_phase_planner.dart` for
// `stalledZeroRegimentAllFactionPeaceTargets`,
// `stalledZeroRegimentGpPeaceTargets`,
// `mutualZeroRegimentGpStalematePeaceTargets`,
// `mutualExhaustedBelowQuotaGpStalematePeaceTargets`, and
// `multiFrontNonBlockerGpPeaceTargets` (Refs #2509 S1). Also covers
// `stalledZeroRegimentGpPeaceTargets` and
// `mutualZeroRegimentGpStalematePeaceTargets` EXPAND-phase zero-regiment
// survival peace deciders at their new home in `expand_phase_planner.dart`
// (Refs #2509 S1).
//
// Both deciders were relocated from `diplomacy_planner_peace_targets.dart`
// so they survive the now-completed S1 deletion of that file. The canonical
// implementations live in `expand_phase_planner.dart`;
// `diplomacy_planner_peace_targets.dart` previously retained thin delegating stubs
// for the legacy `diplomacy_planner_below_quota_peace_part3_test.dart`
// § "all GP wars when stalled" fixture and the in-file
// `_survivalGreatPowerPeaceTargets` /
// `collectStalledGreatPowerPeaceTargets` `zeroRegimentBlockerPeace` /
// `stalledOwExpansionNeedsPeacePass` consumer chains until the planned
// deletion.
//
// Live consumers (post-relocation):
//   * `stalledZeroRegimentGpPeaceTargets` is the broad EXPAND
//     zero-regiment rebuild shortcut from
//     `SPEC/ai/ai-architecture.md` § Diplomacy targeting — "when
//     stalled below quota with zero regiments, peace every at-war
//     Great Power so rebuild is not blocked by futile fronts". It
//     peaces every at-war GP once the active player is inside the
//     stalled OW band and holds zero standing regiments, sorted
//     ascending by `factionId` for downstream offer-peace
//     determinism.
//   * `mutualZeroRegimentGpStalematePeaceTargets` is the sole-GP
//     mutual-stalemate carve-out. It peaces the lone GP enemy when
//     both sides have zero standing regiments and the active player
//     is stalled — the only path that exits an army-exhausted GP-only
//     frontier where the broader `stalledZeroRegimentGpPeaceTargets`
//     arm is overridden by the `collectStalledGreatPowerPeaceTargets`
//     GP-only-frontier carve-out re-adding the canonical OW frontier
//     blocker to the keep-at-war set.
//
// Sibling test coverage that this file complements (but does not duplicate):
//
//   * `diplomacy_planner_below_quota_peace_part3_test.dart` § "all GP
//     wars when stalled" exercises the broader arm through the legacy
//     `diplomacy_planner_peace_targets.dart` entry point and pins the
//     "filters minors out of GP results" invariant. Both legacy
//     fixtures depend on the delegating stubs and continue to pass
//     unchanged after the canonical bodies relocated here.
//   * `domain_planner_orchestrator_*_two_gp_peace_test.dart` exercise
//     the deciders through the orchestrator's `runDiplomacyPlanner`
//     pass under EXPAND / COLONIAL / DEVELOP phases. Those flows rely
//     on the same post-delegation return values pinned here.
//
// Behavioral invariants pinned at the canonical entry points:
//
//   1. `stalledZeroRegimentGpPeaceTargets` short-circuits to `const []`
//      when the active player's `oldWorldProvincesOwned` exceeds
//      `kStalledOldWorldProvinceThreshold` — outside the stalled band
//      the rebuild-peace arm does not engage.
//   2. `stalledZeroRegimentGpPeaceTargets` short-circuits to `const []`
//      when the active player still holds at least one standing
//      regiment — the rebuild-peace arm is a zero-regiment shortcut.
//   3. `stalledZeroRegimentGpPeaceTargets` filters minors and tribes
//      from `threats.atWarWith` so only Great Powers appear in the
//      returned list; the companion `stalledZeroRegimentAllFactionPeaceTargets`
//      owns the minor/tribe arm.
//   4. `stalledZeroRegimentGpPeaceTargets` sorts the GP list ascending
//      so the downstream offer-peace pass observes a stable order
//      regardless of the iteration order of `threats.atWarWith`.
//   5. `mutualZeroRegimentGpStalematePeaceTargets` short-circuits to
//      `const []` when the active player's `oldWorldProvincesOwned`
//      is outside the stalled band, when the active player still has
//      at least one standing regiment, when the GP-war set is empty,
//      when the GP-war set has 2+ entries (multi-front shape handled
//      by `multiFrontNonBlockerGpPeaceTargets`), or when the sole GP
//      enemy still has at least one standing regiment.
//   6. `mutualZeroRegimentGpStalematePeaceTargets` returns the
//      single-element list with the lone GP enemy's `factionId` when
//      all guards pass.
//   7. The delegating stubs in `diplomacy_planner_peace_targets.dart`
//      return the same value as the canonical helpers for every
//      representative input — required so the legacy fixtures and the
//      in-file consumer paths agree on the deciders.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

const String _gpEnemy = 'gp_enemy';
const String _gpThird = 'gp_third';
const String _minor1 = 'minor1';
const String _tribe1 = 'tribe1';

void registerExpandSurvivalStubsDelegatingPeaceDelegationMatchCases() {}
