import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/orders/build_rail_work_rules.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('rejectionReasonForBuildRailOrder', () {
    const early = kTechIdEarlySteamEngine;
    const later = kTechIdLaterSteamEngine;
    const dynamite = kTechIdDynamite;

    test('rejects when road level is neither 1 nor 2 (too high)', () {
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {early: true},
          roadLevel: 4,
          terrain: TerrainType.plains,
        ),
        'Tile already has maximum transport level',
      );
    });

    test('rejects when road level is 3 (intermediate, not 1 or 2)', () {
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {early: true},
          roadLevel: 3,
          terrain: TerrainType.plains,
        ),
        'Railroad requires an existing road (transport level 1 or 2) on the tile',
      );
    });

    test('rejects when road level is 0', () {
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {early: true},
          roadLevel: 0,
          terrain: TerrainType.plains,
        ),
        'Railroad requires an existing road (transport level 1 or 2) on the tile',
      );
    });

    test('rejects when terrain is null', () {
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {early: true},
          roadLevel: 1,
          terrain: null,
        ),
        'Tile terrain data required for railroad work orders',
      );
    });

    test('plains: rejects without rail tech', () {
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {},
          roadLevel: 1,
          terrain: TerrainType.plains,
        ),
        'Early Steam Engine or later rail technology required for this terrain',
      );
    });

    test('plains: allows with Early Steam', () {
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {early: true},
          roadLevel: 2,
          terrain: TerrainType.forest,
        ),
        isNull,
      );
    });

    test('hills: rejects without Later Steam or Dynamite', () {
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {early: true},
          roadLevel: 1,
          terrain: TerrainType.hills,
        ),
        'Later Steam Engine or Dynamite required for rail on this terrain',
      );
    });

    test('hills: allows with Later Steam', () {
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {later: true},
          roadLevel: 1,
          terrain: TerrainType.swamp,
        ),
        isNull,
      );
    });

    test('mountain: rejects without Dynamite', () {
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {early: true, later: true},
          roadLevel: 1,
          terrain: TerrainType.mountain,
        ),
        'Dynamite required for rail in mountains',
      );
    });

    test('hills: allows with Dynamite only', () {
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {dynamite: true},
          roadLevel: 2,
          terrain: TerrainType.hills,
        ),
        isNull,
      );
    });

    test('plains: allows with Later Steam only', () {
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {later: true},
          roadLevel: 1,
          terrain: TerrainType.desert,
        ),
        isNull,
      );
    });

    test('mountain: allows with Dynamite', () {
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {dynamite: true},
          roadLevel: 1,
          terrain: TerrainType.mountain,
        ),
        isNull,
      );
    });
  });

  group('terrainTypeForTileKey', () {
    test('returns null for malformed tile key', () {
      expect(terrainTypeForTileKey(null, 'bad'), isNull);
    });

    test('returns null when region map is missing', () {
      expect(
        terrainTypeForTileKey({}, 'oldWorld|P|0|0'),
        isNull,
      );
    });

    test('returns null when x or y are not integers', () {
      final m = TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['P'],
        ],
        terrainGrid: [
          [TerrainType.plains],
        ],
      );
      expect(
        terrainTypeForTileKey({'oldWorld': m}, 'oldWorld|P|x|0'),
        isNull,
      );
    });

    test('returns null when coordinates are out of bounds', () {
      final m = TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['P'],
        ],
        terrainGrid: [
          [TerrainType.plains],
        ],
      );
      expect(
        terrainTypeForTileKey({'oldWorld': m}, 'oldWorld|P|1|0'),
        isNull,
      );
    });

    test('returns terrain from tile map', () {
      final m = TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['P'],
        ],
        terrainGrid: [
          [TerrainType.desert],
        ],
      );
      expect(
        terrainTypeForTileKey({'oldWorld': m}, 'oldWorld|P|0|0'),
        TerrainType.desert,
      );
    });
  });
}
