// Pins the host-level Build railroad shortcut-assignment tap flow for both
// province detail hosts. Refs #4383.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'province_shortcut_host_emit_test_support.dart';
import 'app_test_hive_harness.dart';

const String _kGameId = 'g_brr_shortcut_emit';
const String _kHumanPlayerId = 'gp1';
const String _kProvinceId = 'oldWorld|p1';
const String _kTileKey = 'oldWorld|p1|0|0';

final MapTopology _combinedTopology = provinceShortcutHostCombinedTopology();
final Map<String, MapTopology> _topologyByRegion =
    provinceShortcutHostTopologyByRegion();

final Map<String, TileMapResult> _tileMapByRegion =
    provinceShortcutHostGoldenCoastalTileMapByRegion();

Game _buildGame({required bool withRailBuilder, int roadLevel = 1}) {
  return Game(
    id: _kGameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      portsByProvinceSeaboard: const {},
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _kProvinceId,
            regionId: 'oldWorld',
            ownerId: _kHumanPlayerId,
          ),
        ],
        units: [
          if (withRailBuilder)
            Unit(
              id: 'u_rail',
              type: kUnitTypeRailBuilder,
              ownerId: _kHumanPlayerId,
              locationProvinceId: _kProvinceId,
              tileKey: _kTileKey,
              status: UnitStatus.idle,
            ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      resourceByTileKey: const {_kTileKey: 'grain'},
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          _kProvinceId: [_kTileKey],
        },
      },
      tileState: TileMapState().setRoadLevel(_kTileKey, roadLevel),
      playerVisibilityByTile: {
        _kHumanPlayerId: {_kTileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: _kHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: _kProvinceId,
        stockpile: const Stockpile(quantities: {'lumber': 10, 'steel': 10}),
        techUnlocked: const {kTechIdEarlySteamEngine: true},
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

RegionMapViewData _region() {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 1,
    height: 1,
    cellSize: 16,
    cells: const [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        terrainType: TerrainType.plains,
        resourceId: 'grain',
        ownerFactionId: _kHumanPlayerId,
        provinceDisplayName: 'Test Province',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: {_kHumanPlayerId},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {
      'oldWorld|p1': _kHumanPlayerId,
    },
  );
}

Finder _buildRailroadAction({required bool enabledOnly}) {
  return find.byWidgetPredicate(
    (Widget w) =>
        w is CtIconAction &&
        w.icon == Icons.directions_railway &&
        (!enabledOnly || w.onPressed != null),
  );
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'province_brr_shortcut_emit');
  });

  Future<List<OpenCivilianUnitsPanelEvent>> pumpHostAndSelect(
    WidgetTester tester, {
    required Game game,
    required ProvinceShortcutHostCase host,
  }) => pumpProvinceShortcutHostAndSelect(
    tester,
    gamesBox: gamesBox,
    gameService: provinceShortcutHostEmitGameService(
      gamesBox: gamesBox,
      gameId: _kGameId,
      combinedTopology: _combinedTopology,
      tileMapByRegion: _tileMapByRegion,
      topologyByRegion: _topologyByRegion,
    ),
    game: game,
    humanPlayerId: _kHumanPlayerId,
    host: host,
    region: _region(),
    combinedTopology: _combinedTopology,
    workTargetSelectionCache: refreshedProvinceShortcutWorkTargetCache(
      game: game,
      humanPlayerId: _kHumanPlayerId,
      combinedTopology: _combinedTopology,
      tileMapByRegion: _tileMapByRegion,
    ),
    selectedTileKey: _kTileKey,
  );

  Future<void> expectBuildRailroadShortcutEmits(
    WidgetTester tester, {
    required List<OpenCivilianUnitsPanelEvent> opened,
    required String hostLabel,
  }) async {
    final shortcut = _buildRailroadAction(enabledOnly: true);
    expect(
      shortcut,
      findsOneWidget,
      reason: '$hostLabel enabled Build railroad',
    );
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pump();
    expect(opened, hasLength(1));
    final event = opened.single;
    expect(event.railBuilderOnly, isTrue);
    expect(event.engineerOnly, isFalse);
    expect(event.builderOnly, isFalse);
    expect(event.explorerOnly, isFalse);
    expect(event.buildRailShortcutTargetTileKey, _kTileKey);
    expect(event.buildPortShortcutTargetTileKey, isNull);
    expect(event.buildRoadShortcutTargetTileKey, isNull);
    expect(event.buildFortShortcutTargetTileKey, isNull);
    expect(event.exploreShortcutTargetTileKey, isNull);
    expect(event.prospectShortcutTargetTileKey, isNull);
    expect(event.buildImprovementShortcutTargetTileKey, isNull);
    expect(event.purchaseLandShortcutTargetTileKey, isNull);
    expect(event.upgradeTownShortcutTargetTileKey, isNull);
  }

  for (final host in provinceShortcutHostCases) {
    testWidgets(
      '${host.wide ? 'wide' : 'narrow'} host: tapping the enabled Build '
      'railroad shortcut emits a Rail-Builder-only OpenCivilianUnitsPanelEvent '
      'targeting the exact selected tile key',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withRailBuilder: true),
          host: host,
        );
        await expectBuildRailroadShortcutEmits(
          tester,
          opened: opened,
          hostLabel: host.label,
        );
      },
    );

    testWidgets(
      'negative — ${host.wide ? 'wide' : 'narrow'} host with no Rail Builder '
      'does not enable Build railroad and emits no '
      'OpenCivilianUnitsPanelEvent',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withRailBuilder: false),
          host: host,
        );
        expect(
          _buildRailroadAction(enabledOnly: true),
          findsNothing,
          reason: host.wide
              ? 'Without an assignable Rail Builder the Build railroad inline '
                    'action must not be enabled.'
              : null,
        );
        if (host.wide) {
          final anyShortcut = _buildRailroadAction(enabledOnly: false);
          if (anyShortcut.evaluate().isNotEmpty) {
            await tester.tap(anyShortcut.first, warnIfMissed: false);
            await tester.pump();
          }
          expect(opened, isEmpty);
        } else {
          expect(opened, isEmpty);
        }
      },
    );

    testWidgets(
      'negative — ${host.wide ? 'wide' : 'narrow'} host hides Build railroad '
      'when stored transport is 0 even with a Rail Builder',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withRailBuilder: true, roadLevel: 0),
          host: host,
        );
        expect(_buildRailroadAction(enabledOnly: false), findsNothing);
        expect(opened, isEmpty);
      },
    );

    testWidgets(
      'negative — ${host.wide ? 'wide' : 'narrow'} host hides Build railroad '
      'when stored transport is 4 even with a Rail Builder',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withRailBuilder: true, roadLevel: 4),
          host: host,
        );
        expect(_buildRailroadAction(enabledOnly: false), findsNothing);
        expect(opened, isEmpty);
      },
    );
  }
}
