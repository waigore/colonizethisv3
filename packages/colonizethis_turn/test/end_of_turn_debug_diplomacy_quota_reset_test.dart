import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/src/turn/end_of_turn_resolver.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('runEndOfTurnPhase debug diplomacy quota reset', () {
    MapTopology minimalTopology() {
      const ow = 'oldWorld';
      return MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
    }

    Game gameAtTurn(int turn, Set<String> usedPairKeys) {
      const ow = 'oldWorld';
      return Game(
        id: 'g-quota',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.endOfTurn, turnNumber: turn),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true),
        ],
        debugDiplomacyUsedPairKeys: usedPairKeys,
      );
    }

    test('clears used pair keys when the turn advances', () {
      final after = runEndOfTurnPhase(
        gameAtTurn(5, {'gp1|gp2'}),
        topology: minimalTopology(),
      );

      expect(after.worldState.turnState.turnNumber, 6);
      expect(after.debugDiplomacyUsedPairKeys, isEmpty);
    });
  });
}
