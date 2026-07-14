// Topic-split case module (Refs #3997 Phase 8).
// Pin/row coverage preserved 1:1 from the former combined cases file.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _minor1 = 'minor1';
const String _minor2 = 'minor2';

const List<Player> _gp1gp2 = <Player>[
  Player(id: _gp1, displayName: 'GP1', isHuman: false),
  Player(id: _gp2, displayName: 'GP2', isHuman: false),
];
const List<Player> _gp1only = <Player>[
  Player(id: _gp1, displayName: 'GP1', isHuman: false),
];

class _Case {
  const _Case({
    required this.name,
    required this.players,
    required this.playerId,
    required this.owProvinces,
    required this.ow,
    required this.expected,
    this.minorNations = const <MinorNation>[],
    this.atWarWith = const <String>[],
    this.invadable = const <String>[],
    this.turnNumber = 80,
  });

  final String name;
  final List<Player> players;
  final String playerId;
  final List<Province> owProvinces;
  final int ow;
  final bool expected;
  final List<MinorNation> minorNations;
  final List<String> atWarWith;
  final List<String> invadable;
  final int turnNumber;
}

Game _buildGame(_Case c) => Game(
  id: 'g-expand-peace-predicate-matrix',
  worldState: WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: c.turnNumber),
    oldWorld: RegionData(provinces: c.owProvinces),
    newWorld: const RegionData(),
  ),
  players: c.players,
  minorNations: c.minorNations,
);

AIWorldSnapshot _snapshot(_Case c) => AIWorldSnapshot(
  playerId: c.playerId,
  threats: ThreatSummary(atWarWith: c.atWarWith),
  opportunities: const OpportunitySummary(),
  conquest: ConquestSummary(
    oldWorldProvincesOwned: c.ow,
    invadableProvinceIdsSorted: c.invadable,
  ),
  colonial: const ColonialSummary(),
  economy: const EconomySummary(),
  relations: const {},
);

void registerExpandPeaceGamePredicateDeterminismCases() {
  group('peace-predicate determinism guards', () {
    test(
      'canPivotFromSoleGpWarAfterPeace: identical inputs produce identical '
      'outputs (must-have #7)',
      () {
        const c = _Case(
          name: 'determinism',
          players: _gp1gp2,
          playerId: _gp1,
          owProvinces: [
            Province(id: 'oldWorld|gp1_1', regionId: 'oldWorld', ownerId: _gp1),
            Province(id: 'oldWorld|gp1_2', regionId: 'oldWorld', ownerId: _gp1),
            Province(id: 'oldWorld|gp1_3', regionId: 'oldWorld', ownerId: _gp1),
            Province(id: 'oldWorld|gp1_4', regionId: 'oldWorld', ownerId: _gp1),
            Province(id: 'oldWorld|gp1_5', regionId: 'oldWorld', ownerId: _gp1),
            Province(id: 'oldWorld|gp1_6', regionId: 'oldWorld', ownerId: _gp1),
            Province(id: 'oldWorld|gp1_7', regionId: 'oldWorld', ownerId: _gp1),
            Province(id: 'oldWorld|gp1_8', regionId: 'oldWorld', ownerId: _gp1),
            Province(id: 'oldWorld|minor1_a', regionId: 'oldWorld', ownerId: _minor1),
          ],
          minorNations: [MinorNation(id: _minor1, displayName: 'M1')],
          ow: 8,
          atWarWith: [_gp2],
          invadable: ['oldWorld|minor1_a'],
          expected: true,
        );
        final game = _buildGame(c);
        final snapshot = _snapshot(c);
        final first =
            canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot);
        final second =
            canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot);
        final third =
            canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot);
        expect(first, isTrue);
        expect(second, first);
        expect(third, first);
      },
    );

    test(
      'hasUninvadedOldWorldMinor: identical inputs produce identical outputs',
      () {
        const c = _Case(
          name: 'determinism',
          players: _gp1only,
          playerId: _gp1,
          owProvinces: [
            Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
            Province(id: 'oldWorld|m2_a', regionId: 'oldWorld', ownerId: _minor2),
          ],
          minorNations: [
            MinorNation(id: _minor1, displayName: 'M1'),
            MinorNation(id: _minor2, displayName: 'M2'),
          ],
          ow: 0,
          atWarWith: [_minor1],
          turnNumber: 50,
          expected: true,
        );
        final game = _buildGame(c);
        final snapshot = _snapshot(c);
        final first = hasUninvadedOldWorldMinor(game: game, snapshot: snapshot);
        final second = hasUninvadedOldWorldMinor(game: game, snapshot: snapshot);
        expect(second, first);
        expect(
          first,
          isTrue,
          reason:
              'Sanity-check the determinism fixture exercises the positive '
              'branch (so a regression that always returned false would '
              'still fail this group, not just silently match itself).',
        );
      },
    );
  });
}
