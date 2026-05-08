import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('OrderEngine', () {
    group('validateWork (build_improvement)', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$provinceId|0|0';

      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      test(
        'accepts build_improvement on purchased tile in foreign province',
        () {
          final foreignProvinceId = '$ow|P2';
          final foreignTileKey = '$foreignProvinceId|0|0';
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 0,
              ),
              oldWorld: RegionData(
                provinces: [
                  Province(id: provinceId, regionId: ow, ownerId: 'p1'),
                  Province(id: foreignProvinceId, regionId: ow, ownerId: 'p2'),
                ],
                units: [
                  Unit(
                    id: 'builder1',
                    type: kUnitTypeBuilder,
                    ownerId: 'p1',
                    locationProvinceId: provinceId,
                    tileKey: tileKey,
                  ),
                ],
              ),
              newWorld: const RegionData(),
              resourceByTileKey: {tileKey: 'grain', foreignTileKey: 'grain'},
              tileState: const TileMapState(),
              tileKeysByRegionAndProvince: {
                ow: {
                  provinceId: [tileKey],
                  foreignProvinceId: [foreignTileKey],
                },
              },
              playerVisibilityByTile: {
                'p1': {tileKey: 'fullyVisible', foreignTileKey: 'fullyVisible'},
              },
              purchasedTilesByTileKey: {foreignTileKey: 'p1'},
            ),
            players: [
              Player(
                id: 'p1',
                displayName: 'P1',
                isHuman: true,
                capitalProvinceId: provinceId,
                stockpile: Stockpile()
                    .applyDelta(CommodityCatalog.lumber.id, 2)
                    .applyDelta(CommodityCatalog.castIron.id, 2),
                techUnlocked: const {kTechIdCircularSaw: true},
              ),
              const Player(id: 'p2', displayName: 'P2', isHuman: false),
            ],
          );
          final engine = OrderEngine();
          engine.addWorkOrder(
            'p1',
            WorkOrder(
              unitId: 'builder1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: foreignTileKey,
            ),
          );
          final results = engine.validatePlayerOrdersWithContext(
            game,
            topology,
            'p1',
          );
          expect(results.single.status, OrderValidationStatus.accepted);
        },
      );
    });
  });
}
