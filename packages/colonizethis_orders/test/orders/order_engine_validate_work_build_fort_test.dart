import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('OrderEngine', () {
    group('validateWork (build_fort tech)', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$provinceId|0|0';

      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      test('rejects build_fort to level 2 without Mine Engineering', () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: provinceId,
                  regionId: ow,
                  ownerId: 'p1',
                  fortLevel: 1,
                ),
              ],
              units: [
                Unit(
                  id: 'eng1',
                  type: kUnitTypeEngineer,
                  ownerId: 'p1',
                  locationProvinceId: provinceId,
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                provinceId: [tileKey],
              },
            },
            playerVisibilityByTile: const {
              'p1': {tileKey: 'fullyVisible'},
            },
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: provinceId,
              stockpile: Stockpile()
                  .applyDelta(CommodityCatalog.lumber.id, 4)
                  .applyDelta(CommodityCatalog.bronze.id, 4),
              techUnlocked: {},
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          const WorkOrder(
            unitId: 'eng1',
            target: kWorkTargetBuildFort,
            targetTileKey: tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('Mine Engineering'));
      });

      test('rejects build_fort to level 3 without Modern Forts', () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: provinceId,
                  regionId: ow,
                  ownerId: 'p1',
                  fortLevel: 2,
                ),
              ],
              units: [
                Unit(
                  id: 'eng1',
                  type: kUnitTypeEngineer,
                  ownerId: 'p1',
                  locationProvinceId: provinceId,
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                provinceId: [tileKey],
              },
            },
            playerVisibilityByTile: const {
              'p1': {tileKey: 'fullyVisible'},
            },
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: provinceId,
              stockpile: Stockpile()
                  .applyDelta(CommodityCatalog.steel.id, 5)
                  .applyDelta(CommodityCatalog.lumber.id, 5),
              techUnlocked: const {kTechIdMineEngineering: true},
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          const WorkOrder(
            unitId: 'eng1',
            target: kWorkTargetBuildFort,
            targetTileKey: tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('Modern Forts'));
      });
    });
  });
}
