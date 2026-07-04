import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

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

  group('computeTownManufacturingBonusForGame', () {
    test('GP town-connected timber yields lumber bonus in bonusByFactionId', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|p1';
      const townKey = '$provinceId|0|0';
      const timberTile = '$provinceId|1|0';
      final game = TestFixtures.minimalGame(
        players: const [
          Player(
            id: 'pl1',
            displayName: 'Spain',
            isHuman: true,
            capitalProvinceId: provinceId,
            capitalTile: CapitalTile(
              regionId: ow,
              provinceId: provinceId,
              x: 0,
              y: 0,
            ),
            techUnlocked: {kTechIdCircularSaw: true},
          ),
        ],
        capitalTileGrainBonusPerTurn: 0,
        oldWorld: RegionData(
          provinces: [
            Province(
              id: provinceId,
              regionId: ow,
              ownerId: 'pl1',
              townDevelopmentLevel: 4,
              townTileKey: townKey,
            ),
          ],
        ),
        tileKeysByRegionAndProvince: {
          ow: {provinceId: [townKey, timberTile]},
        },
        tileState: tileStateFromSpecs([
          const TileImprovementSpec(timberTile, improvement: 4, roadLevel: 4),
          const TileImprovementSpec(townKey, roadLevel: 1),
        ]),
      );
      final tileMap = TileMapResult(
        width: 2,
        height: 1,
        grid: const [
          ['p1', 'p1'],
        ],
        resourceGrid: const [
          [null, Resource.timber],
        ],
        terrainGrid: const [
          [null, TerrainType.hardwoodForest],
        ],
      );
      final result = computeTownManufacturingBonusForGame(
        game: game,
        tileMapByRegion: {ow: tileMap},
        gpConnectivityByPlayerId: connectivityFor({townKey, timberTile}),
        nonGpConnectivityByFactionId: const {},
      );
      expect(
        result.bonusByFactionId['pl1']?[CommodityCatalog.lumber.id],
        2,
      );
      expect(
        result.deliveredRawByProvince[provinceId]?[CommodityCatalog.timber.id],
        greaterThan(0),
      );
    });

    test('minor town-connected timber accumulates delivered raw extraction', () {
      const tileKey = 'oldWorld|m1|0|0';
      final game = TestFixtures.minimalGame(
        id: 'g_town_bonus_minor',
        players: const [Player(id: 'gpA', displayName: 'GP A', isHuman: true)],
        oldWorld: const RegionData(
          provinces: [
            Province(
              id: 'oldWorld|m1',
              regionId: 'oldWorld',
              ownerId: 'm1',
              townDevelopmentLevel: 4,
              townTileKey: tileKey,
            ),
          ],
        ),
        tileKeysByRegionAndProvince: {
          'oldWorld': {
            'oldWorld|m1': [tileKey],
          },
        },
        minorNations: const [
          MinorNation(
            id: 'm1',
            capitalProvinceId: 'oldWorld|m1',
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|m1',
              x: 0,
              y: 0,
            ),
          ),
        ],
        tileState: tileStateFromSpecs([
          const TileImprovementSpec(tileKey, improvement: 1, roadLevel: 1),
        ]),
      );
      final delivered = computeTownConnectedDeliveredRawByProvince(
        game: game,
        tileMapByRegion: {
          'oldWorld': singleResourceTileMap(Resource.timber, province: 'm1'),
        },
        gpConnectivityByPlayerId: const {},
        nonGpConnectivityByFactionId: const {
          'm1': ConnectivityResult(connected: {tileKey}),
        },
        townConnectedByProvinceId: const {
          'oldWorld|m1': {tileKey},
        },
      );
      expect(
        delivered['oldWorld|m1']?[CommodityCatalog.timber.id],
        greaterThan(0),
      );
    });

    test('townManufacturingBonusToAutoOffers emits priority-1 offers for minors',
        () {
      final game = TestFixtures.minimalGame(
        minorNations: const [MinorNation(id: 'm1')],
      );
      final offers = townManufacturingBonusToAutoOffers(
        game: game,
        bonusByFactionId: {
          'm1': {CommodityCatalog.lumber.id: 2},
        },
      );
      expect(offers.keys, equals(['m1']));
      expect(offers['m1']!.single.commodityId, CommodityCatalog.lumber.id);
      expect(offers['m1']!.single.type, TradeOrderType.offer);
      expect(offers['m1']!.single.priority, 1);
      expect(offers['m1']!.single.quantity, 2);
    });

    test('previewTownManufacturingBonusByProvince matches live bonusByProvinceId when connectivity resolves',
        () {
      const ow = 'oldWorld';
      const provinceId = '$ow|p1';
      const townKey = '$provinceId|0|0';
      const timberTile = '$provinceId|1|0';
      final game = TestFixtures.minimalGame(
        players: const [
          Player(
            id: 'pl1',
            displayName: 'Spain',
            isHuman: true,
            capitalProvinceId: provinceId,
            capitalTile: CapitalTile(
              regionId: ow,
              provinceId: provinceId,
              x: 0,
              y: 0,
            ),
            techUnlocked: {kTechIdCircularSaw: true},
          ),
        ],
        capitalTileGrainBonusPerTurn: 0,
        oldWorld: RegionData(
          provinces: [
            Province(
              id: provinceId,
              regionId: ow,
              ownerId: 'pl1',
              townDevelopmentLevel: 4,
              townTileKey: townKey,
            ),
          ],
        ),
        tileKeysByRegionAndProvince: {
          ow: {provinceId: [townKey, timberTile]},
        },
        tileState: tileStateFromSpecs([
          const TileImprovementSpec(timberTile, improvement: 4, roadLevel: 4),
          const TileImprovementSpec(townKey, roadLevel: 1),
        ]),
      );
      final tileMap = TileMapResult(
        width: 2,
        height: 1,
        grid: const [
          ['p1', 'p1'],
        ],
        resourceGrid: const [
          [null, Resource.timber],
        ],
        terrainGrid: const [
          [null, TerrainType.hardwoodForest],
        ],
      );
      final tileMaps = {ow: tileMap};
      const topology = MapTopology();
      final gpConnectivity = resolveConnectivity(
        game: game,
        tileMapByRegion: tileMaps,
        topology: topology,
      );
      final nonGpConnectivity = resolveNonGreatPowerConnectivity(
        game: game,
        tileMapByRegion: tileMaps,
        topology: topology,
      );
      final live = computeTownManufacturingBonusForGame(
        game: game,
        tileMapByRegion: tileMaps,
        gpConnectivityByPlayerId: gpConnectivity,
        nonGpConnectivityByFactionId: nonGpConnectivity,
      );
      final preview = previewTownManufacturingBonusByProvince(
        game: game,
        topology: topology,
        tileMapByRegion: tileMaps,
      );
      expect(preview, live.bonusByProvinceId);
      expect(
        preview[provinceId]?[CommodityCatalog.lumber.id],
        live.bonusByFactionId['pl1']?[CommodityCatalog.lumber.id],
      );
    });

    test('previewTownManufacturingBonusByProvince returns empty without tile maps',
        () {
      final game = TestFixtures.minimalGame();
      expect(
        previewTownManufacturingBonusByProvince(
          game: game,
          topology: const MapTopology(),
          tileMapByRegion: null,
        ),
        isEmpty,
      );
    });
  });
}
