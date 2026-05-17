import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  suppressLogsForTests();

  group('suggestArmyMoveOrders', () {
    const gp = 'gp1';
    const cap = 'oldWorld|cap';
    const p1 = 'oldWorld|p1';
    const nw = 'newWorld|col';

    Game game0({String? extraNeighborProvinceId}) {
      final provinces = <Province>[
        Province(
          id: cap,
          regionId: 'oldWorld',
          ownerId: gp,
          townTileKey: 'oldWorld|cap|0|0',
        ),
        Province(id: p1, regionId: 'oldWorld', ownerId: gp),
      ];
      if (extraNeighborProvinceId != null) {
        provinces.add(
          Province(
            id: extraNeighborProvinceId,
            regionId: 'oldWorld',
            ownerId: gp,
          ),
        );
      }
      return Game(
        id: 'g_army_sug',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: provinces,
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: gp,
                locationProvinceId: p1,
                tileKey: 'oldWorld|p1|0|0',
              ),
            ],
          ),
          newWorld: RegionData(
            provinces: [Province(id: nw, regionId: 'newWorld', ownerId: gp)],
          ),
          armies: [
            Army(
              id: homeArmyIdFor(gp),
              ownerId: gp,
              regionId: 'oldWorld',
              stationedProvinceId: cap,
              regimentUnitIds: const [],
              isHomeArmy: true,
            ),
            Army(
              id: 'field_a',
              ownerId: gp,
              regionId: 'oldWorld',
              stationedProvinceId: p1,
              regimentUnitIds: const ['u1'],
              isHomeArmy: false,
            ),
          ],
          playerVisibilityByTile: {
            gp: {
              'oldWorld|cap|0|0': 'fullyVisible',
              'oldWorld|p1|0|0': 'fullyVisible',
              'newWorld|col|0|0': 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              cap: ['oldWorld|cap|0|0'],
              p1: ['oldWorld|p1|0|0'],
            },
            'newWorld': {
              nw: ['newWorld|col|0|0'],
            },
          },
        ),
        players: [
          Player(
            id: gp,
            displayName: 'T',
            isHuman: true,
            capitalProvinceId: cap,
          ),
        ],
      );
    }

    MapTopology topology0({bool includeP2 = false}) {
      final nodes = <TopologyNode>[
        const TopologyNode(
          id: 'oldWorld|cap',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        const TopologyNode(
          id: 'oldWorld|p1',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        const TopologyNode(
          id: 'newWorld|col',
          regionId: 'newWorld',
          type: TopologyNodeType.province,
        ),
      ];
      final edges = <TopologyEdge>[];
      if (includeP2) {
        nodes.add(
          const TopologyNode(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        );
        edges.add(const TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2'));
      }
      return MapTopology(nodes: nodes, edges: edges);
    }

    test('includes cross-region player-owned province as destination', () {
      final game = game0();
      final topology = topology0();
      final view = buildPlayerView(game, topology, gp);
      final suggestions = suggestArmyMoveOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(
        suggestions.any(
          (s) => s.armyId == 'field_a' && s.destinationProvinceId == nw,
        ),
        isTrue,
      );
    });

    test('armyMoveCandidateDestinationProvinceIds with PlayerView-owned cache '
        'matches legacy allProvinces scan', () {
      final game = game0();
      final topology = topology0();
      final view = buildPlayerView(game, topology, gp);
      final army = game.worldState.armies.firstWhere((a) => a.id == 'field_a');
      final ownedFromView = <String>{
        for (final e in view.provincesById.entries)
          if (e.value.ownerId == gp) e.key,
      };
      final withoutCache = armyMoveCandidateDestinationProvinceIds(
        game: game,
        topology: topology,
        playerId: gp,
        army: army,
      );
      final withCache = armyMoveCandidateDestinationProvinceIds(
        game: game,
        topology: topology,
        playerId: gp,
        army: army,
        playerOwnedFullProvinceIds: ownedFromView,
      );
      expect(withCache, withoutCache);
    });

    test(
      'still proposes alternate destination when draft has prior army move',
      () {
        const p2 = 'oldWorld|p2';
        final game = game0(extraNeighborProvinceId: p2);
        final topology = topology0(includeP2: true);
        final tileKeys = Map<String, List<String>>.from(
          game.worldState.tileKeysByRegionAndProvince['oldWorld']!,
        );
        tileKeys[p2] = ['oldWorld|p2|0|0'];
        final ws = game.worldState.copyWith(
          tileKeysByRegionAndProvince: {
            ...game.worldState.tileKeysByRegionAndProvince,
            'oldWorld': tileKeys,
          },
          playerVisibilityByTile: {
            gp: {
              ...game.worldState.playerVisibilityByTile[gp]!,
              'oldWorld|p2|0|0': 'fullyVisible',
            },
          },
        );
        final game2 = game.copyWith(worldState: ws);

        final view2 = buildPlayerView(game2, topology, gp);
        final current = Orders(
          armyMoveOrdersByPlayerId: {
            gp: [ArmyMoveOrder(armyId: 'field_a', destinationProvinceId: p2)],
          },
        );
        final suggestions = suggestArmyMoveOrders(
          view2,
          game2,
          topology,
          current,
        );
        expect(
          suggestions.any((s) => s.destinationProvinceId == nw),
          isTrue,
          reason:
              'replacement-aware validation should allow other owned destinations',
        );
      },
    );
  });

  group('armyMoveCandidateDestinationProvinceIds', () {
    test('cached player-owned set matches default allProvinces scan', () {
      const gp = 'gp1';
      const cap = 'oldWorld|cap';
      const p1 = 'oldWorld|p1';
      const nw = 'newWorld|col';
      const p2 = 'oldWorld|p2';
      final game = Game(
        id: 'g_army_dest_ids',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: cap,
                regionId: 'oldWorld',
                ownerId: gp,
                townTileKey: 'oldWorld|cap|0|0',
              ),
              Province(id: p1, regionId: 'oldWorld', ownerId: gp),
              Province(id: p2, regionId: 'oldWorld', ownerId: gp),
            ],
            units: const [],
          ),
          newWorld: RegionData(
            provinces: [Province(id: nw, regionId: 'newWorld', ownerId: gp)],
          ),
          armies: [
            Army(
              id: 'field_a',
              ownerId: gp,
              regionId: 'oldWorld',
              stationedProvinceId: p1,
              regimentUnitIds: const [],
              isHomeArmy: false,
            ),
          ],
          tileKeysByRegionAndProvince: const {},
        ),
        players: [
          Player(
            id: gp,
            displayName: 'T',
            isHuman: true,
            capitalProvinceId: cap,
          ),
        ],
      );
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'oldWorld|cap',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'newWorld|col',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2')],
      );
      final army = game.worldState.armies.first;
      final uncached = armyMoveCandidateDestinationProvinceIds(
        game: game,
        topology: topology,
        playerId: gp,
        army: army,
      );
      final owned = <String>{
        for (final p in allProvinces(game.worldState))
          if (p.ownerId == gp) toFullProvinceId(p.regionId, p.id),
      };
      final cached = armyMoveCandidateDestinationProvinceIds(
        game: game,
        topology: topology,
        playerId: gp,
        army: army,
        playerOwnedFullProvinceIds: owned,
      );
      expect(cached, uncached);
    });
  });
}
