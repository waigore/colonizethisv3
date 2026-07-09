// Compact build_rail work-rules assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/build_rail_work_rules.dart';
import 'package:colonizethis_test/test.dart';

const _early = kTechIdEarlySteamEngine;
const _later = kTechIdLaterSteamEngine;
const _dynamite = kTechIdDynamite;

/// Pins for [rejectionReasonForBuildRailOrderScenarios] rows.
enum RejectionReasonForBuildRailOrderTarget {
  rejectsWhenRoadLevelTooHigh,
  rejectsWhenRoadLevelIntermediate,
  rejectsWhenRoadLevelZero,
  rejectsWhenTerrainNull,
  plainsRejectsWithoutRailTech,
  plainsAllowsWithEarlySteam,
  hillsRejectsWithoutLaterSteamOrDynamite,
  hillsAllowsWithLaterSteam,
  mountainRejectsWithoutDynamite,
  hillsAllowsWithDynamiteOnly,
  plainsAllowsWithLaterSteamOnly,
  mountainAllowsWithDynamite,
}

/// Pins for [terrainTypeForTileKeyScenarios] rows.
enum TerrainTypeForTileKeyTarget {
  malformedTileKey,
  missingRegionMap,
  nonIntegerCoordinates,
  outOfBoundsCoordinates,
  returnsTerrainFromTileMap,
}

void runRejectionReasonForBuildRailOrderExpectation(
  RejectionReasonForBuildRailOrderTarget target,
) {
  switch (target) {
    case RejectionReasonForBuildRailOrderTarget.rejectsWhenRoadLevelTooHigh:
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {_early: true},
          roadLevel: 4,
          terrain: TerrainType.plains,
        ),
        'Tile already has maximum transport level',
      );

    case RejectionReasonForBuildRailOrderTarget.rejectsWhenRoadLevelIntermediate:
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {_early: true},
          roadLevel: 3,
          terrain: TerrainType.plains,
        ),
        'Railroad requires an existing road (transport level 1 or 2) on the tile',
      );

    case RejectionReasonForBuildRailOrderTarget.rejectsWhenRoadLevelZero:
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {_early: true},
          roadLevel: 0,
          terrain: TerrainType.plains,
        ),
        'Railroad requires an existing road (transport level 1 or 2) on the tile',
      );

    case RejectionReasonForBuildRailOrderTarget.rejectsWhenTerrainNull:
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {_early: true},
          roadLevel: 1,
          terrain: null,
        ),
        'Tile terrain data required for railroad work orders',
      );

    case RejectionReasonForBuildRailOrderTarget.plainsRejectsWithoutRailTech:
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {},
          roadLevel: 1,
          terrain: TerrainType.plains,
        ),
        'Early Steam Engine or later rail technology required for this terrain',
      );

    case RejectionReasonForBuildRailOrderTarget.plainsAllowsWithEarlySteam:
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {_early: true},
          roadLevel: 2,
          terrain: TerrainType.hardwoodForest,
        ),
        isNull,
      );

    case RejectionReasonForBuildRailOrderTarget.hillsRejectsWithoutLaterSteamOrDynamite:
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {_early: true},
          roadLevel: 1,
          terrain: TerrainType.hills,
        ),
        'Later Steam Engine or Dynamite required for rail on this terrain',
      );

    case RejectionReasonForBuildRailOrderTarget.hillsAllowsWithLaterSteam:
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {_later: true},
          roadLevel: 1,
          terrain: TerrainType.swamp,
        ),
        isNull,
      );

    case RejectionReasonForBuildRailOrderTarget.mountainRejectsWithoutDynamite:
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {_early: true, _later: true},
          roadLevel: 1,
          terrain: TerrainType.mountain,
        ),
        'Dynamite required for rail in mountains',
      );

    case RejectionReasonForBuildRailOrderTarget.hillsAllowsWithDynamiteOnly:
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {_dynamite: true},
          roadLevel: 2,
          terrain: TerrainType.hills,
        ),
        isNull,
      );

    case RejectionReasonForBuildRailOrderTarget.plainsAllowsWithLaterSteamOnly:
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {_later: true},
          roadLevel: 1,
          terrain: TerrainType.desert,
        ),
        isNull,
      );

    case RejectionReasonForBuildRailOrderTarget.mountainAllowsWithDynamite:
      expect(
        rejectionReasonForBuildRailOrder(
          techUnlocked: const {_dynamite: true},
          roadLevel: 1,
          terrain: TerrainType.mountain,
        ),
        isNull,
      );
  }
}

void runTerrainTypeForTileKeyExpectation(TerrainTypeForTileKeyTarget target) {
  switch (target) {
    case TerrainTypeForTileKeyTarget.malformedTileKey:
      expect(terrainTypeForTileKey(null, 'bad'), isNull);

    case TerrainTypeForTileKeyTarget.missingRegionMap:
      expect(
        terrainTypeForTileKey({}, 'oldWorld|P|0|0'),
        isNull,
      );

    case TerrainTypeForTileKeyTarget.nonIntegerCoordinates:
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

    case TerrainTypeForTileKeyTarget.outOfBoundsCoordinates:
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

    case TerrainTypeForTileKeyTarget.returnsTerrainFromTileMap:
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
  }
}
