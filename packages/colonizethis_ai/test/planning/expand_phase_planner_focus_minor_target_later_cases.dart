// Case bodies (later) for expand_phase_planner_focus_minor_target_test (Refs #3997 Phase 8).
// Pins canonical homes for stalledFocusMinorTarget /
// belowQuotaActiveMinorWarTarget (Refs #2509 S1).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

const String _gpOwn = 'gp_own';
const String _minorAlpha = 'minor_alpha';
const String _minorBeta = 'minor_beta';
const String _minorGamma = 'minor_gamma';
const String _tribeOne = 'tribe_one';

/// Builds a minimal `Game` where:
///   * `gp_own` holds [ownProvinces] OW provinces (so quota-band
///     ownership counts via `Game.worldState.oldWorld.provinces` are
///     deterministic without forcing the test to enumerate them).
///   * Each entry in [minorOwnedInvadables] places that minor as the
///     owner of every province id in the value list (these are the
///     ids the snapshot exposes via `invadableProvinceIdsSorted`).
///   * Every minor in [atWarMinors] is in `RelationState.atWar`
///     against `gp_own`. Minors not listed here exist on the map but
///     are at peace.
///   * Every tribe in [atWarTribes] is in `RelationState.atWar`. The
///     focused-minor scan iterates `Game.minorNations` only, so
///     tribes here exercise the "tribes don't participate" rule.
///   * Every GP in [atWarRivalGps] is in `RelationState.atWar`. The
///     focused-minor scan never inspects GPs (the same iteration
///     filter); the GP at-war set keeps the fixture honest about
///     `threats.atWarWith` mixing in non-minor entries.
Game _focusMinorGame({
  required int ownProvinces,
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

  return Game(
    id:
        'g-2509-focus-minor-canonical-'
        'own$ownProvinces-${minorOwnedInvadables.keys.join("-")}',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
    diplomacyRelations: relations,
  );
}


void registerExpandPhasePlannerFocusMinorTargetLaterCases() {
  group('belowQuotaActiveMinorWarTarget — fire path', () {
    test(
      'returns the focused minor below quota (delegates to stalledFocusMinorTarget)',
      () {
        // ownOw < quota → outer guard passes → result mirrors
        // stalledFocusMinorTarget exactly.
        final game = _focusMinorGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
            _minorBeta: ['oldWorld|beta_1'],
          },
          atWarMinors: const [_minorAlpha, _minorBeta],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [_minorAlpha, _minorBeta],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_1',
            'oldWorld|alpha_2',
            'oldWorld|beta_1',
          ],
        );
        expect(
          belowQuotaActiveMinorWarTarget(game: game, snapshot: snapshot),
          _minorAlpha,
          reason:
              'Below quota → outer guard passes → result mirrors '
              'stalledFocusMinorTarget which prefers minor_alpha (2 '
              'invadable provinces vs minor_beta\'s 1).',
        );
      },
    );

    test('returns null below quota when focused-minor scan finds nothing', () {
      // Below quota but no at-war minor owns an invadable province →
      // stalledFocusMinorTarget returns null → the wrapper passes
      // that null through unchanged.
      final game = _focusMinorGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
        minorOwnedInvadables: const {
          _minorAlpha: ['oldWorld|alpha_home'],
        },
        atWarMinors: const [_minorAlpha],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
        atWarWith: const [_minorAlpha],
        invadableProvinceIdsSorted: const [],
      );
      expect(
        belowQuotaActiveMinorWarTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Below quota but the inner focused-minor scan finds no '
            'candidate (empty invadable list) → the wrapper must '
            'return null instead of inventing a target.',
      );
    });
  });

  group('Determinism (Must-have #7)', () {
    test('stalledFocusMinorTarget returns identical results on repeat', () {
      final game = _focusMinorGame(
        ownProvinces: 7,
        minorOwnedInvadables: const {
          _minorAlpha: ['oldWorld|alpha_1'],
          _minorBeta: ['oldWorld|beta_1', 'oldWorld|beta_2'],
        },
        atWarMinors: const [_minorAlpha, _minorBeta],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_minorAlpha, _minorBeta],
        invadableProvinceIdsSorted: const [
          'oldWorld|alpha_1',
          'oldWorld|beta_1',
          'oldWorld|beta_2',
        ],
      );
      final first = stalledFocusMinorTarget(game: game, snapshot: snapshot);
      final second = stalledFocusMinorTarget(game: game, snapshot: snapshot);
      expect(first, equals(second));
      expect(first, _minorBeta);
    });

    test(
      'belowQuotaActiveMinorWarTarget returns identical results on repeat',
      () {
        final game = _focusMinorGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
          },
          atWarMinors: const [_minorAlpha],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [_minorAlpha],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_1',
            'oldWorld|alpha_2',
          ],
        );
        final first = belowQuotaActiveMinorWarTarget(
          game: game,
          snapshot: snapshot,
        );
        final second = belowQuotaActiveMinorWarTarget(
          game: game,
          snapshot: snapshot,
        );
        expect(first, equals(second));
        expect(first, _minorAlpha);
      },
    );
  });

  group('Stub delegation parity', () {
    test('stalledFocusMinorTarget stub mirrors canonical across fixtures', () {
      final fixtures = <({Game game, AIWorldSnapshot snapshot, String label})>[
        (
          label: 'no at-war minor',
          game: _focusMinorGame(
            ownProvinces: 7,
            minorOwnedInvadables: const {
              _minorAlpha: ['oldWorld|alpha_1'],
            },
            peacefulMinors: const [_minorAlpha],
            atWarTribes: const [_tribeOne],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: 7,
            atWarWith: const [_tribeOne],
            invadableProvinceIdsSorted: const ['oldWorld|alpha_1'],
          ),
        ),
        (
          label: 'fire path with strict-greater winner',
          game: _focusMinorGame(
            ownProvinces: 7,
            minorOwnedInvadables: const {
              _minorAlpha: ['oldWorld|alpha_1'],
              _minorBeta: ['oldWorld|beta_1', 'oldWorld|beta_2'],
            },
            atWarMinors: const [_minorAlpha, _minorBeta],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: 7,
            atWarWith: const [_minorAlpha, _minorBeta],
            invadableProvinceIdsSorted: const [
              'oldWorld|alpha_1',
              'oldWorld|beta_1',
              'oldWorld|beta_2',
            ],
          ),
        ),
        (
          label: 'tie preserves iteration order',
          game: _focusMinorGame(
            ownProvinces: 7,
            minorOwnedInvadables: const {
              _minorAlpha: ['oldWorld|alpha_1'],
              _minorGamma: ['oldWorld|gamma_1'],
            },
            atWarMinors: const [_minorAlpha, _minorGamma],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: 7,
            atWarWith: const [_minorAlpha, _minorGamma],
            invadableProvinceIdsSorted: const [
              'oldWorld|alpha_1',
              'oldWorld|gamma_1',
            ],
          ),
        ),
      ];
      for (final fixture in fixtures) {
        final canonical = stalledFocusMinorTarget(
          game: fixture.game,
          snapshot: fixture.snapshot,
        );
        final stub = diplomacy_planner_peace_targets.stalledFocusMinorTarget(
          game: fixture.game,
          snapshot: fixture.snapshot,
        );
        expect(
          stub,
          equals(canonical),
          reason:
              'Stub-canonical parity broken for fixture '
              '"${fixture.label}". The legacy '
              'stalledExpansionDistractionPeaceTargets and '
              'belowQuotaMultiMinorDistractionPeaceTargets consumers '
              'depend on this parity until the now-completed S1 deletion.',
        );
      }
    });

    test(
      'belowQuotaActiveMinorWarTarget stub mirrors canonical across fixtures',
      () {
        final fixtures =
            <({Game game, AIWorldSnapshot snapshot, String label})>[
              (
                label: 'outer guard at quota',
                game: _focusMinorGame(
                  ownProvinces: kObserverConquestMinOwProvincesPerGp,
                  minorOwnedInvadables: const {
                    _minorAlpha: ['oldWorld|alpha_1'],
                  },
                  atWarMinors: const [_minorAlpha],
                ),
                snapshot: ownSnapshot(
                  oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
                  atWarWith: const [_minorAlpha],
                  invadableProvinceIdsSorted: const ['oldWorld|alpha_1'],
                ),
              ),
              (
                label: 'fire path below quota',
                game: _focusMinorGame(
                  ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
                  minorOwnedInvadables: const {
                    _minorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
                  },
                  atWarMinors: const [_minorAlpha],
                ),
                snapshot: ownSnapshot(
                  oldWorldProvincesOwned:
                      kObserverConquestMinOwProvincesPerGp - 2,
                  atWarWith: const [_minorAlpha],
                  invadableProvinceIdsSorted: const [
                    'oldWorld|alpha_1',
                    'oldWorld|alpha_2',
                  ],
                ),
              ),
              (
                label: 'below quota with no focused minor',
                game: _focusMinorGame(
                  ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
                  minorOwnedInvadables: const {
                    _minorAlpha: ['oldWorld|alpha_home'],
                  },
                  atWarMinors: const [_minorAlpha],
                ),
                snapshot: ownSnapshot(
                  oldWorldProvincesOwned:
                      kObserverConquestMinOwProvincesPerGp - 2,
                  atWarWith: const [_minorAlpha],
                  invadableProvinceIdsSorted: const [],
                ),
              ),
            ];
        for (final fixture in fixtures) {
          final canonical = belowQuotaActiveMinorWarTarget(
            game: fixture.game,
            snapshot: fixture.snapshot,
          );
          final stub = diplomacy_planner_peace_targets
              .belowQuotaActiveMinorWarTarget(
                game: fixture.game,
                snapshot: fixture.snapshot,
              );
          expect(
            stub,
            equals(canonical),
            reason:
                'Stub-canonical parity broken for fixture '
                '"${fixture.label}". The diplomatic-candidate-scoring '
                'below-quota minor-front-hold consumer depends on '
                'this parity until the now-completed S1 deletion.',
          );
        }
      },
    );
  });
}
