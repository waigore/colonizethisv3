import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/world/connectivity_faction_input.dart';

void main() {
  group('buildFactionProvinceCaches', () {
    test('buckets owned provinces and town tiles by owner (positive)', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'gp1',
                townTileKey: 'oldWorld|p1|0|0',
              ),
              Province(
                id: 'oldWorld|p2',
                regionId: 'oldWorld',
                ownerId: 'm1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'gp1', displayName: 'GP', isHuman: true)],
        minorNations: const [MinorNation(id: 'm1')],
      );

      final caches = buildFactionProvinceCaches(game);

      expect(caches.ownedByFaction['gp1'], {'oldWorld|p1'});
      expect(caches.ownedByFaction['m1'], {'oldWorld|p2'});
      expect(caches.townByTileKeyByFaction['gp1']!.keys, ['oldWorld|p1|0|0']);
    });

    test('skips unowned provinces (negative)', () {
      final game = Game(
        id: 'g2',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
            ],
          ),
          newWorld: RegionData(),
        ),
        players: const [],
      );

      final caches = buildFactionProvinceCaches(game);

      expect(caches.ownedByFaction, isEmpty);
      expect(caches.townByTileKeyByFaction, isEmpty);
    });
  });

  group('ConnectivityFactionInput', () {
    test('fromGame exposes topology and ownership inputs (positive)', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g3',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'gp1',
              ),
            ],
          ),
          newWorld: RegionData(),
        ),
        players: const [Player(id: 'gp1', displayName: 'GP', isHuman: true)],
      );

      final input = ConnectivityFactionInput.fromGame(
        game: game,
        topology: topology,
      );

      expect(input.provinceIdsByType, contains('oldWorld|p1'));
      expect(input.topologySeaZones, contains('oldWorld|sea1'));
      expect(input.ownedByFaction['gp1'], {'oldWorld|p1'});
    });
  });
}
