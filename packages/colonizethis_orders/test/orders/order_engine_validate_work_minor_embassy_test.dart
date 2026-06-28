import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('OrderEngine', () {
    group('validateWork (Minor/Tribe embassy + diplomatic_expertise)', () {
      const ow = 'oldWorld';
      const minorProvId = '$ow|MN';
      const tileKey = '$minorProvId|0|0';

      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'MN', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      test('rejects build_road in minor province without embassy path', () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: minorProvId, regionId: ow, ownerId: 'minor1'),
              ],
              units: [
                Unit(
                  id: 'e1',
                  type: kUnitTypeEngineer,
                  ownerId: 'gp1',
                  locationProvinceId: minorProvId,
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {minorProvId: [tileKey]},
            },
            playerVisibilityByTile: const {
              'gp1': {tileKey: 'fullyVisible'},
            },
          ),
          players: [
            Player(
              id: 'gp1',
              displayName: 'GP1',
              isHuman: true,
              capitalProvinceId: '$ow|CAP',
              stockpile: Stockpile()
                  .applyDelta(CommodityCatalog.lumber.id, 4)
                  .applyDelta(CommodityCatalog.castIron.id, 4),
              techUnlocked: const {kTechIdDiplomaticExpertise: true},
            ),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor'),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'minor1',
              state: RelationState.atPeace,
              level: RelationLevel.neutral,
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'gp1',
          const WorkOrder(
            unitId: 'e1',
            target: kWorkTargetBuildRoad,
            targetTileKey: tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'gp1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('foreign province'));
      });

      test(
        'rejects build_road in minor province even with embassy when occupancy disallows tile',
        () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: minorProvId, regionId: ow, ownerId: 'minor1'),
              ],
              units: [
                Unit(
                  id: 'e1',
                  type: kUnitTypeEngineer,
                  ownerId: 'gp1',
                  locationProvinceId: minorProvId,
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {minorProvId: [tileKey]},
            },
            playerVisibilityByTile: const {
              'gp1': {tileKey: 'fullyVisible'},
            },
          ),
          players: [
            Player(
              id: 'gp1',
              displayName: 'GP1',
              isHuman: true,
              capitalProvinceId: '$ow|CAP',
              stockpile: Stockpile()
                  .applyDelta(CommodityCatalog.lumber.id, 4)
                  .applyDelta(CommodityCatalog.castIron.id, 4),
              techUnlocked: const {kTechIdDiplomaticExpertise: true},
            ),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor'),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'minor1',
              state: RelationState.atPeace,
              level: RelationLevel.neutral,
            ),
          ],
          overtureStates: const [
            OvertureState(
              gpId: 'gp1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'gp1',
          const WorkOrder(
            unitId: 'e1',
            target: kWorkTargetBuildRoad,
            targetTileKey: tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'gp1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('cannot occupy'));
      },
      );
    });
  });
}
