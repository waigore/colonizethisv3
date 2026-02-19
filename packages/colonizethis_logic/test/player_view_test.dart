import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

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

      const ow = 'oldWorld';
      final p1 = Province(id: '$ow|p1', regionId: ow, displayName: 'P1');
      final p2 = Province(
        id: '$ow|p2',
        regionId: ow,
        displayName: 'P2',
        ownerId: 'gp2',
      );

      final u1 = Unit(
        id: 'u1',
        type: 'inf',
        ownerId: 'gp1',
        provinceId: '$ow|p1',
      );
      final u2 = Unit(
        id: 'u2',
        type: 'inf',
        ownerId: 'gp2',
        provinceId: '$ow|p2',
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

      // Provinces: keyed by regionId|provinceId so both regions can share ids.
      expect(
        view.provincesById.keys,
        containsAll(<String>['oldWorld|p1', 'oldWorld|p2']),
      );
      expect(
        view.provinceByRegionAndId('oldWorld', 'p1')?.displayName,
        'P1',
      );
      expect(
        view.provinceByRegionAndId('oldWorld', 'p2')?.ownerId,
        'gp2',
      );

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

