// Case bodies for expand_phase_planner_focus_minor_target_test (Refs #3997 Phase 8).
// Pins canonical homes for stalledFocusMinorTarget /
// belowQuotaActiveMinorWarTarget (Refs #2509 S1).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gpOwn = 'gp_own';
const String _gpRival = 'gp_rival';
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

void registerExpandPhasePlannerFocusMinorTargetEarlyCases() {
  group('stalledFocusMinorTarget — canonical outer guards', () {
    test('returns null when no minor is at war', () {
      // Only a tribe and a rival GP are at war; the
      // Game.minorNations / RelationState.atWar filter rejects every
      // minor candidate before the invadable scan runs.
      final game = _focusMinorGame(
        ownProvinces: 7,
        minorOwnedInvadables: const {
          _minorAlpha: ['oldWorld|alpha_1'],
        },
        peacefulMinors: const [_minorAlpha],
        atWarTribes: const [_tribeOne],
        atWarRivalGps: const [_gpRival],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_tribeOne, _gpRival],
        invadableProvinceIdsSorted: const ['oldWorld|alpha_1'],
      );
      expect(
        stalledFocusMinorTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'No at-war minor → the at-war filter rejects every '
            'Game.minorNations candidate before the invadable scan; '
            'tribes do not participate even though tribe_one owns '
            'an invadable province in a sibling fixture.',
      );
    });

    test(
      'returns null when at-war minors exist but own no invadable OW provinces',
      () {
        // Both minors are at war but own only non-invadable OW
        // provinces; the bestInvadableCount stays at 0 so the helper
        // returns null without picking an arbitrary minor.
        final game = _focusMinorGame(
          ownProvinces: 7,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_home'],
            _minorBeta: ['oldWorld|beta_home'],
          },
          atWarMinors: const [_minorAlpha, _minorBeta],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 7,
          atWarWith: const [_minorAlpha, _minorBeta],
          // None of the at-war minors' provinces appear in the
          // invadable frontier.
          invadableProvinceIdsSorted: const [],
        );
        expect(
          stalledFocusMinorTarget(game: game, snapshot: snapshot),
          isNull,
          reason:
              'Empty invadableProvinceIdsSorted → every minor scores '
              '0 → the strict-greater comparison never updates; '
              'returning null preserves the "no focused front" '
              'contract instead of arbitrarily picking one minor.',
        );
      },
    );
  });

  group('stalledFocusMinorTarget — fire path', () {
    test('returns the at-war minor with the most invadable OW provinces', () {
      // minor_alpha owns 1 invadable; minor_beta owns 2 invadables —
      // beta wins on the strict-greater comparison.
      final game = _focusMinorGame(
        ownProvinces: 7,
        minorOwnedInvadables: const {
          _minorAlpha: ['oldWorld|alpha_1'],
          _minorBeta: ['oldWorld|beta_1', 'oldWorld|beta_2'],
        },
        atWarMinors: const [_minorAlpha, _minorBeta],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_minorAlpha, _minorBeta],
        invadableProvinceIdsSorted: const [
          'oldWorld|alpha_1',
          'oldWorld|beta_1',
          'oldWorld|beta_2',
        ],
      );
      expect(
        stalledFocusMinorTarget(game: game, snapshot: snapshot),
        _minorBeta,
        reason:
            'minor_beta owns 2 invadable provinces → strict-greater '
            'comparison vs minor_alpha (1) selects beta as the '
            'focused single-front minor.',
      );
    });

    test('preserves Game.minorNations iteration order on count ties', () {
      // minor_alpha and minor_gamma each own 1 invadable. Only
      // strict-greater updates win, so the first iterated minor to
      // reach bestInvadableCount keeps the lead. Game.minorNations
      // iterates in construction order (alpha registered before
      // gamma) → alpha wins.
      final game = _focusMinorGame(
        ownProvinces: 7,
        minorOwnedInvadables: const {
          _minorAlpha: ['oldWorld|alpha_1'],
          _minorGamma: ['oldWorld|gamma_1'],
        },
        atWarMinors: const [_minorAlpha, _minorGamma],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_minorGamma, _minorAlpha],
        invadableProvinceIdsSorted: const [
          'oldWorld|alpha_1',
          'oldWorld|gamma_1',
        ],
      );
      expect(
        stalledFocusMinorTarget(game: game, snapshot: snapshot),
        _minorAlpha,
        reason:
            'Tie at 1 invadable each → only the first iterated minor '
            'updates bestInvadableCount; later minors with equal '
            'counts cannot displace it (strict-greater). This pins '
            'the deterministic-order contract for Must-have #7.',
      );
    });

    test('ignores tribes and rival GPs holding invadable provinces', () {
      // tribe_one and gp_rival each own an invadable OW province but
      // neither participates in the focused-minor scan (the loop
      // iterates Game.minorNations only). minor_alpha — the only
      // at-war minor with an invadable — must win.
      final game = _focusMinorGame(
        ownProvinces: 7,
        minorOwnedInvadables: const {
          _minorAlpha: ['oldWorld|alpha_1'],
        },
        atWarMinors: const [_minorAlpha],
        atWarTribes: const [_tribeOne],
        atWarRivalGps: const [_gpRival],
      );
      // Tribe and GP owned invadables on the same frontier (added
      // out-of-band so the snapshot exposes them but minor_alpha
      // still wins the focused-minor scan).
      final gameWithTribeAndGpInvadables = Game(
        id: game.id,
        worldState: WorldState(
          turnState: game.worldState.turnState,
          oldWorld: RegionData(
            provinces: <Province>[
              ...game.worldState.oldWorld.provinces,
              const Province(
                id: 'oldWorld|tribe_invadable_1',
                regionId: 'oldWorld',
                ownerId: _tribeOne,
              ),
              const Province(
                id: 'oldWorld|gp_rival_invadable_1',
                regionId: 'oldWorld',
                ownerId: _gpRival,
              ),
            ],
          ),
          newWorld: game.worldState.newWorld,
        ),
        players: game.players,
        minorNations: game.minorNations,
        tribes: game.tribes,
        diplomacyRelations: game.diplomacyRelations,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_minorAlpha, _tribeOne, _gpRival],
        invadableProvinceIdsSorted: const [
          'oldWorld|alpha_1',
          'oldWorld|tribe_invadable_1',
          'oldWorld|gp_rival_invadable_1',
        ],
      );
      expect(
        stalledFocusMinorTarget(
          game: gameWithTribeAndGpInvadables,
          snapshot: snapshot,
        ),
        _minorAlpha,
        reason:
            'The focused-minor scan iterates Game.minorNations only; '
            'tribe_one and gp_rival are never considered even when '
            'they own invadable provinces. minor_alpha (the only '
            'at-war minor with an invadable) wins.',
      );
    });
  });

  group('belowQuotaActiveMinorWarTarget — canonical outer guard', () {
    test(
      'returns null at quota even when a focused minor would fire below',
      () {
        // ownOw == quota → isBelowObserverConquestQuota is false →
        // outer guard fires before the inner stalledFocusMinorTarget
        // delegation. Even with minor_alpha clearly leading the
        // invadable count, the helper returns null at quota.
        final game = _focusMinorGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
          },
          atWarMinors: const [_minorAlpha],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          atWarWith: const [_minorAlpha],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_1',
            'oldWorld|alpha_2',
          ],
        );
        expect(
          belowQuotaActiveMinorWarTarget(game: game, snapshot: snapshot),
          isNull,
          reason:
              'At quota the quota-met / consolidate deciders own '
              'minor-front decisions. A regression that flipped the '
              'guard from `<` to `<=` would silently engage the '
              'helper at quota and force-hold a minor war the '
              'consolidate arm intended to peace.',
        );
        // Sanity-pin the same input through the canonical inner
        // helper to confirm the outer guard is the only difference
        // (would have returned minor_alpha otherwise).
        expect(
          stalledFocusMinorTarget(game: game, snapshot: snapshot),
          _minorAlpha,
          reason:
              'Without the below-quota guard the focused-minor scan '
              'would pick minor_alpha; the outer guard is the only '
              'reason belowQuotaActiveMinorWarTarget returns null.',
        );
      },
    );
  });

}
