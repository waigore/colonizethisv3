import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

// --- Wave 2 runners (Refs #4410) ---
// dart format off
const _ow = 'oldWorld';
const _gpProvinceId = '$_ow|p1';
const _gpTownKey = '$_gpProvinceId|0|0';
const _gpTimberTile = '$_gpProvinceId|1|0';
({Game game, Map<String, TileMapResult> tileMaps}) _gpTownTimberFixture() {
  final tileMaps = {
    _ow: TileMapResult(
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
    ),
  };
  return (
    game: spainExtractorGame(
      techUnlocked: {kTechIdCircularSaw: true},
      oldWorld: RegionData(provinces: [owP1Province(townTileKey: _gpTownKey)]),
      tileKeysByRegionAndProvince: {
        _ow: {
          _gpProvinceId: [_gpTownKey, _gpTimberTile],
        },
      },
      tileState: tileStateFromSpecs(const [TileImprovementSpec(_gpTimberTile, 4, 4), TileImprovementSpec(_gpTownKey, 0, 1)]),
    ),
    tileMaps: tileMaps,
  );
}
void runTownManufacturingBonusGamePin(TownManufacturingBonusGamePin pin, TownManufacturingBonusGameExpectation expect) {
  switch (pin) {
    case TownManufacturingBonusGamePin.gpTownTimberBonus:
      final f = _gpTownTimberFixture();
      final live = computeTownManufacturingBonusForGame(game: f.game, tileMapByRegion: f.tileMaps, gpConnectivityByPlayerId: connectivityFor({_gpTownKey, _gpTimberTile}), nonGpConnectivityByFactionId: const {});
      assertTownManufacturingBonusGameExpectation(expectation: expect, bonusByFactionId: live.bonusByFactionId, deliveredRawByProvince: live.deliveredRawByProvince);
    case TownManufacturingBonusGamePin.minorDeliveredRaw:
      const tileKey = 'oldWorld|m1|0|0';
      final game = nonGpMinorM1Game(
        id: 'g_town_bonus_minor',
        townDev: 4,
        townTileKey: tileKey,
        tileSpecs: const [TileImprovementSpec(tileKey, 1, 1)],
        players: const [Player(id: 'gpA', displayName: 'GP A', isHuman: true)],
        tileKeysByRegionAndProvince: {
          'oldWorld': {
            'oldWorld|m1': [tileKey],
          },
        },
      );
      final delivered = computeTownConnectedDeliveredRawByProvince(
        game: game,
        tileMapByRegion: {'oldWorld': singleTileMap(Resource.timber, province: 'm1')},
        gpConnectivityByPlayerId: const {},
        nonGpConnectivityByFactionId: connectivityByFaction({
          'm1': {tileKey},
        }),
        townConnectedByProvinceId: const {
          'oldWorld|m1': {tileKey},
        },
      );
      assertTownManufacturingBonusGameExpectation(expectation: expect, deliveredRawByProvince: delivered);
    case TownManufacturingBonusGamePin.autoOffersMinor:
      final game = TestFixtures.minimalGame(minorNations: const [MinorNation(id: 'm1')]);
      final offers = townManufacturingBonusToAutoOffers(
        game: game,
        bonusByFactionId: {
          'm1': {'lumber': 2},
        },
      );
      assertTownManufacturingBonusGameExpectation(expectation: expect, autoOffers: offers);
    case TownManufacturingBonusGamePin.previewMatchesLive:
      final f = _gpTownTimberFixture();
      const topology = MapTopology();
      final live = computeTownManufacturingBonusForGame(
        game: f.game,
        tileMapByRegion: f.tileMaps,
        gpConnectivityByPlayerId: resolveConnectivity(game: f.game, tileMapByRegion: f.tileMaps, topology: topology),
        nonGpConnectivityByFactionId: resolveNonGreatPowerConnectivity(game: f.game, tileMapByRegion: f.tileMaps, topology: topology),
      );
      assertTownManufacturingBonusGameExpectation(
        expectation: expect,
        bonusByProvinceId: live.bonusByProvinceId,
        bonusByFactionId: live.bonusByFactionId,
        previewByProvince: previewTownManufacturingBonusByProvince(game: f.game, topology: topology, tileMapByRegion: f.tileMaps),
      );
    case TownManufacturingBonusGamePin.previewEmpty:
      final game = TestFixtures.minimalGame();
      final preview = previewTownManufacturingBonusByProvince(game: game, topology: const MapTopology(), tileMapByRegion: null);
      assertTownManufacturingBonusGameExpectation(expectation: expect, previewByProvince: preview);
  }
}
void runTownManufacturingBonusGameScenario(TownManufacturingBonusGameScenario scenario) {
  runTownManufacturingBonusGamePin(scenario.pin, scenario.expect);
}
// dart format on

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
    test('recipe excluded when any input is manufactured', () {
      expect(
        isTownManufacturingRecipeEligible(
          ProductionRecipe(
            id: 'test_steel_from_castIron',
            outputCommodityId: CommodityCatalog.steel.id,
            outputQuantity: 1,
            inputQuantities: {
              CommodityCatalog.castIron.id: 2,
              CommodityCatalog.coal.id: 1,
            },
            labourPerOutput: 5,
          ),
        ),
        isFalse,
      );
    });

    test('steel from iron and coal is eligible (all raw inputs)', () {
      expect(
        isTownManufacturingRecipeEligible(
          ProductionRecipesCatalog.steelFromIronCoal,
        ),
        isTrue,
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
    runLabeledScenarios(townManufacturingBonusProvinceScenarios(), (scenario) {
      runTownManufacturingBonusProvinceScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  runLabeledScenarioGroup(
    'computeTownManufacturingBonusForGame',
    townManufacturingBonusGameScenarios(),
    runTownManufacturingBonusGameScenario,
    labelOf: (s) => s.label,
  );
}
