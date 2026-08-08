// Case bodies for `expand_phase_planner_stalled_futile_gp_and_tribe_distraction_peace_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Topic-split case module (Refs #3997 Phase 8).
// Pin/row coverage preserved 1:1 from the former combined cases file.

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

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

const String _gpOwn = 'gp_own';
const String _gpRivalA = 'gp_rival_a';
const String _gpRivalB = 'gp_rival_b';
const String _minor1 = 'minor1';
const String _tribeA = 'tribe_a';
const String _tribeB = 'tribe_b';


void registerExpandTribeDistractionPeaceStubCases() {
  group('diplomacy_planner_peace_targets stub delegation equality scan', () {
    test(
      'stalledFutileGpPeaceTargets stub mirrors canonical across fixtures',
      () {
        const minor1Pid = 'oldWorld|${_minor1}_active';
        const rivalAPid = 'oldWorld|${_gpRivalA}_blocker';
        final fixtures = <({String name, Game game, AIWorldSnapshot snapshot})>[
          (
            name: 'fire path, futile GP and active GP blocker',
            game: buildStalledFutileExpandPeaceGame(
              ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
              gpRivalProvincesById: const {
                _gpRivalA: [rivalAPid],
                _gpRivalB: [],
              },
              minorOwProvincesByMinorId: const {
                _minor1: [minor1Pid],
              },
              atWarFactionIds: const [_gpRivalA, _gpRivalB],
            ),
            snapshot: ownSnapshot(
              oldWorldProvincesOwned:
                  kObserverDefaultStartOldWorldProvincesPerGp,
              atWarWith: const [_gpRivalB, _gpRivalA],
              invadableProvinceIdsSorted: const [minor1Pid, rivalAPid],
            ),
          ),
          (
            name: 'above-quota guard',
            game: buildStalledFutileExpandPeaceGame(
              ownProvinces: kObserverConquestMinOwProvincesPerGp,
              gpRivalProvincesById: const {_gpRivalA: []},
              minorOwProvincesByMinorId: const {
                _minor1: ['oldWorld|${_minor1}_active'],
              },
              atWarFactionIds: const [_gpRivalA],
            ),
            snapshot: ownSnapshot(
              oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
              atWarWith: const [_gpRivalA],
              invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_active'],
            ),
          ),
          (
            name: 'empty invadable guard',
            game: buildStalledFutileExpandPeaceGame(
              ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
              gpRivalProvincesById: const {_gpRivalA: []},
              atWarFactionIds: const [_gpRivalA],
            ),
            snapshot: ownSnapshot(
              oldWorldProvincesOwned:
                  kObserverDefaultStartOldWorldProvincesPerGp,
              atWarWith: const [_gpRivalA],
              invadableProvinceIdsSorted: const [],
            ),
          ),
          (
            name: 'GP-only invadable guard (no minor on frontier)',
            game: buildStalledFutileExpandPeaceGame(
              ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
              gpRivalProvincesById: const {
                _gpRivalA: [rivalAPid],
                _gpRivalB: [],
              },
              atWarFactionIds: const [_gpRivalA, _gpRivalB],
            ),
            snapshot: ownSnapshot(
              oldWorldProvincesOwned:
                  kObserverDefaultStartOldWorldProvincesPerGp,
              atWarWith: const [_gpRivalA, _gpRivalB],
              invadableProvinceIdsSorted: const [rivalAPid],
            ),
          ),
        ];
        for (final fx in fixtures) {
          final canonical = stalledFutileGpPeaceTargets(
            game: fx.game,
            snapshot: fx.snapshot,
          );
          final stub = diplomacy_peace_targets.stalledFutileGpPeaceTargets(
            game: fx.game,
            snapshot: fx.snapshot,
          );
          expect(
            stub,
            canonical,
            reason:
                'Delegating stub must mirror the canonical helper for '
                'fixture "${fx.name}".',
          );
        }
      },
    );

    test('atWarGpDistractionTribePeaceTargets stub mirrors canonical '
        'across fixtures', () {
      final fixtures = <({String name, Game game, AIWorldSnapshot snapshot})>[
        (
          name: 'fire path, two tribes plus GP front',
          game: buildStalledFutileExpandPeaceGame(
            ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
            gpRivalProvincesById: const {_gpRivalA: []},
            tribeIds: const [_tribeA, _tribeB],
            atWarFactionIds: const [_gpRivalA, _tribeA, _tribeB],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
            atWarWith: const [_tribeB, _tribeA, _gpRivalA],
          ),
        ),
        (
          name: 'above-quota guard',
          game: buildStalledFutileExpandPeaceGame(
            ownProvinces: kObserverConquestMinOwProvincesPerGp,
            gpRivalProvincesById: const {_gpRivalA: []},
            tribeIds: const [_tribeA],
            atWarFactionIds: const [_gpRivalA, _tribeA],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
            atWarWith: const [_gpRivalA, _tribeA],
          ),
        ),
        (
          name: 'no-GP-front guard (tribe-only war)',
          game: buildStalledFutileExpandPeaceGame(
            ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
            tribeIds: const [_tribeA],
            atWarFactionIds: const [_tribeA],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
            atWarWith: const [_tribeA],
          ),
        ),
        (
          name: 'GP-only war (no tribe in atWarWith)',
          game: buildStalledFutileExpandPeaceGame(
            ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
            gpRivalProvincesById: const {_gpRivalA: []},
            tribeIds: const [_tribeA],
            atWarFactionIds: const [_gpRivalA],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
            atWarWith: const [_gpRivalA],
          ),
        ),
      ];
      for (final fx in fixtures) {
        final canonical = atWarGpDistractionTribePeaceTargets(
          game: fx.game,
          snapshot: fx.snapshot,
        );
        final stub = diplomacy_peace_targets
            .atWarGpDistractionTribePeaceTargets(
              game: fx.game,
              snapshot: fx.snapshot,
            );
        expect(
          stub,
          canonical,
          reason:
              'Delegating stub must mirror the canonical helper for '
              'fixture "${fx.name}".',
        );
      }
    });
  });
}
