import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('OrderEngine work-order uniqueness', () {
    test('rejects second pending work order for same unit in one turn', () {
      const regionId = 'oldWorld';
      const provinceId = '$regionId|P1';
      const tileA = '$provinceId|0|0';
      const tileB = '$provinceId|1|0';

      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: provinceId, regionId: regionId, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'builder1',
                type: kUnitTypeBuilder,
                ownerId: 'p1',
                locationProvinceId: provinceId,
                tileKey: tileA,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            regionId: {
              provinceId: [tileA, tileB],
            },
          },
          resourceByTileKey: const {tileA: 'grain', tileB: 'grain'},
          playerVisibilityByTile: const {
            'p1': {tileA: 'fullyVisible', tileB: 'fullyVisible'},
          },
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: provinceId,
            stockpile: Stockpile()
                .applyDelta(CommodityCatalog.lumber.id, 20)
                .applyDelta(CommodityCatalog.castIron.id, 20),
            techUnlocked: const {kTechIdCircularSaw: true},
          ),
        ],
      );

      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: regionId,
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );

      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'builder1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: tileA,
        ),
      );
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'builder1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: tileB,
        ),
      );

      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results, hasLength(2));
      expect(results.first.status, OrderValidationStatus.accepted);
      expect(results.last.status, OrderValidationStatus.rejected);
      expect(
        results.last.reason,
        contains('Only one work order per unit is allowed each turn'),
      );
    });
  });
}
