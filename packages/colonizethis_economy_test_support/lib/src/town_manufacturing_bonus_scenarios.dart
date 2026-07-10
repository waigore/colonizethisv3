// dart format off
// Table-driven town manufacturing bonus scenarios (Refs #3939 phase 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'extraction_fixture_support.dart';
import 'town_manufacturing_bonus_expectations.dart';

/// One row in [townManufacturingBonusProvinceScenarios].
typedef TownManufacturingBonusProvinceScenario = ({String label, int townDevelopmentLevel, Map<CommodityId, int> townConnectedDeliveredRawByCommodity, Map<String, bool>? techUnlocked, void Function(Map<CommodityId, int> bonus) verify, String? refs});

/// Compact province-bonus row (Refs #3939 slice 47 / 57).
TownManufacturingBonusProvinceScenario townBonusProvinceRow({required String label, required int townDevelopmentLevel, required Map<CommodityId, int> townConnectedDeliveredRawByCommodity, required TownManufacturingBonusProvinceExpectation expect, Map<String, bool> techUnlocked = const {}, String? refs = '#3872'}) => (label: label, townDevelopmentLevel: townDevelopmentLevel, townConnectedDeliveredRawByCommodity: townConnectedDeliveredRawByCommodity, techUnlocked: techUnlocked, refs: refs, verify: (bonus) => assertTownManufacturingBonusProvinceExpectation(bonus, expect, townDevelopmentLevel: townDevelopmentLevel, townConnectedDeliveredRawByCommodity: townConnectedDeliveredRawByCommodity));

/// Canonical scenarios for [computeTownManufacturingBonusForProvince].
List<TownManufacturingBonusProvinceScenario> townManufacturingBonusProvinceScenarios() => [
  townBonusProvinceRow(
    label: 'floor(7/4)*1 = 1 lumber at level 2',
    townDevelopmentLevel: 2,
    townConnectedDeliveredRawByCommodity: {'timber': 7},
    expect: TownManufacturingBonusProvinceExpectation(commodityAmounts: {'lumber': 1}),
  ),
  townBonusProvinceRow(
    label: 'level 4 with 4 timber → 2 lumber (replacement multiplier)',
    townDevelopmentLevel: 4,
    townConnectedDeliveredRawByCommodity: {'timber': 4},
    expect: TownManufacturingBonusProvinceExpectation(commodityAmounts: {'lumber': 2}),
  ),
  townBonusProvinceRow(label: 'level 3 grants zero bonus', townDevelopmentLevel: 3, townConnectedDeliveredRawByCommodity: {'timber': 8}, expect: const TownManufacturingBonusProvinceExpectation(isEmpty: true)),
  townBonusProvinceRow(
    label: 'bronze limiting input min(8,2)=2 → floor(2/4)=0',
    townDevelopmentLevel: 2,
    townConnectedDeliveredRawByCommodity: {'copper': 8, 'tin': 2},
    expect: TownManufacturingBonusProvinceExpectation(absentCommodities: ['bronze']),
  ),
  townBonusProvinceRow(
    label: 'cotton fabric requires cotton_weaving tech',
    townDevelopmentLevel: 2,
    townConnectedDeliveredRawByCommodity: {'cotton': 8},
    expect: TownManufacturingBonusProvinceExpectation(absentCommodities: ['fabric'], techGated: (techUnlocked: {kTechIdCottonWeaving: true}, withTechCommodityAmounts: {'fabric': 2}, withTechAbsentCommodities: <CommodityId>[])),
  ),
];

void runTownManufacturingBonusProvinceScenario(TownManufacturingBonusProvinceScenario scenario) {
  final bonus = computeTownManufacturingBonusForProvince(townDevelopmentLevel: scenario.townDevelopmentLevel, townConnectedDeliveredRawByCommodity: scenario.townConnectedDeliveredRawByCommodity, techUnlocked: scenario.techUnlocked);
  scenario.verify(bonus);
}

/// Fixture-backed game-level scenario pins (Refs #3939 phase 3 slice 32).
enum TownManufacturingBonusGamePin { gpTownTimberBonus, minorDeliveredRaw, autoOffersMinor, previewMatchesLive, previewEmpty }

/// One row in [townManufacturingBonusGameScenarios] (Refs #3939 slice 63).
typedef TownManufacturingBonusGameScenario = ({String label, TownManufacturingBonusGamePin pin, TownManufacturingBonusGameExpectation expect, String? refs});

void runTownManufacturingBonusGameScenario(TownManufacturingBonusGameScenario scenario) {
  runTownManufacturingBonusGamePin(scenario.pin, scenario.expect);
}

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

/// Canonical fixture-backed scenarios for game-level town manufacturing bonus.
List<TownManufacturingBonusGameScenario> townManufacturingBonusGameScenarios() => [
  (
    label: 'GP town-connected timber yields lumber bonus in bonusByFactionId',
    pin: TownManufacturingBonusGamePin.gpTownTimberBonus,
    expect: TownManufacturingBonusGameExpectation(
      factionBonus: {
        'pl1': {'lumber': 2},
      },
      deliveredRawGreaterThanZero: {_gpProvinceId: 'timber'},
    ),
    refs: '#3872',
  ),
  (label: 'minor town-connected timber accumulates delivered raw extraction', pin: TownManufacturingBonusGamePin.minorDeliveredRaw, expect: TownManufacturingBonusGameExpectation(deliveredRawGreaterThanZero: {'oldWorld|m1': 'timber'}), refs: '#3872'),
  (
    label: 'townManufacturingBonusToAutoOffers emits priority-1 offers for minors',
    pin: TownManufacturingBonusGamePin.autoOffersMinor,
    expect: TownManufacturingBonusGameExpectation(
      autoOffers: {'m1': TownManufacturingAutoOfferExpectation(commodityId: 'lumber', type: TradeOrderType.offer, priority: 1, quantity: 2)},
    ),
    refs: '#3872',
  ),
  (label: 'previewTownManufacturingBonusByProvince matches live bonusByProvinceId when connectivity resolves', pin: TownManufacturingBonusGamePin.previewMatchesLive, expect: TownManufacturingBonusGameExpectation(previewMatchesLive: true, previewProvinceMatchesFactionCommodity: (provinceId: _gpProvinceId, factionId: 'pl1', commodityId: 'lumber')), refs: '#3872'),
  (label: 'previewTownManufacturingBonusByProvince returns empty without tile maps', pin: TownManufacturingBonusGamePin.previewEmpty, expect: const TownManufacturingBonusGameExpectation(previewEmpty: true), refs: '#3872'),
];
// dart format on
