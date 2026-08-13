// Pins the host-level Upgrade town *shortcut-assignment* tap flow for
// both province detail hosts. SPEC/ui/province-sea-zone-detail-overlay.md;
// SPEC/ui/civilian-units-panel.md. Refs #4316, #4352.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_state_logic.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'province_shortcut_host_emit_test_support.dart';

const String _kGameId = 'g_ut_shortcut_emit';
const String _kHumanPlayerId = 'gp1';
const String _kProvinceId = 'oldWorld|p1';
const String _kTileKey = 'oldWorld|p1|0|0';

final MapTopology _combinedTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|s1',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
  ],
  edges: const [TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|s1')],
);

final Map<String, MapTopology> _topologyByRegion = {
  'oldWorld': MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 's1',
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
  ),
};

final Map<String, TileMapResult> _tileMapByRegion = {
  'oldWorld': TileMapResult(
    width: 1,
    height: 1,
    grid: const [
      ['p1'],
    ],
    terrainGrid: const [
      [TerrainType.plains],
    ],
    resourceGrid: const [
      [Resource.grain],
    ],
  ),
};

Game _buildGame({required bool withBuilder}) {
  return Game(
    id: _kGameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _kProvinceId,
            regionId: 'oldWorld',
            ownerId: _kHumanPlayerId,
            townDevelopmentLevel: 2,
            townTileKey: _kTileKey,
          ),
        ],
        units: [
          if (withBuilder)
            Unit(
              id: 'u_builder',
              type: kUnitTypeBuilder,
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
        techUnlocked: const {kTechIdNationalBureaucracy: true},
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

Finder _upgradeTownAction({required bool enabledOnly}) {
  final l10n = AppLocalizationsEn();
  return find.byWidgetPredicate(
    (Widget w) =>
        w is CtActionTextButton &&
        w.label == l10n.provinceOverlay_upgradeTownAction &&
        (!enabledOnly || (w.enabled && w.onPressed != null)),
  );
}

const List<ProvinceShortcutHostCase> _hostCases = provinceShortcutHostCases;

void main() {
  suppressLogsForTests();

  test('upgrade town action state fixture is enabled for host wiring', () {
    final game = _buildGame(withBuilder: true);
    final playerView = buildPlayerView(game, _combinedTopology, _kHumanPlayerId);
    final state = GameMapAreaStateLogicProvinceActions.provinceUpgradeTownActionState(
      game: game,
      humanPlayerId: _kHumanPlayerId,
      provinceId: _kProvinceId,
      playerView: playerView,
      topology: _combinedTopology,
      currentOrders: const Orders(),
      tileMapByRegion: _tileMapByRegion,
    );
    expect(state.showControl, isTrue);
    expect(state.enabled, isTrue);
    expect(state.townTileKey, _kTileKey);
  });

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_province_ut_shortcut_emit');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  Future<List<OpenCivilianUnitsPanelEvent>> pumpHostAndSelect(
    WidgetTester tester, {
    required Game game,
    required ProvinceShortcutHostCase host,
  }) =>
      pumpProvinceShortcutHostAndSelect(
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
        host: provinceShortcutHostCaseWithoutTileTab(host),
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

  Future<void> expectUpgradeTownShortcutEmits(
    WidgetTester tester, {
    required List<OpenCivilianUnitsPanelEvent> opened,
    required String hostLabel,
  }) async {
    final shortcut = _upgradeTownAction(enabledOnly: true);
    expect(shortcut, findsOneWidget, reason: '$hostLabel enabled Upgrade town');
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pump();
    expect(opened, hasLength(1));
    final event = opened.single;
    expect(event.builderOnly, isTrue);
    expect(event.explorerOnly, isFalse);
    expect(event.engineerOnly, isFalse);
    expect(event.merchantOnly, isFalse);
    expect(event.upgradeTownShortcutTargetTileKey, _kTileKey);
    expect(event.exploreShortcutTargetTileKey, isNull);
    expect(event.prospectShortcutTargetTileKey, isNull);
    expect(event.buildImprovementShortcutTargetTileKey, isNull);
    expect(event.buildRoadShortcutTargetTileKey, isNull);
    expect(event.buildFortShortcutTargetTileKey, isNull);
    expect(event.purchaseLandShortcutTargetTileKey, isNull);
  }

  for (final host in _hostCases) {
    testWidgets(
      '${host.wide ? 'wide' : 'narrow'} host: tapping the enabled Upgrade '
      'town shortcut emits a Builder-only OpenCivilianUnitsPanelEvent '
      'targeting the province town tile key',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withBuilder: true),
          host: host,
        );
        await expectUpgradeTownShortcutEmits(
          tester,
          opened: opened,
          hostLabel: host.label,
        );
      },
    );

    testWidgets(
      'negative — ${host.wide ? 'wide' : 'narrow'} host with no Builder unit '
      'does not enable Upgrade town and emits no '
      'OpenCivilianUnitsPanelEvent',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withBuilder: false),
          host: host,
        );
        expect(_upgradeTownAction(enabledOnly: true), findsNothing);
        final disabled = _upgradeTownAction(enabledOnly: false);
        if (disabled.evaluate().isNotEmpty) {
          await tester.tap(disabled.first, warnIfMissed: false);
          await tester.pump();
        }
        expect(opened, isEmpty);
      },
    );
  }
}
