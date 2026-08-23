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

void registerExpandPhasePlannerStalledFutileGpPeaceCases() {
  group('stalledFutileGpPeaceTargets — outer guards', () {
    test('returns const [] above the stalled OW band (own == quota)', () {
      // gp_own at the observer OW quota — isStalledOldWorldExpansion is
      // false so the canonical decider must short-circuit before the
      // futile-GP scan.
      final game = buildStalledFutileExpandPeaceGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp,
        gpRivalProvincesById: const {
          _gpRivalA: ['oldWorld|${_gpRivalA}_target'],
        },
        minorOwProvincesByMinorId: const {
          _minor1: ['oldWorld|${_minor1}_active'],
        },
        atWarFactionIds: const [_gpRivalA],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const [_gpRivalA],
        invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_active'],
      );
      expect(
        stalledFutileGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'At the observer OW quota the stalled-OW guard must fire '
            'and short-circuit the futile-GP pivot so the quota-met '
            'collectors take over.',
      );
    });

    test('returns const [] when invadableProvinceIdsSorted is empty', () {
      // gp_own in the stalled band with an at-war GP but no invadable OW
      // — the empty-invadable guard must short-circuit.
      final game = buildStalledFutileExpandPeaceGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        gpRivalProvincesById: const {_gpRivalA: []},
        minorOwProvincesByMinorId: const {_minor1: []},
        atWarFactionIds: const [_gpRivalA],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gpRivalA],
        invadableProvinceIdsSorted: const [],
      );
      expect(
        stalledFutileGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'No invadable OW means a futile-GP pivot cannot be diagnosed '
            'this turn; the decider must short-circuit before the '
            'province-owner scan.',
      );
    });

    test('returns const [] when no minor owns any invadable OW province', () {
      // gp_own in the stalled band, at war with a GP, but the only
      // invadable OW province is GP-owned (no minor on the invadable
      // frontier). The minorsOwnInvadable guard must short-circuit so
      // the stalledGpBlockerFocus collector owns the decision instead.
      final game = buildStalledFutileExpandPeaceGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        gpRivalProvincesById: const {
          _gpRivalA: ['oldWorld|${_gpRivalA}_target'],
          _gpRivalB: [],
        },
        atWarFactionIds: const [_gpRivalA, _gpRivalB],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gpRivalA, _gpRivalB],
        invadableProvinceIdsSorted: const ['oldWorld|${_gpRivalA}_target'],
      );
      expect(
        stalledFutileGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'A GP-only invadable frontier is not a futile-GP pivot — '
            'the stalledGpBlockerFocus collector handles that shape '
            'instead, so this decider must short-circuit.',
      );
    });
  });

  group('stalledFutileGpPeaceTargets — futile-GP fire path', () {
    test(
      'peaces every at-war GP that owns no invadable OW (sorted ascending)',
      () {
        // gp_own in the stalled band; a minor (minor1) holds the
        // invadable OW province (mixed frontier). gp_rival_b is also
        // at war but owns NONE of the invadable provinces (futile —
        // peace it). gp_rival_a is at war and owns one of the
        // invadable provinces (active blocker — keep at war). Result
        // must be exactly [gp_rival_b] (gp_rival_a filtered out).
        const minor1Pid = 'oldWorld|${_minor1}_active';
        const rivalAPid = 'oldWorld|${_gpRivalA}_blocker';
        final game = buildStalledFutileExpandPeaceGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          gpRivalProvincesById: const {
            _gpRivalA: [rivalAPid],
            _gpRivalB: [],
          },
          minorOwProvincesByMinorId: const {
            _minor1: [minor1Pid],
          },
          atWarFactionIds: const [_gpRivalA, _gpRivalB],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const [_gpRivalB, _gpRivalA],
          invadableProvinceIdsSorted: const [minor1Pid, rivalAPid],
        );
        expect(
          stalledFutileGpPeaceTargets(game: game, snapshot: snapshot),
          const [_gpRivalB],
          reason:
              'A regression that broadened "futile GP" to "every at-war '
              'GP" would also include gp_rival_a here, dropping the '
              'active OW frontier blocker from the war.',
        );
      },
    );

    test('fire path filters minors and tribes out of atWarWith', () {
      // gp_own in the stalled band, mixed frontier (minor holds
      // invadable). atWarWith contains a futile GP, a minor, and a
      // tribe. Only the GP must surface — minors and tribes have
      // their own dedicated peace deciders.
      const minor1Pid = 'oldWorld|${_minor1}_active';
      final game = buildStalledFutileExpandPeaceGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        gpRivalProvincesById: const {_gpRivalA: []},
        minorOwProvincesByMinorId: const {
          _minor1: [minor1Pid],
        },
        tribeIds: const [_tribeA],
        atWarFactionIds: const [_gpRivalA, _minor1, _tribeA],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gpRivalA, _minor1, _tribeA],
        invadableProvinceIdsSorted: const [minor1Pid],
      );
      expect(
        stalledFutileGpPeaceTargets(game: game, snapshot: snapshot),
        const [_gpRivalA],
        reason:
            'A regression that broadened the filter to "any at-war '
            'faction without an invadable OW" would include minor1 '
            'and tribe_a, double-peacing them with the dedicated '
            'minor / tribe collectors.',
      );
    });

    test('fire path returns ascending-sorted GP ids when many are futile', () {
      // Two futile GPs (own no invadable OW) listed in atWarWith in
      // non-sorted order. Result must be ascending [gp_rival_a,
      // gp_rival_b].
      const minor1Pid = 'oldWorld|${_minor1}_active';
      final game = buildStalledFutileExpandPeaceGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        gpRivalProvincesById: const {_gpRivalA: [], _gpRivalB: []},
        minorOwProvincesByMinorId: const {
          _minor1: [minor1Pid],
        },
        atWarFactionIds: const [_gpRivalA, _gpRivalB],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gpRivalB, _gpRivalA],
        invadableProvinceIdsSorted: const [minor1Pid],
      );
      expect(
        stalledFutileGpPeaceTargets(game: game, snapshot: snapshot),
        const [_gpRivalA, _gpRivalB],
        reason:
            'A regression that dropped the trailing sort would emit '
            '[gp_rival_b, gp_rival_a] in atWarWith order, breaking '
            'downstream deterministic peace-target ordering.',
      );
    });
  });

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
