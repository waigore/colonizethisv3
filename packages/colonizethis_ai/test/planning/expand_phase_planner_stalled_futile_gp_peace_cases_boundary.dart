// Case bodies for `expand_phase_planner_stalled_futile_gp_and_tribe_distraction_peace_test.dart` (Refs #3977 Phase 6).
// Registered from the thin contract file of the same stem.
// Pin/row coverage is preserved 1:1 from the former inline suite.

// Pins the canonical `stalledFutileGpPeaceTargets` and
// `atWarGpDistractionTribePeaceTargets` EXPAND-stalled peace deciders in
// `expand_phase_planner.dart` (Refs #2509 S1).
//
// Both deciders were relocated from
// `diplomacy_planner_peace_targets.dart` so they survive the planned
// S1 deletion of that file. The canonical implementations live in
// `expand_phase_planner.dart`; `diplomacy_planner_peace_targets.dart`
// previously retained thin delegating stubs for legacy callers (the existing
// `diplomacy_planner_stalled_peace_test.dart` § `stalledFutileGpPeaceTargets`
// fixture and the `_expandRatchetGreatPowerPeaceTargets` /
// `collectStalledGreatPowerPeaceTargets` /
// `stalledOwExpansionNeedsPeacePass` consumer chains within
// `diplomacy_planner_peace_targets.dart` itself) until the planned
// deletion.
//
// Live consumers (post-relocation):
//   * `stalledFutileGpPeaceTargets` is the EXPAND-stalled shortcut
//     that peaces every at-war Great Power that owns no invadable OW
//     province while at least one minor still holds invadable land,
//     so regiments concentrate on the active minor frontier.
//   * `atWarGpDistractionTribePeaceTargets` is the EXPAND-stalled
//     shortcut that peaces every at-war tribe while at least one
//     Great Power is on the same map, so regiments concentrate on
//     the OW consolidation push instead of bleeding into tribe
//     fronts.
//
// Behavioral invariants pinned here (all deterministic — Must-have #7):
//
// `stalledFutileGpPeaceTargets`:
//   1. Returns `const []` for each outer guard in order:
//      a. `!isStalledOldWorldExpansion(oldWorldProvincesOwned)`
//         — above the stalled OW band the above-quota collectors
//         own the decision.
//      b. `invadableProvinceIdsSorted` is empty — no OW invasion
//         target so a futile-GP diagnosis cannot fire.
//      c. No minor owns any invadable OW province — the frontier
//         is GP-only / unowned, so the
//         `stalledGpBlockerFocusPeaceTargets` collector owns the
//         decision instead.
//   2. When the guards pass, every at-war Great Power in
//      `threats.atWarWith` (filtered via `Game.playerById`) that
//      owns **no** province in `invadableProvinceIdsSorted` is
//      peaced; GPs that own at least one invadable OW province are
//      kept at war (active blockers). Returned in ascending lex
//      order over the GP `factionId`s.
//
// `atWarGpDistractionTribePeaceTargets`:
//   1. Returns `const []` for each outer guard in order:
//      a. `!isStalledOldWorldExpansion(oldWorldProvincesOwned)`
//         — above the stalled OW band the GP-distraction tribe
//         shortcut does not apply.
//      b. No at-war Great Power present in `threats.atWarWith` —
//         without an active GP front the tribe peace is not
//         justified.
//   2. When the guards pass, every at-war tribe in
//      `threats.atWarWith` (membership tested via `Game.tribes`)
//      is peaced. Minors and at-war Great Powers are filtered out.
//      Returned in ascending lex order over the tribe `factionId`s.
//
// Delegation parity:
//   3. The delegating stubs in
//      `diplomacy_planner_peace_targets.dart` return the same
//      values as the canonical helpers for every relevant input —
//      required so the legacy `diplomacy_planner_stalled_peace_test.dart`
//      fixture and the `_expandRatchetGreatPowerPeaceTargets` /
//      `collectStalledGreatPowerPeaceTargets` consumer chains agree
//      on both deciders.

// ignore_for_file: unused_element
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';

const String _gpOwn = 'gp_own';
const String _gpRivalA = 'gp_rival_a';
const String _gpRivalB = 'gp_rival_b';
const String _minor1 = 'minor1';
const String _tribeA = 'tribe_a';

void registerExpandPhasePlannerStalledFutileGpPeaceBoundaryCases() {
  group('stalledFutileGpPeaceTargets — band boundaries', () {
    test('fires at the upper inclusive boundary of the stalled OW band', () {
      // own == kStalledOldWorldProvinceThreshold (still stalled).
      // The decider must run normally and surface the futile GP.
      const minor1Pid = 'oldWorld|${_minor1}_active';
      final game = buildStalledFutileExpandPeaceGame(
        ownProvinces: kStalledOldWorldProvinceThreshold,
        gpRivalProvincesById: const {_gpRivalA: []},
        minorOwProvincesByMinorId: const {
          _minor1: [minor1Pid],
        },
        atWarFactionIds: const [_gpRivalA],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
        atWarWith: const [_gpRivalA],
        invadableProvinceIdsSorted: const [minor1Pid],
      );
      expect(
        stalledFutileGpPeaceTargets(game: game, snapshot: snapshot),
        const [_gpRivalA],
        reason:
            'A regression that flipped the stalled-OW guard to a '
            'strict-less-than would short-circuit at the upper '
            'inclusive boundary and leave the futile GP war open.',
      );
    });
  });
}
