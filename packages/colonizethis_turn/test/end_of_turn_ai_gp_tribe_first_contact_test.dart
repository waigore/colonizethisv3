import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/src/turn/end_of_turn_resolver.dart';

const _ow = 'oldWorld';
const _nw = 'newWorld';

MapTopology _minimalTopology() => const MapTopology(
  nodes: [
    TopologyNode(id: '$_ow|p1', regionId: _ow, type: TopologyNodeType.province),
  ],
  edges: [],
);

/// End-of-turn fixture: an AI GP holds visibility into a New World tribe colony
/// tile while the human GP holds visibility into the same tile. No GP–Tribe
/// relation exists. (Refs #3620 AC-5)
Game _gameAtEndOfTurn() {
  return Game(
    id: 'g-eot',
    turnTimeMapping: TurnTimeMapping.gdd01,
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.endOfTurn, turnNumber: 5),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$_ow|p1', regionId: _ow, ownerId: 'gp1'),
          Province(id: '$_ow|p2', regionId: _ow, ownerId: 'gp2'),
        ],
      ),
      newWorld: RegionData(
        provinces: [Province(id: '$_nw|t1', regionId: _nw, ownerId: 'tribe1')],
      ),
      playerVisibilityByTile: {
        'gp1': {'$_nw|t1|0|0': 'fullyVisible'},
        'gp2': {'$_nw|t1|0|0': 'fullyVisible'},
      },
      tileKeysByRegionAndProvince: {
        _nw: {
          '$_nw|t1': ['$_nw|t1|0|0'],
        },
      },
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Spain', isHuman: true),
      Player(id: 'gp2', displayName: 'France', isHuman: false),
    ],
    tribes: const [Tribe(id: 'tribe1', displayName: 'Maya')],
    diplomacyRelations: const [],
  );
}

void main() {
  suppressLogsForTests();

  group('runEndOfTurnPhase GP-Tribe first contact (AI parity)', () {
    test('AI GP gains a persisted GP-Tribe relation; human GP does not', () {
      final after = runEndOfTurnPhase(
        _gameAtEndOfTurn(),
        topology: _minimalTopology(),
      );

      final aiRel = getRelation(after, 'gp2', 'tribe1');
      expect(aiRel, isNotNull);
      expect(aiRel!.state, RelationState.atPeace);
      expect(aiRel.score, relationScoreNeutral);
      expect(aiRel.level, RelationLevel.neutral);

      // Human relation persistence/herald remain the app layer's responsibility.
      expect(getRelation(after, 'gp1', 'tribe1'), isNull);
      expect(after.diplomacyRelations.length, 1);
    });

    test('negative: AI GP without NW visibility gets no relation', () {
      final base = _gameAtEndOfTurn();
      final game = base.copyWith(
        worldState: base.worldState.copyWith(
          playerVisibilityByTile: const {
            'gp2': {'$_ow|p2|0|0': 'fullyVisible'},
          },
        ),
      );

      final after = runEndOfTurnPhase(game, topology: _minimalTopology());

      expect(getRelation(after, 'gp2', 'tribe1'), isNull);
      expect(after.diplomacyRelations, isEmpty);
    });
  });
}
