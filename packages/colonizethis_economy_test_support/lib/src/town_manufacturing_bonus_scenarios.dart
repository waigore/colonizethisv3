// Table-driven town manufacturing bonus scenarios (Refs #3939 phase 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'resource_extractor_test_support.dart';
import 'scenario_runner.dart';
import 'tile_map_test_support.dart';

/// One row in [townManufacturingBonusProvinceScenarios].
typedef TownManufacturingBonusProvinceScenario = ({
  String label,
  int townDevelopmentLevel,
  Map<CommodityId, int> townConnectedDeliveredRawByCommodity,
  Map<String, bool>? techUnlocked,
  void Function(Map<CommodityId, int> bonus) verify,
  String? refs,
});

/// Canonical scenarios for [computeTownManufacturingBonusForProvince].
List<TownManufacturingBonusProvinceScenario>
    townManufacturingBonusProvinceScenarios() => [
  (
    label: 'floor(7/4)*1 = 1 lumber at level 2',
    townDevelopmentLevel: 2,
    townConnectedDeliveredRawByCommodity: {CommodityCatalog.timber.id: 7},
    techUnlocked: const {},
    verify: _expectLumber1,
    refs: '#3872',
  ),
  (
    label: 'level 4 with 4 timber → 2 lumber (replacement multiplier)',
    townDevelopmentLevel: 4,
    townConnectedDeliveredRawByCommodity: {CommodityCatalog.timber.id: 4},
    techUnlocked: const {},
    verify: _expectLumber2,
    refs: '#3872',
  ),
  (
    label: 'level 3 grants zero bonus',
    townDevelopmentLevel: 3,
    townConnectedDeliveredRawByCommodity: {CommodityCatalog.timber.id: 8},
    techUnlocked: const {},
    verify: _expectEmptyBonus,
    refs: '#3872',
  ),
  (
    label: 'bronze limiting input min(8,2)=2 → floor(2/4)=0',
    townDevelopmentLevel: 2,
    townConnectedDeliveredRawByCommodity: {
      CommodityCatalog.copper.id: 8,
      CommodityCatalog.tin.id: 2,
    },
    techUnlocked: const {},
    verify: _expectNoBronze,
    refs: '#3872',
  ),
  (
    label: 'cotton fabric requires cotton_weaving tech',
    townDevelopmentLevel: 2,
    townConnectedDeliveredRawByCommodity: {CommodityCatalog.cotton.id: 8},
    techUnlocked: const {},
    verify: _expectCottonFabricTechGated,
    refs: '#3872',
  ),
];

void _expectLumber1(Map<CommodityId, int> bonus) {
  expect(bonus[CommodityCatalog.lumber.id], 1);
}

void _expectLumber2(Map<CommodityId, int> bonus) {
  expect(bonus[CommodityCatalog.lumber.id], 2);
}

void _expectEmptyBonus(Map<CommodityId, int> bonus) {
  expect(bonus, isEmpty);
}

void _expectNoBronze(Map<CommodityId, int> bonus) {
  expect(bonus[CommodityCatalog.bronze.id], isNull);
}

void _expectCottonFabricTechGated(Map<CommodityId, int> bonus) {
  expect(bonus[CommodityCatalog.fabric.id], isNull);
  final withTech = computeTownManufacturingBonusForProvince(
    townDevelopmentLevel: 2,
    townConnectedDeliveredRawByCommodity: {CommodityCatalog.cotton.id: 8},
    techUnlocked: {kTechIdCottonWeaving: true},
  );
  expect(withTech[CommodityCatalog.fabric.id], 2);
}

void runTownManufacturingBonusProvinceScenario(
  TownManufacturingBonusProvinceScenario scenario,
) {
  final bonus = computeTownManufacturingBonusForProvince(
    townDevelopmentLevel: scenario.townDevelopmentLevel,
    townConnectedDeliveredRawByCommodity:
        scenario.townConnectedDeliveredRawByCommodity,
    techUnlocked: scenario.techUnlocked,
  );
  scenario.verify(bonus);
}

/// One row in [townManufacturingBonusGameScenarios].
class TownManufacturingBonusGameScenario implements RefsScenario {
  const TownManufacturingBonusGameScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runTownManufacturingBonusGameScenario(
  TownManufacturingBonusGameScenario scenario,
) {
  scenario.run();
}

const _ow = 'oldWorld';
const _gpProvinceId = '$_ow|p1';
const _gpTownKey = '$_gpProvinceId|0|0';
const _gpTimberTile = '$_gpProvinceId|1|0';

TileMapResult _gpTimberTileMap() => TileMapResult(
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

Game _gpTownTimberGame() => TestFixtures.minimalGame(
      players: const [
        Player(
          id: 'pl1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: _gpProvinceId,
          capitalTile: CapitalTile(
            regionId: _ow,
            provinceId: _gpProvinceId,
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
            id: _gpProvinceId,
            regionId: _ow,
            ownerId: 'pl1',
            townDevelopmentLevel: 4,
            townTileKey: _gpTownKey,
          ),
        ],
      ),
      tileKeysByRegionAndProvince: {
        _ow: {
          _gpProvinceId: [_gpTownKey, _gpTimberTile],
        },
      },
      tileState: tileStateFromSpecs([
        const TileImprovementSpec(_gpTimberTile, improvement: 4, roadLevel: 4),
        const TileImprovementSpec(_gpTownKey, roadLevel: 1),
      ]),
    );

/// Canonical fixture-backed scenarios for game-level town manufacturing bonus.
List<TownManufacturingBonusGameScenario> townManufacturingBonusGameScenarios() =>
    [
      TownManufacturingBonusGameScenario(
        label: 'GP town-connected timber yields lumber bonus in bonusByFactionId',
        run: () {
          final game = _gpTownTimberGame();
          final result = computeTownManufacturingBonusForGame(
            game: game,
            tileMapByRegion: {_ow: _gpTimberTileMap()},
            gpConnectivityByPlayerId:
                connectivityFor({_gpTownKey, _gpTimberTile}),
            nonGpConnectivityByFactionId: const {},
          );
          expect(
            result.bonusByFactionId['pl1']?[CommodityCatalog.lumber.id],
            2,
          );
          expect(
            result.deliveredRawByProvince[_gpProvinceId]
                ?[CommodityCatalog.timber.id],
            greaterThan(0),
          );
        },
        refs: '#3872',
      ),
      TownManufacturingBonusGameScenario(
        label: 'minor town-connected timber accumulates delivered raw extraction',
        run: () {
          const tileKey = 'oldWorld|m1|0|0';
          final game = TestFixtures.minimalGame(
            id: 'g_town_bonus_minor',
            players: const [
              Player(id: 'gpA', displayName: 'GP A', isHuman: true),
            ],
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
        },
        refs: '#3872',
      ),
      TownManufacturingBonusGameScenario(
        label: 'townManufacturingBonusToAutoOffers emits priority-1 offers for minors',
        run: () {
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
        },
        refs: '#3872',
      ),
      TownManufacturingBonusGameScenario(
        label: 'previewTownManufacturingBonusByProvince matches live bonusByProvinceId when connectivity resolves',
        run: () {
          final game = _gpTownTimberGame();
          final tileMaps = {_ow: _gpTimberTileMap()};
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
            preview[_gpProvinceId]?[CommodityCatalog.lumber.id],
            live.bonusByFactionId['pl1']?[CommodityCatalog.lumber.id],
          );
        },
        refs: '#3872',
      ),
      TownManufacturingBonusGameScenario(
        label: 'previewTownManufacturingBonusByProvince returns empty without tile maps',
        run: () {
          final game = TestFixtures.minimalGame();
          expect(
            previewTownManufacturingBonusByProvince(
              game: game,
              topology: const MapTopology(),
              tileMapByRegion: null,
            ),
            isEmpty,
          );
        },
        refs: '#3872',
      ),
    ];
