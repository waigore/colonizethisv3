// Case bodies for `expand_phase_planner_below_quota_multi_minor_distraction_peace_test.dart` (Refs #3977 Phase 6).
// Registered from the thin contract file of the same stem.
// Pin/row coverage is preserved 1:1 from the former inline suite.

// Pins the canonical home in `expand_phase_planner.dart` for
// `belowQuotaMultiMinorDistractionPeaceTargets` (Refs #2509 S1).
//
// The helper was relocated from `diplomacy_planner_peace_targets.dart`
// so it survives the now-completed S1 deletion of that file. The canonical
// implementation lives in `expand_phase_planner.dart` alongside the
// `stalledFocusMinorTarget` helper it composes;
// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating
// stub for the in-file `collectStalledGreatPowerPeaceTargets`
// `minorTribePeace` consumer chain and the legacy
// `diplomacy_planner_below_quota_peace_part3_test.dart` fixture until
// the now-completed S1 deletion.
//
// Behavioral invariants pinned at the canonical entry point:
//
// `belowQuotaMultiMinorDistractionPeaceTargets`:
//   1. Returns `const []` when
//      `isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)`
//      is `false` — at and above quota the quota-met / consolidate /
//      near-quota deciders own the multi-minor decision instead.
//   2. Returns `const []` when `regimentCountForPlayer` returns 0 —
//      the zero-regiment survival deciders own the peace decision
//      below the affordability gate.
//   3. Returns `const []` when `regimentCountForPlayer` returns a
//      value `>= kBelowQuotaPeaceMinRegimentsBeforeDeclareWar` — once
//      the active player can sustain multiple fronts the
//      distraction-peace pivot is not warranted.
//   4. Returns `const []` when
//      `snapshot.conquest.invadableProvinceIdsSorted` is empty —
//      no OW frontier means no minor war to concentrate on.
//   5. Returns `const []` when `stalledFocusMinorTarget` returns
//      `null` — without an at-war minor owning an invadable OW
//      province the pivot has no target to preserve.
//   6. When all guards pass, returns every at-war minor in
//      `ThreatSummary.atWarWith` except the focused-minor target
//      preserved by `stalledFocusMinorTarget`. Tribes and Great
//      Powers are dropped because their respective peace deciders
//      own those decisions.
//   7. Sorts the result ascending so emission order is deterministic
//      for fixed inputs (Refs #2509 Must-have #7).
//
// Delegation parity:
//   * The delegating stub in `diplomacy_planner_peace_targets.dart`
//     returns the same value as the canonical helper for every
//     representative input — required so the in-file
//     `collectStalledGreatPowerPeaceTargets` `minorTribePeace`
//     consumer resolves to the same multi-minor peace set until the
//     now-completed S1 deletion.

// ignore_for_file: unused_element
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';

const String _gpOwn = 'gp_own';
const String _minorAlpha = 'minor_alpha';
const String _minorBeta = 'minor_beta';

/// Builds a minimal `Game` where:
///   * `gp_own` holds [ownProvinces] OW provinces so quota-band checks
///     can route off `oldWorldProvincesOwned` deterministically.
///   * Each entry in [minorOwnedInvadables] places that minor as the
///     owner of every province id in the value list (these are the
///     ids the snapshot exposes via `invadableProvinceIdsSorted`).
///   * `gp_own` owns a Home Army with [ownRegiments] regiment unit ids
///     so `regimentCountForPlayer` returns exactly that count for the
///     active player (the function sums `regimentUnitIds.length` across
///     armies owned by `playerId`).
///   * Every minor in [atWarMinors] is in `RelationState.atWar`
///     against `gp_own`. Minors not listed exist on the map but are
///     at peace.
///   * Every tribe in [atWarTribes] is in `RelationState.atWar`.
///     Tribes are valid members of `ThreatSummary.atWarWith` but the
///     distraction-peace pivot drops them (only minors qualify).
///   * Every GP in [atWarRivalGps] is in `RelationState.atWar`. GPs
///     are valid members of `ThreatSummary.atWarWith` but the
///     distraction-peace pivot drops them (only minors qualify).
Game _multiMinorGame({
  required int ownProvinces,
  required int ownRegiments,
  Map<String, List<String>> minorOwnedInvadables = const {},
  List<String> atWarMinors = const [],
  List<String> atWarTribes = const [],
  List<String> atWarRivalGps = const [],
  List<String> peacefulMinors = const [],
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|${_gpOwn}_$i',
        regionId: 'oldWorld',
        ownerId: _gpOwn,
      ),
    for (final entry in minorOwnedInvadables.entries)
      for (final pid in entry.value)
        Province(id: pid, regionId: 'oldWorld', ownerId: entry.key),
  ];

  final players = <Player>[
    const Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
    for (final id in atWarRivalGps)
      Player(id: id, displayName: id.toUpperCase(), isHuman: false),
  ];

  final allMinorIds = <String>{
    ...minorOwnedInvadables.keys,
    ...atWarMinors,
    ...peacefulMinors,
  };
  final minorNations = <MinorNation>[
    for (final minorId in allMinorIds)
      MinorNation(id: minorId, displayName: minorId),
  ];

  final tribes = <Tribe>[
    for (final tribeId in atWarTribes) Tribe(id: tribeId, displayName: tribeId),
  ];

  final relations = <DiplomacyRelation>[
    for (final id in atWarMinors)
      DiplomacyRelation(
        factionId1: _gpOwn,
        factionId2: id,
        state: RelationState.atWar,
        score: 30,
      ),
    for (final id in atWarTribes)
      DiplomacyRelation(
        factionId1: _gpOwn,
        factionId2: id,
        state: RelationState.atWar,
        score: 30,
      ),
    for (final id in atWarRivalGps)
      DiplomacyRelation(
        factionId1: _gpOwn,
        factionId2: id,
        state: RelationState.atWar,
        score: 30,
      ),
  ];

  final armies = <Army>[
    if (ownRegiments > 0)
      Army(
        id: homeArmyIdFor(_gpOwn),
        ownerId: _gpOwn,
        regionId: 'oldWorld',
        stationedProvinceId: ownProvinces > 0
            ? 'oldWorld|${_gpOwn}_1'
            : 'oldWorld|capital',
        regimentUnitIds: <String>[
          for (var i = 1; i <= ownRegiments; i++) 'u_${_gpOwn}_$i',
        ],
        isHomeArmy: true,
      ),
  ];

  return Game(
    id:
        'g-2509-multi-minor-distraction-'
        'own$ownProvinces-reg$ownRegiments-'
        '${minorOwnedInvadables.keys.join("-")}',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
      armies: armies,
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
    diplomacyRelations: relations,
  );
}

void registerExpandPhasePlannerBelowQuotaMultiMinorDistractionGuardsCases() {
  group(
    'belowQuotaMultiMinorDistractionPeaceTargets — canonical outer guards',
    () {
      test('returns const [] at quota even with two at-war minors', () {
        // ownOw == quota → isBelowObserverConquestQuota is false →
        // outer guard fires before the regiment, frontier, and focus
        // checks. Even with two at-war minors clearly contested on
        // the same frontier, the helper returns const [] at quota.
        final game = _multiMinorGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp,
          ownRegiments: 2,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
            _minorBeta: ['oldWorld|beta_1'],
          },
          atWarMinors: const [_minorAlpha, _minorBeta],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          atWarWith: const [_minorAlpha, _minorBeta],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_1',
            'oldWorld|alpha_2',
            'oldWorld|beta_1',
          ],
        );
        expect(
          belowQuotaMultiMinorDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'At quota the quota-met / consolidate deciders own the '
              'multi-minor peace decision. A regression flipping the '
              'guard from `<` to `<=` would silently engage the '
              'distraction pivot and peace minor_beta even when the '
              'consolidate arm intended to hold both wars open.',
        );
      });

      test('returns const [] with zero regiments (zero-band reserved)', () {
        // regimentCount == 0 → the zero-regiment survival deciders
        // (`stalledZeroRegimentAllFactionPeaceTargets` /
        // `stalledZeroRegimentGpPeaceTargets`) own the peace decision
        // below the affordability gate; this helper must defer.
        final game = _multiMinorGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          ownRegiments: 0,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_1'],
            _minorBeta: ['oldWorld|beta_1'],
          },
          atWarMinors: const [_minorAlpha, _minorBeta],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [_minorAlpha, _minorBeta],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_1',
            'oldWorld|beta_1',
          ],
        );
        expect(
          belowQuotaMultiMinorDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'Zero regiments → the zero-regiment survival arm owns '
              'the peace decision; the distraction-peace pivot must '
              'defer so it does not double-emit a peace target the '
              'survival arm already produced.',
        );
      });

      test('returns const [] when regiments reach the declare-war floor', () {
        // regimentCount == kBelowQuotaPeaceMinRegimentsBeforeDeclareWar
        // → the player can sustain multiple fronts so the
        // distraction-peace pivot is not warranted. The boundary is
        // `>=`, so the exact threshold value triggers the outer
        // guard.
        final game = _multiMinorGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          ownRegiments: kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_1'],
            _minorBeta: ['oldWorld|beta_1'],
          },
          atWarMinors: const [_minorAlpha, _minorBeta],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [_minorAlpha, _minorBeta],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_1',
            'oldWorld|beta_1',
          ],
        );
        expect(
          belowQuotaMultiMinorDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'A regression flipping the threshold check from `>=` '
              'to `>` would silently engage the pivot at the floor '
              'value and force-peace minor_beta even though the '
              'player can sustain the second front.',
        );
      });

      test('returns const [] when invadable OW frontier is empty', () {
        // Empty invadableProvinceIdsSorted → the active player has
        // no OW frontier to concentrate on; the pivot has no
        // purpose so the helper returns const [] before invoking
        // the focused-minor scan.
        final game = _multiMinorGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          ownRegiments: 2,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_home'],
            _minorBeta: ['oldWorld|beta_home'],
          },
          atWarMinors: const [_minorAlpha, _minorBeta],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [_minorAlpha, _minorBeta],
          invadableProvinceIdsSorted: const [],
        );
        expect(
          belowQuotaMultiMinorDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'No invadable OW frontier → the distraction-peace '
              'pivot has no front to concentrate on so it returns '
              'const [] instead of arbitrarily peacing one of the '
              'two minors.',
        );
      });

      test('returns const [] when focused-minor scan finds no candidate', () {
        // Below quota, regiments in the active band, non-empty
        // invadable list, but neither at-war minor owns an
        // invadable OW province → stalledFocusMinorTarget returns
        // null → the helper passes that null through as const [].
        final game = _multiMinorGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          ownRegiments: 2,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_home'],
            _minorBeta: ['oldWorld|beta_home'],
          },
          atWarMinors: const [_minorAlpha, _minorBeta],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [_minorAlpha, _minorBeta],
          // Frontier is non-empty but none of these provinces
          // are owned by the at-war minors.
          invadableProvinceIdsSorted: const ['oldWorld|gp_rival_1'],
        );
        expect(
          belowQuotaMultiMinorDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'No focused minor → no minor war to preserve; the '
              'helper must not invent a focus target and start '
              'peacing the only at-war minors arbitrarily.',
        );
      });
    },
  );

}
