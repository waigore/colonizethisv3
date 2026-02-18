import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:test/test.dart';

void main() {
  group('PlayerView', () {
    test('buildPlayerView collects own units, provinces and diplomacy', () {
      final player = const Player(
        id: 'gp1',
        displayName: 'Test GP',
        isHuman: false,
      );
      final otherPlayer = const Player(
        id: 'gp2',
        displayName: 'Other GP',
        isHuman: false,
      );

      final p1 = const Province(id: 'p1', regionId: 'oldWorld', displayName: 'P1');
      final p2 = const Province(
        id: 'p2',
        regionId: 'oldWorld',
        displayName: 'P2',
        ownerId: 'gp2',
      );

      final u1 = const Unit(
        id: 'u1',
        type: 'inf',
        ownerId: 'gp1',
        provinceId: 'p1',
      );
      final u2 = const Unit(
        id: 'u2',
        type: 'inf',
        ownerId: 'gp2',
        provinceId: 'p2',
      );

      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [p1, p2],
          units: [u1, u2],
        ),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          'gp1': {
            'oldWorld|p1|0|0': 'fullyVisible',
          },
        },
        playerProspectedTiles: const {
          'gp1': {'oldWorld|p1|0|0'},
        },
      );

      final relation = const DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
      );

      final game = Game(
        id: 'g1',
        worldState: world,
        players: [player, otherPlayer],
        diplomacyRelations: [relation],
      );

      final topology = MapTopology(nodes: const [], edges: const []);

      final view = buildPlayerView(game, topology, 'gp1');

      expect(view.playerId, 'gp1');
      expect(view.player.id, 'gp1');

      // Own units: only u1 should be visible as owned by gp1.
      expect(view.ownUnitsById.length, 1);
      expect(view.ownUnitsById['u1'], isNotNull);
      expect(view.ownUnitsById['u1']!.ownerId, 'gp1');

      // Provinces: both p1 and p2 are known at this stage.
      expect(view.provincesById.keys, containsAll(<String>['p1', 'p2']));

      // Diplomacy: relation with gp2 is indexed.
      final rel = view.relationWith('gp2');
      expect(rel, isNotNull);
      expect(rel!.factionId1 == 'gp1' || rel.factionId2 == 'gp1', isTrue);

      // Visibility and prospection: values are propagated from WorldState.
      expect(
        view.visibilityForTile('oldWorld|p1|0|0'),
        VisibilityLevel.fullyVisible,
      );
      expect(
        view.tileIsProspected('oldWorld|p1|0|0'),
        isTrue,
      );
    });
  });
}

