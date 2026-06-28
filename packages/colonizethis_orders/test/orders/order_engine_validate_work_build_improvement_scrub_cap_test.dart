import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// build_improvement terrain extraction-cap prechecks for the forest split
/// (R4 / AC10, issue #3573): scrub-forest timber is hard-capped at level 1, so
/// raising a level-1 scrub timber tile must be rejected even with full gathering
/// tech; hardwood timber follows the normal tech progression.
void main() {
  group('validateWork (build_improvement) — scrub timber terrain cap', () {
    const ow = 'oldWorld';
    const provinceId = '$ow|P1';
    const tileKey = '$provinceId|0|0';

    final topology = MapTopology(
      nodes: const [
        TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
      ],
      edges: const [],
    );

    Map<String, TileMapResult> tileMaps(TerrainType terrain) => {
      ow: TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['P1'],
        ],
        terrainGrid: [
          [terrain],
        ],
        resourceGrid: const [
          [Resource.timber],
        ],
      ),
    };

    Game baseGame({required int level}) {
      return Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: provinceId, regionId: ow, ownerId: 'p1'),
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
          resourceByTileKey: const {tileKey: 'timber'},
          tileState: TileMapState(
            improvementByTile: {tileKey: level},
          ),
          tileKeysByRegionAndProvince: const {
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
                .applyDelta(CommodityCatalog.lumber.id, 20)
                .applyDelta(CommodityCatalog.castIron.id, 20),
            techUnlocked: const {
              kTechIdSawMill: true,
              kTechIdWindSawMill: true,
              kTechIdCircularSaw: true,
            },
          ),
        ],
      );
    }

    OrderValidationResult validate(Game game, TerrainType terrain) {
      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'builder1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: tileKey,
        ),
      );
      return engine
          .validatePlayerOrdersWithContext(
            game,
            topology,
            'p1',
            tileMapByRegion: tileMaps(terrain),
          )
          .single;
    }

    test(
      'rejects raising scrub timber from level 1 even with circular_saw',
      () {
        final result = validate(baseGame(level: 1), TerrainType.scrubForest);
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, contains('Terrain caps'));
        expect(result.reason, contains('level 1'));
      },
    );

    test('accepts raising hardwood timber from level 1 with circular_saw', () {
      final result = validate(baseGame(level: 1), TerrainType.hardwoodForest);
      expect(result.status, OrderValidationStatus.accepted);
    });

    test('accepts initial scrub timber improvement (level 0 -> 1)', () {
      final result = validate(baseGame(level: 0), TerrainType.scrubForest);
      expect(result.status, OrderValidationStatus.accepted);
    });
  });
}
