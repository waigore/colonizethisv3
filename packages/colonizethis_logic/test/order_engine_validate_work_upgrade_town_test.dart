import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('OrderEngine', () {
    group('validateWork (upgrade_town tech)', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$provinceId|0|0';

      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      test('rejects upgrade_town without National Bureaucracy', () {
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
                  townTileKey: tileKey,
                  townDevelopmentLevel: 1,
                ),
              ],
              units: [
                Unit(
                  id: 'b1',
                  type: kUnitTypeBuilder,
                  ownerId: 'p1',
                  locationProvinceId: provinceId,
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {provinceId: [tileKey]},
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
                  .applyDelta(CommodityCatalog.lumber.id, 10)
                  .applyDelta(CommodityCatalog.castIron.id, 10),
              techUnlocked: const {},
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetUpgradeTown,
            targetTileKey: tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('National Bureaucracy'));
      });

      test('accepts upgrade_town when National Bureaucracy unlocked', () {
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
                  townTileKey: tileKey,
                  townDevelopmentLevel: 1,
                ),
              ],
              units: [
                Unit(
                  id: 'b1',
                  type: kUnitTypeBuilder,
                  ownerId: 'p1',
                  locationProvinceId: provinceId,
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {provinceId: [tileKey]},
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
                  .applyDelta(CommodityCatalog.lumber.id, 10)
                  .applyDelta(CommodityCatalog.castIron.id, 10),
              techUnlocked: const {kTechIdNationalBureaucracy: true},
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetUpgradeTown,
            targetTileKey: tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.accepted);
      });
    });
  });
}
