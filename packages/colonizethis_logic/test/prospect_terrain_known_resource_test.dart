import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Regression coverage for prospect eligibility when terrain maps are present
/// but `resourceByTileKey` holds a terrain-known non-mineral (Refs #1914).
/// AC1–AC3 from the issue (validator, picker, suggestions) alongside helpers
/// tests in `orders_application_helpers_test.dart`.
void main() {
  group(
    'OrderEngine prospect validation (tile map + terrain-known resource)',
    () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$provinceId|0|0';

      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      TileMapResult hillsWoolTileMap() => TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['P1'],
        ],
        terrainGrid: const [
          [TerrainType.hills],
        ],
        resourceGrid: const [
          [Resource.wool],
        ],
      );

      test(
        'rejects prospect on known wool with hills terrain from tile map',
        () {
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 0,
              ),
              oldWorld: RegionData(
                provinces: [
                  Province(id: provinceId, regionId: ow, ownerId: 'tribe1'),
                ],
                units: [
                  Unit(
                    id: 'u1',
                    type: kUnitTypeExplorer,
                    ownerId: 'p1',
                    locationProvinceId: provinceId,
                    tileKey: tileKey,
                  ),
                ],
              ),
              newWorld: const RegionData(),
              resourceByTileKey: const {tileKey: 'wool'},
              playerVisibilityByTile: const {
                'p1': {tileKey: 'fogged'},
              },
              tileKeysByRegionAndProvince: {
                ow: {
                  provinceId: [tileKey],
                },
              },
            ),
            players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
            tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
          );

          final engine = OrderEngine();
          engine.addWorkOrder(
            'p1',
            const WorkOrder(
              unitId: 'u1',
              target: kWorkTargetProspect,
              targetTileKey: tileKey,
            ),
          );
          final results = engine.validatePlayerOrdersWithContext(
            game,
            topology,
            'p1',
            tileMapByRegion: {ow: hillsWoolTileMap()},
          );
          expect(results.single.status, OrderValidationStatus.rejected);
          expect(results.single.reason, contains('mineral-eligible'));
        },
      );

      test(
        'rejects prospect when iron tile already prospected (tile map present)',
        () {
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 0,
              ),
              oldWorld: RegionData(
                provinces: [
                  Province(id: provinceId, regionId: ow, ownerId: 'tribe1'),
                ],
                units: [
                  Unit(
                    id: 'u1',
                    type: kUnitTypeExplorer,
                    ownerId: 'p1',
                    locationProvinceId: provinceId,
                    tileKey: tileKey,
                  ),
                ],
              ),
              newWorld: const RegionData(),
              resourceByTileKey: const {tileKey: 'iron'},
              playerProspectedTiles: const {
                'p1': {tileKey},
              },
              playerVisibilityByTile: const {
                'p1': {tileKey: 'fogged'},
              },
              tileKeysByRegionAndProvince: {
                ow: {
                  provinceId: [tileKey],
                },
              },
            ),
            players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
            tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
          );

          final engine = OrderEngine();
          engine.addWorkOrder(
            'p1',
            const WorkOrder(
              unitId: 'u1',
              target: kWorkTargetProspect,
              targetTileKey: tileKey,
            ),
          );
          final results = engine.validatePlayerOrdersWithContext(
            game,
            topology,
            'p1',
            tileMapByRegion: {
              ow: TileMapResult(
                width: 1,
                height: 1,
                grid: const [
                  ['P1'],
                ],
                terrainGrid: const [
                  [TerrainType.hills],
                ],
                resourceGrid: const [
                  [Resource.iron],
                ],
              ),
            },
          );
          expect(results.single.status, OrderValidationStatus.rejected);
          expect(results.single.reason, contains('already prospected'));
        },
      );
    },
  );

  group('suggestWorkOrders prospect (tile map + terrain-known resource)', () {
    test(
      'does not emit prospect for wool on prospectable hills when tile map is present',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const tileKey = 'oldWorld|p1|0|0';
        final player = const Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
        );
        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
        );
        final tileMapByRegion = <String, TileMapResult>{
          ow: TileMapResult(
            width: 1,
            height: 1,
            grid: const [
              ['p1'],
            ],
            terrainGrid: const [
              [TerrainType.hills],
            ],
            resourceGrid: const [
              [Resource.wool],
            ],
          ),
        };
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1], units: [unit]),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            playerId: {tileKey: 'fogged'},
          },
          resourceByTileKey: const {tileKey: 'wool'},
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': [tileKey],
            },
          },
        );
        final game = Game(
          id: 'g1',
          worldState: world,
          players: [player],
          tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
          tileMapByRegion: tileMapByRegion,
        );
        expect(
          suggestions.where((o) => o.target == kWorkTargetProspect),
          isEmpty,
        );
      },
    );
  });
}
