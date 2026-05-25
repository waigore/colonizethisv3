// Pins canonical homes in `expand_phase_planner.dart` for
// `stalledGpBlockerFocusPeaceTargets` and
// `stalledStrongerGpBlockerPeaceTarget` (Refs #2509 S1).
//
// Both deciders were relocated from
// `diplomacy_planner_peace_targets.dart` so they survive the planned
// S1 deletion of that file. The canonical implementations live in
// `expand_phase_planner_peer_peace.dart` (part of `expand_phase_planner.dart`);
// `diplomacy_planner_peace_targets.dart` retains thin delegating stubs
// for the legacy `expand_phase_planner_peer_peace_basic_test.dart` and
// `diplomacy_planner_stalled_peace_test.dart` fixtures and the in-file
// `_expandRatchetGreatPowerPeaceTargets` /
// `stalledOwExpansionNeedsPeacePass` consumer chains until the planned
// deletion.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gpOwn = 'gp4';
const String _gpBlocker = 'gp3';
const String _gpDistraction = 'gp5';
const String _minor1 = 'minor1';

Game _gpBlockerFocusGame({
  required List<Province> provinces,
  required List<String> atWarFactionIds,
  List<MinorNation> minorNations = const [],
  Set<String> extraGpIds = const {},
}) {
  final playerIds = <String>{
    _gpOwn,
    ...extraGpIds,
    for (final id in atWarFactionIds)
      if (id.startsWith('gp')) id,
  };
  return Game(
    id: 'g-2509-gp-blocker-focus-${provinces.length}',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: [
      for (final id in playerIds)
        Player(id: id, displayName: id.toUpperCase(), isHuman: false),
    ],
    minorNations: minorNations,
    diplomacyRelations: [
      for (final id in atWarFactionIds)
        DiplomacyRelation(
          factionId1: _gpOwn,
          factionId2: id,
          state: RelationState.atWar,
          score: 10,
        ),
    ],
  );
}

AIWorldSnapshot _ownSnapshot({
  required int oldWorldProvincesOwned,
  required List<String> atWarWith,
  required List<String> invadableProvinceIdsSorted,
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
  group('stalledGpBlockerFocusPeaceTargets — canonical outer guards', () {
    test('returns const [] when frontier is not GP-only', () {
      // Invadable province owned by a minor →
      // isOldWorldGpOnlyInvadableFrontier is false.
      final game = _gpBlockerFocusGame(
        provinces: [
          for (var i = 0; i < 7; i++)
            Province(
              id: 'oldWorld|${_gpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: _gpOwn,
            ),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
        atWarFactionIds: const [_gpBlocker, _gpDistraction],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker, _gpDistraction],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      expect(
        stalledGpBlockerFocusPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Mixed frontier (minor owns invadable) → GP-only guard fails; '
            'stalledFutileGpPeaceTargets owns this shape instead.',
      );
    });

    test('returns const [] when primary blocker is null', () {
      // GP-only frontier shape but no GP owns invadable provinces
      // (unowned invadable) → blocker resolution returns null.
      final game = _gpBlockerFocusGame(
        provinces: [
          for (var i = 0; i < 7; i++)
            Province(
              id: 'oldWorld|${_gpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: _gpOwn,
            ),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: null,
          ),
        ],
        atWarFactionIds: const [_gpDistraction],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpDistraction],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      expect(
        stalledGpBlockerFocusPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
      );
    });
  });

  group('stalledGpBlockerFocusPeaceTargets — fire path', () {
    test('peaces non-blocker GP on GP-only invadable frontier', () {
      // Mirrors colonial_pressure_test § stalledGpBlockerFocusPeaceTargets:
      // gp3 owns the sole invadable province (blocker); gp5 is at war but
      // does not own invadable land → peaced.
      final game = _gpBlockerFocusGame(
        provinces: [
          for (var i = 0; i < 7; i++)
            Province(
              id: 'oldWorld|${_gpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: _gpOwn,
            ),
          for (var i = 0; i < 10; i++)
            Province(
              id: 'oldWorld|${_gpBlocker}_$i',
              regionId: 'oldWorld',
              ownerId: _gpBlocker,
            ),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _gpBlocker,
          ),
        ],
        atWarFactionIds: const [_gpBlocker, _gpDistraction],
        extraGpIds: const {_gpBlocker},
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker, _gpDistraction],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      expect(
        stalledGpBlockerFocusPeaceTargets(game: game, snapshot: snapshot),
        const [_gpDistraction],
      );
    });

    test('sole non-blocker GP war on GP-only frontier returns that GP', () {
      // gpWars.length == 1 && sole GP != blocker → return [soleGp]
      final gpOnlyGame = _gpBlockerFocusGame(
        provinces: [
          for (var i = 0; i < 7; i++)
            Province(
              id: 'oldWorld|${_gpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: _gpOwn,
            ),
          for (var i = 0; i < 5; i++)
            Province(
              id: 'oldWorld|${_gpBlocker}_$i',
              regionId: 'oldWorld',
              ownerId: _gpBlocker,
            ),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _gpBlocker,
          ),
        ],
        atWarFactionIds: const [_gpDistraction],
        extraGpIds: const {_gpBlocker},
      );
      final gpOnlySnapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpDistraction],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      expect(
        stalledGpBlockerFocusPeaceTargets(
          game: gpOnlyGame,
          snapshot: gpOnlySnapshot,
        ),
        const [_gpDistraction],
        reason:
            'Sole GP war where the lone GP is not the blocker → return '
            'that GP so the planner can drop the distraction front.',
      );
    });
  });

  group('stalledStrongerGpBlockerPeaceTarget — canonical outer guards', () {
    test('returns null above stalled OW band', () {
      final game = _gpBlockerFocusGame(
        provinces: [
          for (var i = 0; i < 12; i++)
            Province(
              id: 'oldWorld|${_gpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: _gpOwn,
            ),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
        atWarFactionIds: const [_gpBlocker],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 12,
        atWarWith: const [_gpBlocker],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      expect(
        stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot),
        isNull,
      );
    });

    test(
      'returns null when no OW minor remains on the map (GP-blocker focus)',
      () {
        // Mirrors diplomacy_planner_stalled_peace_test: minor exists in
        // minorNations but owns no OW province → anyMinorOwnsOw is false.
        final game = _gpBlockerFocusGame(
          provinces: [
            for (var i = 0; i < 7; i++)
              Province(
                id: 'oldWorld|${_gpOwn}_$i',
                regionId: 'oldWorld',
                ownerId: _gpOwn,
              ),
            for (var i = 0; i < 10; i++)
              Province(
                id: 'oldWorld|${_gpBlocker}_$i',
                regionId: 'oldWorld',
                ownerId: _gpBlocker,
              ),
            const Province(
              id: 'oldWorld|inv1',
              regionId: 'oldWorld',
              ownerId: _gpBlocker,
            ),
          ],
          atWarFactionIds: const [_gpBlocker],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 7,
          atWarWith: const [_gpBlocker],
          invadableProvinceIdsSorted: const ['oldWorld|inv1'],
        );
        expect(
          stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot),
          isNull,
        );
      },
    );
  });

  group('stalledStrongerGpBlockerPeaceTarget — fire path', () {
    test('returns strongest non-blocker GP owning invadable OW provinces', () {
      final game = _gpBlockerFocusGame(
        provinces: [
          for (var i = 0; i < 7; i++)
            Province(
              id: 'oldWorld|${_gpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: _gpOwn,
            ),
          for (var i = 0; i < 10; i++)
            Province(
              id: 'oldWorld|${_gpBlocker}_$i',
              regionId: 'oldWorld',
              ownerId: _gpBlocker,
            ),
          for (var i = 0; i < 8; i++)
            Province(
              id: 'oldWorld|${_gpDistraction}_$i',
              regionId: 'oldWorld',
              ownerId: _gpDistraction,
            ),
          const Province(
            id: 'oldWorld|inv_blocker',
            regionId: 'oldWorld',
            ownerId: _gpBlocker,
          ),
          const Province(
            id: 'oldWorld|inv_distraction',
            regionId: 'oldWorld',
            ownerId: _gpDistraction,
          ),
          const Province(
            id: 'oldWorld|minor1_p1',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
        atWarFactionIds: const [_gpBlocker, _gpDistraction],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker, _gpDistraction],
        invadableProvinceIdsSorted: const [
          'oldWorld|inv_blocker',
          'oldWorld|inv_distraction',
        ],
      );
      expect(
        stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot),
        _gpDistraction,
        reason:
            'gp3 is the primary blocker; gp5 owns invadable land with '
            'lead 8-7=1 > 0 → strongest non-blocker GP is gp5.',
      );
    });

    test('returns null when sole at-war GP is the primary blocker', () {
      // Mirrors diplomacy_planner_stalled_peace_test first case: only
      // gp3 at war and gp3 is the blocker → no non-blocker candidate.
      final game = _gpBlockerFocusGame(
        provinces: [
          for (var i = 0; i < 7; i++)
            Province(
              id: 'oldWorld|${_gpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: _gpOwn,
            ),
          for (var i = 0; i < 10; i++)
            Province(
              id: 'oldWorld|${_gpBlocker}_$i',
              regionId: 'oldWorld',
              ownerId: _gpBlocker,
            ),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _gpBlocker,
          ),
          const Province(
            id: 'oldWorld|inv2',
            regionId: 'oldWorld',
            ownerId: _gpBlocker,
          ),
          const Province(
            id: 'oldWorld|minor1_p1',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
        atWarFactionIds: const [_gpBlocker],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker],
        invadableProvinceIdsSorted: const ['oldWorld|inv1', 'oldWorld|inv2'],
      );
      expect(
        stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot),
        isNull,
      );
    });
  });

  group('Determinism (Must-have #7)', () {
    test('stalledGpBlockerFocusPeaceTargets is identical on repeat', () {
      final game = _gpBlockerFocusGame(
        provinces: [
          for (var i = 0; i < 7; i++)
            Province(
              id: 'oldWorld|${_gpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: _gpOwn,
            ),
          for (var i = 0; i < 10; i++)
            Province(
              id: 'oldWorld|${_gpBlocker}_$i',
              regionId: 'oldWorld',
              ownerId: _gpBlocker,
            ),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _gpBlocker,
          ),
        ],
        atWarFactionIds: const [_gpBlocker, _gpDistraction],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker, _gpDistraction],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      final first = stalledGpBlockerFocusPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = stalledGpBlockerFocusPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(first, equals(second));
      expect(first, const [_gpDistraction]);
    });

    test('stalledStrongerGpBlockerPeaceTarget is identical on repeat', () {
      final game = _gpBlockerFocusGame(
        provinces: [
          for (var i = 0; i < 7; i++)
            Province(
              id: 'oldWorld|${_gpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: _gpOwn,
            ),
          for (var i = 0; i < 10; i++)
            Province(
              id: 'oldWorld|${_gpBlocker}_$i',
              regionId: 'oldWorld',
              ownerId: _gpBlocker,
            ),
          for (var i = 0; i < 8; i++)
            Province(
              id: 'oldWorld|${_gpDistraction}_$i',
              regionId: 'oldWorld',
              ownerId: _gpDistraction,
            ),
          const Province(
            id: 'oldWorld|inv_blocker',
            regionId: 'oldWorld',
            ownerId: _gpBlocker,
          ),
          const Province(
            id: 'oldWorld|inv_distraction',
            regionId: 'oldWorld',
            ownerId: _gpDistraction,
          ),
          const Province(
            id: 'oldWorld|minor1_p1',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
        atWarFactionIds: const [_gpBlocker, _gpDistraction],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker, _gpDistraction],
        invadableProvinceIdsSorted: const [
          'oldWorld|inv_blocker',
          'oldWorld|inv_distraction',
        ],
      );
      final first = stalledStrongerGpBlockerPeaceTarget(
        game: game,
        snapshot: snapshot,
      );
      final second = stalledStrongerGpBlockerPeaceTarget(
        game: game,
        snapshot: snapshot,
      );
      expect(first, equals(second));
      expect(first, _gpDistraction);
    });
  });

  group('Stub delegation parity', () {
    test('stalledGpBlockerFocusPeaceTargets stub mirrors canonical', () {
      final game = _gpBlockerFocusGame(
        provinces: [
          for (var i = 0; i < 7; i++)
            Province(
              id: 'oldWorld|${_gpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: _gpOwn,
            ),
          for (var i = 0; i < 10; i++)
            Province(
              id: 'oldWorld|${_gpBlocker}_$i',
              regionId: 'oldWorld',
              ownerId: _gpBlocker,
            ),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _gpBlocker,
          ),
        ],
        atWarFactionIds: const [_gpBlocker, _gpDistraction],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker, _gpDistraction],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      final canonical = stalledGpBlockerFocusPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final stub = diplomacy_planner_peace_targets
          .stalledGpBlockerFocusPeaceTargets(game: game, snapshot: snapshot);
      expect(stub, equals(canonical));
    });

    test('stalledStrongerGpBlockerPeaceTarget stub mirrors canonical', () {
      final game = _gpBlockerFocusGame(
        provinces: [
          for (var i = 0; i < 7; i++)
            Province(
              id: 'oldWorld|${_gpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: _gpOwn,
            ),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
          const Province(
            id: 'oldWorld|minor1_p1',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
        atWarFactionIds: const [_gpBlocker],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      final canonical = stalledStrongerGpBlockerPeaceTarget(
        game: game,
        snapshot: snapshot,
      );
      final stub = diplomacy_planner_peace_targets
          .stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot);
      expect(stub, equals(canonical));
    });
  });
}
