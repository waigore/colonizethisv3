import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void main() {
  group('townManufacturingBonusMultiplier (Refs #3872)', () {
    test('level 2 → 1, level 4 → 2, others → 0', () {
      expect(townManufacturingBonusMultiplier(2), 1);
      expect(townManufacturingBonusMultiplier(4), 2);
      expect(townManufacturingBonusMultiplier(1), 0);
      expect(townManufacturingBonusMultiplier(3), 0);
      expect(townManufacturingBonusMultiplier(0), 0);
    });
  });

  group('isTownManufacturingRecipeEligible', () {
    test('steel recipe excluded when input includes manufactured castIron', () {
      expect(
        isTownManufacturingRecipeEligible(
          ProductionRecipesCatalog.steelFromCastIronCoal,
        ),
        isFalse,
      );
    });

    test('lumber from timber is eligible', () {
      expect(
        isTownManufacturingRecipeEligible(
          ProductionRecipesCatalog.lumberFromTimber,
        ),
        isTrue,
      );
    });
  });

  group('computeTownManufacturingBonusForProvince', () {
    test('floor(7/4)*1 = 1 lumber at level 2', () {
      final bonus = computeTownManufacturingBonusForProvince(
        townDevelopmentLevel: 2,
        townConnectedDeliveredRawByCommodity: {
          CommodityCatalog.timber.id: 7,
        },
        techUnlocked: const {},
      );
      expect(bonus[CommodityCatalog.lumber.id], 1);
    });

    test('level 4 with 4 timber → 2 lumber (replacement multiplier)', () {
      final bonus = computeTownManufacturingBonusForProvince(
        townDevelopmentLevel: 4,
        townConnectedDeliveredRawByCommodity: {
          CommodityCatalog.timber.id: 4,
        },
        techUnlocked: const {},
      );
      expect(bonus[CommodityCatalog.lumber.id], 2);
    });

    test('level 3 grants zero bonus', () {
      final bonus = computeTownManufacturingBonusForProvince(
        townDevelopmentLevel: 3,
        townConnectedDeliveredRawByCommodity: {
          CommodityCatalog.timber.id: 8,
        },
        techUnlocked: const {},
      );
      expect(bonus, isEmpty);
    });

    test('bronze limiting input min(8,2)=2 → floor(2/4)=0', () {
      final bonus = computeTownManufacturingBonusForProvince(
        townDevelopmentLevel: 2,
        townConnectedDeliveredRawByCommodity: {
          CommodityCatalog.copper.id: 8,
          CommodityCatalog.tin.id: 2,
        },
        techUnlocked: const {},
      );
      expect(bonus[CommodityCatalog.bronze.id], isNull);
    });

    test('cotton fabric requires cotton_weaving tech', () {
      final withoutTech = computeTownManufacturingBonusForProvince(
        townDevelopmentLevel: 2,
        townConnectedDeliveredRawByCommodity: {
          CommodityCatalog.cotton.id: 8,
        },
        techUnlocked: const {},
      );
      final withTech = computeTownManufacturingBonusForProvince(
        townDevelopmentLevel: 2,
        townConnectedDeliveredRawByCommodity: {
          CommodityCatalog.cotton.id: 8,
        },
        techUnlocked: {kTechIdCottonWeaving: true},
      );
      expect(withoutTech[CommodityCatalog.fabric.id], isNull);
      expect(withTech[CommodityCatalog.fabric.id], 2);
    });
  });

  group('resolveTownConnectedTileKeysForProvince', () {
    test('4-adjacent and road-path tiles within province are town-connected',
        () {
      const ow = 'oldWorld';
      const provinceId = '$ow|p1';
      const townKey = '$ow|p1|1|1';
      const adjacentKey = '$ow|p1|0|1';
      const pathKey = '$ow|p1|2|1';
      final tileState = TileMapState()
          .setRoadLevel(townKey, 1)
          .setRoadLevel(adjacentKey, 1)
          .setRoadLevel('$ow|p1|1|0', 1)
          .setRoadLevel(pathKey, 1);
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
        tileState: tileState,
        tileKeysByRegionAndProvince: {
          ow: {
            provinceId: [adjacentKey, townKey, pathKey, '$ow|p1|2|0'],
          },
        },
      );
      final map = TileMapResult(
        width: 3,
        height: 2,
        grid: const [
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1'],
        ],
      );
      final connected = resolveTownConnectedTileKeysForProvince(
        provinceId: provinceId,
        townTileKey: townKey,
        worldState: world,
        tileMapByRegion: {ow: map},
        portTileToProvinceSeaZone: const {},
      );
      expect(connected, contains(townKey));
      expect(connected, contains(adjacentKey));
      expect(connected, contains(pathKey));
      expect(connected, isNot(contains('$ow|p1|2|0')));
    });
  });
}
