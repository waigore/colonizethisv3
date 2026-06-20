import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

/// Regression cover for the connectivity per-player province cache built once
/// per `resolveConnectivity` call (Refs #2394). The previous implementation
/// scanned `allProvinces()` twice per player (owned-province set + town-tile
/// lookup); the consolidated single pass must keep results equivalent for
/// multi-player scenes, isolate ownership across players, and degrade
/// gracefully when ownership is mixed with unowned provinces.
void main() {
  group('ConnectivityResolver per-player province cache (Refs #2394)', () {
    test(
      'isolates per-player ownership in a single resolve call so unowned'
      ' province tiles do not bridge two players through propagation',
      () {
        const ow = 'oldWorld';
        // Three provinces in a line: p1 (pl1 owned), p2 (unowned buffer),
        // p3 (pl2 owned). Each player's capital is at the far edge so any
        // cross-player connectivity would have to traverse the unowned p2
        // buffer, which the per-player cache disallows.
        final grid = [
          ['p1', 'p2', 'p3'],
        ];
        final tileMap = TileMapResult(width: 3, height: 1, grid: grid);
        final topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p3',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        );
        final capPl1 = CapitalTile(
          regionId: ow,
          provinceId: '$ow|p1',
          x: 0,
          y: 0,
        );
        final capPl2 = CapitalTile(
          regionId: ow,
          provinceId: '$ow|p3',
          x: 2,
          y: 0,
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
                // p2 is unowned (ownerId == null) — must appear in neither
                // player's bucket in the per-player province cache.
                Province(id: '$ow|p2', regionId: ow),
                Province(id: '$ow|p3', regionId: ow, ownerId: 'pl2'),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'pl1',
              displayName: 'Spain',
              isHuman: true,
              capitalProvinceId: '$ow|p1',
              capitalTile: capPl1,
            ),
            Player(
              id: 'pl2',
              displayName: 'Portugal',
              isHuman: true,
              capitalProvinceId: '$ow|p3',
              capitalTile: capPl2,
            ),
            // pl3 has no province ownership and no capital declared — the
            // consolidated cache must still produce an empty result without
            // throwing.
            Player(id: 'pl3', displayName: 'Tribe', isHuman: false),
          ],
        );

        final result = resolveConnectivity(
          game: game,
          tileMapByRegion: {ow: tileMap},
          topology: topology,
        );

        expect(result.keys.toSet(), {'pl1', 'pl2', 'pl3'});

        final pl1Connected = result['pl1']!.connected;
        // pl1's own capital tile must always be present.
        expect(pl1Connected.contains('oldWorld|p1|0|0'), isTrue);
        // pl1 must not bridge through unowned p2 and reach pl2's capital
        // tile in p3; this is the per-player owned-cache guarantee.
        expect(pl1Connected.contains('oldWorld|p3|2|0'), isFalse);

        final pl2Connected = result['pl2']!.connected;
        expect(pl2Connected.contains('oldWorld|p3|2|0'), isTrue);
        expect(pl2Connected.contains('oldWorld|p1|0|0'), isFalse);

        // No capital and no owned provinces means the consolidated cache must
        // still return an empty `ConnectivityResult` (fallback path).
        expect(result['pl3']!.connected, isEmpty);
      },
    );

    test(
      'unowned provinces (ownerId == null) are excluded from every player'
      "'s cache and yield empty connectivity for orphan players",
      () {
        const ow = 'oldWorld';
        final grid = [
          ['p1', 'p2'],
        ];
        final tileMap = TileMapResult(width: 2, height: 1, grid: grid);
        final topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        );
        // p1 has no owner; p2 is owned. The unowned province must not appear
        // in any player's cached owned set, and the player whose capital tile
        // sits on an unowned province must get an empty result.
        final cap = CapitalTile(
          regionId: ow,
          provinceId: '$ow|p1',
          x: 0,
          y: 0,
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow),
                Province(id: '$ow|p2', regionId: ow, ownerId: 'pl2'),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'pl1',
              displayName: 'Spain',
              isHuman: true,
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
            Player(
              id: 'pl2',
              displayName: 'Portugal',
              isHuman: false,
              capitalProvinceId: '$ow|p2',
              capitalTile: CapitalTile(
                regionId: ow,
                provinceId: '$ow|p2',
                x: 1,
                y: 0,
              ),
            ),
          ],
        );

        final result = resolveConnectivity(
          game: game,
          tileMapByRegion: {ow: tileMap},
          topology: topology,
        );

        // pl1's capital province is unowned; cache contains no entry for pl1
        // so the early-return in `_connectedTilesForPlayer` triggers.
        expect(result['pl1']!.connected, isEmpty);
        // pl2 still gets its expected connectivity through the cache.
        expect(result['pl2']!.connected.contains('oldWorld|p2|1|0'), isTrue);
      },
    );
  });
}
