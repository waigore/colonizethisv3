import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('previewTotalTurnsForPendingWorkOrder', () {
    Game buildGame({
      required Unit unit,
      Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince =
          const {},
      TileMapState? tileState,
    }) {
      return Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
              Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
          tileState: tileState ?? TileMapState(),
        ),
        players: const [Player(id: 'h1', displayName: 'Human', isHuman: true)],
      );
    }

    test('returns scaled explore turns from province size', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: 'h1',
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final game = buildGame(
        unit: unit,
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'oldWorld|p1': ['oldWorld|p1|0|0', 'oldWorld|p1|1|0'],
            'oldWorld|p2': [
              'oldWorld|p2|0|0',
              'oldWorld|p2|1|0',
              'oldWorld|p2|2|0',
              'oldWorld|p2|3|0',
            ],
          },
        },
      );
      const order = WorkOrder(
        unitId: 'u1',
        target: kWorkTargetExplore,
        targetTileKey: 'oldWorld|p1|0|0',
      );

      final turns = previewTotalTurnsForPendingWorkOrder(
        game: game,
        unit: unit,
        order: order,
      );

      expect(turns, 2);
    });

    test('returns fort-level scaled turns for build_fort', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeEngineer,
        ownerId: 'h1',
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', fortLevel: 2),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'h1', displayName: 'Human', isHuman: true)],
      );
      const order = WorkOrder(
        unitId: 'u1',
        target: kWorkTargetBuildFort,
        targetTileKey: 'oldWorld|p1|0|0',
      );

      final turns = previewTotalTurnsForPendingWorkOrder(
        game: game,
        unit: unit,
        order: order,
      );

      expect(turns, 3);
    });

    test('returns minimum one turn for instant targets', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: 'h1',
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final game = buildGame(unit: unit);

      final prospectTurns = previewTotalTurnsForPendingWorkOrder(
        game: game,
        unit: unit,
        order: const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: 'oldWorld|p1|0|0',
        ),
      );
      final purchaseTurns = previewTotalTurnsForPendingWorkOrder(
        game: game,
        unit: unit,
        order: const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetPurchaseLand,
          targetTileKey: 'oldWorld|p1|0|0',
        ),
      );

      expect(prospectTurns, 1);
      expect(purchaseTurns, 1);
    });
  });
}
