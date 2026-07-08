// Table-driven town manufacturing bonus scenarios (Refs #3939 phase 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'extraction_fixture_support.dart';
import 'scenario_runner.dart';
import 'town_manufacturing_bonus_expectations.dart';

/// One row in [townManufacturingBonusProvinceScenarios].
class TownManufacturingBonusProvinceScenario {
  const TownManufacturingBonusProvinceScenario({
    required this.label,
    required this.townDevelopmentLevel,
    required this.townConnectedDeliveredRawByCommodity,
    required this.verify,
    this.techUnlocked,
    this.refs,
  });

  TownManufacturingBonusProvinceScenario.expect({
    required String label,
    required int townDevelopmentLevel,
    required Map<CommodityId, int> townConnectedDeliveredRawByCommodity,
    Map<String, bool>? techUnlocked,
    required TownManufacturingBonusProvinceExpectation expect,
    String? refs,
  }) : this(
          label: label,
          townDevelopmentLevel: townDevelopmentLevel,
          townConnectedDeliveredRawByCommodity:
              townConnectedDeliveredRawByCommodity,
          techUnlocked: techUnlocked,
          refs: refs,
          verify: (bonus) =>
              assertTownManufacturingBonusProvinceExpectation(bonus, expect),
        );

  final String label;
  final int townDevelopmentLevel;
  final Map<CommodityId, int> townConnectedDeliveredRawByCommodity;
  final Map<String, bool>? techUnlocked;
  final void Function(Map<CommodityId, int> bonus) verify;
  final String? refs;
}

/// Compact province-bonus row (Refs #3939 slice 47).
TownManufacturingBonusProvinceScenario townBonusProvinceRow({
  required String label,
  required int townDevelopmentLevel,
  required Map<CommodityId, int> townConnectedDeliveredRawByCommodity,
  required TownManufacturingBonusProvinceExpectation expect,
  Map<String, bool> techUnlocked = const {},
  String? refs = '#3872',
}) =>
    TownManufacturingBonusProvinceScenario.expect(
      label: label,
      townDevelopmentLevel: townDevelopmentLevel,
      townConnectedDeliveredRawByCommodity:
          townConnectedDeliveredRawByCommodity,
      techUnlocked: techUnlocked,
      expect: expect,
      refs: refs,
    );

/// Canonical scenarios for [computeTownManufacturingBonusForProvince].
List<TownManufacturingBonusProvinceScenario>
    townManufacturingBonusProvinceScenarios() => [
  townBonusProvinceRow(
    label: 'floor(7/4)*1 = 1 lumber at level 2',
    townDevelopmentLevel: 2,
    townConnectedDeliveredRawByCommodity: {CommodityCatalog.timber.id: 7},
    expect: TownManufacturingBonusProvinceExpectation(
      commodityAmounts: {CommodityCatalog.lumber.id: 1},
    ),
  ),
  townBonusProvinceRow(
    label: 'level 4 with 4 timber → 2 lumber (replacement multiplier)',
    townDevelopmentLevel: 4,
    townConnectedDeliveredRawByCommodity: {CommodityCatalog.timber.id: 4},
    expect: TownManufacturingBonusProvinceExpectation(
      commodityAmounts: {CommodityCatalog.lumber.id: 2},
    ),
  ),
  townBonusProvinceRow(
    label: 'level 3 grants zero bonus',
    townDevelopmentLevel: 3,
    townConnectedDeliveredRawByCommodity: {CommodityCatalog.timber.id: 8},
    expect: const TownManufacturingBonusProvinceExpectation(isEmpty: true),
  ),
  townBonusProvinceRow(
    label: 'bronze limiting input min(8,2)=2 → floor(2/4)=0',
    townDevelopmentLevel: 2,
    townConnectedDeliveredRawByCommodity: {
      CommodityCatalog.copper.id: 8,
      CommodityCatalog.tin.id: 2,
    },
    expect: TownManufacturingBonusProvinceExpectation(
      absentCommodities: [CommodityCatalog.bronze.id],
    ),
  ),
  townBonusProvinceRow(
    label: 'cotton fabric requires cotton_weaving tech',
    townDevelopmentLevel: 2,
    townConnectedDeliveredRawByCommodity: {CommodityCatalog.cotton.id: 8},
    expect: TownManufacturingBonusProvinceExpectation(
      absentCommodities: [CommodityCatalog.fabric.id],
      techGated: (
        techUnlocked: {kTechIdCottonWeaving: true},
        withTechCommodityAmounts: {CommodityCatalog.fabric.id: 2},
        withTechAbsentCommodities: <CommodityId>[],
        townDevelopmentLevel: 2,
        townConnectedDeliveredRawByCommodity: {CommodityCatalog.cotton.id: 8},
      ),
    ),
  ),
];

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

/// Fixture-backed game-level scenario pins (Refs #3939 phase 3 slice 32).
enum TownManufacturingBonusGamePin {
  gpTownTimberBonus,
  minorDeliveredRaw,
  autoOffersMinor,
  previewMatchesLive,
  previewEmpty,
}

/// One row in [townManufacturingBonusGameScenarios].
class TownManufacturingBonusGameScenario implements RefsScenario {
  const TownManufacturingBonusGameScenario({
    required this.label,
    required this.pin,
    required this.expect,
    this.refs,
  });

  @override
  final String label;
  final TownManufacturingBonusGamePin pin;
  final TownManufacturingBonusGameExpectation expect;
  @override
  final String? refs;
}

void runTownManufacturingBonusGameScenario(
  TownManufacturingBonusGameScenario scenario,
) {
  runTownManufacturingBonusGamePin(scenario.pin, scenario.expect);
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

void runTownManufacturingBonusGamePin(
  TownManufacturingBonusGamePin pin,
  TownManufacturingBonusGameExpectation expect,
) {
  switch (pin) {
    case TownManufacturingBonusGamePin.gpTownTimberBonus:
      final game = _gpTownTimberGame();
      final live = computeTownManufacturingBonusForGame(
        game: game,
        tileMapByRegion: {_ow: _gpTimberTileMap()},
        gpConnectivityByPlayerId: connectivityFor({_gpTownKey, _gpTimberTile}),
        nonGpConnectivityByFactionId: const {},
      );
      assertTownManufacturingBonusGameExpectation(
        expectation: expect,
        bonusByFactionId: live.bonusByFactionId,
        deliveredRawByProvince: live.deliveredRawByProvince,
      );
    case TownManufacturingBonusGamePin.minorDeliveredRaw:
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
      assertTownManufacturingBonusGameExpectation(
        expectation: expect,
        deliveredRawByProvince: delivered,
      );
    case TownManufacturingBonusGamePin.autoOffersMinor:
      final game = TestFixtures.minimalGame(
        minorNations: const [MinorNation(id: 'm1')],
      );
      final offers = townManufacturingBonusToAutoOffers(
        game: game,
        bonusByFactionId: {
          'm1': {CommodityCatalog.lumber.id: 2},
        },
      );
      assertTownManufacturingBonusGameExpectation(
        expectation: expect,
        autoOffers: offers,
      );
    case TownManufacturingBonusGamePin.previewMatchesLive:
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
      assertTownManufacturingBonusGameExpectation(
        expectation: expect,
        bonusByProvinceId: live.bonusByProvinceId,
        bonusByFactionId: live.bonusByFactionId,
        previewByProvince: preview,
      );
    case TownManufacturingBonusGamePin.previewEmpty:
      final game = TestFixtures.minimalGame();
      final preview = previewTownManufacturingBonusByProvince(
        game: game,
        topology: const MapTopology(),
        tileMapByRegion: null,
      );
      assertTownManufacturingBonusGameExpectation(
        expectation: expect,
        previewByProvince: preview,
      );
  }
}

/// Canonical fixture-backed scenarios for game-level town manufacturing bonus.
List<TownManufacturingBonusGameScenario> townManufacturingBonusGameScenarios() =>
    [
      TownManufacturingBonusGameScenario(
        label: 'GP town-connected timber yields lumber bonus in bonusByFactionId',
        pin: TownManufacturingBonusGamePin.gpTownTimberBonus,
        expect: TownManufacturingBonusGameExpectation(
          factionBonus: {
            'pl1': {CommodityCatalog.lumber.id: 2},
          },
          deliveredRawGreaterThanZero: {
            _gpProvinceId: CommodityCatalog.timber.id,
          },
        ),
        refs: '#3872',
      ),
      TownManufacturingBonusGameScenario(
        label: 'minor town-connected timber accumulates delivered raw extraction',
        pin: TownManufacturingBonusGamePin.minorDeliveredRaw,
        expect: TownManufacturingBonusGameExpectation(
          deliveredRawGreaterThanZero: {
            'oldWorld|m1': CommodityCatalog.timber.id,
          },
        ),
        refs: '#3872',
      ),
      TownManufacturingBonusGameScenario(
        label: 'townManufacturingBonusToAutoOffers emits priority-1 offers for minors',
        pin: TownManufacturingBonusGamePin.autoOffersMinor,
        expect: TownManufacturingBonusGameExpectation(
          autoOffers: {
            'm1': TownManufacturingAutoOfferExpectation(
              commodityId: CommodityCatalog.lumber.id,
              type: TradeOrderType.offer,
              priority: 1,
              quantity: 2,
            ),
          },
        ),
        refs: '#3872',
      ),
      TownManufacturingBonusGameScenario(
        label: 'previewTownManufacturingBonusByProvince matches live bonusByProvinceId when connectivity resolves',
        pin: TownManufacturingBonusGamePin.previewMatchesLive,
        expect: TownManufacturingBonusGameExpectation(
          previewMatchesLive: true,
          previewProvinceMatchesFactionCommodity: (
            provinceId: _gpProvinceId,
            factionId: 'pl1',
            commodityId: CommodityCatalog.lumber.id,
          ),
        ),
        refs: '#3872',
      ),
      TownManufacturingBonusGameScenario(
        label: 'previewTownManufacturingBonusByProvince returns empty without tile maps',
        pin: TownManufacturingBonusGamePin.previewEmpty,
        expect: const TownManufacturingBonusGameExpectation(
          previewEmpty: true,
        ),
        refs: '#3872',
      ),
    ];
