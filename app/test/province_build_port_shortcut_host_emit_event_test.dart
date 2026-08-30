// Pins the host-level Build port *shortcut-assignment* tap flow for both
// province detail hosts. Refs #4332, #4352.

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

const String _kGameId = 'g_bp_shortcut_emit';
const String _kHumanPlayerId = 'gp1';
const String _kProvinceId = 'oldWorld|p1';
const String _kTileKey = 'oldWorld|p1|0|0';

final MapTopology _combinedTopology = provinceShortcutHostCombinedTopology();
final Map<String, MapTopology> _topologyByRegion =
    provinceShortcutHostTopologyByRegion();

final Map<String, TileMapResult> _tileMapByRegion =
    provinceShortcutHostGoldenCoastalTileMapByRegion();

Game _buildGame({required bool withEngineer}) {
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
          if (withEngineer)
            Unit(
              id: 'u_engineer',
              type: kUnitTypeEngineer,
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
      tileState: TileMapState(),
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
        stockpile: const Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
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

Finder _buildPortAction({required bool enabledOnly}) {
  return find.byWidgetPredicate(
    (Widget w) =>
        w is CtIconAction &&
        w.icon == Icons.anchor &&
        (!enabledOnly || w.onPressed != null),
  );
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_province_bp_shortcut_emit');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
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

  Future<void> expectBuildPortShortcutEmits(
    WidgetTester tester, {
    required List<OpenCivilianUnitsPanelEvent> opened,
    required String hostLabel,
  }) async {
    final shortcut = _buildPortAction(enabledOnly: true);
    expect(shortcut, findsOneWidget, reason: '$hostLabel enabled Build port');
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pump();
    expect(opened, hasLength(1));
    final event = opened.single;
    expect(event.engineerOnly, isTrue);
    expect(event.builderOnly, isFalse);
    expect(event.explorerOnly, isFalse);
    expect(event.buildPortShortcutTargetTileKey, _kTileKey);
    expect(event.exploreShortcutTargetTileKey, isNull);
    expect(event.prospectShortcutTargetTileKey, isNull);
    expect(event.buildImprovementShortcutTargetTileKey, isNull);
  }

  for (final host in provinceShortcutHostCases) {
    testWidgets(
      '${host.wide ? 'wide' : 'narrow'} host: tapping the enabled Build '
      'road shortcut emits an Engineer-only OpenCivilianUnitsPanelEvent '
      'targeting the exact selected tile key',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withEngineer: true),
          host: host,
        );
        await expectBuildPortShortcutEmits(
          tester,
          opened: opened,
          hostLabel: host.label,
        );
      },
    );

    testWidgets(
      'negative — ${host.wide ? 'wide' : 'narrow'} host with no Engineer unit '
      'does not enable Build port and emits no '
      'OpenCivilianUnitsPanelEvent',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withEngineer: false),
          host: host,
        );
        expect(
          _buildPortAction(enabledOnly: true),
          findsNothing,
          reason: host.wide
              ? 'Without an assignable Engineer the Build port inline '
                    'action must not be enabled.'
              : null,
        );
        if (host.wide) {
          final anyShortcut = _buildPortAction(enabledOnly: false);
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
  }
}
