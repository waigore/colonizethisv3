// Pins the canonical home in `expand_phase_planner.dart` for
// `belowQuotaMultiMinorDistractionPeaceTargets` (Refs #2509 S1).
//
// The helper was relocated from `diplomacy_planner_peace_targets.dart`
// so it survives the planned S1 deletion of that file. The canonical
// implementation lives in `expand_phase_planner.dart` alongside the
// `stalledFocusMinorTarget` helper it composes;
// `diplomacy_planner_peace_targets.dart` retains a thin delegating
// stub for the in-file `collectStalledGreatPowerPeaceTargets`
// `minorTribePeace` consumer chain and the legacy
// `diplomacy_planner_below_quota_peace_part3_test.dart` fixture until
// the planned S1 deletion.
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
//     planned S1 deletion.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/diplomacy_planner_peace_targets.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gpOwn = 'gp_own';
const String _gpRival = 'gp_rival';
const String _minorAlpha = 'minor_alpha';
const String _minorBeta = 'minor_beta';
const String _minorGamma = 'minor_gamma';
const String _tribeOne = 'tribe_one';

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

AIWorldSnapshot _ownSnapshot({
  required int oldWorldProvincesOwned,
  required List<String> atWarWith,
  List<String> invadableProvinceIdsSorted = const [],
}) {
  return AIWorldSnapshot(
    playerId: _gpOwn,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      invadableProvinceIdsSorted: invadableProvinceIdsSorted,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
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
        final snapshot = _ownSnapshot(
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
        final snapshot = _ownSnapshot(
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
        final snapshot = _ownSnapshot(
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
        final snapshot = _ownSnapshot(
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
        final snapshot = _ownSnapshot(
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

  group('belowQuotaMultiMinorDistractionPeaceTargets — fire path', () {
    test('peaces every at-war minor except the focused-minor target', () {
      // ownOw < quota, regiments in (0, threshold), non-empty
      // frontier, focused minor = alpha (owns 2 invadable provinces
      // vs beta's 1 vs gamma's 1 → alpha wins strict-greater) →
      // result keeps minor_beta and minor_gamma sorted ascending.
      final game = _multiMinorGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
        ownRegiments: 2,
        minorOwnedInvadables: const {
          _minorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
          _minorBeta: ['oldWorld|beta_1'],
          _minorGamma: ['oldWorld|gamma_1'],
        },
        atWarMinors: const [_minorAlpha, _minorBeta, _minorGamma],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
        // Deliberately unsorted to ensure the sort-asc applies even
        // when atWarWith is not sorted.
        atWarWith: const [_minorGamma, _minorAlpha, _minorBeta],
        invadableProvinceIdsSorted: const [
          'oldWorld|alpha_1',
          'oldWorld|alpha_2',
          'oldWorld|beta_1',
          'oldWorld|gamma_1',
        ],
      );
      expect(
        belowQuotaMultiMinorDistractionPeaceTargets(
          game: game,
          snapshot: snapshot,
        ),
        const [_minorBeta, _minorGamma],
        reason:
            'Focused minor = alpha (2 invadable provinces, strict-'
            'greater winner over beta and gamma at 1 each); the '
            'helper peaces every other at-war minor sorted '
            'ascending so emission order is deterministic for '
            'fixed inputs (Refs #2509 Must-have #7).',
      );
    });

    test('drops tribes and GPs from atWarWith even on the same frontier', () {
      // Tribes and GPs may appear in ThreatSummary.atWarWith but
      // the distraction-peace pivot only emits minors — the
      // GP-distraction-tribe / GP-blocker / peer-GP deciders own
      // those decisions.
      final game = _multiMinorGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
        ownRegiments: 2,
        minorOwnedInvadables: const {
          _minorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
          _minorBeta: ['oldWorld|beta_1'],
        },
        atWarMinors: const [_minorAlpha, _minorBeta],
        atWarTribes: const [_tribeOne],
        atWarRivalGps: const [_gpRival],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
        atWarWith: const [_minorAlpha, _minorBeta, _tribeOne, _gpRival],
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
        const [_minorBeta],
        reason:
            'Tribes and GPs participate in atWarWith but the '
            'membership filter (Game.minorNations only) drops them; '
            'minor_alpha is preserved as the focused-minor target, '
            'so only minor_beta remains.',
      );
    });

    test(
      'returns const [] when the focused minor is the only at-war minor',
      () {
        // Only one at-war minor, and it is the focused minor → after
        // the focus filter no candidates remain; the helper returns
        // an empty list (not a list containing focus) so the consumer
        // does not double-peace the preserved front.
        final game = _multiMinorGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          ownRegiments: 2,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
          },
          atWarMinors: const [_minorAlpha],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [_minorAlpha],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_1',
            'oldWorld|alpha_2',
          ],
        );
        expect(
          belowQuotaMultiMinorDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'After the focus filter no minor remains; the helper '
              'returns an empty list so the consumer does not peace '
              'the preserved focused front.',
        );
      },
    );
  });

  group('Determinism (Must-have #7)', () {
    test(
      'belowQuotaMultiMinorDistractionPeaceTargets returns identical results on repeat',
      () {
        final game = _multiMinorGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          ownRegiments: 2,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
            _minorBeta: ['oldWorld|beta_1'],
            _minorGamma: ['oldWorld|gamma_1'],
          },
          atWarMinors: const [_minorAlpha, _minorBeta, _minorGamma],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [_minorGamma, _minorAlpha, _minorBeta],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_1',
            'oldWorld|alpha_2',
            'oldWorld|beta_1',
            'oldWorld|gamma_1',
          ],
        );
        final first = belowQuotaMultiMinorDistractionPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final second = belowQuotaMultiMinorDistractionPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        expect(first, equals(second));
        expect(first, const [_minorBeta, _minorGamma]);
      },
    );
  });

  group('Stub delegation parity', () {
    test(
      'belowQuotaMultiMinorDistractionPeaceTargets stub mirrors canonical across fixtures',
      () {
        final fixtures =
            <({Game game, AIWorldSnapshot snapshot, String label})>[
              (
                label: 'outer guard at quota',
                game: _multiMinorGame(
                  ownProvinces: kObserverConquestMinOwProvincesPerGp,
                  ownRegiments: 2,
                  minorOwnedInvadables: const {
                    _minorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
                    _minorBeta: ['oldWorld|beta_1'],
                  },
                  atWarMinors: const [_minorAlpha, _minorBeta],
                ),
                snapshot: _ownSnapshot(
                  oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
                  atWarWith: const [_minorAlpha, _minorBeta],
                  invadableProvinceIdsSorted: const [
                    'oldWorld|alpha_1',
                    'oldWorld|alpha_2',
                    'oldWorld|beta_1',
                  ],
                ),
              ),
              (
                label: 'outer guard at zero regiments',
                game: _multiMinorGame(
                  ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
                  ownRegiments: 0,
                  minorOwnedInvadables: const {
                    _minorAlpha: ['oldWorld|alpha_1'],
                    _minorBeta: ['oldWorld|beta_1'],
                  },
                  atWarMinors: const [_minorAlpha, _minorBeta],
                ),
                snapshot: _ownSnapshot(
                  oldWorldProvincesOwned:
                      kObserverConquestMinOwProvincesPerGp - 2,
                  atWarWith: const [_minorAlpha, _minorBeta],
                  invadableProvinceIdsSorted: const [
                    'oldWorld|alpha_1',
                    'oldWorld|beta_1',
                  ],
                ),
              ),
              (
                label: 'outer guard at declare-war floor',
                game: _multiMinorGame(
                  ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
                  ownRegiments: kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
                  minorOwnedInvadables: const {
                    _minorAlpha: ['oldWorld|alpha_1'],
                    _minorBeta: ['oldWorld|beta_1'],
                  },
                  atWarMinors: const [_minorAlpha, _minorBeta],
                ),
                snapshot: _ownSnapshot(
                  oldWorldProvincesOwned:
                      kObserverConquestMinOwProvincesPerGp - 2,
                  atWarWith: const [_minorAlpha, _minorBeta],
                  invadableProvinceIdsSorted: const [
                    'oldWorld|alpha_1',
                    'oldWorld|beta_1',
                  ],
                ),
              ),
              (
                label: 'fire path with tribe + GP filter',
                game: _multiMinorGame(
                  ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
                  ownRegiments: 2,
                  minorOwnedInvadables: const {
                    _minorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
                    _minorBeta: ['oldWorld|beta_1'],
                  },
                  atWarMinors: const [_minorAlpha, _minorBeta],
                  atWarTribes: const [_tribeOne],
                  atWarRivalGps: const [_gpRival],
                ),
                snapshot: _ownSnapshot(
                  oldWorldProvincesOwned:
                      kObserverConquestMinOwProvincesPerGp - 2,
                  atWarWith: const [
                    _minorAlpha,
                    _minorBeta,
                    _tribeOne,
                    _gpRival,
                  ],
                  invadableProvinceIdsSorted: const [
                    'oldWorld|alpha_1',
                    'oldWorld|alpha_2',
                    'oldWorld|beta_1',
                  ],
                ),
              ),
              (
                label: 'sort-ascending across unsorted atWarWith',
                game: _multiMinorGame(
                  ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
                  ownRegiments: 2,
                  minorOwnedInvadables: const {
                    _minorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
                    _minorBeta: ['oldWorld|beta_1'],
                    _minorGamma: ['oldWorld|gamma_1'],
                  },
                  atWarMinors: const [_minorAlpha, _minorBeta, _minorGamma],
                ),
                snapshot: _ownSnapshot(
                  oldWorldProvincesOwned:
                      kObserverConquestMinOwProvincesPerGp - 2,
                  atWarWith: const [_minorGamma, _minorAlpha, _minorBeta],
                  invadableProvinceIdsSorted: const [
                    'oldWorld|alpha_1',
                    'oldWorld|alpha_2',
                    'oldWorld|beta_1',
                    'oldWorld|gamma_1',
                  ],
                ),
              ),
            ];
        for (final fixture in fixtures) {
          final canonical = belowQuotaMultiMinorDistractionPeaceTargets(
            game: fixture.game,
            snapshot: fixture.snapshot,
          );
          final stub = diplomacy_planner_peace_targets
              .belowQuotaMultiMinorDistractionPeaceTargets(
                game: fixture.game,
                snapshot: fixture.snapshot,
              );
          expect(
            stub,
            equals(canonical),
            reason:
                'Stub-canonical parity broken for fixture '
                '"${fixture.label}". The in-file '
                'collectStalledGreatPowerPeaceTargets minorTribePeace '
                'consumer depends on this parity until the planned '
                'S1 deletion.',
          );
        }
      },
    );
  });
}
